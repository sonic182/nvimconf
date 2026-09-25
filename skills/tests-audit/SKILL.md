---
name: tests-audit
description: "Invoke whenever writing, changing, reviewing, or sweeping tests (pytest, ExUnit, Vitest/Jest, Playwright). Authoring gate for new tests plus audit workflow for low-value, implementation-coupled, duplicative, or over-mocked tests and the test-only production seams they demand. Use for test cleanup, pruning, redundant or brittle tests, regression-test design, and deciding whether a test is worth keeping."
---

# Tests Audit

Three modes, one value bar. **Authoring** gates every new or changed test at
write time. **Audit** runs focused sweeps for tests that re-assert source,
duplicate stronger proof, couple to implementation, or keep test-only
production seams alive. **Campaign** prunes one whole subsystem's test surface;
read [references/campaign.md](references/campaign.md) before starting one.
Optimize for confidence, not deletion count.

This file is language-neutral. Read only the references for the languages the
tests in scope are written in; a mixed-stack change (e.g. Phoenix with JS
hooks) reads each one it touches.

| Read | When the tests in scope are |
| --- | --- |
| `references/python.md` | pytest / `*.py` |
| `references/elixir.md` | ExUnit / `*.exs` |
| `references/frontend.md` | JS/TS unit or component tests, or browser e2e |
| `references/campaign.md` | any language, campaign mode only |

This skill judges whether a test earns its keep, not how it is styled; for
naming, fixture layout, and idiom, follow the project's existing tests.

## Gotchas

- Judge a test by its assertions, not its name. A test named "rejects expired
  token" may only assert that a function was called.
- Coverage proves a line ran, not that anything asserts on it. Only a
  mutation of the production line that turns the keeper red proves the
  keeper guards it.
- A suite that stays green after a deletion proves nothing about the deleted
  contract; the deleted test may have been its only assertion.
- A mock with no interface spec accepts any call, so assertions against it,
  especially negative ones, can pass when the real API changed.
- A retained test failing on baseline is more often a product bug than a stale
  test. Reproduce it before touching the test.

## Authoring gate

Before adding a test, answer all four; a missing answer means do not add it yet:

1. What observable behavior, invariant, or independent contract does it protect?
2. What credible regression makes it fail?
3. Why does existing coverage not already catch it? Each contract has one
   primary owner test at the strongest boundary; another layer needs its own
   distinct risk (e.g. a transport or lifecycle failure the owner cannot reach).
   Prefer extending a table-driven case or shared fixture over a near-duplicate;
   consolidate duplicated setup in the same change.
4. Does it need a production seam (export, flag, wrapper, injection hook) no
   production caller needs? If yes, test at the real boundary instead.

Then check it against every [junk pattern](#junk-patterns); a match fails the
gate unless the [retention bar](#retention-bar) names the contract it
independently guards. A test that breaks under behavior-preserving refactoring
asserts implementation, not behavior; rewrite it at the owning boundary.

Bug regression tests must fail on the pre-fix code for the intended reason and
pass after the fix. A regression test that never demonstrably failed proves the
mock, not the fix. One regression at the owner boundary covers the bug; do not
replay it at every layer it crosses.

## Junk patterns

Shared checklist: authoring rejects new tests that match; audits hunt existing
ones. Each language reference shows how these patterns look in its tooling.

- assertion-free coverage probes;
- self-comparisons and identity copiers;
- copied fixtures, inventories, manifests, or export lists;
- exact source, import, or string greps;
- private predicate or call-shape tests duplicated at real boundaries;
- duplicate invocations of the same contract;
- per-adapter/per-provider replays of a shared helper's tests;
- tests whose only purpose is preserving test-only exports, globals, or wrappers;
- dead production code whose only callers are tests;
- expected values produced by the helper or renderer under test;
- mocks that implement the asserted behavior, or one identical mock standing in
  for different APIs;
- fixtures that supply the result, ordering, or callback the code under test
  should produce, or persistence asserted against a store the path never writes;
- capability tests that restate declared flags instead of exercising what the
  flag promises;
- negative controls that pass for an unrelated reason (a different guard
  rejects, or the production path never reaches that rejection);
- names or fixtures that promise more than the input exercises.

## Value bar

Tests justify their maintenance cost by protecting behavior, a credible
regression, or an independently meaningful contract. In an audit, an existing
test that must change for behavior-preserving refactoring is suspect, not
automatically deletable.

Before judging a candidate, read the complete test and its production owner,
entry point, callers, callees, sibling implementations, overlapping tests, CI
config, and relevant git history. Read project `AGENTS.md`/`CLAUDE.md` first.
When a test claims dependency-backed behavior, inspect the dependency source or
types directly.

## Audit workflow

Copy this checklist and tick it as you go:

```
- [ ] Read AGENTS.md/CLAUDE.md and the language reference
- [ ] Discovery (read-only): candidates, each naming its junk pattern
- [ ] Candidate evidence recorded, all fields, per candidate
- [ ] Evidence reported to the user before any edit
- [ ] One coherent owner-boundary batch edited
- [ ] Validation steps 1-6 pass
- [ ] Handoff report written
```

## Discovery

Keep discovery read-only and report evidence before editing. For broad scope,
split into parallel lanes along production owner boundaries (domain/context,
adapters/IO, web/UI, jobs/processes, tooling) plus one cross-cutting
junk-pattern sweep. Start from the discovery recipes in the language reference:
`ast-grep` for syntax-shaped patterns, `rg` for text. Outside
campaign mode, prefer a few high-confidence candidates over a large speculative
inventory.

## Retention bar

Keep a test when it independently enforces a public API, protocol, config,
migration, storage, security, platform, default-value, serialization/byte-level,
package, release, or architecture contract. Also keep:

- call ordering when order is observable behavior;
- regressions with a credible failure mode;
- source inspection when it is the cheapest independent guard: it fails when
  the contract changes (the user-facing key, byte, or path) and survives an
  identifier-only refactor;
- a retained test that fails on baseline: treat it as a possible product bug,
  reproduce it, and fix the owner rather than deleting the test.

Static or slow is not a deletion reason. A test that resembles implementation
may still be the independent contract; prove otherwise before removing it.

## Candidate evidence

Record every field before editing; a missing field means not ready to delete:

- exact test name and location;
- what failure it can actually detect;
- non-test callers of the covered production or support seam;
- stronger remaining owner-boundary proof, or why no proof is needed;
- relevant history and why the test or seam exists;
- production or test-support deletion unlocked;
- risk and the focused validation command.

## Edit shape

Pick one coherent owner-boundary batch. Delete obsolete test-only exports,
globals, wrappers, and dead production paths instead of keeping aliases. Move
retained regressions to their canonical owners. Consolidate repeated
package/dependency assertions into one generic contract.

Prefer net-negative production LOC. Do not add replacement tests that restate
the same implementation, and do not turn uncertain candidates into cleanup to
inflate deletion counts.

## Validation

Do not edit while a test watcher is running on the checkout. Follow the
project's test policy in `AGENTS.md`/`CLAUDE.md`: many projects say to run only
the touched test files and leave the full suite to CI; respect that.

1. Run the smallest owner and sibling tests with the focused command from the
   language reference.
2. When a deletion relies on "still covered elsewhere", mutate the production
   line the deleted test guarded and confirm the keeper goes red, then restore
   the source byte for byte. Use the reference's coverage command only to find
   which lines to mutate.
3. For removed source greps or plan assertions, run the script or dry-run that
   owns the real contract.
4. Run the formatter, linter, and compile/type gate from the reference, then
   `git diff --check`.
5. Inspect `git diff --numstat`; report production/tooling separately from
   tests and test support.
6. Reread the full diff for deleted assertions without a named keeper, and
   for new assertions that cannot fail.

## Landing

Commit, push, or open a PR only when authorized. Land one coherent PR at a
time; after landing, refresh from main and rerun read-only discovery for the
next batch.

## Handoff

Use this template, dropping empty sections:

```markdown
## Tests audit: <scope>

**Removed**: <count> tests: <junk-pattern categories, one line each with an example>
**Production simplified**: <seams/dead paths deleted, file:line>
**Kept on purpose**: <candidate → contract it guards>
**Proof run**: <exact commands and results; mutations that went red>
**LOC**: production <+/->, tests/support <+/->
**State**: <uncommitted | branch | PR link>
**Follow-ups**: <next batch or suspected product bugs>
```
