# Test-pruning campaign

Campaign mode prunes one subsystem's whole test surface in one PR: an app,
package, context, or adapter area. The value bar, retention bar, candidate evidence, and
validation in `SKILL.md` apply to every lane. This file adds the
order of work. Each step ends on its completion criterion; do not start the
next step early.

## 1. Baseline

Record the subsystem's test and support line counts and every test file's
pass/fail state at a pinned main SHA. Run the subsystem's scoped suite (its
test directory or tag, per the language reference), not the whole project
suite. Keep baseline failures in their own list; they are often real bugs, not
stale tests.

Done when every in-scope test file has a recorded baseline result.

## 2. Lanes and inventory

Split the surface into **lanes** along production owner boundaries, not file
prefixes (e.g. domain/context, adapters/IO, persistence, web/UI, jobs and
processes, shared helpers, test harness, e2e scenarios). Include the subsystem's cases
at shared core boundaries and its e2e/live harness tests.

Done when every test file and scenario the subsystem owns belongs to exactly
one lane.

## 3. Read-only ledger per lane

Give each lane to its own read-only agent. It reads every assigned test in
full, including parameter tables, plus the production owners, entry points,
callers, history, and CI config. Each test declaration goes into a written
**ledger** with one mark. A parametrized test is one declaration unless its
rows need different marks; then mark each row.

- `R`: retain, naming the contract and the bug it catches; a move to a
  better-named file stays `R` with the move noted;
- `F`: retain the contract but fix the assertion (e.g. a vacuous negative that
  passes when only one of several items is missing);
- `C`: consolidate, naming the owner that absorbs the assertion: a sibling
  table case, a stronger boundary suite, or a shared owner elsewhere;
- `D`: delete, naming the proof that remains, or why no contract exists.

Judge a test by its assertions, not its name.

Done when every declaration in the lane has a mark and an evidence line.

## 4. Layer plan per lane

Treat the ledger as input, not the edit list. A second read-only pass looks for
the redundant **layer**: e.g. several suites replaying the same shared helper
through one mock, around stronger real-boundary suites. Name the **keeper**
suite for each contract. Prefer the real transport boundary with a fake network
over a mocked collaborator. Correct ledger errors this pass finds.

Done when each lane plan names its retired files, keeper per contract,
assertions to carry into keepers, and test-only production seams unlocked.

## 5. Cutover

Edit lane by lane. Serialize changes to shared harnesses and support files
through one owner. With each lane, remove the test-only production seams it
unlocks: injection parameters, getters, reset exports, indirection layers.
Register moved suites in CI config and test inventories. Put durable
test-ownership rules in the subsystem's `AGENTS.md`/`CLAUDE.md`, drawn from
mistakes this campaign actually found.

Done when every lane plan is applied and each lane's keepers pass.

## 6. Preservation review

Before claiming completion, have independent reviewers compare deleted coverage
against the keepers, one reviewer per boundary group. They look for contracts
that lost their only proof, and for new assertions that cannot fail (e.g. a
rejection row production never reaches).

For each restored contract, make one deliberate **mutation** of the production
owner and confirm the keeper goes red. Then restore the source byte for byte.

Done when every reported gap is restored or rejected with source evidence, and
every restored contract has a caught mutation.

## 7. Product defects

A baseline failure that survives into a keeper is a bug report. Fix it at its
owner as a separate commit, and prove it through the real user flow with a
**control** run that reverts the fix and shows the old behavior. Record
unrelated discrepancies as follow-ups instead of fixing them in the campaign.

Done when each repaired defect has a failing control and a passing candidate
on the same harness.

## 8. Reconcile and hand off

Campaigns outlive many main commits. Merge main rather than rebasing a long
campaign. When main modified a file the campaign deleted, keep the deletion,
port the new contract into the keeper, and confirm every new regression main
added still has a home. Rerun the whole subsystem suite on the merged head.

Hand off with the `SKILL.md` report, plus:

- baseline and final test/support line counts, production counted separately;
- lanes, retired layers, and keepers;
- preservation gaps found and their mutations;
- product defects with control and candidate proof.
