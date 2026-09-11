---
name: pr-reviewer
description: Review pull requests for behavioral bugs, security risks, and regression risk using git diff and optional gh PR context. Applies deep language-specific checks for Python and Elixir/Phoenix, and a generic checklist for any other language. Use whenever asked to review a PR or diff, even if the user just says "review this PR" or "look at this diff".
license: MIT
compatibility: expects git CLI and repository access; optionally uses gh CLI for PR and issue context
metadata:
  workflow: github-pr-review
---

## What I do

- Review pull requests with a focus on **behavior changes**, not just line-by-line diff comments
- Gather missing context (callers, routes/views, services, schemas, models, settings) to detect:
  - hidden bugs and regressions
  - auth/security gaps, including cross-tenant/cross-customer data access (IDOR)
  - concurrency issues
  - query/persistence issues (N+1, missing preloads/indexes, transaction consistency)
  - performance and memory risks
  - dead/unreachable code introduced or left behind by the change
  - unsafe or non-backward-compatible migrations
- Provide a **structured, actionable review** with concrete fixes and severity levels

## When to use me

Use this when you want a rigorous PR review, and you can share:
- the committed diff against the correct base branch, and ideally
- PR context (title/body/comments) via `gh` CLI.

Ask clarifying questions only when missing context blocks correctness/security conclusions.

## When not to use me

- Pure formatting/lint-only changes where no behavior changed
- Product/design requests that are not code-review tasks

## How I work

### 0) Review workflow (git / gh CLI) — do this before reviewing

1) Load project instructions
- Find and read the applicable `AGENTS.md` and `CLAUDE.md` files from the repository root through the directories containing touched files.
- Turn their MUST/DO NOT/testing/validation rules into a review checklist.
- Verify every newly introduced or modified behavior against that checklist; do not report unrelated pre-existing violations.
- Cite the instruction file and rule when it causes a finding.

2) Confirm the base branch  
Try `origin/main`, then `origin/master`. If neither resolves cleanly (e.g. the repo uses `develop` or a release branch), ask the user which base branch the PR targets before computing the diff — comparing against the wrong base produces misleading reviews.

3) Verify the base branch is up to date  
Ask the user to run:
- `git fetch origin`

4) Get the diff (committed changes only)  
Ask the user to share the diff against the confirmed base, e.g.:
- `git diff origin/main...HEAD` (substitute the real base branch)

5) Ignore unstaged/uncommitted files  
Only review committed changes shown by the diff above.

6) Extract PR information with `gh` CLI (optional, recommended)  
Ask for one of:
- `gh pr view`
- `gh pr view --comments`
- `gh pr view --json number,title,body,comments`

7) Extract linked issue information (optional)  
If referenced:
- Same repo: `gh issue view <NUMBER>`
- With comments: `gh issue view <NUMBER> --comments`
- JSON: `gh issue view <NUMBER> --json number,title,body,comments`

If repository access isn't available, explicitly list the exact files/commands needed and why.

### 1) Context-gathering playbook (MANDATORY)

Before writing conclusions, identify:
- touched modules (routes/views/controllers, services/contexts, schemas/models, settings/config, background jobs, middleware)
- call sites and data flow (who calls what, with what inputs, and error paths)
- framework wiring (routing/registration, dependency injection, middleware/auth setup, startup/shutdown hooks, task scheduler wiring)
- the full input boundary: methods, content types, parsers, headers, body shapes, path/query values, and the concrete values produced before changed code runs
- configuration across development, test, production, runtime config, environment variables, and container/deployment overrides
- for multi-tenant apps, the tenancy model (is data scoped per org/account/customer, and by what column/mechanism?) — this determines what "correct data access" even means

Do not dismiss malformed or unsupported public input as unreachable. Confirm it is rejected with a controlled response rather than crashing, being silently transformed, or reaching side effects.

If behavior cannot be confirmed due to missing context, state the assumption and request the specific file/function.

### 2) Language-specific deep dive

Detect the PR's primary language from the diff's file extensions, then read the matching reference and apply its checklist alongside the dimensions below:

- Primarily Python (`.py`) → read `references/python.md`
- Primarily Elixir/Phoenix (`.ex`, `.exs`, `.heex`) → read `references/elixir.md`
- Anything else → read `references/generic.md`

### 3) Review dimensions

- Code quality (readability, cohesion, low surprise behavior, explicit errors)
- Logic & correctness (edge cases, exception paths, state transitions, null/optional handling)
- Security (authz, injection, unsafe deserialization, path traversal, SSRF, secret leakage, multi-tenant data isolation)
- Performance (query efficiency, N+1, algorithmic hotspots, blocking I/O)
- Testing (coverage for happy path, auth failures, error paths, regressions)
- Architecture (separation of routing, business logic, persistence, side effects)
- Documentation (behavior changes, migrations, config/env updates, new features documented in the project's docs system, if one exists — flag as minor if a docs system exists but the new feature has no entry)
- Project instructions (new and modified code follows every applicable `AGENTS.md`/`CLAUDE.md` rule, especially required tests and validation commands)

### 4) Required output structure (MANDATORY)

I output the review as:

1) Summary (what changed + ship/needs work/blocked + project-instruction compliance)  
2) Critical Issues (blocking)  
3) Major Concerns  
4) Minor Suggestions  
5) Positive Highlights  
6) Questions (only if needed to unblock)

For **each issue**, include:
- file path
- line reference if available (or nearest function/class/endpoint)
- description
- why it matters (impact)
- suggested fix (concrete; snippets when helpful)
- severity: critical / major / minor

Rules:
- Do **not** invent line numbers
- If lines are unavailable, anchor to function/class/endpoint names
- Cross-boundary data exposure, broken authorization, and destructive/irreversible migrations default to **critical** unless context proves otherwise

## Tone rules

Be direct but kind. Prefer "Here's a safer approach" over "This is wrong".  
If you suspect a bug but lack context, state the assumption and request the missing info.  
Focus on impact over nitpicks. For dead-code removals in particular, explain *why* the code is believed unreachable and ask before recommending deletion, since hidden call paths (metaprogramming, behaviours/interfaces, config, reflection) are easy to miss.
