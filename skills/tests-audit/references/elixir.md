# Elixir (ExUnit)

On-demand reference for `tests-audit`. Read when the tests in scope are ExUnit.

## Commands

| Purpose | Command |
| --- | --- |
| Focused | `mix test test/my_app/billing_test.exs:42` |
| Scoped suite (baseline) | `mix test test/my_app/billing/` or `mix test --only billing` |
| Rerun | `mix test --failed`, `mix test --stale` |
| Mutation targets | `mix test <keeper> --cover` (or `mix coveralls.html` with excoveralls) to list the lines the keeper executes (execution, not assertion) |
| Gate | `mix format --check-formatted`, `mix credo --strict`, `mix compile --warnings-as-errors` |
| Types | `mix dialyzer`, if configured |

Mutation check: edit one production line the keeper should guard, rerun the
focused command, confirm red, restore.

## Junk patterns in ExUnit

- Mox `expect(Mock, :fun, fn args -> ... end)` tests that only restate the call
  shape, while a context-level test already proves the outcome.
- Mox/Mimic stubs that return exactly the value the test then asserts.
- `Mimic.copy/1` or `stub` on the module under test.
- `:sys.get_state/1` or other internal-state assertions on a GenServer instead
  of its public API or emitted messages.
- `Process.sleep/1` or polling loops. Use `start_supervised!/1`,
  `Process.monitor/1` + `assert_receive {:DOWN, ...}`, or `assert_receive`
  with a timeout.
- Private functions made public for tests (`@doc false def`,
  `@compile :export_all`) and tested directly.
- Changeset-internal tests that duplicate the context function's own
  validation tests.
- LiveView tests that assert raw HTML substrings instead of `has_element?/2`
  on stable ids, or `render_component` tests that duplicate a `live/2` test.
- Job tests (e.g. Oban in `:inline` or `:manual` mode) that assert enqueued
  args instead of the outcome the job produces, when the outcome is reachable.
- `async: false` added to hide shared-state leaks rather than isolate them.
- Fixtures that insert the rows or state the function under test should create.
- Tests with no `assert`, `refute`, `assert_raise`, or `assert_receive`.

## Production seams to delete

- `@doc false` public functions whose only callers are tests.
- A behaviour plus `Application.get_env(:my_app, :impl)` with one real
  implementation and a Mox mock as the only other. Keep it when the behaviour
  wraps a real IO boundary (HTTP, email, LLM, payment provider).
- Test-only branches in `config/*.exs` or `Mix.env()` checks in lib code.
- `reset/0` or `clear/0` GenServer calls with no production caller.

## Keepers to prefer

- The public context function with the Ecto SQL sandbox.
- LiveView through `live/2` plus `render_submit/2`, `render_change/2`,
  `element/2`, and `has_element?/2`.
- `Req.Test` or Bypass at the HTTP edge over mocking the client module.
- One deterministic test adapter at an IO boundary, selected by config, over
  per-test Mox expectations for the same contract.

## Discovery recipes

```bash
rg -n '@doc false' lib/ -A1 | rg 'def '                 # then rg each name outside test/
rg -n ':sys.get_state|Process.sleep|@compile :export_all' test/ lib/
rg -c 'expect\(' test/ | sort -t: -k2 -n | tail
rg -n 'Mimic.copy|copy\(' test/test_helper.exs
rg -n 'async: false' test/
```

Tests without any assertion (`assert*` / `refute*` prefixes cover
`assert_receive`, `assert_raise`, etc.):

```bash
ast-grep scan --inline-rules '
id: no-assert
language: elixir
rule:
  pattern: test $NAME do $$$BODY end
  not:
    has:
      stopBy: end
      regex: ^(assert|refute)
' test/
```
