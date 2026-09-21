# Module Conventions

On-demand reference for `elixir-development`.

Read this when creating a module, reordering its directives, writing `@doc`,
`@moduledoc`, `@spec`, or `@type`, or defining a struct.

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

