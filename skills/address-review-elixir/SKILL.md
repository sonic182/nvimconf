---
name: address-review-elixir
description: Fetch and address inline PR review comments on the current GitHub pull request in Elixir/Phoenix projects by reading the affected files, applying targeted fixes following Elixir and project conventions, and summarizing resolved and unresolved items.
---

# Address PR Review Comments (Elixir/Phoenix)

Fetch all inline comments from the current PR, inspect the affected files, and apply each fix carefully and minimally.

## Goal

Resolve actionable inline PR review comments while preserving existing behavior, following project conventions, and avoiding unrelated changes.

## Steps

### 1. Identify the current PR

```bash
gh pr view --json number,headRefName
````

### 2. Fetch all inline review comments

```bash
PR=$(gh pr view --json number --jq .number)
REPO=$(gh repo view --json nameWithOwner --jq .nameWithOwner)
gh api "repos/$REPO/pulls/$PR/comments" \
  --jq '[.[] | {path: .path, line: .line, body: .body}]'
```

### 3. Filter and group comments

Collect all inline comments, ignore comments that are clearly outdated or no longer applicable, then group the remaining comments by file path.

For each affected file:

* Read the full file
* Inspect the area around each referenced line
* Apply all relevant fixes in that file together when possible

### 4. Apply each fix

For each comment:

1. Read the file and surrounding context
2. Understand the reviewer's intent, not just the literal wording
3. Apply the smallest correct change
4. Follow the project's UI and code conventions (check if any available skills cover the relevant conventions for this project)
5. Do not refactor unrelated code unless required to address the comment
6. Preserve existing behavior unless the review explicitly asks for a behavior change

### 5. Validate changes

After editing:

* Re-read the updated sections
* Check for consistency with nearby code
* Ensure imports, aliases, and component usage still make sense
* Run a lightweight project validation step if it is cheap and obvious

### 6. Report results

Summarize:

* Which files were modified
* What was changed in each file
* Which comments were addressed
* Any comments that could not be resolved automatically because they require product or human judgment

## Common Fix Patterns

Based on recurring review findings in Elixir/Phoenix projects:

* **Inline `style=`** → Replace with the project's CSS utility classes
* **Raw `<button>`** → Replace with the project's button component (e.g. a custom `<UI.button>`)
* **Raw JS modal dispatch** → Replace with the project's modal helper (e.g. `Modal.show("id")` / `Modal.hide("id")`)
* **Unused event attributes** → Remove attributes that have no handler wired up
* **Missing component alias** → Add the missing alias to the LiveView's alias block
* **`Jason` for simple encode/decode** → If the project has standardized on Elixir 1.18+, prefer the built-in `JSON` module for plain encode/decode; keep `Jason` where custom encoder protocols are needed
* **Hardcoded hex in SCSS** → Replace with the project's color utility function (check project conventions)

## Guardrails

* Do not modify files that have no review comments unless necessary
* Do not invent fixes for ambiguous comments
* If a comment is unclear, apply only what is strongly supported by the surrounding code
* Prefer minimal diffs that are easy to review
