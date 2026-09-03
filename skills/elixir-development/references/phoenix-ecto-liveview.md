# Phoenix, Ecto, LiveView & Supervision

On-demand reference for `elixir-development`.

Read this when the task touches Phoenix contexts, controllers, Ecto schemas,
changesets, queries, migrations, LiveView, PubSub, background work, or the supervision
tree.

Style and general Elixir idioms still come from `SKILL.md`; this file adds
framework-specific boundaries, security checks, and runtime guidance.

## Architecture: contexts as the boundary

Phoenix is the web interface into an Elixir application. Treat contexts as the
application boundary that owns business rules, data access, and validation.

Rules:

* Keep the web layer thin (controllers, LiveViews, LiveComponents, channels, plugs).
* The web layer parses input, authorizes, calls a context, and renders.
* Business logic and persistence live in contexts, not controllers or LiveViews.
* A context owns a bounded concept, such as `Accounts`, `Billing`, `Catalog`, or
  `Search`.
* Do not reach into another context's schemas or `Repo` calls directly. Call the
  other context's public API.
* Never call `Repo` from controllers or LiveViews unless the project has a deliberate,
  documented exception.
* If a controller, LiveView, or component imports or aliases `Repo`, flag it as a
  likely boundary leak.
* Context functions should return stable shapes for expected outcomes: `{:ok, value}`,
  `{:error, reason}`, or `{:error, changeset}`.
* Do not vary return shapes via options. Prefer separate functions with clear names.

```elixir
# good — web layer calls the context, context owns the scope check
def show(conn, %{"id" => id}) do
  with {:ok, invoice} <- Billing.fetch_invoice(current_scope(conn), id) do
    render(conn, :show, invoice: invoice)
  end
end

# bad — Repo leaks into the web layer, no scope check
def show(conn, %{"id" => id}) do
  invoice = Repo.get!(Invoice, id)
  render(conn, :show, invoice: invoice)
end
```

---

## Ecto

### Schemas and changesets

Changesets are the boundary for casting, validating, and preparing external changes.

Rules:

* `cast/3` only fields the caller legitimately owns.
* Do not cast open or privileged field lists.
* Never cast fields such as `role`, `admin`, `org_id`, `tenant_id`, `user_id`, or
  `account_id` from untrusted params unless that is explicitly the intended API.
* Set privileged, tenant, scope, or ownership fields server-side.
* Validate with targeted validators: `validate_required/2`, `validate_format/3`,
  `validate_number/3`, `validate_length/3`, `validate_inclusion/3`, or custom validators
  when domain-specific.
* Enforce database invariants with constraint helpers so database errors surface as
  changeset errors: `unique_constraint/3`, `foreign_key_constraint/3`,
  `check_constraint/3`, `exclusion_constraint/3`.
* Pair constraint helpers with matching migration constraints or indexes.
* Mark secret or PII fields with `redact: true` in schema field definitions when
  they must not leak through inspect/logging.
* Keep changesets focused. Prefer separate changeset functions for different callers
  or flows.

```elixir
# good — casts only fields the caller owns
def changeset(user, attrs) do
  user
  |> cast(attrs, [:name, :email])
  |> validate_required([:name, :email])
  |> validate_format(:email, ~r/@/)
  |> unique_constraint(:email)
end

# bad — mass assignment: caller can set role/org_id/admin
def changeset(user, attrs) do
  user
  |> cast(attrs, [:name, :email, :role, :org_id, :admin])
  |> validate_required([:name, :email])
end
```

Prefer separate changesets over option-driven shape shifting:

```elixir
def registration_changeset(user, attrs) do
  user
  |> cast(attrs, [:name, :email, :password])
  |> validate_required([:name, :email, :password])
end

def admin_update_changeset(user, attrs) do
  user
  |> cast(attrs, [:name, :email, :role])
  |> validate_required([:name, :email, :role])
end
```

### Queries

Rules:

* `Repo.get/2` returns `nil`; use it when absence is expected.
* `Repo.get!/2` raises; reserve it for setup, tests, or cases where absence is a bug.
* Keep query composition in contexts or dedicated query modules, not controllers or
  LiveViews.
* Compose queries with `Ecto.Query`: `from`, `where`, `join`, `order_by`, `limit`,
  `select`, `preload`.
* Avoid N+1 queries. Preload associations explicitly with `Repo.preload/2` or query
  preloads.
* For large reads, select only needed fields.
* Do not interpolate user input into SQL fragments. Use placeholders.
* Keep tenant or authorization scope in every query that touches tenant-owned data.
* Prefer keyset pagination for large or frequently changing datasets when offset
  pagination becomes slow or unstable.

```elixir
# good — scoped to the tenant, returns a tagged tuple
def fetch_invoice(scope, id) do
  Invoice
  |> where([invoice], invoice.org_id == ^scope.org_id)
  |> where([invoice], invoice.id == ^id)
  |> Repo.one()
  |> case do
    nil -> {:error, :not_found}
    invoice -> {:ok, invoice}
  end
end

# bad — no tenant scope, raises instead of returning {:error, _}
def fetch_invoice(_scope, id) do
  {:ok, Repo.get!(Invoice, id)}
end
```

```elixir
where(query, [item], fragment("? ilike ?", item.name, ^"%#{term}%"))  # safe — parameterized
where(query, [item], fragment("name ilike '%#{term}%'"))              # unsafe — interpolated
```

### Transactions and Ecto.Multi

Use transactions when several operations must succeed or fail together.

Prefer ordinary control flow in a transaction when the sequence is simple. Use
`Ecto.Multi` when the operations are dynamic, need names, are useful to inspect in tests,
or depend on previous operation results.

Rules:

* Use `Ecto.Multi` for multi-step writes that need atomicity and named operations.
* Use `Multi.run/3` when a step depends on previous results and may return
  `{:ok, value}` or `{:error, reason}`.
* Keep operation names stable and meaningful.
* Pattern match on `{:ok, changes}` and `{:error, failed_operation, failed_value, changes_so_far}`.
* Do not perform slow external API calls inside a database transaction unless the
  consistency requirement is explicit and worth the lock time.
* Prefer building changesets before the transaction when possible, so invalid changesets
  fail before the transaction starts.
* Use `Repo.transact/1` when the project uses modern Ecto naming. Use
  `Repo.transaction/1` when that is the project convention or version-compatible path.

Good:

```elixir
alias Ecto.Multi

def create_user_with_profile(attrs) do
  Multi.new()
  |> Multi.insert(:user, User.registration_changeset(%User{}, attrs))
  |> Multi.insert(:profile, fn %{user: user} ->
    Profile.changeset(%Profile{}, %{
      user_id: user.id,
      display_name: attrs["display_name"] || attrs[:display_name]
    })
  end)
  |> Repo.transact()
end
```

For non-database or validation-dependent steps:

```elixir
Multi.new()
|> Multi.insert(:invoice, Invoice.changeset(%Invoice{}, attrs))
|> Multi.run(:audit_log, fn repo, %{invoice: invoice} ->
  audit_log =
    AuditLog.changeset(%AuditLog{}, %{
      invoice_id: invoice.id,
      action: "invoice_created"
    })

  case repo.insert(audit_log) do
    {:ok, log} -> {:ok, log}
    {:error, changeset} -> {:error, changeset}
  end
end)
|> Repo.transact()
```

### Migrations

Prefer migrations that are safe in rolling deploys.

Rules:

* Prefer reversible `change/0`.
* If a migration is irreversible, use `up/0` and `down/0`, and make the tradeoff
  explicit.
* Pair database constraints and indexes with changeset constraint helpers.
* Keep migrations backward compatible for at least one deploy when old and new code
  may run against the same database.
* Sequence destructive changes across deploys:

  1. Add new nullable column or new table.
  2. Deploy code that writes both old and new shapes if needed.
  3. Backfill out of band or in safe batches.
  4. Deploy code that reads the new shape.
  5. Add constraints.
  6. Drop old columns later.
* Avoid renaming or dropping columns in the same deploy that introduces new code
  depending on the replacement.
* Avoid long locks on large tables.
* For PostgreSQL indexes on large tables, prefer concurrent indexes when needed.
* When using concurrent indexes, disable DDL transactions with
  `@disable_ddl_transaction true`.
* Keep non-transactional migrations short and carefully reviewed.
* Avoid `NOT NULL` with a default on large existing tables unless the database/version
  behavior is known to be safe.

Concurrent index example:

```elixir
defmodule MyApp.Repo.Migrations.AddInvoicesOrgStatusIndex do
  use Ecto.Migration

  @disable_ddl_transaction true

  def change do
    create index(:invoices, [:org_id, :status], concurrently: true)
  end
end
```

Constraint example (paired with the `unique_constraint(:email)` changeset shown in
Schemas and changesets above):

```elixir
def change do
  create unique_index(:users, [:email])
end
```

---

## Phoenix: controllers and contexts

Controllers should be boring.

Rules:

* Pattern match params.
* Fetch current user/scope from the connection.
* Call context functions.
* Render success.
* Let `action_fallback` translate expected errors.
* Do not put business rules in controllers.
* Do not call `Repo` in controllers.
* Do not compose Ecto queries in controllers.
* Do not trust resource IDs in params. Always scope reads and writes to the current
  user, organization, account, or tenant.
* Authorize in plugs when possible, but re-check authorization for mutations and
  resource-specific access in the context.

Good:

```elixir
defmodule MyAppWeb.InvoiceController do
  use MyAppWeb, :controller

  alias MyApp.Billing

  action_fallback MyAppWeb.FallbackController

  def show(conn, %{"id" => id}) do
    with {:ok, invoice} <- Billing.fetch_invoice(current_scope(conn), id) do
      render(conn, :show, invoice: invoice)
    end
  end

  def update(conn, %{"id" => id, "invoice" => invoice_params}) do
    with {:ok, invoice} <- Billing.update_invoice(current_scope(conn), id, invoice_params) do
      render(conn, :show, invoice: invoice)
    end
  end
end
```

Fallback controller example:

```elixir
def call(conn, {:error, :not_found}) do
  conn
  |> put_status(:not_found)
  |> put_view(html: MyAppWeb.ErrorHTML, json: MyAppWeb.ErrorJSON)
  |> render(:"404")
end

def call(conn, {:error, %Ecto.Changeset{} = changeset}) do
  conn
  |> put_status(:unprocessable_entity)
  |> render(:error, changeset: changeset)
end
```

---

## LiveView

### Lifecycle

Rules:

* Keep `mount/3` light.
* Assign defaults for every assign the template reads.
* Use `connected?/1` before subscribing to PubSub or starting work that should happen
  only for the connected LiveView process.
* Use `handle_params/3` for URL-driven state.
* Keep `apply_action/3` branches consistent. Do not assign keys in one branch that are
  missing in another when the template reads them.
* Use `handle_event/3` for client events, but treat all event params as untrusted.
* Surface errors through flash, changesets, or explicit UI state.
* Avoid silent failures.

```elixir
# assign defaults for every template assign, and subscribe only once connected
def mount(_params, _session, socket) do
  if connected?(socket) do
    Phoenix.PubSub.subscribe(MyApp.PubSub, "feed:#{socket.assigns.current_scope.org_id}")
  end

  socket =
    socket
    |> assign(:page_title, "Invoices")
    |> assign(:invoice, nil)
    |> assign(:form, nil)
    |> assign(:loading, false)

  {:ok, socket}
end
```

### Security

LiveView params and event payloads come from the client. Treat them as untrusted.

Rules:

* Validate and authorize `mount/3` params.
* Validate and authorize `handle_params/3` params.
* Validate and authorize every `handle_event/3` payload.
* Do not assume mount-time authorization protects later events.
* Re-check ownership before every event that reads, updates, deletes, exports, or
  broadcasts resource data.
* Derive tenant/org/user scope from the authenticated session or socket assigns, not
  from user-supplied params.
* Do not trust hidden form inputs or DOM IDs as authorization proof.
* Never put secrets in assigns.
* Do not store tokens, API keys, credentials, or sensitive PII in socket assigns.
* Avoid logging full event payloads when they may include sensitive values.

```elixir
# bad — no scope, no authorization check, raises instead of handling failure
def handle_event("delete", %{"id" => id}, socket) do
  Billing.delete_invoice!(id)
  {:noreply, socket}
end
```

```elixir
# good — scoped to the current user/org, re-authorized in the context
def handle_event("delete", %{"id" => id}, socket) do
  scope = socket.assigns.current_scope

  case Billing.delete_invoice(scope, id) do
    {:ok, _invoice} ->
      {:noreply, put_flash(socket, :info, "Invoice deleted")}

    {:error, :not_found} ->
      {:noreply, put_flash(socket, :error, "Invoice not found")}

    {:error, :unauthorized} ->
      {:noreply, put_flash(socket, :error, "You cannot delete this invoice")}
  end
end
```

### State and performance

Rules:

* Keep socket assigns small and intentional.
* Do not store large structs, large lists, secrets, or raw external payloads in assigns.
* Store IDs or view models when full structs are unnecessary.
* Use `stream/3` for large or changing collections.
* Use `temporary_assigns` only when the render lifecycle is well understood.
* Prefer `assign_new/3` for shared assigns passed from parent layouts or hooks.
* Avoid repeated queries during render. Load data in callbacks, not inside HEEx.
* Avoid expensive computed values in templates. Precompute assigns.
* Ensure every item in a streamed collection has stable DOM identity.

Good stream setup:

```elixir
def mount(_params, _session, socket) do
  invoices = Billing.list_recent_invoices(socket.assigns.current_scope)

  {:ok, stream(socket, :invoices, invoices)}
end
```

Stream delete:

```elixir
def handle_event("delete", %{"id" => id}, socket) do
  scope = socket.assigns.current_scope

  with {:ok, invoice} <- Billing.delete_invoice(scope, id) do
    {:noreply, stream_delete(socket, :invoices, invoice)}
  else
    {:error, reason} ->
      {:noreply, put_flash(socket, :error, humanize_error(reason))}
  end
end
```

### Async work

Use LiveView async helpers for work that should not block the LiveView process.

Rules:

* Use `assign_async/3` when the result should become assigns.
* Use `start_async/3` when the result should be handled in `handle_async/3`.
* Use `stream_async/4` when async work returns streamed items.
* Do not pass the whole socket into async functions.
* Copy only the needed values from assigns into local variables before starting async work.
* Remember async work starts only when the socket is connected.
* Handle loading and failure states explicitly.
* Use `cancel_async/3` when replacing or cancelling in-flight work matters.
* Do not rely on LiveView assigns or Ecto prefixes magically existing in tasks. Pass
  tenant/scope context explicitly.

```elixir
# copy the value out of assigns first — don't reference socket/socket.assigns inside the fn
def mount(_params, _session, socket) do
  org_id = socket.assigns.current_scope.org_id

  socket =
    assign_async(socket, :stats, fn ->
      case Billing.fetch_dashboard_stats(org_id) do
        {:ok, stats} -> {:ok, %{stats: stats}}
        {:error, reason} -> {:error, reason}
      end
    end)

  {:ok, socket}
end
```

`start_async/3`:

```elixir
def handle_event("refresh", _params, socket) do
  org_id = socket.assigns.current_scope.org_id

  {:noreply,
   socket
   |> assign(:refreshing, true)
   |> start_async(:refresh_stats, fn -> Billing.fetch_dashboard_stats(org_id) end)}
end

def handle_async(:refresh_stats, {:ok, {:ok, stats}}, socket) do
  {:noreply, assign(socket, stats: stats, refreshing: false)}
end

def handle_async(:refresh_stats, {:ok, {:error, reason}}, socket) do
  {:noreply,
   socket
   |> assign(:refreshing, false)
   |> put_flash(:error, humanize_error(reason))}
end

def handle_async(:refresh_stats, {:exit, reason}, socket) do
  {:noreply,
   socket
   |> assign(:refreshing, false)
   |> put_flash(:error, "Refresh failed")}
end
```

### Forms

Rules:

* Drive forms from changesets and `to_form/2`.
* Validate on `"validate"` events.
* Submit on `"save"` or domain-specific event names.
* Keep form params scoped under the resource key when following Phoenix conventions.
* Reflect changeset errors in the UI.
* Do not silently discard changeset errors.
* Do not trust form params just because the form was rendered by the server.

Good:

```elixir
def mount(_params, _session, socket) do
  changeset = Billing.change_invoice(%Invoice{})

  {:ok, assign(socket, form: to_form(changeset))}
end

def handle_event("validate", %{"invoice" => params}, socket) do
  changeset =
    %Invoice{}
    |> Billing.change_invoice(params)
    |> Map.put(:action, :validate)

  {:noreply, assign(socket, form: to_form(changeset))}
end

def handle_event("save", %{"invoice" => params}, socket) do
  case Billing.create_invoice(socket.assigns.current_scope, params) do
    {:ok, invoice} ->
      {:noreply,
       socket
       |> put_flash(:info, "Invoice created")
       |> push_navigate(to: ~p"/invoices/#{invoice}")}

    {:error, %Ecto.Changeset{} = changeset} ->
      {:noreply, assign(socket, form: to_form(changeset))}
  end
end
```

### Real-time and PubSub

Rules:

* Scope PubSub topics to the correct boundary (organization, account, tenant, user,
  or resource).
* Derive topic names from authenticated server-side scope, not client params.
* Subscribe only after `connected?/1`.
* Broadcast only data the subscribers are authorized to see.
* Prefer broadcasting IDs or small view models over large structs.
* Be careful broadcasting changesets or structs containing redacted/secret fields.
* Unsubscribe or change subscriptions when navigation changes the authorized boundary.

```elixir
# good — topic derived from server-side scope
defp feed_topic(scope), do: "feed:#{scope.org_id}"

def mount(_params, _session, socket) do
  scope = socket.assigns.current_scope

  if connected?(socket) do
    Phoenix.PubSub.subscribe(MyApp.PubSub, feed_topic(scope))
  end

  {:ok, assign(socket, items: [])}
end

# bad — topic derived from a client-supplied param; a user can guess/forge another org's topic
def mount(%{"org_id" => org_id}, _session, socket) do
  Phoenix.PubSub.subscribe(MyApp.PubSub, "feed:#{org_id}")
  {:ok, socket}
end
```

---

## Supervision and concurrency selection

Choose the abstraction by runtime need.

Use:

* plain module/function → code organization and pure business logic
* `Task` → one-off async work tied to the caller
* `Task.Supervisor` → supervised async tasks
* `Agent` → simple shared state only
* `GenServer` → long-lived stateful process, serialization, or protocol boundary
* `DynamicSupervisor` → children started at runtime
* `Registry` → process discovery by key
* Oban or existing job library → durable jobs, retries, scheduling, queues
* GenStage/Broadway → streaming, demand, backpressure, ingestion pipelines
* Phoenix PubSub → fan-out notifications
* LiveView → real-time server-rendered UI

Tree rules:

* Define long-lived children in `application.ex`.
* Supervise every long-lived process.
* Do not use unsupervised `spawn` for production workflows.
* Use `:one_for_one` for independent workers.
* Use `:one_for_all` only when children depend on each other and should restart
  together.
* Use `DynamicSupervisor` for runtime children.
* Use `Registry` for process discovery instead of inventing global names.
* Pass tenant/scope context explicitly into tasks and jobs.
* Background jobs and tasks do not inherit LiveView assigns, connection assigns, or
  Ecto prefixes.

```elixir
# bad — GenServer used purely for code organization, no runtime state or concurrency need
defmodule Billing.InvoiceServer do
  use GenServer
end

# better — plain module and functions
defmodule Billing.Invoices do
  def calculate_total(invoice) do
    # pure domain logic
  end
end
```

Supervised task example:

```elixir
Task.Supervisor.start_child(MyApp.TaskSupervisor, fn ->
  Billing.recalculate_invoice_totals(invoice_id, org_id)
end)
```
