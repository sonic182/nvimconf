# Phoenix

On-demand reference for `elixir-development`.

Read this when the task touches Phoenix contexts, controllers, plugs, or the
web layer boundary.

Ecto specifics live in `references/ecto.md`, LiveView specifics in
`references/liveview.md`, and general Elixir idioms in `SKILL.md`.

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

## Controllers

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

