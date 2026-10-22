---
name: iterative-issue-planning
description: Turn a large change (stack or dependency upgrade, migration, refactor, pipeline or infra change) into a tracking GitHub issue that splits the work into small, independent, ordered PRs. Use when the user asks to plan, define an issue, or break down work iteratively into small deliverables. Does not implement the PRs and does not publish the issue without approval.
---

# Iterative issue planning

Produce one short issue whose checklist is a sequence of small PRs. Each PR leaves the repo green, is validated on its own, and can be reverted on its own.

## 1. Gather evidence before splitting

Do not split from intuition. Collect what makes the split real:

1. **Reference project.** If the user points to a project that already did this (e.g. a sibling repo), read its history (`git log --grep`, `git show --stat`) and note which commits did what, and what they had to fix afterwards (reverts, follow-up fixes).
2. **Current state.** List the exact files and lines that change here, with `path:line`.
3. **Trial run.** Apply the change in a scratch copy (`git archive HEAD | tar -x -C <scratch>`), never in the repo, and run build, tests, format and lint. Record each real breakage and its fix. Separate what breaks because of the change from what merely warns.
4. **Surprises.** Note anything that does not match the docs or the names (stale scripts, missing files referenced by deploy scripts, things only verifiable outside the repo).

## 2. Split into PRs

Rules, in priority order:

1. **Each PR is complete.** It carries its own tests, validation and project conventions; nothing is deferred to a later PR.
2. **Prep that works on the current versions goes first** (dependency bumps, warning fixes, test-library swaps). This makes the final change small.
3. **Decouple different kinds of change** (infra vs language, build pipeline vs runtime version) so a failure points at one cause.
4. **Atomic pairs stay together.** If two edits break each other when separated (e.g. a binary built for one OS plus the image it runs on), they are one PR.
5. **Remove the old flow only after the new one exists**, so it stays as a fallback.
6. **The riskiest change goes last and is versions-only**, so it is trivial to revert.

Mark which PRs are independent (can be reviewed in parallel) and which depend on others.

## 3. Write the issue

English, short, simple, precise. Use exactly these sections; drop any that is empty.

```markdown
<one sentence: goal and reference project/PRs>

## Findings
- <breakage or surprise found in the trial run, with path:line>

## Plan
- [ ] 1. <what it does> (<why / what it enables>)
- [ ] 2. ...

<one or two lines: which PRs are independent, which depend on which, which must stay together and why>

## To verify before <step N>
- <fact only the user can check, or that needs access we lack>

Out of scope: <items explicitly excluded>
```

Checklist items must say what the change is and why. "Prep" or "cleanup" alone is not an item: write "Update deps X, Y and fix 2 warnings, still on current versions, so step 6 is a versions-only change".

## 4. Respect scope the user sets

- If the user says something is out of scope (e.g. no deploy in this issue), remove it from the plan and move it to "Out of scope". Do not name deploys as validation; validate by CI or review instead.
- Put facts you could not verify under "To verify", never in Findings.

## 5. Publish only with approval

Creating or editing an issue is visible to the team.

1. Show the draft in the conversation and ask for approval.
2. Check the current body first (`gh issue view <n> --json title,body`); do not overwrite non-empty content without saying so.
3. Write the body to a scratch file and publish with `gh issue edit <n> --body-file <file>` (or `gh issue create --body-file`). Re-read it afterwards.
4. Ask whether PR descriptions should start with `closes <issue url>`, and whether non-final PRs should use `refs #<n>` instead so the first merge does not close the issue. Apply the answer to every PR. Do not add the line unless the user wants it.

## 6. Executing the plan

Work one PR at a time on its own branch. Stop after each PR is ready locally and ask before committing or pushing. Use the project's own test and lint commands as the PR's validation.
