
## Code Search

Pick the tool by what you are looking for:

* Where a symbol is defined, or what a file contains: use the gmem `find_symbol` / `code_outline` tools when they are available, then read only the returned line range instead of the whole file. They index definitions only, never call sites or references. When they are listed, load the `graphmem:graphmem-code-analysis` skill before the first code lookup of the session.
* Call sites, usages, and syntax-shaped patterns (function calls, imports, JSX, decorators, AST structure): use `ast-grep`. If an `ast-grep-find` skill is available, load it first.
* Plain text (strings, comments, config, logs): use `rg`. Do not use `grep` when `rg` is available.

## Shell Commands

Do not prefix a command with a `cd` into the working directory when the shell is already there. The working directory persists between calls, so a redundant `cd` only adds noise and can trigger permission prompts. Use absolute paths where a path is needed instead.

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

"As few tests as necessary" never overrides the project's own testing rules (`AGENTS.md`), and never means skipping these:

* A public function that writes or deletes is a trust boundary, even when its only caller lives in a later PR of a stack. Validate its input in the function itself and cover each class of invalid input with a test that asserts the error tuple and that existing data is left untouched.
* When one function reads a shape and another writes the same shape, add a round-trip test: what the read returns can be written back unchanged.

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
