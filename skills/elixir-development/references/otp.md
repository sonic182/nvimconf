# OTP

On-demand reference for `elixir-development`.

Read this when the task introduces, reviews, or debugs a process: a GenServer,
Agent, Task, supervisor, supervision tree, or a choice between them.

## GenServer

Provide a module-level client API. Do not make callers use `GenServer.call/3` or
`GenServer.cast/2` directly across the application.

Put the public API before callbacks. Mark callbacks with `@impl true`.

Use:

* `handle_call/3` for calls that reply.
* `handle_cast/2` for fire-and-forget messages.
* `handle_info/2` for plain messages.

Prefer a map or struct for GenServer state once the state has more than one concept or may
grow. A bare value is acceptable only for tiny examples or truly single-value state.

Do not perform slow I/O inside callbacks. Start supervised async work or reply later with
`GenServer.reply/2` when appropriate.

Example:

```elixir
defmodule MyApp.Counter do
  use GenServer

  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, %{count: 0}, opts)
  end

  @spec increment(pid()) :: :ok
  def increment(pid), do: GenServer.cast(pid, :increment)

  @spec value(pid()) :: integer()
  def value(pid), do: GenServer.call(pid, :value)

  @impl true
  def init(state), do: {:ok, state}

  @impl true
  def handle_call(:value, _from, state), do: {:reply, state.count, state}

  @impl true
  def handle_cast(:increment, state) do
    {:noreply, %{state | count: state.count + 1}}
  end
end
```

## Agent, Task, and Supervision

Choose the abstraction by runtime need:

* plain module/function → code organization and pure business logic.
* `Task` → one-off async work tied to the caller.
* `Task.Supervisor` → supervised async tasks, when lifecycle matters.
* `Agent` → simple shared state only.
* `GenServer` → long-lived stateful process, serialization, or protocol boundary.
* `DynamicSupervisor` → children started at runtime.
* `Registry` → process discovery by key, instead of inventing global names.
* Oban or an existing job library → durable background work, retries, scheduling, queues, when the project already uses it or the user asks for that design.
* GenStage/Broadway → streaming, demand, backpressure, ingestion pipelines.
* Phoenix PubSub → fan-out notifications.

Tree rules:

* Define long-lived children in `application.ex`.
* Always supervise long-lived processes. Do not use unsupervised `spawn` for production workflows.
* Use `:one_for_one` for independent children and `:one_for_all` only when children depend on each other and should restart together.
* Pass tenant/scope context explicitly into tasks and jobs. Background jobs and tasks do not inherit LiveView assigns, connection assigns, or Ecto prefixes.

Do not put business logic in processes merely because they feel “service-like.” Use modules and functions until runtime state, concurrency, fault tolerance, or isolation is needed.

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

# supervised async work
Task.Supervisor.start_child(MyApp.TaskSupervisor, fn ->
  Billing.recalculate_invoice_totals(invoice_id, org_id)
end)
```

