
## Special Rule

Prefer `ast-grep` over other tools for structural code search (matching syntax patterns like function calls, imports, JSX, decorators, etc.) — if an `ast-grep-find` skill is available, load it first to know when and how to use it. For plain text search, prefer `rg` (ripgrep) over `grep` when it's installed.

## Code comments

Do not add comments in code changes unless the user explicitly asks for them.

## Writing tests

If the project already does testing, write as few tests as possible while still covering important paths. Prefer integration, functional, and e2e tests over unit tests. Fewer tests with good important-path coverage beats broad, granular coverage.

## File edits

Do use `edit` tool or similar tools instead of bash scripting for editing files, unless there is a clear pattern to replace text on "big scale".


## Plan mode

When writing a plan:

- **Reference call stacks** for code sections where understanding the call hierarchy matters. Show the chain of callers/callees so the context of the change is clear.
- **Cite exact locations** using `path/to/file.ext:line` format for every place that needs a change — whether adding, modifying, or removing code.

### Call stack example

Hypothetical: planning a change to add retry logic in a library's HTTP layer.

```
Call stack (where the change lands):
  client.py:42        Client.fetch()          ← public API, callers rely on this
    └─ session.py:88  Session.request()       ← add retry wrapper HERE
        └─ transport.py:15  Transport.send()  ← raises ConnectionError we catch

Change:
  - session.py:88     wrap Transport.send() call in retry loop (modify)
  - session.py:120    add `_should_retry(exc)` helper (new)
  - transport.py:15   no change — just documents what raises
```

This shows *why* the edit goes in `session.py` rather than `client.py` or `transport.py`: it's the layer that sees the failure but still owns the request lifecycle.
