---
name: elixir-development
description: |
  Expert Elixir assistant for writing, reviewing, and refactoring idiomatic Elixir/Phoenix code. Use for any task that introduces or changes Elixir code. Enforces the Elixir Style Guide and official Naming Conventions across formatting, naming, module layout, docs, typespecs, error handling, OTP, structs, and collections, while avoiding the official Elixir anti-patterns. Phoenix, LiveView, Ecto, and supervision specifics live in references/phoenix-ecto-liveview.md (loaded on demand).

  Use for: any new or modified Elixir/Phoenix code, OTP modules, LiveView, Ecto, tests, docs, typespecs, and code review/refactoring.
  Do not use for: non-Elixir code, infra unrelated to Elixir, or pure architecture with no Elixir code.
---

# SKILL.md — Elixir

Reference for generating and reviewing Elixir code. Ground all decisions in:

- Elixir Style Guide: https://github.com/christopheradams/elixir_style_guide
- Naming Conventions: https://hexdocs.pm/elixir/naming-conventions.html
- Official anti-patterns: https://hexdocs.pm/elixir/code-anti-patterns.html (also `design-`, `process-`, and `macro-anti-patterns.html`)

For Phoenix, LiveView, Ecto, and supervision detail, read `references/phoenix-ecto-liveview.md`.

## Core Principles

- Write idiomatic, readable Elixir that already matches `mix format`.
- Prefer simple functions over clever abstractions.
- Prefer explicit return values over exceptions for *expected* failures.
- Avoid the official anti-patterns even when the code is technically valid.

## Formatting

Most of this is applied automatically by `mix format`; the rules are here so generated code is correct before formatting.

- Max line length: 98 chars (comments may go to 100).
- Unix line endings, trailing newline, no trailing whitespace.
- Spaces around operators and after commas/colons/semicolons.
- **No** spaces inside matched pairs (brackets, parens), after unary operators, or around the range operator.
- No space before `(` in calls.
- No blank line after `defmodule`.
- Blank line between `def`s to separate logical paragraphs.
- Add a blank line after a multiline assignment (visual cue the assignment is "over").
- Multiline lists/maps/structs: one item per line, opening and closing brackets on their own lines, items indented one level, brackets not indented. **When assigning**, keep the opening bracket on the assignment line.
- Multiline `case`/`cond`: if any clause needs multiple lines, make *all* clauses multiline and separate each with a blank line.
- Multiline `with`: align clauses; put `do:` on a new line aligned with the clauses, or use a full `do … else … end` block when there is an `else` or a multiline body.
- If a function head + `do:` is too long for one line, put `do:` on its own line indented one level, and treat the def as multiline (blank lines around it).

```elixir
# good — no spaces in pairs, spaces around binary operators, none around unary/range
sum = 1 + 2
0 - 1 == -1
^pinned = some_func()
5 in 1..10

# good — multiline assignment keeps the bracket on the assignment line
list = [
  :first_item,
  :second_item
]

# good — blank line after a multiline assignment
sanitized =
  raw_input
  |> String.trim()
  |> String.downcase()

next = another <> sanitized
```

## Naming

- Functions, variables, atoms: `snake_case`
- Modules: `CamelCase`; acronyms stay uppercase (`HTTP`, `XML`, `RFC`)
- Boolean predicates: trailing `?`
- Guard-safe boolean checks: `is_` prefix with `defguard`
- Exceptions: end with `Error`
- Filenames: `snake_case`, matching the module path (each namespace level = a directory)
- Avoid repeated namespace fragments (`Todo.Todo` → `Todo.Item`)
- Private functions must not reuse a public function's name; avoid the `def name` / `defp do_name` pattern — find a more descriptive name for the helper

```elixir
# good
def valid?(user), do: ...
defguard is_admin(role) when role == :admin
defmodule MyApp.HTTPClient do
end

# bad
def isValid(user), do: ...
defguard admin?(role) when role == :admin   # guard-safe check should be is_admin
defmodule MyApp.HttpClient do                # acronym must stay uppercase
end
```

## Module Layout

List directives and attributes in this order, with a blank line between groups, and sort terms (alias/import module names) alphabetically within a group:

1. `@moduledoc`
2. `@behaviour`
3. `use`
4. `import`
5. `require`
6. `alias`
7. module attributes
8. `defstruct`
9. `@typedoc` / `@type`
10. `@callback` / `@macrocallback` / `@optional_callbacks`
11. macros (`defmacro`)
12. guards (`defguard`)
13. public/private functions

Also:

- `@moduledoc` immediately after `defmodule`, separated from the next line by a blank line.
- `@moduledoc false` for intentionally undocumented internal modules.
- One module per file (except a module used only internally, e.g. in a test).
- Use `__MODULE__` for self-reference; if you want a prettier name, `alias __MODULE__, as: Name`.

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

- Use Markdown heredocs; add doctests when useful (indent the `iex>` block 4 spaces under `## Examples`).
- Put `@spec` directly before `def`, after `@doc`, with no blank line between `@spec` and `def`.
- Define custom types near the top; pair each `@typedoc` with its `@type`, separated by a blank line.
- Name the primary struct type `t`.
- Split a union type that is too long across lines, each member indented one level past the type name with leading `|`.

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

@type result ::
        {:ok, term()}
        | {:error, :empty}
        | {:error, :invalid}
```

## Pipelines and Expressions

- Use pipelines only for **multiple** transformations; don't pipe just once.
- Start a pipeline from a bare variable, not a function call.
- Always use parentheses in piped calls and for zero-arity calls (`do_stuff()`), so they're distinguishable from variables.
- Use parentheses when a `def` has arguments; omit them when it doesn't.
- Group single-line `def`s that match the same function; separate multiline `def`s with a blank line. If you have more than one multiline `def`, don't mix in single-line `def`s.
- Use `do:` for a simple one-line `if`.
- Never use `unless` **with `else`** — rewrite positive-case-first as `if`. (This skill additionally prefers `if … not` over a bare `unless`; that is stricter than the official guide, which permits bare `unless` — keep or drop this house rule deliberately.)
- Use `true` as the final catch-all in `cond` (not `:else`).
- Omit square brackets from keyword lists when they're the last argument and optional.

```elixir
# good
sanitized =
  raw_input
  |> String.trim()
  |> String.downcase()

if valid?(user), do: :ok, else: :error
if plan not in @accessible_plans, do: disable(account_code)
some_function(foo, bar, a: "baz", b: "qux")

# bad
sanitized = raw_input |> String.trim()        # single pipe
sanitized =
  String.trim(raw_input)                       # pipeline must start from a bare variable
  |> String.downcase()
unless valid?(user), do: :error, else: :ok     # unless with else
some_function(foo, bar, [a: "baz", b: "qux"])  # unneeded brackets
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

# bad — raises on an expected "not found"
def fetch_user(id), do: Repo.get!(User, id)
```

### `with`

Use to chain multiple fallible steps. Include `else`. Don't use `with` for a single clause — use `case`. If `else` gets complex, normalize error shapes before the `with`.

```elixir
with {:ok, user} <- fetch_user(user_id),
     {:ok, account} <- fetch_account(user.account_id) do
  {:ok, account}
else
  {:error, :not_found} -> {:error, :not_found}
end
```

### `case`

Use `case` to branch on one result or match multiple shapes.

```elixir
case HTTPClient.get(url) do
  {:ok, %{status: 200, body: body}} -> {:ok, body}
  {:ok, %{status: status}} -> {:error, {:unexpected_status, status}}
  {:error, reason} -> {:error, {:http_error, reason}}
end
```

### `try/rescue`

Only around code that may raise, usually third-party. Don't wrap your own expected-failure logic.

```elixir
# good
def safe_decode(json) do
  {:ok, Jason.decode!(json)}
rescue
  Jason.DecodeError -> {:error, :invalid_json}
end
```

### `raise`

Only for programmer errors / invariant violations. Exception modules end in `Error`; messages are lowercase with no trailing punctuation.

```elixir
raise ArgumentError, "expected a non-empty list"
```

## OTP

### GenServer

- Public API first, callbacks after; mark callbacks `@impl true`.
- Expose a module API; never call `GenServer.call/cast` from outside the module.
- `handle_call` for replies, `handle_cast` for fire-and-forget, `handle_info` for plain messages.
- State is a map or struct, never a bare value.
- Don't do slow I/O inside a callback — reply async (`GenServer.reply/2` from a `Task`) instead of blocking the process.

```elixir
defmodule MyApp.Counter do
  use GenServer

  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(opts \\ []), do: GenServer.start_link(__MODULE__, %{count: 0}, opts)

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

### Agent / Task

- `Agent` only for simple shared state, never complex business workflows.
- `Task` for one-off async work; `Task.Supervisor` when supervision matters.

```elixir
task = Task.async(fn -> expensive_computation() end)
result = Task.await(task, 5_000)
```

### Supervision

- Always supervise long-lived processes; don't spawn unsupervised.
- `:one_for_one` for independent workers, `:one_for_all` when children depend on each other.
- `DynamicSupervisor` for children started at runtime; `Registry` for process discovery.

See `references/phoenix-ecto-liveview.md` for application-tree and concurrency-selection detail.

## Structs and Collections

- In `defstruct`, list `nil`-default atom fields first, then keyword defaults.
- Omit the brackets when `defstruct`'s argument is a pure keyword list; brackets are **required** once there's at least one bare atom.
- Use `%__MODULE__{}` in the struct's own type.
- Keyword lists: `[a: 1]`. Atom-key maps: `%{a: 1}`. Mixed-key maps: verbose, atoms first: `%{:a => 1, "b" => 2}`.
- Match strings with the concatenator, not binary patterns: `"my" <> rest = str`.

```elixir
# brackets required (has bare atoms)
defstruct [:id, :name, active: true, params: []]

# brackets omitted (pure keyword list)
defstruct params: [], active: true

@type t :: %__MODULE__{
        id: integer() | nil,
        name: String.t() | nil,
        active: boolean(),
        params: Keyword.t()
      }
```

## Testing

- Use `describe` blocks.
- Expression under test on the left, expected on the right — unless the assertion is a pattern match (then `assert {:ok, x} = fun()`).
- Prefer `setup`; use `setup_all` only when truly needed.

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

- Place comments on the line above the code they describe; one space after `#`.
- Comments longer than a word are capitalized and use sentence punctuation; limit comment lines to 100 chars.
- Annotations are uppercase + colon + space + note: `TODO:`, `FIXME:`, `OPTIMIZE:`, `HACK:`, `REVIEW:`. Document any custom keyword in the project README.

```elixir
# Normalize external input before matching.
attrs = normalize_attrs(attrs)
```

## Anti-Patterns to Avoid

Follow the official anti-pattern docs linked at the top. The most common in generated code:

### Code

```elixir
String.to_atom(user_input)        # bad — unbounded atom table (DoS)
String.to_existing_atom(user_input)  # good

user[:id]                         # bad for required keys — silent nil
user.id                           # good — raises on a real bug

enabled = is_admin && is_active   # bad — use strict boolean operators
enabled = is_admin and is_active  # good

create_user(name, email, role, active, confirmed)  # bad — positional soup
create_user(%{name: name, email: email, role: role})  # good
```

### Design

- Don't vary the return shape via options; use separate functions (`fetch_user/1` vs `fetch_user_map/1`).
- Avoid many boolean flags; prefer a single atom option.
- Avoid primitive obsession; model domain concepts as structs/maps.
- Don't raise for expected failures.

### Process / OTP

- Avoid large GenServer state and slow I/O in callbacks.
- Don't use processes purely for code organization.
- Pass only needed fields in messages.
- Don't wrap everything in defensive `try/rescue`.

```elixir
# bad — blocks the GenServer on slow I/O
def handle_call(:sync_remote, _from, state) do
  {:reply, HTTPClient.get!("https://example.com/slow"), state}
end

# better — reply asynchronously
def handle_call(:sync_remote, from, state) do
  Task.start(fn -> GenServer.reply(from, HTTPClient.get!("https://example.com/slow")) end)
  {:noreply, state}
end
```

### Metaprogramming

- Prefer functions over macros; avoid macros unless clearly necessary.
- Don't generate at runtime what could be generated at compile time.

## Tooling

```sh
mix format --check-formatted
mix credo --strict
mix dialyzer
mix test
mix docs
```
