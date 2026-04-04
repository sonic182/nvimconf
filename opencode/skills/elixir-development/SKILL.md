---
name: elixir-development
description: |
  Expert Elixir assistant for writing new, reviewing, and refactoring idiomatic Elixir and Phoenix code. Use this skill for any task that introduces or changes Elixir code. Enforces the Elixir Style Guide and official Naming Conventions across formatting, naming, module structure, docs, typespecs, error handling, OTP, structs, collections, and tests. Also covers Phoenix, LiveView, Ecto, supervision, and BEAM-friendly concurrency, while avoiding common anti-patterns.

  Use for: any new or modified Elixir/Phoenix code, OTP modules, LiveView, Ecto, tests, docs, typespecs, and code review/refactoring.
  Do not use for: non-Elixir code, infra unrelated to Elixir, or pure architecture with no Elixir code.
---

# SKILL.md — Elixir

Reference for generating and reviewing Elixir code.
Ground all decisions in:
- Elixir Style Guide: https://github.com/christopheradams/elixir_style_guide
- Naming Conventions: https://hexdocs.pm/elixir/naming-conventions.html

## Core Principles

- Write idiomatic, readable Elixir that matches `mix format`.
- Prefer simple functions over clever abstractions.
- Prefer explicit return values over exceptions for expected failures.
- Avoid anti-patterns even when technically valid.

## Formatting

- Max line length: 98 chars.
- Unix line endings, trailing newline, no trailing whitespace.
- No space before `(` in calls.
- No spaces inside brackets/parens; use spaces around operators and after commas.
- No blank line after `defmodule`.
- Add a blank line after multiline assignment.
- Multiline lists/maps/structs: one item per line.
- Multiline `case`/`cond`: all clauses multiline, separated by blank lines.
- Multiline `with`: align clauses; `do` on new line.

```elixir
# good
value =
  some_long_function_call(
    arg1,
    arg2
  )

# bad
value =
  some_long_function_call(
    arg1,
    arg2)
````

## Naming

* Functions, variables, atoms: `snake_case`
* Modules: `CamelCase`; acronyms stay uppercase
* Boolean predicates: trailing `?`
* Guards: `is_` prefix with `defguard`
* Exceptions: end with `Error`
* Filenames: `snake_case`, matching module path
* Avoid repeated namespace fragments
* Private functions must not reuse public names

```elixir
# good
def valid?(user), do: ...
defguard is_admin(role) when role == :admin
defmodule MyApp.HTTPClient do
end

# bad
def isValid(user), do: ...
defguard admin?(role) when role == :admin
defmodule MyApp.HttpClient do
end
```

## Module Layout

Use this order, with blank lines between groups:

1. `@moduledoc`
2. `@behaviour`
3. `use`
4. `import`
5. `require`
6. `alias`
7. module attributes
8. `defstruct`
9. `@typedoc` / `@type`
10. callbacks
11. macros
12. guards
13. public/private functions

Also:

* Put `@moduledoc` immediately after `defmodule`
* Use `__MODULE__` for self-reference
* Use `@moduledoc false` for intentionally undocumented internal modules

```elixir
defmodule MyApp.Token do
  @moduledoc """
  Token utilities.
  """

  alias MyApp.User

  @type t :: %__MODULE__{value: String.t()}
  defstruct [:value]

  @spec parse(String.t()) :: {:ok, t()} | {:error, :empty}
  def parse(""), do: {:error, :empty}
  def parse(value), do: {:ok, %__MODULE__{value: value}}
end
```

## Docs and Typespecs

* Use Markdown heredocs.
* Add doctests when useful.
* Put `@spec` directly before `def`, after `@doc`, with no blank line.
* Define custom types near the top.
* Name primary struct type `t`.

```elixir
@doc """
Parses a token.

## Examples

    iex> MyApp.Token.parse("abc")
    {:ok, %MyApp.Token{value: "abc"}}
"""
@spec parse(String.t()) :: {:ok, t()} | {:error, :empty}
def parse(""), do: {:error, :empty}
def parse(value), do: {:ok, %__MODULE__{value: value}}

# bad
@spec parse(String.t()) :: term()

@doc "Parses a token"
def parse(value), do: value
```

## Pipelines and Expressions

* Use pipelines only for multiple transformations.
* Start pipelines from a bare variable.
* Always use parentheses in piped calls.
* Call zero-arity functions with `()`.
* Use `do:` for simple one-line `if` / `unless`.
* Never use `unless` with `else`.
* Use `true` as final catch-all in `cond`.

```elixir
# good
sanitized =
  raw_input
  |> String.trim()
  |> String.downcase()

# bad: single pipe
sanitized = raw_input |> String.trim()

# bad: starts with function call
sanitized =
  String.trim(raw_input)
  |> String.downcase()
```

```elixir
# good
if valid?(user), do: :ok, else: :error

# bad
unless valid?(user), do: :error, else: :ok
```

## Error Handling

### Tagged tuples

Use `{:ok, value}` / `{:error, reason}` for expected outcomes.

```elixir
# good
def fetch_user(id) do
  case Repo.get(User, id) do
    nil -> {:error, :not_found}
    user -> {:ok, user}
  end
end

# bad
def fetch_user(id) do
  Repo.get!(User, id)
end
```

### `with`

Use for chaining multiple fallible steps. Include `else`.

```elixir
# good
with {:ok, user} <- fetch_user(user_id),
     {:ok, account} <- fetch_account(user.account_id) do
  {:ok, account}
else
  {:error, :not_found} -> {:error, :not_found}
end

# bad: single clause
with {:ok, user} <- fetch_user(user_id) do
  {:ok, user}
end
```

If `else` becomes complex, normalize error shapes before the `with`.

### `case`

Use `case` for branching on one result or matching multiple shapes.

```elixir
case HTTPClient.get(url) do
  {:ok, %{status: 200, body: body}} -> {:ok, body}
  {:ok, %{status: status}} -> {:error, {:unexpected_status, status}}
  {:error, reason} -> {:error, {:http_error, reason}}
end
```

### `try/rescue`

Only around code that may raise, usually third-party code.

```elixir
# good
def safe_decode(json) do
  {:ok, Jason.decode!(json)}
rescue
  Jason.DecodeError -> {:error, :invalid_json}
end

# bad
def validate(data) do
  try do
    if data == %{}, do: raise("bad")
    :ok
  rescue
    _ -> :error
  end
end
```

### `raise`

Use only for programmer errors or invariant violations.

```elixir
# good
raise ArgumentError, "expected a non-empty list"

# bad
raise ArgumentError, "Expected a non-empty list."
```

## OTP

### GenServer

Rules:

* Public API first, callbacks after
* Mark callbacks with `@impl true`
* Expose API in the module; do not call `GenServer.call/cast` directly from outside
* `handle_call` for replies
* `handle_cast` for fire-and-forget
* `handle_info` for plain messages
* State must be a map or struct, not a bare value

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
  def handle_cast(:increment, state), do: {:noreply, %{state | count: state.count + 1}}
end
```

```elixir
# bad
GenServer.call(pid, :value) # from random external modules everywhere
```

### Agent

Use `Agent` only for simple shared state.

```elixir
# good
def start_link(initial), do: Agent.start_link(fn -> initial end)

# bad
# using Agent for complex business workflows
```

### Task

Use `Task` for one-off async work. Use `Task.Supervisor` when supervision matters.

```elixir
task = Task.async(fn -> expensive_computation() end)
result = Task.await(task, 5_000)
```

### Supervision

* Always supervise long-lived processes
* `:one_for_one` for independent workers
* `:one_for_all` when children depend on each other
* `DynamicSupervisor` for dynamic children

## Structs and Collections

* In `defstruct`, list nil-default atom fields first, then keyword defaults.
* Use `%__MODULE__{}` in types.
* Keyword lists: `[a: 1]`
* Atom-key maps: `%{a: 1}`
* Mixed-key maps: `%{:a => 1, "b" => 2}`

```elixir
# good
defstruct [:id, :name, active: true, params: []]

@type t :: %__MODULE__{
        id: integer() | nil,
        name: String.t() | nil,
        active: boolean(),
        params: Keyword.t()
      }

# bad
defstruct [active: true, :id, :name]
```

## Testing

* Use `describe` blocks
* Expression under test on the left
* Use pattern-match assertions where appropriate
* Prefer `setup`; use `setup_all` only when really needed

```elixir
describe "parse/1" do
  test "returns ok tuple for valid input" do
    assert MyApp.Token.parse("abc") == {:ok, %MyApp.Token{value: "abc"}}
  end

  test "returns error for empty input" do
    assert {:error, :empty} = MyApp.Token.parse("")
  end
end
```

## Comments

* Put comments above the code they describe
* One space after `#`
* Keep comments short and clear

```elixir
# Good: normalize external input before matching.
attrs = normalize_attrs(attrs)
```

Use these annotations where useful:

* `TODO:`
* `FIXME:`
* `OPTIMIZE:`
* `HACK:`
* `REVIEW:`

## Concurrency Selection

Choose by runtime need:

* long-lived stateful process → `GenServer`
* simple shared state → `Agent`
* one-off async work → `Task`
* jobs / retries / queues → `Oban`
* streaming / backpressure → `GenStage` / `Broadway`
* real-time UI → `Phoenix LiveView` + PubSub

## Anti-Patterns to Avoid

### Code

```elixir
# bad
String.to_atom(user_input)

# good
String.to_existing_atom(user_input)
```

```elixir
# bad for required keys
user[:id]

# good
user.id
```

```elixir
# bad
enabled = is_admin && is_active

# good
enabled = is_admin and is_active
```

```elixir
# bad
create_user(name, email, role, active, confirmed)

# good
create_user(%{name: name, email: email, role: role})
```

### Design

* Do not vary return shape via options; use separate functions.
* Avoid too many boolean flags; prefer one atom option.
* Avoid primitive obsession; use structs/maps for domain concepts.
* Split unrelated behaviors into separate functions.
* Do not raise for expected failures.

```elixir
# bad
fetch_user(id, as: :tuple)
fetch_user(id, as: :map)

# good
fetch_user(id)
fetch_user_map(id)
```

### OTP / Process Design

* Avoid large GenServer state
* Avoid slow I/O inside GenServer callbacks
* Always supervise long-lived processes
* Do not expose raw `GenServer.call/cast`
* Do not use processes only for code organization
* Pass only needed fields in messages
* Do not wrap everything in defensive `try/rescue`

```elixir
# bad
def handle_call(:sync_remote, _from, state) do
  result = HTTPClient.get!("https://example.com/slow")
  {:reply, result, state}
end

# better
def handle_call(:sync_remote, from, state) do
  Task.start(fn ->
    result = HTTPClient.get!("https://example.com/slow")
    GenServer.reply(from, result)
  end)

  {:noreply, state}
end
```

## Metaprogramming

* Prefer functions over macros
* Avoid macros unless clearly necessary
* Do not generate runtime code that could be generated at compile time

## Tooling

```sh
mix format
mix credo
mix dialyzer
mix test
mix docs
```
