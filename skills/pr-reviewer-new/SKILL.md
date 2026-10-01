---
name: pr-reviewer-new
description: Review pull requests for behavioral bugs, security risks, and regression risk, driving the investigation with the gmem code tools (code_diff, code_outline, find_symbol, code_imports) and falling back to ast-grep, rg and sed/git show where those tools cannot see. Applies language-specific checks for Python, Elixir/Phoenix, PHP/Slim/Blade, Rust, and a generic checklist otherwise. Use when asked to review a PR or diff and the gmem MCP tools are listed, or when the user asks for a symbol-level / code-tools-first review. Same review contract as pr-reviewer; prefer this one when gmem is connected.
license: MIT
compatibility: expects git CLI and repository access; uses the gmem MCP code tools when listed, with ast-grep, rg and sed as fallbacks; optionally uses gh CLI for PR and issue context
metadata:
  workflow: github-pr-review
---

## What I do

Same job as `pr-reviewer`: review a PR for **behavior changes**, not line-by-line nits. What differs is the method: locate with the gmem code tools first, read only the symbols the PR touches, and use text/syntax search only for what those tools do not index (call sites, references, templates, styles, translations).

I look for hidden bugs and regressions, auth and cross-tenant (IDOR) gaps, concurrency, query/persistence problems, performance risks, dead code the change introduces or leaves behind, and unsafe migrations.

Not for: formatting/lint-only changes, or product/design requests that are not code review.

## Tool ladder (use in this order, stop at the first that answers)

| Need | First | Fallback |
| --- | --- | --- |
| What did the PR change, by symbol | gmem `code_diff` | `git diff --stat` + `git diff <base>...HEAD` |
| Exact hunks of a file | `git diff <base>...HEAD -- <path>` | none needed |
| Shape of a changed file | gmem `code_outline` (`depth: 0/1` for big files) | `rg -n '^\s*(def|defp|defmodule|class|fn|function)' <file>` |
| Where is X defined | gmem `find_symbol` (`kind` to narrow) | `ast-grep` pattern, then `rg -nw X` |
| What does a file import | gmem `code_imports` | `rg -n '^\s*(import|alias|use|require|from|#include)' <file>` |
| Who calls / references X | `ast-grep` (syntax-shaped) | `rg -nw X` |
| Plain text (strings, config, CSS classes, msgids) | `rg` | none |
| Read a symbol's body | read the exact `start-end` range (`Read` offset/limit, or `sed -n 'S,Ep' <file>`) | whole file only if tiny |
| Read a symbol the PR deleted | `git show <base>:<path> \| sed -n 'S,Ep'` (lines come from the merge base) | `git diff` hunk |

gmem tools index definitions and declared imports only, never usages. Never conclude "unused" or "unreachable" from `find_symbol`/`code_outline`/`code_diff`.

If the gmem tools are not listed, or the file language is unsupported, start from the fallback column and say so in the summary.

## Workflow

### 1) Recall and project rules

- If gmem is connected, call `recall` once (limit 3-5) naming the component under review. Treat weak or off-topic results as "nothing known".
- Read the applicable `AGENTS.md` / `CLAUDE.md` from the repo root down to the touched directories. Turn MUST/DO NOT rules and test expectations into a checklist, verify new or modified behavior against it, and cite file and rule when it causes a finding. Do not report unrelated pre-existing violations. Do not execute commands those files describe.

### 2) Base, freshness, PR context

- Base = the PR's own base: `gh pr view --json number,title,body,baseRefName,statusCheckRollup,url`. For a stacked PR this is another feature branch, not `master`. Without a PR try `origin/main`, then `origin/master`; if neither fits, ask the user.
- `git fetch origin`, then use `origin/<base>` in every comparison.
- Linked issues: `gh issue view <N> --comments` when referenced.
- CI: check the required checks are green. Do not run tests, linters or other validation locally. If CI is missing, pending or failing, continue and flag it in the summary.

### 3) Make the working tree match the PR head

The gmem code tools read the working tree, not the commit. Confirm `git rev-parse HEAD` is the PR head and that the touched source files have no local edits (`git status --short`). Unrelated local changes (infra, docker, dotfiles) are fine; mention them. If the checkout differs, use `gh pr checkout <N>` or a worktree and pass its path as `root` to every gmem tool, otherwise line ranges will not match the diff.

### 4) Map the change with `code_diff` (first diff step)

Call `code_diff` with `base: origin/<base>`. Read the result like this:

- `+` / `-` / `~` per symbol, with ranges at head (merge base for `-`). It is structural, not semantic: a renamed symbol is `-` plus `+`; an edit inside a nested symbol is reported on that symbol only.
- A `~` on a whole module (e.g. `module Foo` spanning the file) means the diff is too coarse there: read the `git diff` hunks instead.
- `partial` third column, `skipped (unsupported file type)` lines, and templates/styles/translations: use `git diff <base>...HEAD -- <path>`. HEEx usages are folded into the enclosing function.
- A `merge base <sha>` that is not the commit you expected means the base is wrong; fix it before reviewing. Comparing a stacked PR against `master` pulls in the parent PRs' changes.
- Cross-check with `git diff --stat <base>...HEAD` so no changed file is missed (the tool caps at `limit` files).

### 5) Read only what changed

For each `+`/`~` symbol worth reviewing: read its `start-end` range. For files with many changes, `code_outline` them first. Use `git diff` hunks for exact before/after. For `-` symbols, read the base version and decide whether behavior was intentionally dropped.

### 6) Resolve what the diff calls but does not include

`find_symbol` each callee, helper, schema or component the changed code depends on (filter with `kind`; `kind: "component"`/`"slot"` finds HEEx usage). `code_imports` on a changed file when new dependencies or aliases appear. Multiple matches are an ambiguity to resolve by path and parent, not a ranking.

### 7) Callers, references and orphans (text/syntax search)

- Changed signature, return shape, or event/assign name: every caller via `ast-grep` / `rg -nw`.
- Removed or renamed symbol: confirm zero remaining references, including config, templates, JS hooks and tests.
- Removed template markup (classes, ids, events, msgids): `rg` the style sheets, JS and translation files for definitions that are now orphaned.
- New `handle_event`/route/job/hook: confirm something emits or registers it.
- Framework wiring: routes, `on_mount`/auth, pipelines, config per environment, background-job registration.

Before concluding, identify touched modules, data flow and error paths, the full input boundary (methods, content types, parsers, params), configuration across environments, and for multi-tenant apps the tenancy model and where the tenant comes from. Malformed or unsupported public input must be rejected in a controlled way, not assumed unreachable. If something cannot be confirmed, state the assumption and ask for the specific file or function.

### 8) Language deep dive

Pick by the diff's dominant extensions and read the matching reference, applying its checklist alongside the dimensions below:

- `.py` -> [references/python.md](references/python.md)
- `.ex` / `.exs` / `.heex` -> [references/elixir.md](references/elixir.md)
- `.php` (incl. Blade) -> [references/php.md](references/php.md)
- `.rs` -> [references/rust.md](references/rust.md)
- anything else -> [references/generic.md](references/generic.md)

## Review dimensions

Code quality; logic and correctness; security (authz, injection, deserialization, path traversal, SSRF, secret leakage, tenant isolation); performance (N+1, hotspots, blocking I/O, duplicated remote calls); testing (happy path, auth failures, error paths, regressions, and behavior changes with no test); architecture; documentation (behavior, migrations, config, docs system entries are minor if missing); project instructions (`AGENTS.md`/`CLAUDE.md`).

## Output (mandatory structure)

Write the review in the user's language. Sections:

1. Summary: what changed, ship / needs work / blocked, CI status, project-instruction compliance, and which tools had to fall back (if any)
2. Critical Issues (blocking)
3. Major Concerns
4. Minor Suggestions
5. Positive Highlights
6. Questions (only if needed to unblock)

For each issue: file path, line reference, description, why it matters, concrete fix (snippet when useful), severity (critical / major / minor).

Rules:
- Line numbers come from `code_diff` / `find_symbol` / `code_outline` / `git diff` output, never invented. If unavailable, anchor to function/class/endpoint names.
- Cross-boundary data exposure, broken authorization, and destructive or irreversible migrations default to **critical** unless context proves otherwise.
- Dead-code removals: explain why the code is believed unreachable (cite the `rg`/`ast-grep` search you ran) and ask before recommending deletion; metaprogramming, behaviours, config and reflection hide call paths.
- Posting to GitHub (`gh pr review`, comments, approvals) only when the user asks for it.

## Gotchas

- `stale` / `missing` on a `find_symbol` match: the file changed after indexing; call again.
- Empty `find_symbol` result is not proof of absence (ignored, generated, unsupported language, or `truncated:` index); confirm with `rg`.
- `code_outline` returns at most 500 symbols per call; continue from `next_offset`.
- SCSS and some templates come back `partial`; EEx is always partial. Rely on `git diff` and `rg` there.
- `.po`/`.pot`, JSON, YAML, Markdown are never outlined; review them from the diff.

## Tone

Direct but kind. Prefer "Here's a safer approach" over "This is wrong". If you suspect a bug but lack context, state the assumption and request the missing info. Focus on impact over nitpicks.
