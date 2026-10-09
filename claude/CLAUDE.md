
## Code Search

Use `rg` for plain text (strings, comments, config, logs). Do not use `grep` when `rg` is available.

## Subagents

Do NOT use subagents unless the user explicitly asks for one or an active skill requires one.

## Code Comments

Do not add comments to code changes unless the user explicitly requests them, even when the code is complex or new.

## Writing Tests

If the project already has a testing practice, add as few tests as necessary to cover the important behavior affected by the change.

Prefer, in order when appropriate:

1. End-to-end tests
2. Integration or functional tests
3. Unit tests

Prefer a small number of high-value tests covering important paths over broad granular unit-test coverage.

Do not introduce a new testing framework solely for a small change unless explicitly requested or clearly required by the project.

"As few tests as necessary" never overrides the project's own testing rules (`AGENTS.md`), and never means skipping this: when one function reads a shape and another writes the same shape, add a round-trip test, so what the read returns can be written back unchanged.

## Stacked PRs

Each PR in a stack is reviewed on its own. It must hold its own contracts: do not defer validation, tests or project conventions (such as where cross-context code lives) to a later PR in the stack.

## Plan Mode

When producing an implementation plan:

* Cite every relevant location using the exact `path/to/file.ext:line` format.
* Include locations for files or code that will be added, modified, or removed.
* When understanding the caller/callee hierarchy is relevant to deciding where a change belongs, include the call stack.

Example:

```text
Call stack (where the change lands):
  client.py:42        Client.fetch()             <- public API
    └─ session.py:88  Session.request()          <- change HERE
        └─ transport.py:15  Transport.send()     <- failure originates here

Change:
  - session.py:88     wrap Transport.send() in retry handling (modify)
  - session.py:120    add `_should_retry(exc)` helper (new)
  - transport.py:15   no change; referenced to explain error origin
```

The plan must explain why the selected layer is the correct place for the change when that choice depends on the call hierarchy.
