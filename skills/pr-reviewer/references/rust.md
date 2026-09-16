On-demand reference for `pr-reviewer`. Read this when the PR is primarily Rust.

### Context-gathering expansions

- Error handling & boundaries:
  - error types (`thiserror`/`anyhow`/custom enums) and whether `?` propagation preserves enough context to debug a failure (which record/request/id, not just "it failed")
  - every `unwrap()`/`expect()`/`panic!()`/array-or-map indexing (`v[i]`, `map[&k]`) outside tests — is the panic actually impossible, or reachable from untrusted/external input or concurrent mutation?
- Unsafe & FFI:
  - every `unsafe` block: does it carry a `// SAFETY:` comment stating the invariant it relies on, and is that invariant actually true at the call site (not just asserted)?
  - raw pointers, `transmute`, `mem::uninitialized`/`MaybeUninit`, FFI signatures matching the C ABI they bind
- Concurrency:
  - shared mutable state (`Arc<Mutex<_>>`/`RwLock`), lock scope and ordering (deadlock risk from inconsistent lock order across two call sites)
  - a `MutexGuard`/lock held across an `.await` point (blocks the executor, can deadlock the runtime)
  - `unsafe impl Send`/`unsafe impl Sync` and whether the type actually upholds those guarantees
- Async:
  - blocking calls (`std::fs`, `std::thread::sleep`, CPU-bound loops, blocking DB drivers) inside an `async fn` without `spawn_blocking`/an async-native equivalent
  - cancellation safety: what partial side effects already happened if this future is dropped mid-`.await`?
  - spawned tasks (`tokio::spawn`) whose `JoinHandle` is dropped — a panic or error inside is silently lost unless joined or the result is checked
- Data/persistence (when the project touches a DB via `rusqlite`/`sqlx`/`diesel`):
  - migration safety for rolling deploys: destructive/irreversible changes, `NOT NULL` on existing tables, FK cascade behavior
  - transaction boundaries around multi-step writes; whether a loop of individual writes should instead be one transaction (or, if not, whether that's a deliberate choice worth calling out)
  - schema/table access patterns matching the project's own scoping model (multi-tenant scoping, cascade deletes, provenance tables)
- Dependencies/build:
  - new crate additions: maintenance status, `unsafe` usage inside the crate itself, MSRV/edition impact
  - `Cargo.lock` present/consistent with `Cargo.toml`; feature flag changes and their effect on downstream consumers
  - visibility changes (`pub`/`pub(crate)`) that widen the crate's public API surface, and whether that widening is actually required by the change

### Review dimensions add-ons

- Panic-safety (does normal, even malformed, input reach a panic path instead of a `Result`?)
- API surface discipline (is a type/field `pub` because something outside the crate needs it, or just because it was convenient?)
- Partial-failure/resource-state honesty (does a mid-operation failure leave the store/filesystem/lock in an inconsistent state, and is that acknowledged — either handled or explicitly out of scope?)

### Rust-specific review checklist

- Error handling:
  - does `?` propagation lose context that later blocks debugging (which id/record/request failed)?
  - is a loop's `?` on each iteration turning "process N items" into "abort entirely on the first bad one," where a partial-failure/continue-and-report design would better serve the feature's actual goal (e.g. a batch/migration command)?
  - are errors matched exhaustively, or is a `_ => {}` arm silently swallowing a case that should be handled?
- Panics & indexing:
  - `unwrap()`/`expect()`/direct indexing on anything derived from external input, another process's concurrent writes, or a value whose invariant isn't actually enforced by the type system (a comment claiming an invariant holds is not the same as the type system enforcing it)
  - integer arithmetic that can overflow on attacker-influenced or unbounded input — `checked_*`/`saturating_*`/`wrapping_*` used deliberately, not left to default (panics in debug, silently wraps in release)
- Unsafe:
  - each `unsafe` block reviewed for actual soundness, not just the presence of a comment
  - could the same result be achieved with a safe API instead (a crate feature, a different data structure)?
- Concurrency & async:
  - lock held across `.await`, or across a call that can itself block
  - shared-state mutation correctness under concurrent access assumed by the code — does a single-process/CLI-style code path assume no concurrent writer, and is that assumption actually true in production?
  - spawned task failures observed somewhere, not silently dropped
- Ownership & API design:
  - unnecessary `.clone()` on a hot path where a reference or `Cow` would do
  - `Rc<RefCell<_>>`/interior mutability substituting for a design that could enforce the invariant at compile time
  - public types/fields that don't need to be public, widening the crate's compatibility surface
- Architecture:
  - business logic separated from I/O/transport, matching the project's own layering conventions when documented (e.g. a domain/application/infrastructure/CLI split) — flag new logic that bypasses an existing service/application layer to talk to storage or a transport type directly
  - new trait/port/generic introduced for a single implementation — flag as premature abstraction unless a second real implementation or a genuine test seam requires it
- Migration/schema safety (when applicable):
  - backward-compatible for rolling deploys, or intentionally not with that called out
  - destructive changes (dropped/renamed columns/tables) sequenced across releases, not same-PR as code that still depends on them
- Testing:
  - integration tests for CLI/service-boundary behavior, unit tests for pure/domain logic — matches the common Rust-project convention of thin unit-test surface plus real integration coverage
  - a fix's regression test actually exercises the failure path the fix addresses, not just the happy path

Documentation:
- if new user-facing behavior (CLI commands, config keys, public API) was added, is it reflected in the project's docs (README, `docs/`, doc comments feeding `cargo doc`)?
- if a docs system is present but the new feature has no entry, flag it as a minor issue.

Use relevant CI results for formatting, lint, build, test, and dependency/supply-chain checks; do not run those commands locally.
