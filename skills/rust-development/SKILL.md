---
name: rust-development
description: |
    Expert Rust assistant for writing, reviewing, debugging, optimizing, and refactoring idiomatic Rust (edition 2021/2024) code. Use whenever the user asks to create, modify, review, explain, speed up, or test Rust code, including crates, modules, traits, error types, async/Tokio code, CLI tools, unsafe/FFI, Cargo features, and tests. Enforces project-local conventions, rustfmt, Clippy, the Rust API Guidelines, and a performance mindset built on zero-copy data flow and avoiding context switches. Performance and async/concurrency detail live in references/ (loaded on demand).

    Use for: any new or modified Rust code, Cargo.toml changes, trait/type design, error handling, async code, performance work, unsafe review, tests, and docs.
    Do not use for: non-Rust code, or pure architecture discussion with no Rust code.
---

# Rust Development

Use this skill for any task that introduces, changes, reviews, debugs, optimizes, or
refactors Rust code.

This file holds the rules that apply to every Rust task. Everything else is loaded on
demand — read a reference only when its trigger below is true, and read only that one.

| Read | When the task touches |
| --- | --- |
| `references/performance.md` | hot paths, zero-copy, allocation, buffers, serialization, mmap, thread counts, batching, profiling, release profiles, or any "make it faster / use less memory" request |
| `references/async-concurrency.md` | `async`/`.await`, Tokio, threads, rayon, locks, channels, `Send`/`Sync`, cancellation, or blocking work inside a runtime |

Official docs:

* The Rust API Guidelines: https://rust-lang.github.io/api-guidelines/
* The Rust Book: https://doc.rust-lang.org/book/
* Rust Reference: https://doc.rust-lang.org/reference/
* Clippy lints: https://rust-lang.github.io/rust-clippy/master/
* The Rust Performance Book: https://nnethercote.github.io/perf-book/
* The Rustonomicon (unsafe): https://doc.rust-lang.org/nomicon/
* Rust Style Guide (rustfmt): https://doc.rust-lang.org/style-guide/
* Tokio tutorial: https://tokio.rs/tokio/tutorial

## Operating Principles

Write Rust that is correct, simple, readable, and already close to `rustfmt` and Clippy.

Prefer:

* Project-local conventions over generic style advice.
* Types that make invalid states unrepresentable over runtime checks.
* `Result` for expected failure, panics only for broken invariants.
* Borrowing over cloning, moving over copying, and one pass over data over several.
* Plain functions, structs, and enums over traits and generics until a second real
  implementation exists.
* Measured optimizations over guessed ones.

Avoid:

* `unwrap()`/`expect()` on anything reachable from external input.
* `.clone()` used to silence the borrow checker instead of fixing ownership.
* Traits, generics, builders, or feature flags built before a caller needs them.
* `unsafe` where a safe API exists.
* Oversubscribed threads, locks held across `.await`, and per-item round trips.
* Style churn unrelated to the user's request.

## Rule Priority

When rules conflict, apply this priority:

1. User request and correctness (including soundness).
2. Existing public API compatibility, unless the user asks for a redesign.
3. Project-local conventions:

   * `rustfmt.toml`, `clippy.toml`, `[lints]` in `Cargo.toml`
   * `AGENTS.md`/`CLAUDE.md`/`CONTRIBUTING.md` layering rules
   * existing module layout, error types, and test patterns
   * existing dependency choices and feature flags
   * a `justfile`/`Makefile`/`xtask` gate
4. The Rust API Guidelines, std conventions, and Clippy defaults.
5. The Rust Performance Book and Tokio docs when applicable.
6. This skill's house rules.

When applying a house rule, do not present it as official Rust guidance.

## Idiomatic Enforcement Protocol

When writing code:

0. If the gmem MCP server is connected, `recall` once on the crate, module, or type being touched, before reading code. Project conventions and prior decisions that the source does not state live there.
1. Inspect nearby project code and `Cargo.toml` (edition, MSRV, features, lints).
2. Preserve the existing architecture unless it is clearly broken or the user asks to change it.
3. Generate code that should pass `cargo fmt --check` and `cargo clippy -- -D warnings`.
4. Prefer narrow visibility (`pub(crate)`, private) and explicit, small APIs.
5. Include tests when behavior changes or new behavior is introduced.
6. Before claiming a dependency does something (zero-copy, lock-free, async-safe), read its source in `~/.cargo/registry/src/` — names and docs overstate.
7. Explain non-obvious idiomatic choices briefly.

When reviewing code, report findings in this order:

1. Correctness and soundness bugs (UB, data races, panics on reachable input).
2. Security or data-loss risks.
3. Concurrency, async, and resource risks (blocking the runtime, deadlocks, leaks).
4. Performance problems on a real hot path.
5. Non-idiomatic Rust.
6. Maintainability and readability.
7. Formatting and tooling.

For each issue, include:

* The problem.
* Why it matters.
* A concrete fix or replacement snippet when practical.

## Formatting

Use the project `rustfmt.toml` as the source of truth. Do not fight formatter output.

Generate code that should pass `cargo fmt --check` before formatting:

* 4-space indentation, 100-column max width (rustfmt default).
* Trailing commas in multiline lists, struct literals, and match arms with blocks.
* Imports grouped `std`, external crates, then `crate`/`super`, merged per crate
  (`use std::{fs, io};`).
* One blank line between items; no blank line directly after an opening brace.
* Prefer early returns and `let ... else` over deep nesting.

```rust
use std::{fs, io, path::Path};

use serde::Deserialize;

use crate::config::Config;

fn load(path: &Path) -> io::Result<Config> {
    let Ok(raw) = fs::read_to_string(path) else {
        return Ok(Config::default());
    };
    toml::from_str(&raw).map_err(io::Error::other)
}
```

## Naming

Follow RFC 430 and the API Guidelines naming rules (C-CASE, C-CONV, C-GETTER, C-ITER).

Use:

* Types, traits, enum variants: `UpperCamelCase`. Acronyms count as one word: `Uuid`,
  `HttpClient`, `SqliteStore` — not `UUID`, `HTTPClient`.
* Functions, methods, modules, locals, fields: `snake_case`.
* Constants and statics: `SCREAMING_SNAKE_CASE`.
* Lifetimes: short lowercase (`'a`), or descriptive when several interact (`'de`, `'buf`).
* Conversions: `as_*` (free, borrowed → borrowed), `to_*` (expensive or owned result),
  `into_*` (consumes `self`).
* Getters: the field name, no `get_` prefix (`fn len(&self)`, `fn name(&self) -> &str`).
* Iterators: `iter()`, `iter_mut()`, `into_iter()`; iterator types named after the method
  (`Iter`, `IntoIter`).
* Predicates: `is_*`, `has_*`, `can_*`.
* Constructors: `new`, `with_capacity`, `from_*`, `open`/`connect` for I/O.
* Error types: `Error` inside a module (`config::Error`) or `*Error` at crate level.

```rust
struct HttpClient;                       // good — acronym as one word
fn as_bytes(&self) -> &[u8]              // good — free borrow
fn to_vec(&self) -> Vec<u8>              // good — allocates
fn into_inner(self) -> T                 // good — consumes

struct HTTPClient;                       // bad — acronym uppercase
fn get_name(&self) -> &str               // bad — get_ prefix
fn to_inner(self) -> T                   // bad — consuming conversion is into_
```

## Types and Ownership

* Accept borrowed, return owned: `&str`, `&[T]`, `&Path` in parameters; `String`,
  `Vec<T>`, `PathBuf` in returns. Use `impl AsRef<Path>` only on public ergonomic APIs.
* Take ownership (`T`, `impl Into<String>`) only when the function stores the value.
* Model domain values with newtypes (`struct MemoryId(i64)`) instead of bare primitives.
* Replace boolean parameters with an enum when the call site would read `f(true, false)`.
* Use `Option<T>` instead of sentinel values (`-1`, `""`, `0`).
* Use `std::mem::take`/`replace` to move out of `&mut` instead of cloning.
* Derive what the type honestly supports (`Debug` almost always; `Clone`, `Copy`,
  `PartialEq`, `Eq`, `Hash`, `Default` when meaningful). `Copy` only for small plain data.
* Mark constructors and pure functions whose result must be used with `#[must_use]`
  when ignoring it is a likely bug.
* Keep fields private and expose methods when an invariant must hold.

```rust
// good — the type enforces non-empty; no runtime check at each use
pub struct Query(String);

impl Query {
    pub fn new(raw: &str) -> Option<Self> {
        let trimmed = raw.trim();
        (!trimmed.is_empty()).then(|| Self(trimmed.to_owned()))
    }

    pub fn as_str(&self) -> &str {
        &self.0
    }
}

// bad — every caller must remember the rule
fn search(query: String, include_global: bool, limit: i32) { ... }
```

## Error Handling

* Libraries and layered apps: typed errors with `thiserror`, one enum per boundary, variants
  that carry the context needed to debug (which id, which path).
* Binaries at the top level: `anyhow::Result` with `.context(...)` is fine; do not leak
  `anyhow` through a library API.
* Propagate with `?`; convert with `#[from]` or `map_err` at the boundary that knows
  what failed.
* Error `Display` messages are lowercase with no trailing punctuation (C-GOOD-ERR).
* `unwrap()` only in tests and examples. `expect("reason")` only where the invariant is
  enforced nearby and the message states it.
* Never `let _ = fallible();` on a result that can lose data; handle or log it.
* Document failure modes in `# Errors` and `# Panics` doc sections on public functions.

```rust
#[derive(Debug, thiserror::Error)]
pub enum StoreError {
    #[error("memory {id} not found")]
    NotFound { id: i64 },
    #[error("database error: {0}")]
    Sqlite(#[from] rusqlite::Error),
}

// good — expected miss is a value, not a panic
pub fn fetch(conn: &Connection, id: i64) -> Result<Memory, StoreError> {
    conn.query_row(SELECT_MEMORY, [id], Memory::from_row)
        .optional()?
        .ok_or(StoreError::NotFound { id })
}

// bad — panics on a missing row that external input can request
pub fn fetch(conn: &Connection, id: i64) -> Memory {
    conn.query_row(SELECT_MEMORY, [id], Memory::from_row).unwrap()
}
```

Collect fallible iterators directly instead of looping and pushing:

```rust
let vectors = texts
    .iter()
    .map(|text| embed(text))
    .collect::<Result<Vec<_>, _>>()?;
```

## Traits and Generics

* Do not introduce a trait for a single implementation. Add it when a second real
  implementation or a genuine test boundary exists; until then an enum matched at one
  construction point is usually enough.
* Implement std traits instead of ad-hoc methods: `From`/`TryFrom`, `FromStr`, `Display`,
  `Error`, `Default`, `AsRef`, `IntoIterator`.
* Generics (static dispatch) for hot, monomorphic code; `dyn Trait` for heterogeneous
  collections, plugin points, or to cut compile time and binary size.
* Use `impl Trait` in argument position for simple one-off bounds; name the generic when
  the bound is reused or needs `where` clarity.
* Keep trait bounds on `impl` blocks and functions, not on struct definitions.
* Seal traits that downstream crates must not implement.

## Iterators and Collections

* Prefer iterator chains for map/filter/fold transformations; use a `for` loop when the
  body has side effects, early returns, or several `?`.
* Do not `collect()` just to iterate again; chain instead.
* Pick the collection by access pattern: `Vec` by default, `HashMap`/`HashSet` for keyed
  lookup, `BTreeMap` when ordering matters, `VecDeque` for queues. A linear scan over a
  small `Vec` often beats a map.
* Pre-size with `Vec::with_capacity`/`String::with_capacity` when the size is known.
* Use `chunks`, `windows`, `split_at`, and slices instead of copying sub-vectors.
* Use `entry()` instead of `contains_key` + `insert`.
* Use `retain`, `drain`, `extend`, `dedup` instead of rebuilding a collection.

```rust
// good
*counts.entry(word).or_insert(0) += 1;
let active: Vec<_> = users.iter().filter(|user| user.active).map(|user| &user.name).collect();

// bad — double lookup, and a clone per element
if !counts.contains_key(&word) {
    counts.insert(word.clone(), 0);
}
let active: Vec<String> = users.iter().filter(|u| u.active).map(|u| u.name.clone()).collect();
```

## Modules and Visibility

* One concept per module; split a file when it has two reasons to change.
* Default to private; widen to `pub(crate)` before `pub`. Every `pub` item is API.
* Keep `main.rs` a thin composition root; put logic in `lib.rs` modules so integration
  tests can reach it.
* Respect the project's layering (e.g. domain free of I/O crates, adapters in
  `infrastructure/`). Do not import a transport or database type into domain code.
* Re-export deliberately (`pub use`) at the crate root for the public API; avoid glob
  re-exports.

## Unsafe

* Use `unsafe` only when no safe API achieves the goal at acceptable cost.
* Keep each `unsafe` block minimal and wrap it in a safe function that upholds the
  invariant for every caller.
* Every `unsafe` block carries a `// SAFETY:` comment stating the invariant and why it
  holds here. This is the one comment Rust convention requires.
* Every `unsafe fn` documents its contract in a `# Safety` doc section.
* Edition 2024: operations inside `unsafe fn` still need an `unsafe {}` block
  (`unsafe_op_in_unsafe_fn`), and `std::env::set_var`/`remove_var` are `unsafe`.
* Prefer `bytemuck`/`zerocopy` over `transmute` for reinterpreting bytes.
* Run `cargo +nightly miri test` on code with non-trivial `unsafe` when available.

```rust
// SAFETY: the file is opened read-only and the store never truncates it while mapped.
let map = unsafe { Mmap::map(&file)? };
```

## Testing

* Unit tests in `#[cfg(test)] mod tests` next to pure logic; integration tests in `tests/`
  for anything that crosses I/O, CLI, or process boundaries.
* Prefer integration tests through the real public API over mocking internals. Fake only
  at a true external boundary (network, clock, model download).
* Name tests by behavior: `rejects_empty_query`, `reembed_skips_current_rows`.
* Use `#[ignore = "reason"]` for slow or network tests instead of deleting them.
* Use temp directories (`tempfile`) and never touch the developer's real data paths.
* Doc examples are tests; keep them compiling (`cargo test --doc`).
* Follow the project's runner (`cargo nextest`, `just test`) when one exists.

```rust
#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn rejects_blank_query() {
        assert!(Query::new("   ").is_none());
    }
}
```

## Docs

* `///` on every public item; `//!` for crate and module overviews.
* First line: a one-sentence summary. Then what a caller needs, then stop.
* Use `# Errors`, `# Panics`, `# Safety`, and `# Examples` sections when they apply.
* Link types with intra-doc links (``[`Embedder`]``).

## Comments

Prefer readable code over explanatory comments.

Use comments for:

* Non-obvious domain rules.
* External constraints (a library bug, a protocol requirement).
* Intentional tradeoffs.
* `// SAFETY:` on every `unsafe` block.

Rules:

* Put comments above the code they describe, with one space after `//`.
* Use uppercase annotations: `TODO:`, `FIXME:`, `HACK:`, `SAFETY:`.
* Do not leave commented-out code.

### Length

One line. A second only when the rule genuinely does not fit in one. Never a paragraph.

* State the constraint, drop the narrative. The reader needs the rule that binds the code,
  not how it was discovered.
* Cut the defence of the choice. Why an alternative was rejected belongs in the commit
  message or the PR, where it is read once — not above the line, where it drifts.
* Name the mechanism once. Do not restate it in the doc comment and an inline comment.

```rust
// Candle's ModernBERT hardcodes GELU; this checkpoint uses SiLU.
let activation = config.hidden_activation;
```

## Anti-Patterns to Flag

* `unwrap()`/`expect()`/indexing (`v[i]`, `map[&k]`) on values derived from external input.
* `.clone()` to satisfy the borrow checker on a hot path.
* `String`/`Vec<T>` parameters where `&str`/`&[T]` would do.
* `Rc<RefCell<_>>` or `Arc<Mutex<_>>` standing in for an ownership design.
* A `std::sync::Mutex` guard held across `.await`, or blocking I/O inside `async fn`.
* Spawned tasks whose `JoinHandle` is dropped, silently losing panics and errors.
* `_ => {}` match arms that swallow new enum variants.
* `as` casts that can truncate or change sign on real input; use `try_from`.
* Integer arithmetic on unbounded input without `checked_*`/`saturating_*`.
* A trait, generic, or builder with a single use.
* Returning `Box<dyn Error>` from a library API.
* `format!` in a loop to build one string; `println!` in a hot loop.

Also flag, as house rules:

* Public surface with no caller in the change that introduces it: a `pub` item, a Cargo
  feature, a config key, or an enum variant added because it might be useful.
* The same invariant enforced twice in two places. One of the two will drift.
* A performance claim ("zero-copy", "lock-free", "faster") without a measurement or a
  read of the dependency's source.

## Verification

When project files are available and commands are allowed, prefer this gate:

```sh
cargo fmt --all -- --check
cargo clippy --all-targets --all-features -- -D warnings
cargo test --all-targets         # or: cargo nextest run
cargo test --doc
cargo doc --no-deps              # when public docs changed
```

Adapt the gate to the project:

* If a `justfile`/`Makefile`/`xtask` wraps these, run the project's recipe instead
  (e.g. `just verify`).
* Scope to the package (`-p crate`) in large workspaces while iterating.
* Run `cargo deny check`/`cargo audit` only when configured.
* Run Miri only for `unsafe` changes and when nightly is installed.
* Feature-gated code (`cuda`, `mkl`) needs a build with that feature; say so if skipped.
* Do not invent tooling setup unless the user asks.

When commands cannot be run, provide the commands the user should run and clearly label the
review as static.

## Output Style

When generating or refactoring code:

* Return the final code first when the user asks for code.
* Explain only the important choices after the code.
* Keep explanations specific to the code, not generic Rust lectures.
* Mention any assumptions, and state measured numbers for performance claims.

When reviewing code:

* Prioritize actionable findings.
* Avoid noisy style nitpicks unless the user asks for a strict style review.
* Include replacement snippets for high-value changes.
* Distinguish official guidance from project or house style.
