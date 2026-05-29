# Phoenix, Ecto, LiveView & Supervision

On-demand reference for `elixir-development`. Read this when the task touches Phoenix
contexts/controllers, Ecto schemas/queries/migrations, LiveView, or the supervision
tree. Style and idioms still come from `SKILL.md`; this file adds framework specifics.

## Table of contents

- [Architecture: contexts as the boundary](#architecture-contexts-as-the-boundary)
- [Ecto](#ecto)
- [Phoenix (controllers & contexts)](#phoenix-controllers--contexts)
- [LiveView](#liveview)
- [Supervision & concurrency selection](#supervision--concurrency-selection)

---

## Architecture: contexts as the boundary

- The web layer (controllers, LiveViews, channels) is thin: it parses input, calls a
  context, and renders. Business logic and persistence live in **contexts**.
- A context owns a bounded concept (e.g. `Accounts`, `Billing`). Don't reach into
  another context's schemas or `Repo` directly — call its public functions.
- Never call `Repo` from the web layer. If a controller or LiveView imports `Repo`,
  that's a boundary leak to flag.
- Contexts return tagged tuples (`{:ok, _}` / `{:error, _}` or `{:error, changeset}`),
  not raw structs or raised exceptions, for expected outcomes.

---

## Ecto

### Schemas & changesets

- `cast/3` only the fields the caller legitimately owns. Casting an open field list is
  mass assignment — a user can set `role`, `org_id`, `admin`, etc. Set privileged or
  scope fields server-side, not from params.
- Validate with `validate_required/2`, `validate_format/3`, `validate_number/3`, etc.
- Enforce DB-level invariants through constraint helpers so they surface as changeset
  errors instead of raising: `unique_constraint/3`, `foreign_key_constraint/3`,
  `check_constraint/3`. Pair each with the matching migration `constraint`/`unique_index`.
- Mark secret/PII fields `redact: true` in the `field` definition so they don't leak via
  `inspect`/logging.

```elixir
def changeset(user, attrs) do
  user
  |> cast(attrs, [:name, :email])        # NOT :role / :org_id
  |> validate_required([:name, :email])
  |> validate_format(:email, ~r/@/)
  |> unique_constraint(:email)
end
```

### Queries

- `Repo.get/2` returns `nil`; `Repo.get!/2` raises. Use the non-bang form inside contexts
  that return tagged tuples; reserve the bang for edges where absence is a genuine bug.
- Avoid N+1: preload associations explicitly (`Repo.preload/2` or `preload` in the query)
  rather than loading them in a loop. `select` only the fields you need for large reads.
- Compose queries with the `Ecto.Query` API (`from`, `where`, `join`, `order_by`) and keep
  composition in the context, not in controllers/LiveViews.
- Never interpolate user input into `fragment/1`; use parameter placeholders (`?`).
- Wrap multi-step writes that must succeed or fail together in `Ecto.Multi` +
  `Repo.transaction/1` so a failure can't leave partial state.

```elixir
Multi.new()
|> Multi.insert(:user, User.changeset(%User{}, attrs))
|> Multi.insert(:profile, fn %{user: user} -> Profile.changeset(%Profile{}, user) end)
|> Repo.transaction()
```

### Migrations

- Prefer a reversible `change/0`; if irreversible, make it intentional and say so.
- In a rolling deploy, old and new code share the DB — keep each migration backward
  compatible for at least one release. Sequence destructive changes (drop/rename) across
  releases rather than breaking the running version.
- On large tables, create indexes `concurrently` (with `@disable_ddl_transaction true` and
  `@disable_migration_lock true`) and avoid `NOT NULL`-with-default or in-migration
  backfills that hold long locks — add nullable, backfill out-of-band, then constrain.

---

## Phoenix (controllers & contexts)

- Controllers stay thin: pattern-match params, call a context, render. Use `with` for the
  happy path and an `action_fallback` controller to translate `{:error, _}` into responses.
- One responsibility per action. Don't branch return shapes on options.
- Authorize in a plug / `on_mount` and re-check on any action that mutates a resource —
  don't assume an ID in the params belongs to the current user/tenant.

```elixir
def show(conn, %{"id" => id}) do
  with {:ok, invoice} <- Billing.fetch_invoice(current_scope(conn), id) do
    render(conn, :show, invoice: invoice)
  end
end
```

---

## LiveView

### Lifecycle

- `mount/3`: keep it light; assign sensible **defaults for every assign** the template
  reads, so HEEx never renders an unset/`nil` assign after navigation.
- `handle_params/3` + `apply_action/3`: route on `live_action`; keep the assigns each
  action needs consistent across branches (no key that exists in one branch but not another).
- `handle_event/3`: validate and **authorize** every event. The client can send any payload
  or ID, so mount-time checks don't protect later events — re-check ownership on actions
  that read or mutate a resource.
- Surface errors to the UI (flash, changeset errors) rather than silently swallowing them.

### State & performance

- Don't store large structs or secrets in socket assigns; assigns live in process memory
  for the whole session.
- For large or streaming collections use `stream/3` (or `temporary_assigns`) so the socket
  doesn't accumulate unbounded data.
- Forms: drive them from a changeset with `to_form/2`, and validate on the `"validate"`
  event before submit.

### Real-time

- Scope PubSub topics to the right boundary (e.g. `"feed:#{org_id}"`) and derive the topic
  from the authenticated session, never from a user-supplied param — a shared/guessable
  topic can leak one subscriber's data to another's session.

```elixir
def mount(_params, _session, socket) do
  if connected?(socket), do: Phoenix.PubSub.subscribe(MyApp.PubSub, "feed:#{socket.assigns.org_id}")
  {:ok, assign(socket, items: [], loading: false)}  # defaults for everything the HEEx reads
end
```

---

## Supervision & concurrency selection

Choose the abstraction by runtime need:

- long-lived stateful process → `GenServer`
- simple shared state → `Agent`
- one-off async work → `Task` (`Task.Supervisor` when it must be supervised)
- jobs / retries / queues → `Oban`
- streaming / backpressure → `GenStage` / `Broadway`
- real-time UI → Phoenix LiveView + PubSub

Tree rules:

- Define the application's children in `application.ex` and supervise everything long-lived.
- `:one_for_one` for independent workers; `:one_for_all` when children depend on each other.
- `DynamicSupervisor` for children started at runtime; `Registry` for discovering them.
- Background jobs and async tasks don't inherit a LiveView's assigns or an Ecto `prefix` —
  pass any tenant/scope context explicitly into the job.
