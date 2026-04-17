---
name: address-review
description: Fetch and address inline PR review comments on the current GitHub pull request by reading the affected files, applying targeted fixes, following project conventions, and summarizing resolved and unresolved items.
---

# Address PR Review Comments

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

## Discovering Project Patterns

Before applying fixes, look for project-specific conventions by:

* Checking available skills — a project may have a dedicated conventions or language-specific review skill
* Grepping the codebase for existing usage near the affected code

Prefer patterns already established in the project over inventing new ones.

## Guardrails

* Do not modify files that have no review comments unless necessary
* Do not invent fixes for ambiguous comments
* If a comment is unclear, apply only what is strongly supported by the surrounding code
* Prefer minimal diffs that are easy to review
