---
name: dev-workflow
description: Run the PR loop for a change from branch to merge. Build the step on its own branch and PR, review it with pr-reviewer-new in a context-free subagent, report the findings, apply the agreed fixes, wait for green CI, and merge with merge commits; stacked PRs merge one at a time. An evaluation round can follow. Use when the user asks to develop, review, fix, and merge a PR or a stack of PRs, or to "do the usual flow". It does not review code itself (use pr-reviewer-new) and does not answer human GitHub review comments (use address-review-gh).
---

# Development workflow

One loop per change: **build → PR → review → decide → fix → CI → merge**, and an **evaluation** when the project has one. Reply in the user's language, in simple words. Report each step in a line or two; do not narrate.

## 1. Build the step

- Use one branch and one PR per step. In a stack, each PR is reviewed on its own. It must hold its own contracts (validation, tests, docs, project conventions); never defer them to a later PR.
- Follow the project's `AGENTS.md`/`CLAUDE.md` for tests, docs and changelog.
- On a shared machine, run every build, test or program inside its own memory-capped scope: `systemd-run --user --scope -q -p MemoryMax=2G -p MemorySwapMax=0 -- <command>`. Without it, one out-of-memory kill stops the whole session scope, with every agent in it. Put the same rule in every subagent prompt.
- Subagents run tests in the foreground and never wait with `pgrep -f <command>` loops: CI runners on the same host run the same commands, so such a loop never ends. Before finishing, a subagent checks that it left no background process.
- Locally, run only the tests the change touches. Let CI run the full suite, unless the user asks for a local full run.
- Commit messages: a summary line, then short bullets. Never add attribution lines to commits or PR bodies.
- Open the PR with `gh pr create --base <base> --body-file <file>`. The body says what changed, why, and how it was checked.

## 2. Review with a context-free subagent

After pushing, start a general-purpose subagent with exactly this prompt and nothing more, so the review is not biased by your context:

```text
Invoke the `pr-reviewer-new` skill (via the Skill tool) and follow it to review GitHub pull request #N. Do not modify local files, switch branches, commit, push, run tests or programs, or post comments on GitHub. Return the full review report as your final answer.
```

- **Which reviewers, by PR kind:**
  - Trivial changes that cannot affect code, tests or the build (a one-line `.gitattributes` or repo-metadata tweak): no review and no CI wait; merge right away.
  - Docs-only or small PRs: only this peer review.
  - Large or risky code (a VM, a loader for untrusted input, security-sensitive code): run sequentially.
    1. First, in parallel, two critics that may build and run things in the scratchpad but never edit repo files: a **security critic** (memory safety, untrusted input, harnesses, sanitizers, fuzzing) and a **parity/simplicity critic** (differential checks against the reference, speed, KISS, test gaps).
    2. Wait for both, fix all agreed findings in one batch, then push.
    3. Then run this peer review on the fixed head, so it checks the final diff and the project rules.
- For several open PRs, start one subagent per PR.
- Do not read the subagent's transcript, and do not guess its result. Wait for the completion notice. If the user asks before it arrives, say it is still running.
- Meanwhile, do other work that does not touch the same files.

## 3. Report and decide

- Summarize the findings, most severe first: critical, major, then minor. Give each one in a line, with the failure it causes. Add CI status.
- Recommend what to fix and what to skip, with a reason, and ask. Fix right away only when the user already said which findings to fix (for example "fix the major and the minors you consider").
- If the review says the PR title or body no longer matches the change, treat it as a finding to fix.

## 4. Fix

- Apply the agreed fixes. Each behavior fix gets a test that would fail without it.
- Probe new diagnostics or behavior by hand once before writing the test.
- Update the docs the change touches.
- Run the touched tests, then commit and push to the same PR.
- Update the PR title and body when the scope grew: `gh pr edit N --title ... --body-file ...`.
- **Another review pass:** if the review found any critical or major issue, then after the fixes are pushed and CI is green, run the peer review again (same prompt, a new subagent) on the new head. Repeat until a pass finds only minor issues or none. When a pass finds only minors, fix them and go to merge without another review.

## 5. Wait for CI

- Never chain foreground `sleep`. Run a background until-loop and wait for its completion notice.
- Run the query once in the foreground first. A loop whose query always prints nothing never ends. If one hangs, stop it and check CI by hand.

```bash
sha=$(git rev-parse --short HEAD)
until s=$(gh run list --branch "$(git branch --show-current)" -L 10 \
      --json headSha,status,conclusion \
      -q "[.[] | select(.headSha|startswith(\"$sha\")) | .status + \":\" + .conclusion] | join(\",\")"); \
      [ -n "$s" ] && ! echo "$s" | grep -Eq "queued|in_progress|pending|waiting"; do sleep 30; done; echo "$s"
```

## 6. Merge

Merge only when **all** of these hold:

- the review ran, and the last pass found no critical or major issue;
- the agreed fixes are pushed;
- CI is green on the PR's head commit, including a docs-only commit added later;
- the user asked for the merge, or made it conditional ("merge if review and fixes are done") and the condition holds.

Use merge commits: `gh pr merge N --merge`. Then update the local base (`git checkout <base> && git pull`).

After every merge, check the other open PRs: `gh pr list --state open --json number,mergeable,mergeStateStatus`. A PR that now conflicts (`CONFLICTING` / `DIRTY`) gets no `pull_request` CI run at all, so merge the base into it right away (plain merge, keep both sides), push, and restart its CI wait. Run CI wait loops from the main checkout, never from a worktree that may be removed.

**Stacked PRs** merge bottom-up, one at a time:

1. Merge PR N.
2. Retarget the next PR: `gh pr edit N+1 --base <base>`.
3. On the next branch, run `git merge origin/<base>`. Resolve conflicts by keeping both sides' additions (changelog, docs, tests). Run the touched tests.
4. Push, wait for green CI, then merge it and repeat.

Do not merge the top of the stack, or a PR without a review, unless the user says so.

## 7. Evaluate (when the project has an evaluation)

- Run it after review and fixes, on the pushed head, so the numbers match what gets merged.
- For an A/B against the base, make a worktree of the base (`git worktree add ../<repo>-base <base>`) and run both arms in parallel. Do not switch the working checkout.
- Pass secrets only through the runner's option for that (for example `--pass-env NAME`). Never print them.
- Read failed or timed-out runs in the logs before blaming the change.
- Document the round in the same PR: the numbers, the comparison with the previous round, and what the noise allows to conclude. Then commit, push, wait for CI and merge per step 6.
