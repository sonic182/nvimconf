---
name: dev-workflow
description: Run the pull-request loop for a code change in any repository, language and forge (GitHub, GitLab or similar), from branch to merge. Build the change on its own branch, open a PR or merge request, get it reviewed by a fresh agent running the `pr-reviewer-new` skill, fix the findings, repeat until only minor issues remain, wait for green CI, and merge once the user confirms; stacked PRs merge one at a time. Use when the user asks to develop, review, fix and merge a change or a stack of changes, or to "do the usual flow". It does not review code itself and does not answer human review comments.
---

# Development workflow

One loop per change: **build → PR → review → fix → CI → merge**. Report each
step to the user in a line or two, in their language.

Project rules win. Before the first step, read the repository's agent and
contributor instructions (`AGENTS.md`, `CLAUDE.md`, `CONTRIBUTING.md`, a
project workflow skill) and its CI config. Take the build, test, lint, branch
and merge conventions from there, not from habit. Use the forge's CLI (`gh`
on GitHub, `glab` on GitLab); the commands below use `gh` as the example.

## 1. Build

- One branch and one PR per change. In a stack, each PR holds its own
  contracts (validation, tests, docs, changelog); never defer them to a later
  PR.
- Prefer a separate worktree per branch (`git worktree add ../<repo>-<topic>
  -b <branch> origin/<base>`), so parallel work never touches the user's
  checkout.
- Run locally only the checks the change touches; let CI run the full suite
  unless the user asks otherwise.
- A behavior fix gets a test that fails without it. Prefer few high-value
  tests over many small ones.
- Commit messages: a summary line, then short bullets. Never add attribution
  lines. Never rebase or force-push a branch under review; merge the base in.
- Open the PR with a body that says what changed, why, and how it was checked
  (`gh pr create --base <base> --body-file <file>`).

## 2. Review

Skip the review only for trivial changes that cannot affect code, tests or the
build (metadata, a typo). Every other change gets one review per pass, from a
fresh agent that has none of your context, with exactly this prompt:

```text
Invoke the `pr-reviewer-new` skill (via the Skill tool) and follow it to review pull request <id> in the repository at <path>. Do not modify local files, switch branches, commit, push, run tests or programs, or post comments. Return the full review report as your final answer.
```

If `pr-reviewer-new` is not available, tell the user and stop; do not
substitute another reviewer.

Wait for the reviewer's completion notice; do not read its transcript or
guess its result. Meanwhile do other work that does not touch the same files.

## 3. Fix and repeat

- Do not ask which findings to fix: fix every critical and major, plus the
  minors worth it, and say which minors you skip and why. Ask only when the
  user said to for this PR.
- A review that says the PR title or body no longer matches the change is a
  finding too.
- After a pass with any critical or major finding: push the fixes, wait for
  green CI, and run a new review (a new agent) on the new head.
- When a pass finds only minors: fix them and go to merge, no new review.
- **Stop after the third pass.** If the third review still finds a critical
  or major issue, stop. Report the three passes to the user and decide the
  approach together before more work on that PR.
- List skipped findings in the PR body, so the next pass does not re-raise
  them.

## 4. Wait for CI

Never chain foreground sleeps. Run one background loop that polls the checks
of the head commit until none is pending, and wait for its notice. Run its
query once in the foreground first: a query that always prints nothing makes
the loop run forever. On GitHub:

```bash
sha=$(git rev-parse --short HEAD)
until s=$(gh run list --branch "$(git branch --show-current)" -L 10 \
      --json headSha,status,conclusion \
      -q "[.[] | select(.headSha|startswith(\"$sha\")) | .status + \":\" + .conclusion] | join(\",\")"); \
      [ -n "$s" ] && ! echo "$s" | grep -Eq "queued|in_progress|pending|waiting"; do sleep 30; done; echo "$s"
```

Read a failure in its log before blaming the change; rerun a known flaky job
once and say so.

## 5. Merge

A PR is ready when the last review found no critical or major issue, the
fixes are pushed, and CI is green on the head commit.

Once it is ready, always stop and ask the user whether to merge it or to
request human reviewers first, and whom. Never merge on your own; an earlier
merge approval does not carry over to this PR. If they choose reviewers, add
them (`gh pr edit <id> --add-reviewer <login>`) and stop: the loop ends there.

- Use the project's merge method; without one, a merge commit.
- Then check the other open PRs: one that now conflicts gets no CI run, so
  merge the base into it, push, and wait for CI again.
- **Stacks** merge bottom-up: merge PR N, retarget N+1 to the base, merge the
  base into its branch, push, wait for CI, ask, merge, repeat.
- Clean up: remove the worktree and delete the branch (local and remote) once
  it is merged and has no unpushed commits.

## Gotchas

- On a shared machine, cap the memory of builds and tests (on Linux with
  systemd: `systemd-run --user --scope -q -p MemoryMax=4G -p MemorySwapMax=0
  -- <cmd>`); one out-of-memory kill can end the whole session.
- Never wait with `pgrep -f <cmd>` loops: another agent or a self-hosted CI
  runner may run the same command, and the loop never ends. Agents leave no
  background process behind.
- Run CI wait loops from the main checkout, not from a worktree you are about
  to remove.
- Branch protection may require checks that run even on docs-only PRs; a merge
  refused as "not mergeable" usually means checks are still pending.
