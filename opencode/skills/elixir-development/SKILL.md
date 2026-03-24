---
name: elixir-development
description: |
  Expert Elixir programming assistant enforcing idiomatic style, naming conventions, module structure, documentation, typespecs, error handling patterns (tagged tuples, with/case/try-rescue), OTP/GenServer layout, supervision trees, structs, collections, and ExUnit testing. Also covers Phoenix Framework, Phoenix LiveView, Ecto, and distributed/fault-tolerant system design on the BEAM. Grounds every decision in the Elixir Style Guide and official Naming Conventions.

  USE when: writing, reviewing, or refactoring Elixir/Phoenix code; designing GenServer/Agent/Task/Supervisor modules; building real-time features with LiveView; working with Ecto schemas/migrations/queries; writing ExUnit tests; adding typespecs or docs; debugging OTP/BEAM issues; designing supervision trees or distributed systems; or enforcing consistent code style across a codebase.

  DO NOT USE for: non-Elixir languages, infrastructure/DevOps tasks unrelated to Elixir, or purely architectural discussions that have no Elixir code involved.
---

# SKILL.md — Elixir

Reference for AI coding tools generating or reviewing Elixir code.
All rules are grounded in the [Elixir Style Guide](https://github.com/christopheradams/elixir_style_guide)
and Elixir's official [Naming Conventions](https://hexdocs.pm/elixir/naming-conventions.html).

---

## Formatting Rules (enforced by `mix format`)

- Max line length: **98 characters**. Configure via `.formatter.exs`.
- Use Unix line endings. End every file with a newline. No trailing whitespace.
- No space between a function name and its opening parenthesis: `f(x)` not `f (x)`.
- No spaces inside brackets or parentheses. Spaces around operators, after commas/colons/semicolons.
- Do not put a blank line directly after `defmodule`.
- Add a blank line **after** a multiline assignment.
- If a list, map, or struct spans multiple lines: each element on its own line, brackets on their own lines, opening bracket stays on the assignment line.
- Multiline `case`/`cond`: use multiline syntax for **all** clauses and separate them with blank lines.
- Indent and align successive `with` clauses; `do:` on a new line aligned with clauses.

---

## Naming Conventions

| Construct | Rule | Example |
|---|---|---|
| Atoms, functions, variables | `snake_case` | `:ok`, `user_id`, `fetch_user/1` |
| Modules | `CamelCase`; acronyms stay uppercase | `MyModule`, `HTTPClient`, `XMLParser` |
| Boolean functions | trailing `?` | `valid?/1`, `empty?/1` |
| Guard-safe predicates | `is_` prefix via `defguard` | `is_admin/1` |
| Exception modules | trailing `Error` | `NotFoundError`, `BadHTTPCodeError` |
| File names | `snake_case` matching module | `http_client.ex` → `HTTPClient` |

- Private functions must **not** share a name with a public function. Avoid `def foo` / `defp do_foo` — use a descriptive name instead.
- Module nesting maps to directory structure: `Parser.Core.XMLParser` lives at `parser/core/xml_parser.ex`.
- Avoid repeating namespace fragments: `Todo.Item` not `Todo.Todo`.

---

## Module Structure Order

Always order module contents as follows, with a blank line between each group.
Sort terms within each group alphabetically.

```elixir
defmodule MyApp.MyModule do
  @moduledoc """
  Module description.
  """

  @behaviour SomeBehaviour

  use SomeLib

  import ModuleA
  import ModuleB

  require Integer

  alias My.Long.Module.Name
  alias My.Other.Module

  @module_attribute :foo
  @other_attribute 100

  defstruct [:name, params: []]

  @typedoc "The result type"
  @type result :: {:ok, term()} | {:error, term()}

  @callback some_function(term()) :: :ok | {:error, term()}

  @optional_callbacks some_function: 1

  @doc false
  defmacro __using__(_opts), do: :no_op

  @doc """
  Guard example.
  """
  defguard is_ok(term) when term == :ok

  @impl true
  def init(state), do: {:ok, state}
end
```

- Use `__MODULE__` for self-reference. Alias it for a cleaner name when needed.
- Use `@moduledoc false` for intentionally undocumented internal modules.

---

## Documentation

- `@moduledoc` goes on the line immediately after `defmodule`, before any directives.
- Write docs with heredocs and Markdown. Use `## Examples` with `iex>` doctests.
- Place `@spec` directly before `def`, after `@doc`, with **no blank line** between them.

```elixir
@doc """
Parses a raw string into a validated token.

## Examples

    iex> MyModule.parse("hello")
    {:ok, "hello"}

    iex> MyModule.parse("")
    {:error, :empty}
"""
@spec parse(String.t()) :: {:ok, String.t()} | {:error, :empty}
def parse(""), do: {:error, :empty}
def parse(input) when is_binary(input), do: {:ok, input}
```

---

## Typespecs

- Define custom types at the top of the module (see structure order above).
- Pair `@typedoc` and `@type` together, blank line between pairs.
- Long union types: each member on its own line with a leading `|`.
- Name the primary struct type `t`.

```elixir
@typedoc "Primary struct type"
@type t :: %__MODULE__{
        name: String.t() | nil,
        params: Keyword.t()
      }

@typedoc "A long union"
@type status ::
        :pending
        | :active
        | :suspended
        | :deleted
```

---

## Expressions & Pipelines

- Use `|>` to chain **multiple** transformations. Never use it for a single step.
- Start pipelines with a **bare variable**, not a function call.
- Always use parentheses on piped functions, including zero-arity: `|> String.downcase()`.
- Multiline pipelines: each `|>` on its own line, no extra indentation.
- Always call zero-arity functions with `()` to distinguish them from variables.
- Use `do:` for single-line `if`/`unless`.
- Never use `unless` with `else` — rewrite as `if/else` with positive case first.
- Use `true` as the catch-all last clause in `cond`.

```elixir
# correct pipeline
sanitized =
  raw_input
  |> String.trim()
  |> String.downcase()
  |> String.replace(~r/\s+/, "_")

# wrong — single pipe
sanitized = raw_input |> String.trim()

# wrong — starts with function call
sanitized = String.trim(raw_input) |> String.downcase()
```

---

## Error Handling

### Tagged Tuples (primary pattern)

Always return `{:ok, value}` or `{:error, reason}` for recoverable operations.
Never raise for expected failure paths.

```elixir
def fetch_user(id) do
  case Repo.get(User, id) do
    nil -> {:error, :not_found}
    user -> {:ok, user}
  end
end
```

### `with` (chaining fallible steps)

Use `with` when multiple steps can each fail independently.
Align clauses. Put `do` block on a new block (not `do:`). Always include `else`.

```elixir
with {:ok, user} <- fetch_user(user_id),
     {:ok, account} <- fetch_account(user.account_id),
     {:ok, _} <- authorize(user, :read) do
  {:ok, account}
else
  {:error, :not_found} -> {:error, :not_found}
  {:error, :unauthorized} -> {:error, :forbidden}
end
```

- Do not use `with` for a single clause — use `case` instead.
- Keep `else` clauses exhaustive; pattern match on the exact tagged tuple shapes your steps return.
- **Avoid complex `else` blocks.** If you need intricate matching in `else` to figure out which clause failed, the steps are returning ambiguous shapes. Fix by normalizing return values in a private function before passing to `with`, so each error is uniquely identifiable at the call site.

### `case` (branching on a single result)

Prefer `case` over `if` when matching more than two outcomes or matching on structure.

```elixir
case HTTPClient.get(url) do
  {:ok, %{status: 200, body: body}} ->
    {:ok, body}

  {:ok, %{status: status}} ->
    {:error, {:unexpected_status, status}}

  {:error, reason} ->
    {:error, {:http_error, reason}}
end
```

### `try/rescue` (exceptions from third-party code)

Use only when calling code that raises (e.g., JSON parsers, external libraries).
Never use `raise` for your own control flow.

```elixir
def safe_decode(json) do
  {:ok, Jason.decode!(json)}
rescue
  Jason.DecodeError -> {:error, :invalid_json}
end
```

### `raise` (unrecoverable programmer errors)

Use `raise` only for truly unrecoverable states (wrong arguments, violated invariants).
Exception messages: lowercase, no trailing punctuation.

```elixir
# correct
raise ArgumentError, "expected a non-empty list"

# wrong
raise ArgumentError, "Expected a non-empty list."
```

### Exception Modules

Name with trailing `Error`. Always include a `message` field.

```elixir
defmodule MyApp.NotFoundError do
  defexception [:message]
end
```

---

## OTP / GenServer Patterns

### GenServer Structure

Follow this canonical layout for GenServer modules:

```elixir
defmodule MyApp.Worker do
  @moduledoc """
  Manages background work for a single job.
  """

  use GenServer

  alias MyApp.Job

  # --- Public API ---

  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @spec enqueue(term()) :: :ok
  def enqueue(item) do
    GenServer.cast(__MODULE__, {:enqueue, item})
  end

  @spec status() :: map()
  def status do
    GenServer.call(__MODULE__, :status)
  end

  # --- Callbacks ---

  @impl true
  def init(opts) do
    state = %{queue: [], opts: opts}
    {:ok, state}
  end

  @impl true
  def handle_call(:status, _from, state) do
    {:reply, state, state}
  end

  @impl true
  def handle_cast({:enqueue, item}, state) do
    {:noreply, %{state | queue: [item | state.queue]}}
  end

  @impl true
  def handle_info(:timeout, state) do
    {:noreply, state}
  end
end
```

**Rules:**
- Always mark callbacks with `@impl true`.
- Always define a public API in the same module; never call `GenServer.call/cast` from outside the module.
- Use `handle_call` for operations that return a value to the caller.
- Use `handle_cast` for fire-and-forget operations.
- Use `handle_info` for messages sent with plain `send/2` (e.g., `:timeout`, `:DOWN`).
- Initialize state as a struct or map — never a bare value.
- Trap exits explicitly when needed: `Process.flag(:trap_exit, true)` in `init/1`.

### Supervision

- Always supervise GenServers. Define a `child_spec/1` or rely on the one generated by `use GenServer`.
- Prefer `Supervisor.child_spec/2` with explicit restart strategies over implicit defaults when reliability matters.
- Use `:one_for_one` when workers are independent. Use `:one_for_all` when they share state.

```elixir
# in application.ex
children = [
  {MyApp.Worker, opts},
  {Task.Supervisor, name: MyApp.TaskSupervisor}
]

Supervisor.start_link(children, strategy: :one_for_one)
```

### Agents

Use `Agent` only for simple shared state with no complex logic. For anything with business logic, use a full `GenServer`.

```elixir
defmodule MyApp.Counter do
  use Agent

  def start_link(initial), do: Agent.start_link(fn -> initial end, name: __MODULE__)
  def increment, do: Agent.update(__MODULE__, &(&1 + 1))
  def value, do: Agent.get(__MODULE__, & &1)
end
```

### Task

Use `Task` for one-off async work. Use `Task.Supervisor` when tasks must be supervised.

```elixir
# fire-and-forget
Task.start(fn -> process(item) end)

# awaited result
task = Task.async(fn -> expensive_computation() end)
result = Task.await(task, 5_000)

# supervised
Task.Supervisor.start_child(MyApp.TaskSupervisor, fn -> process(item) end)
```

---

## Structs

- List nil-default fields as bare atoms first, then keyword fields with defaults.
- Omit square brackets unless the list starts with atoms.
- Use `__MODULE__` in struct type definitions.

```elixir
defstruct [:id, :name, active: true, params: []]

@type t :: %__MODULE__{
        id: integer() | nil,
        name: String.t() | nil,
        active: boolean(),
        params: Keyword.t()
      }
```

---

## Collections

- Keyword lists: always use `[a: 1, b: 2]` syntax, never `[{:a, 1}, {:b, 2}]`.
- Maps with atom keys only: use `%{a: 1, b: 2}`.
- Maps with mixed keys: use arrow syntax `%{:a => 1, "b" => 2}`.
- String matching: use `<>` concatenator, not binary patterns.

---

## Testing (ExUnit)

- Expression under test goes **left**, expected value goes **right**.
- Pattern match assertions use `assert ... = ...` form.
- Use `describe` blocks to group related tests.
- Use `setup` for shared state; prefer `setup_all` only for truly expensive setup.

```elixir
describe "parse/1" do
  test "returns ok tuple for valid input" do
    assert MyModule.parse("hello") == {:ok, "hello"}
  end

  test "returns error for empty string" do
    assert {:error, :empty} = MyModule.parse("")
  end
end
```

---

## Comments & Annotations

- Comments go **above** the line they describe.
- One space after `#`. Capitalize sentences, use punctuation.
- Max comment line: 100 characters.

| Annotation | Use |
|---|---|
| `TODO:` | Feature to add later |
| `FIXME:` | Broken code needing a fix |
| `OPTIMIZE:` | Performance concern |
| `HACK:` | Code smell to refactor |
| `REVIEW:` | Needs verification |

---

## Concurrency Pattern Decision Framework

When choosing how to model concurrent behaviour:

```
What do you need?
├── Stateful long-lived process         → GenServer
├── Simple shared state, no logic       → Agent
├── One-off async work                  → Task / Task.async + Task.await
├── Background jobs, retries, queuing   → Oban (or Task.Supervisor for simpler cases)
├── Event streaming / backpressure      → GenStage / Broadway
└── Real-time UI updates                → Phoenix LiveView + PubSub
```

### Supervision Strategy Selector

```
How do children relate?
├── Can crash independently             → :one_for_one
├── All depend on each other            → :one_for_all
├── Later children depend on earlier    → :rest_for_one
└── Unknown/dynamic number of children → DynamicSupervisor
```

---

## Anti-Patterns

### Code

| Anti-Pattern | Problem | Correct Approach |
|---|---|---|
| Dynamic atom creation from external input | Atoms are never GC'd; risks memory exhaustion | Map to known atoms explicitly, or use `String.to_existing_atom/1` |
| Non-assertive map access (`map[:key]`) for required keys | Propagates `nil` silently instead of failing fast | Use `map.key` for required keys; `map[:key]` only for optional ones |
| Non-assertive truthiness (`&&`/`\|\|`/`!` on booleans) | Too generic; hides intent when values are definitely booleans | Use strict `and`/`or`/`not` for boolean-only expressions |
| Long parameter list | Order-dependent, easy to call incorrectly | Group related args into a struct, map, or keyword list |
| Single pipe (`x \|> f()`) | Unnecessary noise | Call directly: `f(x)` |
| `unless ... else` | Confusing double negation | Rewrite as `if` with positive case first |
| Repeated namespace in module name | Redundant: `Todo.Todo` | Use `Todo.Item` — avoid fragment repetition |

### Design

| Anti-Pattern | Problem | Correct Approach |
|---|---|---|
| Alternative return types via options | Callers cannot statically know what a function returns | Create separate named functions for each distinct return shape |
| Boolean obsession (multiple `bool` flags) | Overlapping states; combinatorial explosion of valid combinations | Replace with a single atom-typed option (e.g. `role: :admin \| :editor \| :default`) |
| Primitive obsession | Domain concepts lost in raw strings/integers | Define structs or maps; add parser functions at system boundaries |
| Unrelated multi-clause functions | One name hides multiple distinct, unrelated behaviors | Split into separate, clearly-named functions |
| `raise` for expected failures | Wrong abstraction for control flow | Return `{:error, reason}` tuples |

### Process / OTP

| Anti-Pattern | Problem | Correct Approach |
|---|---|---|
| Large GenServer state | Memory bloat and slow serialization | Use external storage (ETS, DB) for large data |
| Blocking GenServer with slow I/O | Single process becomes bottleneck | Spawn `Task` for I/O, reply asynchronously |
| No supervision tree | Crashes are unrecoverable | Always supervise; design restart strategies |
| `GenServer.call/cast` from outside module | Leaks internals, couples callers | Expose a typed public API in the same module |
| Processes as code organization units | Creates unnecessary bottlenecks and coupling | Organize by modules/functions; use processes only for runtime properties (state, concurrency, fault isolation) |
| Sending full structs in messages when only fields are needed | Wastes CPU copying and memory in message passing | Extract and pass only the minimal fields needed |
| Defensive `try/rescue` everywhere | Hides bugs, masks failures | Let it crash; supervise and recover |

---

## Metaprogramming

- Avoid macros unless no simpler abstraction exists.
- Prefer functions over macros. Macros obscure stack traces and complicate debugging.
- Never generate code at runtime that could be generated at compile time.

---

## Quick Reference

```sh
mix format            # Format all source files
mix credo             # Style and static analysis
mix dialyzer          # Typespec checking
mix test              # Run test suite
mix docs              # Generate ExDoc documentation
```
