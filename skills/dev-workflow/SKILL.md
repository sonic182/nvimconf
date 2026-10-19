---
name: dev-workflow
description: Run the pull-request loop for a code change in any repository and language, from branch to merge. Build the change on its own branch, open a PR or merge request, get an independent review, fix the findings, repeat until only minor issues remain, wait for green CI, and merge; stacked PRs merge one at a time. Use when the user asks to develop, review, fix and merge a change or a stack of changes, or to "do the usual flow". It does not review code itself and does not answer human review comments.
---

# Development workflow

One loop per change: **build → PR → review → fix → CI → merge**. Report each
step to the user in a line or two, in their language.

Project rules win. Before the first step, read the repository's agent and
contributor instructions (`AGENTS.md`, `CLAUDE.md`, `CONTRIBUTING.md`, a
project dev-workflow skill) and its CI config. Take the build, test, lint and
merge commands from there, not from habit.

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
  (`gh pr create --base <base> --body-file <file>`; on GitLab, `glab mr
  create`).

## 2. Review

Get a review that is not biased by your own context: a fresh agent, given
only the PR number and the read-only rules. With the `pr-reviewer-new` skill
available, use exactly this prompt:

```text
Invoke the `pr-reviewer-new` skill (via the Skill tool) and follow it to review pull request #N in the repository at <path>. Do not modify local files, switch branches, commit, push, run tests or programs, or post comments. Return the full review report as your final answer.
```

Without it, ask for the same output: findings ranked critical, major and
minor, each with a location and the concrete failure it causes.

Size the review to the risk:

- **Trivial** (metadata, a typo; cannot affect code, tests or the build):
  no review, merge.
- **Docs-only or small code:** one review.
- **Large or risky** (concurrency, a runtime, untrusted input, auth, crypto,
  data migrations): first two critics in parallel, which may build and run
  things in a scratch worktree but never edit the branch:
  - a **security and correctness critic**: untrusted input, races, resource
    lifetimes, memory safety where the language allows bugs there, and the
    project's sanitizers or fuzzers when it has them;
  - a **speed and simplicity critic**: speed A/B against the base when the
    change can affect speed, duplication, needless complexity, test gaps,
    docs that overclaim.
  Fix their findings in one batch, then run the normal review on the fixed
  head. Point each critic at the project's own review guidance when there is
  one.

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

## 4. Wait for CI

Never chain foreground sleeps. Run one background loop on the head commit and
wait for its notice. Run its query once in the foreground first: a query that
always prints nothing makes the loop run forever.

```bash
sha=$(git rev-parse --short HEAD)
until s=$(gh run list --branch "$(git branch --show-current)" -L 10 \
      --json headSha,status,conclusion \
      -q "[.[] | select(.headSha|startswith(\"$sha\")) | .status + \":\" + .conclusion] | join(\",\")"); \
      [ -n "$s" ] && ! echo "$s" | grep -Eq "queued|in_progress|pending|waiting"; do sleep 30; done; echo "$s"
```

Read a failure in its log before blaming the change; rerun a known flaky job
once (`gh run rerun ID --failed`) and say so.

## 5. Merge

Merge only when all hold: the last review found no critical or major issue,
the fixes are pushed, CI is green on the head commit, and the user asked for
the merge (or made it conditional and the condition holds).

- Use the project's merge method; without one, a merge commit (`gh pr merge N
  --merge`).
- Then check the other open PRs: one that now conflicts gets no CI run, so
  merge the base into it, push, and wait for CI again.
- **Stacks** merge bottom-up: merge PR N, retarget N+1 to the base, merge the
  base into its branch, push, wait for CI, merge, repeat.
- Clean up: remove the worktree and delete the branch (local and remote) once
  it is merged and has no unpushed commits.

## Gotchas

- On a shared machine, cap the memory of builds and tests (on Linux with
  systemd: `systemd-run --user --scope -q -p MemoryMax=4G -p MemorySwapMax=0
  -- <cmd>`); one out-of-memory kill can end the whole session. Repeat the
  rule in every agent prompt.
- Never wait with `pgrep -f <cmd>` loops: another agent or a self-hosted CI
  runner may run the same command, and the loop never ends. Agents leave no
  background process behind.
- Run CI wait loops from the main checkout, not from a worktree you are about
  to remove.
- Branch protection may require checks that run even on docs-only PRs; a merge
  refused as "not mergeable" usually means checks are still pending.
- Keep review decisions consistent across passes, or the next pass re-raises
  findings you already decided to skip; list skipped items in the PR body.
