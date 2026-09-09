
## Special Rule

For structural code search involving syntax-aware patterns such as function calls, imports, JSX, decorators, classes, or AST structure:

* Use `ast-grep` instead of text-based search tools.
* If an `ast-grep-find` skill is available, load and follow that skill before performing structural searches.
* For plain-text search, use `rg` (ripgrep) when available.
* Do not use `grep` when `rg` is available.

## File Editing

### Mandatory editing rule

Use the dedicated `Edit` tool for file modifications whenever it is available and capable of making the requested change.

This is a hard requirement, not a preference.

Do NOT modify files by generating or executing scripts or shell commands when the `Edit` tool can perform the change.

In particular, do NOT use any of the following to edit files when `Edit` is available:

* `python` or `python3` scripts
* Node.js scripts
* Perl or Ruby scripts
* `sed -i`
* `awk`
* shell redirection such as `>`, `>>`, or heredocs
* shell pipelines that rewrite files
* ad-hoc scripts created solely to modify files

Use scripting for file modification only when the requested edit genuinely cannot be performed reasonably with the available dedicated editing tools, such as a necessary large-scale generated transformation.

Before falling back to a script or shell-based file modification, explicitly determine that `Edit` is unsuitable for the operation. Convenience, fewer tool calls, or implementation speed are not sufficient reasons to bypass `Edit`.

For ordinary single-file or multi-file code changes, use `Edit`.

## Subagents

Do NOT create, invoke, delegate to, or otherwise use subagents by default.

This is a hard prohibition.

Use a subagent only when one of the following explicitly instructs you to do so:

1. The user explicitly asks you to use a subagent or agents.
2. An active skill explicitly requires or instructs the use of a subagent.

Do not infer permission to use subagents merely because:

* the task is complex,
* work could be parallelized,
* multiple files are involved,
* additional research would be useful,
* delegation might be faster,
* the model believes a specialist agent would help.

If neither the user nor an active skill explicitly authorizes subagents, perform the work directly yourself.

## Code Comments

Do not add comments to code changes unless the user explicitly requests comments.

Do not add explanatory comments merely because code is complex or newly introduced.

## Writing Tests

If the project already has a testing practice, add as few tests as necessary to cover the important behavior affected by the change.

Prefer, in order when appropriate:

1. End-to-end tests
2. Integration or functional tests
3. Unit tests

Prefer a small number of high-value tests covering important paths over broad granular unit-test coverage.

Do not introduce a new testing framework solely for a small change unless explicitly requested or clearly required by the project.

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
