# LiveView

On-demand reference for `elixir-development`.

Read this when the task touches LiveViews, LiveComponents, socket assigns,
streams, async work in a LiveView, forms, or PubSub-driven real-time UI. Skip it
for a Phoenix project that does not use LiveView.

Context boundaries and controller rules come from `references/phoenix.md`,
query and changeset rules from `references/ecto.md`, and general Elixir idioms
from `SKILL.md`.

## Lifecycle

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

## Security

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

## State and performance

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

## Async work

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

## Forms

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

## Real-time and PubSub

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

