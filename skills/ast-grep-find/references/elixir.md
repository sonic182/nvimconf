# Elixir

Verified against ast-grep 0.45.2.

## Everything is a `call` node

Elixir has no dedicated function-definition node. `def`, `defp`, `defmodule`,
`defmacro` and friends are macros, so the grammar sees a call:

```bash
ast-grep -p 'def foo(a) do
  :ok
end' -l elixir --debug-query=ast
```

```
source
  call
    target: identifier          # "def"
    arguments
      call                      # "foo(a)"
        target: identifier
        arguments
    do_block
```

Two consequences run through everything below: `kind:` is almost always `call`
and therefore useless as a filter, and each *syntactic form* of a definition is
a different shape that needs its own pattern.

## The three shapes of a function head

A pattern for one does **not** match the others:

```bash
# plain
ast-grep -p 'def $NAME($$$ARGS) do $$$BODY end' -l elixir lib

# guarded
ast-grep -p 'def $NAME($$$ARGS) when $COND do $$$BODY end' -l elixir lib

# one-liner
ast-grep -p 'def $NAME($$$ARGS), do: $BODY' -l elixir lib
```

Same three for `defp`. When a function may be written any of these ways, run all
three, or combine them under an `any:` YAML rule.

An empty result from the plain pattern is not evidence the function is absent —
the head is probably guarded or inline. Confirm with `--debug-query=cst` before
falling back to `rg`.

Multiline heads and default arguments need no special handling; `$$$ARGS`
absorbs them.

## `ast-grep outline` needs rules for Elixir

`ast-grep outline` prints **`nothing found`** for every `.ex`/`.exs` file out of
the box. That is not a parse failure and not a missing language — patterns work
normally. ast-grep simply ships no bundled outline extractor for Elixir, for the
reason above: there is no node kind to key an extractor on.

Pass the bundled ruleset:

```bash
ast-grep outline lib/my_app/accounts.ex \
  --outline-rules assets/elixir-outline.yml --view expanded
```

```
lib/doomanager/mcp/scope.ex
  1: defmodule Doomanager.MCP.Scope do
 24:   def allowed_account_codes(%{account_code: account_code}), do: List.wrap(account_code)
 31:   def fetch_engine(hashid, context) do
 40:   def check_engine(hashid, allowed_account_codes) do
105:   defp cast_store_id(_store_id), do: :error
```

`assets/elixir-outline.yml` covers `defmodule` plus `def`/`defp` in all three
head shapes. Extend it for `defmacro`, `defstruct`, `defdelegate` or
`defimpl` the same way.

### Outline-rule schema

Outline rules are **not** `ast-grep scan` rules. The fields, in the order the
parser demands them:

| Field           | Notes                                                        |
| --------------- | ------------------------------------------------------------ |
| `id`            | Required. Referenced by `parentRuleIds`.                      |
| `role`          | Required. Only `item` or `member`.                            |
| `parentRuleIds` | Required when `role: member`. List of `item` ids to nest under. |
| `language`      | Required.                                                     |
| `symbolType`    | Required. Free-form label shown in the output (`module`, `function`, …). |
| `name`          | Required. A metavariable the rule binds, e.g. `$NAME`.        |
| `rule`          | Required. Ordinary rule body — `pattern:`, `kind:`, `all:`, … |

Several extractors live in one file as YAML documents separated by `---`.

Two traps:

- A one-liner pattern **must be quoted**: unquoted `pattern: def $NAME($$$ARGS), do: $BODY`
  makes YAML parse `do:` as a mapping value and the file is rejected.
- `role: member` without `parentRuleIds` fails with `missing field parentRuleIds`.
  Members are what nest under the module; items without members produce a flat list.

## Pipelines and `|>`

A piped call is not the same node as a direct one. Against

```elixir
def a(q, id), do: Repo.get(q, id)
def b(q, id), do: q |> Repo.get(id)
```

`Repo.get($Q, $ID)` matches only `a` — the pipe moves the first argument out of
the argument list. `Repo.get($$$ARGS)` matches both, at the cost of the piped
receiver being invisible in the match. Prefer the `$$$ARGS` form for
call-site inventories, and pipe-aware patterns only when the receiver matters.
