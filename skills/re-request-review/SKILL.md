---
name: re-request-review
description: After pushing fixes for addressed PR review comments, reply to each reviewer thread with a minimal one-line acknowledgement, resolve the threads whose fix is pushed, and re-request review from the reviewers whose latest verdict is still changes-requested, skipping anyone who has since approved. Use once fixes for review comments are already committed and pushed.
---

# Re-request Review

Reply to inline review comments and re-request review, after `address-review-gh` (or
equivalent manual fixes) has already been committed and pushed.

## Goal

Close the loop with reviewers: one short reply per addressed comment thread, resolve the
threads a pushed fix answers, then ping the right people to look again. Do not re-explain the fix — the diff already shows it.

## Steps

### 1. Identify the current PR

```bash
gh pr view --json number,headRefName
```

### 2. Fetch inline comments, grouped by thread

```bash
PR=$(gh pr view --json number --jq .number)
REPO=$(gh repo view --json nameWithOwner --jq .nameWithOwner)
gh api --paginate "repos/$REPO/pulls/$PR/comments" \
  --jq '.[] | {id: .id, path: .path, line: .line, body: .body, in_reply_to_id: .in_reply_to_id, user: .user.login}'
```

A **thread** is a top-level comment (`in_reply_to_id: null`) plus any replies chained to it via
`in_reply_to_id`. Group by the top-level comment's `id`.

### 3. Reply only to threads that still need a reply

Skip a thread if:
- it's already been replied to (an entry with `in_reply_to_id` equal to the top-level `id`
  already exists, e.g. from the PR author)
- it was clearly resolved by discussion alone, with no code change needed

For every remaining thread whose fix has actually been committed and pushed, post one reply:

```bash
gh api "repos/$REPO/pulls/$PR/comments" -X POST \
  -f body="ok, <what changed>, in last commit" \
  -F in_reply_to="<top-level comment id>"
```

**Reply style — keep it as short as the reviewer comment was long:**
- One line. No re-statement of the problem, no justification, no "thanks for catching this."
- Say what changed, not why it was wrong — the reviewer already knows why.
- Reference where: `in last commit`, or `in commit <short-hash>` when replying to several
  threads fixed across different commits (so it's unambiguous which one to look at).
- Good: `ok, test enhanced in last commit`, `ok, wording improved in commit a1b2c3d`,
  `done, added a guard clause`, `fixed, now returns {:error, reason}`.
- Bad: anything with more than ~10 words, a bullet list, a code block, or a recap of the
  original comment.
- If a comment is **not** being addressed (disagreement, out of scope, needs more discussion),
  say so in one line too (e.g. `not doing this here, follow-up in DFXXX`) — do not silently
  skip it.

### 4. Resolve the threads a pushed fix answers

Resolve every unresolved thread whose reply (yours from step 3, or an earlier one) points at a
fix that is committed and pushed. Leave open any thread answered with disagreement, a
follow-up, a question, or anything else the reviewer still has to weigh in on.

Thread ids come from GraphQL; match a thread to its top-level comment by `databaseId`:

```bash
gh api graphql -F owner="${REPO%/*}" -F name="${REPO#*/}" -F pr="$PR" -f query='
query($owner: String!, $name: String!, $pr: Int!) {
  repository(owner: $owner, name: $name) {
    pullRequest(number: $pr) {
      reviewThreads(first: 100) {
        nodes { id isResolved comments(first: 1) { nodes { databaseId } } }
      }
    }
  }
}' --jq '.data.repository.pullRequest.reviewThreads.nodes[]
  | select(.isResolved | not) | {thread: .id, comment: .comments.nodes[0].databaseId}'

gh api graphql -f id="<thread id>" -f query='
mutation($id: ID!) { resolveReviewThread(input: {threadId: $id}) { thread { isResolved } } }'
```

### 5. Re-request review

Find who is *currently* blocking, which is each reviewer's **latest** verdict — not everyone
who ever requested changes. A reviewer who requested changes and has since approved is done
with this PR, and re-requesting drops that approval and puts the review back on them:

```bash
gh pr view --json reviews --jq '
  [.reviews[] | select(.state == "APPROVED" or .state == "CHANGES_REQUESTED")]
  | group_by(.author.login)
  | map(max_by(.submittedAt) | select(.state == "CHANGES_REQUESTED") | .author.login)
'
```

`COMMENTED` and `DISMISSED` reviews drop out before the grouping because neither carries a
verdict — a comment left after an approval must not turn that reviewer back into a blocker.

Re-request from exactly those reviewers (not everyone who ever commented):

```bash
gh api "repos/$REPO/pulls/$PR/requested_reviewers" -X POST \
  -f "reviewers[]=<login-1>" -f "reviewers[]=<login-2>"
```

If the PR shows the reviewer already back in the "requested" state (check
`gh pr view --json reviewRequests`), this step is already done — skip it.

### 6. Report results

One or two lines: which threads got a reply, which were resolved, which reviewer(s) were
re-requested. No essay.

## Guardrails

- Never reply to a thread whose fix isn't actually pushed yet — verify with `git log`/`git diff`
  against the PR's base first.
- Never bulk-reply the same canned message to every thread — read each comment, each reply is
  specific to what changed for that one.
- Never resolve a thread whose fix isn't pushed, or one answered with anything other than a
  fix — that stays open for the reviewer.
- Do not re-request a reviewer who only left informational comments and never requested
  changes.
- Do not re-request a reviewer whose latest verdict is `APPROVED`, even if they requested
  changes earlier in the PR — their approval is the current state and re-requesting undoes it.
  They still get a reply on any thread of theirs you fixed.
