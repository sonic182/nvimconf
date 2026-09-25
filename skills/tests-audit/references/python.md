# Python (pytest)

On-demand reference for `tests-audit`. Read when the tests in scope are pytest.

## Commands

Prefix with the project's runner (`poetry run`, `uv run`) when it uses one.

| Purpose | Command |
| --- | --- |
| Focused | `pytest tests/test_billing.py::TestInvoice::test_total` or `pytest tests/test_billing.py -k total` |
| Scoped suite (baseline) | `pytest tests/billing/` or `pytest -m "not e2e" tests/billing/` |
| Mutation targets | `pytest <keeper> --cov=myapp.billing --cov-report=term-missing` to list the lines the keeper executes (execution, not assertion) |
| Lint / format | `ruff check <paths>`, `ruff format <paths>` |
| Types | `mypy` / `pyright` on changed paths, if configured |

Mutation check: edit one production line the keeper should guard, rerun the
focused command, confirm red, restore. `mutmut run --paths-to-mutate <file>`
is an option when installed; never add it just for an audit.

## Junk patterns in pytest

- `mock.assert_called_once_with(...)` call-shape tests that restate the
  implementation, while a boundary test already proves the outcome.
- `MagicMock()` / `AsyncMock()` without `spec=` or `autospec=True`: any
  attribute exists, so a renamed method still "passes". Fix with a spec, or
  test at the real boundary.
- `patch("myapp.billing.compute_total")` in a test *of* `compute_total`'s
  module: the mock replaces the unit under test.
- `side_effect` fakes that re-implement the logic being asserted.
- `@pytest.mark.parametrize` rows that all exercise the same branch; keep one
  row per distinct branch or boundary value.
- Tests importing `_private` helpers when the public function covers them.
- `autouse` conftest fixtures that silently provide the state or result the
  test claims to verify.
- `pytest.raises(Exception)` (or no `match=`) that passes on the wrong error.
- Async tests that never run the path: a missing `pytest.mark.asyncio` under
  `asyncio_mode = strict`, or an un-awaited coroutine.
- Golden/snapshot files regenerated from the code under test and never read.
- Tests with no `assert`, `pytest.raises`, or mock assertion at all.

## Production seams to delete

- `_private` functions or module globals imported only by tests.
- `reset_*()` / `clear_cache_for_tests()` helpers with no production caller.
  Keep a cache reset that production also uses.
- Keyword parameters that default to the real dependency and are overridden
  only by tests; prefer `monkeypatch` at the IO edge.
- `if settings.testing:` or `"PYTEST_CURRENT_TEST" in os.environ` branches.
- `__all__` entries or re-exports that only tests use.

## Keepers to prefer

- The public function or service at the real boundary, with fake IO:
  `tmp_path`, an in-memory or temp SQLite engine, a stub at the HTTP
  transport/client edge, `monkeypatch` on the outermost call.
- One functional harness (CLI, HTTP app client, message dispatcher) over many
  mocked per-layer replays.
- Keep tests that need real services behind their own marker (e.g. `e2e`) so
  they stay out of the focused loop.

## Discovery recipes

```bash
rg -n 'from \S+ import .*\b_[a-z]\w*' tests/          # private imports
rg -n 'MagicMock\(\)|AsyncMock\(\)' tests/            # spec-less mocks
rg -c 'assert_(called|awaited)' tests/ | sort -t: -k2 -n | tail
rg -n 'pytest.raises\(Exception\)' tests/
rg -n 'def (reset|clear)_\w*' src/ myapp/ 2>/dev/null   # candidate seams; then rg their callers
```

Tests without any assertion:

```bash
ast-grep scan --inline-rules '
id: no-assert
language: python
rule:
  kind: function_definition
  regex: ^(async )?def test_
  not:
    has:
      stopBy: end
      any:
        - kind: assert_statement
        - pattern: pytest.raises($$$)
        - all: [{kind: call}, {regex: "\\.assert_\\w+\\("}]
' tests/
```
