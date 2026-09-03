---
name: elixir-development
description: |
    Expert Elixir assistant for writing, reviewing, debugging, and refactoring idiomatic Elixir, Phoenix, LiveView, Ecto, OTP, and ExUnit code. Use whenever the user asks to create, modify, review, explain, modernize, or test Elixir code, including modules, contexts, schemas, migrations, LiveViews, GenServers, supervisors, tests, docs, and typespecs. Enforces project-local conventions, mix format, official naming conventions, official Elixir anti-pattern guidance, and practical idiomatic style.
---

# Elixir Development

Use this skill for any task that introduces, changes, reviews, debugs, or refactors Elixir code.

For Phoenix, LiveView, Ecto, and supervision-tree specifics, read
`references/phoenix-ecto-liveview.md` when the task touches those areas.

Primary references:

* Elixir Naming Conventions: https://hexdocs.pm/elixir/naming-conventions.html
* Elixir code anti-patterns: https://hexdocs.pm/elixir/code-anti-patterns.html
* Elixir design anti-patterns: https://hexdocs.pm/elixir/design-anti-patterns.html
* Elixir process anti-patterns: https://hexdocs.pm/elixir/process-anti-patterns.html
* Elixir macro anti-patterns: https://hexdocs.pm/elixir/macro-anti-patterns.html
* Mix formatter: https://hexdocs.pm/mix/Mix.Tasks.Format.html
* Community Elixir Style Guide: https://github.com/christopheradams/elixir_style_guide

## Operating Principles

Write Elixir that is correct, simple, readable, and already close to `mix format`.

Prefer:

* Project-local conventions over generic style advice.
* Small functions over clever abstractions.
* Explicit return values for expected outcomes.
* Pattern matching and tagged tuples for ordinary control flow.
* Data transformation in pure functions, with side effects at boundaries.
* Official Elixir guidance over house rules.

Avoid:

* Raising for expected failures.
* Defensive code that hides bugs.
* Processes used only for code organization.
* Macros where functions, behaviours, protocols, or data would work.
* Style churn unrelated to the user's request.

## Rule Priority

When rules conflict, apply this priority:

1. User request and correctness.
2. Existing public API compatibility, unless the user asks for a redesign.
3. Project-local conventions:

   * `.formatter.exs`
   * existing module layout
   * existing context/schema/test patterns
   * existing error tuple shapes
   * existing dependency choices
4. Official Elixir docs and anti-pattern guidance.
5. Official Phoenix, Ecto, and LiveView docs when applicable.
6. Community Elixir Style Guide.
7. This skill's house rules.

When applying a house rule, do not present it as official Elixir guidance.

## Idiomatic Enforcement Protocol

When writing code:

1. Inspect nearby project code when available.
2. Preserve the existing architecture unless it is clearly broken or the user asks to change it.
3. Generate code that should pass `mix format`.
4. Prefer explicit, narrow APIs.
5. Include tests when behavior changes or new behavior is introduced.
6. Add docs and specs for public APIs when useful, especially library-style modules.
7. Explain non-obvious idiomatic choices briefly.

When reviewing code, report findings in this order:

1. Correctness bugs.
2. Security or data-leak risks.
3. Runtime, OTP, concurrency, or supervision risks.
4. Non-idiomatic Elixir.
5. Maintainability and readability.
6. Formatting and tooling.

For each issue, include:

* The problem.
* Why it matters.
* A concrete fix or replacement snippet when practical.

## Formatting

Use the project `.formatter.exs` as the source of truth. Do not fight formatter output.

Generate code that should pass `mix format` before formatting:

* No trailing whitespace.
* Unix line endings.
* Trailing newline.
* Spaces around binary operators and after commas, colons, and semicolons.
* No space before `(` in calls.
* No spaces inside matched pairs.
* No blank line immediately after `defmodule`.
* Blank lines between logically distinct functions.
* Multiline collections use one item per line.
* Multiline assignments are followed by a blank line before the next expression.
* Prefer readable line breaks over dense cleverness.

Good:

```elixir
sanitized =
  raw_input
  |> String.trim()
  |> String.downcase()

next = "prefix:" <> sanitized
```

## Naming

Follow official Elixir naming conventions.

Use:

* Variables, functions, module attributes, and atoms: `snake_case`.
* Modules and aliases: `CamelCase`.
* Acronyms in module names: uppercase, such as `HTTP`, `XML`, `API`, `ID`.
* Boolean predicates: trailing `?`.
* Guard-safe boolean checks: `is_` prefix.
* Exceptions: names ending in `Error`.
* Filenames: `snake_case`, matching the module path by convention.

Avoid:

* Combining `is_` and `?`.
* Repeated namespace fragments, such as `Todo.Todo`.
* Private helpers named as vague `do_` versions of public functions when a domain name is clearer.
* Reusing the same name for public and private functions when it makes call sites confusing.

```elixir
def valid?(user), do: user.email_confirmed_at != nil  # good — predicate ends in ?
def isValid(user), do: true                            # bad — not snake_case, no ?

defguard is_admin(role) when role == :admin            # good — is_ prefix, guard-safe
defguard admin?(role) when role == :admin              # bad — ? isn't guard-safe

MyApp.HTTPClient  # good — acronym stays uppercase
MyApp.HttpClient  # bad — acronym should stay uppercase
```

## Module Layout

Use this order unless the project clearly follows another convention:

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
11. macros
12. guards
13. public functions
14. private functions

Within each directive group, sort aliases/imports/requires alphabetically when doing so does not obscure meaning.

Rules:

* Put `@moduledoc` immediately after `defmodule`.
* Use `@moduledoc false` for intentionally internal modules.
* Prefer one module per file.
* Use `__MODULE__` for self-reference.
* If a module aliases itself only for readability, use `alias __MODULE__, as: Name`.

Example:

```elixir
defmodule MyApp.Token do
  @moduledoc """
  Token utilities.
  """

  alias MyApp.Accounts.User

  defstruct [:value]

  @typedoc "Parsed token."
  @type t :: %__MODULE__{value: String.t()}

  @spec parse(String.t()) :: {:ok, t()} | {:error, :empty}
  def parse(""), do: {:error, :empty}
  def parse(value), do: {:ok, %__MODULE__{value: value}}
end
```

## Docs and Typespecs

Use docs and specs to clarify public APIs, not to decorate obvious private helpers.

Rules:

* Put `@doc` before `@spec`.
* Put `@spec` directly before `def`.
* Do not leave a blank line between `@spec` and `def`.
* Use Markdown heredocs for module and function docs.
* Add doctests when they clarify behavior and are stable.
* Name a struct's primary type `t`.
* Put custom types near the top of the module.
* Pair each `@typedoc` with the relevant `@type`.

Example:

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
```

For long union types, split members across lines:

```elixir
@type result ::
        {:ok, term()}
        | {:error, :empty}
        | {:error, :invalid}
```

## Functions and Control Flow

Prefer pattern matching in function heads when it makes valid input shapes clear.

Prefer guards for simple type or value constraints. Keep guards side-effect-free.

Use `case` when branching on one result or matching multiple result shapes.

Use `with` to chain multiple fallible steps. Do not use `with` for a single clause. Include an
`else` when the error shapes need translation. If `else` becomes complex, normalize error
shapes near their source.

Use `cond` for multiple unrelated boolean checks. Use `true` as the catch-all clause.

Use `if` for simple boolean branches.

Do not use `unless` with `else`. This skill also prefers `if ... not` over bare `unless` as
a house rule, but do not claim that bare `unless` is invalid Elixir.

Good:

```elixir
case HTTPClient.get(url) do
  {:ok, %{status: 200, body: body}} -> {:ok, body}
  {:ok, %{status: status}} -> {:error, {:unexpected_status, status}}
  {:error, reason} -> {:error, {:http_error, reason}}
end
```

Good:

```elixir
with {:ok, user} <- fetch_user(user_id),
     {:ok, account} <- fetch_account(user.account_id) do
  {:ok, account}
else
  {:error, :not_found} -> {:error, :not_found}
end
```

Bad:

```elixir
with {:ok, user} <- fetch_user(user_id) do
  {:ok, user}
end
```

## Pipelines

Use pipelines for multiple transformations where each step clearly transforms the previous result.

Rules:

* Do not pipe once.
* Prefer starting a pipeline from a variable or clear value.
* Use parentheses in piped function calls.
* Avoid pipelines that hide branching, error handling, or unrelated operations.
* Break pipelines before they become a railway maze.

Good:

```elixir
normalized =
  attrs
  |> trim_string_values()
  |> downcase_email()
  |> validate_required_fields()
```

Bad:

```elixir
normalized = attrs |> trim_string_values()
```

## Error Handling

Use tagged tuples for expected outcomes:

```elixir
{:ok, value}
{:error, reason}
```

Use non-bang functions when callers are expected to handle failure.

Use bang functions only when failure means a bug, invalid invariant, bad setup, or unrecoverable edge condition.

```elixir
# good — returns a tagged tuple for an expected outcome
def fetch_user(id) do
  case Repo.get(User, id) do
    nil -> {:error, :not_found}
    user -> {:ok, user}
  end
end

# bad — raises on an expected "not found"
def fetch_user(id), do: Repo.get!(User, id)
```

Use `try/rescue` only around code that may raise, usually third-party or boundary code. Do
not wrap your own expected-failure logic in `try/rescue`.

Good:

```elixir
def safe_decode(json) do
  {:ok, Jason.decode!(json)}
rescue
  Jason.DecodeError -> {:error, :invalid_json}
end
```

Raise only for programmer errors or invariant violations:

```elixir
raise ArgumentError, "expected a non-empty list"
```

Exception messages are lowercase and have no trailing punctuation.

## Data and Collections

Prefer domain structs or maps over long positional argument lists.

Use keyword lists for options. Use maps or structs for domain data.

For required atom keys, prefer pattern matching or dot access.

For optional or dynamic keys, prefer bracket access, `Map.get/3`, `Map.fetch/2`, or
`Map.fetch!/2` depending on the failure semantics.

Use:

* `Map.fetch/2` when missing keys are expected and should be handled.
* `Map.fetch!/2` when missing keys are bugs.
* `Map.get/3` when a default is meaningful.

Avoid dynamic atom creation from external input. Use `String.to_existing_atom/1` only when
the atom set is known and already loaded.

Use strict boolean operators (`and`, `or`, `not`) when operands must be booleans. Use `&&`,
`||`, and `!` only when truthy/falsy semantics are intentional.

```elixir
enabled = is_admin and is_active  # good — not `is_admin && is_active`
```

Use `Enum` for eager collection work. Use `Stream` only for lazy, large, or infinite flows.

Use `Date`, `Time`, `NaiveDateTime`, and `DateTime` instead of manual date/time arithmetic.

Use `URI`, `Path`, and structured APIs instead of string concatenation for structured data.

## Structs

Rules:

* In `defstruct`, list `nil`-default atom fields first, then keyword defaults.
* Omit brackets when `defstruct` has only keyword defaults.
* Keep brackets when `defstruct` includes bare atom fields.
* Use `%__MODULE__{}` in the struct's own type.

```elixir
defstruct [:id, :name, active: true, params: []]  # brackets required — has bare atom fields

@type t :: %__MODULE__{
        id: integer() | nil,
        name: String.t() | nil,
        active: boolean(),
        params: Keyword.t()
      }
```

## OTP

### GenServer

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

### Agent, Task, and Supervision

Use:

* `Agent` only for simple shared state.
* `Task` for one-off async work.
* `Task.Supervisor` when task lifecycle and supervision matter.
* `DynamicSupervisor` for children started at runtime.
* `Registry` for process discovery.
* A job library, such as Oban, for durable background work, retries, and queues when the project already uses it or the user asks for that design.

Always supervise long-lived processes. Do not use unsupervised `spawn` for production workflows.

Use `:one_for_one` for independent children and `:one_for_all` when children depend on each other.

Do not put business logic in processes merely because they feel “service-like.” Use modules and functions until runtime state, concurrency, fault tolerance, or isolation is needed.

## Testing

Use ExUnit conventions that match the project.

Prefer:

* `describe` blocks around a function or behavior.
* Clear test names describing observable behavior.
* Expression under test on the left and expected value on the right.
* Pattern matching assertions for tagged tuples.
* `setup` for repeated per-test data.
* `setup_all` only for shared expensive setup that is safe across tests.

Good:

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

When reviewing tests, flag:

* Tests that depend on order.
* Tests that hide too much behind helpers.
* Tests that assert implementation details instead of behavior.
* Shared state that can leak between async tests.

## Comments

Prefer readable code over explanatory comments.

Use comments for:

* Non-obvious domain rules.
* External constraints.
* Intentional tradeoffs.
* Workarounds with context.

Rules:

* Put comments above the code they describe.
* Use one space after `#`.
* Capitalize and punctuate sentence comments.
* Use uppercase annotations: `TODO:`, `FIXME:`, `OPTIMIZE:`, `HACK:`, `REVIEW:`.
* Document custom annotations in the project README.

Good:

```elixir
# Normalize external input before matching on known statuses.
attrs = normalize_attrs(attrs)
```

## Anti-Patterns to Flag

Flag official Elixir anti-patterns, especially:

* Dynamic atom creation from external input.
* Non-assertive map access for required keys.
* Long parameter lists.
* Boolean flag arguments controlling unrelated behavior.
* Return shapes that vary by option.
* Complex `else` blocks in `with`.
* Exceptions for expected failures.
* Overuse of comments to compensate for unclear code.
* Large GenServer state.
* Slow I/O inside GenServer callbacks.
* Sending unnecessary data between processes.
* Processes used only for code organization.
* Unsafely broad `try/rescue`.
* Macros where functions or data would work.

Examples:

```elixir
# Bad for required keys
user[:id]

# Good when missing :id is a bug
user.id
```

```elixir
# Bad
create_user(name, email, role, active, confirmed)

# Better
create_user(%{
  name: name,
  email: email,
  role: role
})
```

## Phoenix, Ecto, and LiveView

When the task touches Phoenix, Ecto, LiveView, controllers, contexts, schemas, migrations,
queries, changesets, PubSub, or application supervision trees, read:

`references/phoenix-ecto-liveview.md`

Use that reference for framework-specific boundaries, security checks, lifecycle rules,
migrations, Ecto query/write patterns, and supervision selection.

## Verification

When project files are available and commands are allowed, prefer this gate:

```sh
mix format --check-formatted
mix compile --warnings-as-errors
mix credo --strict
mix test
mix dialyzer
```

Adapt the gate to the project:

* If Credo is not installed, skip it and say so.
* If Dialyzer is not configured, skip it and say so.
* If tests are expensive, run the narrowest relevant tests first.
* If changing docs or public APIs, consider `mix docs` when ExDoc is configured.
* Do not invent tooling setup unless the user asks.

When commands cannot be run, provide the commands the user should run and clearly label the review as static.

## Output Style

When generating or refactoring code:

* Return the final code first when the user asks for code.
* Explain only the important choices after the code.
* Keep explanations specific to the code, not generic Elixir lectures.
* Mention any assumptions.

When reviewing code:

* Prioritize actionable findings.
* Avoid noisy style nitpicks unless the user asks for a strict style review.
* Include replacement snippets for high-value changes.
* Distinguish official guidance from project or house style.
