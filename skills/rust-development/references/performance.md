# Performance: Zero-Copy, Context Switches, and Measuring

On-demand reference for `rust-development`. Read this when the task touches a hot path,
memory use, buffers, serialization, thread counts, batching, or a "make it faster" request.
Style and idioms still come from `SKILL.md`; this file adds the performance mindset.

## Table of contents

- [Measure first](#measure-first)
- [Zero-copy](#zero-copy)
- [Context switching is the enemy](#context-switching-is-the-enemy)
- [Allocation](#allocation)
- [Data layout and cache locality](#data-layout-and-cache-locality)
- [I/O](#io)
- [Build profile](#build-profile)
- [When not to optimize](#when-not-to-optimize)

---

## Measure first

A performance change without a number is a guess. Before and after every change:

* Build in release (`cargo build --release`, `cargo test --release`). Debug-build timings
  are meaningless for optimization.
* Time the real workload, repeated, with a warm-up call excluded. Report a range when the
  machine is noisy (check `uptime` load average).
* Find the hot spot before touching code: `perf record -g` + `perf report`, `samply`,
  or `cargo flamegraph`. Without a profiler, bracket suspected sections with
  `Instant::now()` temporarily and remove the probes afterward.
* Measure memory too: peak (`VmHWM`) and steady (`VmRSS`) from `/proc/self/status`,
  `heaptrack`, or `dhat` for allocation counts.
* Compare against a reference implementation when one exists (for example the same model
  in another runtime) to know how far from the ceiling you are.
* Use `criterion` or `divan` for microbenchmarks, `hyperfine` for whole CLI commands.

Attribute honestly: if the time is spent inside a dependency (a BLAS, a runtime, a driver),
say so instead of rewriting your own code for no gain.

## Zero-copy

Zero-copy means the bytes are produced once and every later stage reads them in place
instead of duplicating them. Each copy costs memory bandwidth, cache space, and often an
allocation.

### Borrow through the pipeline

* Take `&str`/`&[u8]`/`&[T]` and return slices of the input with lifetimes when the output
  is a view of the input.
* Use `Cow<'a, str>` when a value is usually borrowed but sometimes has to be modified.
* Use `split_at`, `chunks`, `strip_prefix`, `split_once`, and slice ranges instead of
  `to_vec()`/`to_string()` on sub-parts.

```rust
fn header_value<'a>(line: &'a str, name: &str) -> Option<&'a str> {
    let (key, value) = line.split_once(':')?;
    key.trim().eq_ignore_ascii_case(name).then(|| value.trim())
}

fn normalize(input: &str) -> Cow<'_, str> {
    if input.contains('\t') {
        Cow::Owned(input.replace('\t', " "))
    } else {
        Cow::Borrowed(input)
    }
}
```

### Move instead of clone

* Consume with `into_iter()`, `into_inner()`, `drain(..)` when the source is no longer
  needed.
* Move out of `&mut` with `std::mem::take`/`replace`/`swap`.
* Freeze buffers that will not change: `Box<str>`, `Box<[T]>`, `Arc<str>`, `Arc<[T]>`
  instead of `Arc<String>`/`Arc<Vec<T>>`, which add a second indirection.

### Share instead of copy

* `Arc<T>` clones are a refcount bump, not a copy — but the bump is an atomic, so do not
  clone an `Arc` per item in a tight loop across threads.
* `bytes::Bytes`/`BytesMut` give cheap, sliceable, reference-counted buffers for network
  and parsing code: `buf.split_to(n).freeze()` hands out a frame without copying.

### Deserialize in place

* serde can borrow from the input buffer: `&'a str` fields, or `Cow<'a, str>` with
  `#[serde(borrow)]` so escaped strings fall back to owned.
* Keep the input buffer alive as long as the borrowed struct.

```rust
#[derive(Deserialize)]
struct Event<'a> {
    #[serde(borrow)]
    name: Cow<'a, str>,
    id: u64,
}

let event: Event<'_> = serde_json::from_slice(&buffer)?;
```

### Reinterpret bytes safely

* Use `bytemuck::try_cast_slice::<u8, f32>(bytes)` or `zerocopy` derives to view a byte
  buffer as typed data. They check size and alignment; `transmute` does not.
* Alignment is the usual failure: an mmap is page-aligned, but an offset into it may not
  be. Handle the error instead of assuming.

### Memory maps

* `memmap2::Mmap` avoids reading a file into a buffer up front, and the OS pages it in on
  demand and can share it between processes.
* Mapping is `unsafe` for a reason: another process truncating or writing the file
  underneath is undefined behavior or a `SIGBUS`. Document that invariant in the
  `// SAFETY:` comment.

### Verify the claim

Libraries advertise "zero-copy" or "mmap" loading that still copies. For example, an API
named `from_mmaped_safetensors` may mmap the file and then copy every tensor into owned
storage, or convert its dtype. Before claiming zero-copy:

* Read the dependency's source in `~/.cargo/registry/src/` along the path your data takes.
* Look for `to_vec`, `from_slice`, `collect`, `clone`, dtype conversion, or `Vec::from`.
* Confirm with memory numbers: a real zero-copy load does not double peak RSS.

When a copy is unavoidable, make it the cheapest one. Keep data in its native format
(e.g. a BF16 table stays BF16 and only looked-up rows are converted), and convert once
at load instead of on every call.

## Context switching is the enemy

Every time the CPU stops doing your work to do something else — switch threads, enter the
kernel, wait for a lock, wake a task, launch a GPU kernel — you pay the direct switch cost
plus cold caches afterward. Most "Rust is slow here" problems are too many switches, not
slow arithmetic.

### Threads: do not oversubscribe

* CPU-bound work should use about one thread per physical core, in one pool. Two pools
  that each size to all cores (Tokio workers + rayon + a BLAS/ML library's own threads)
  fight for the same cores and thrash caches.
* Small units of work do not parallelize: if each task is microseconds, the fork/join
  overhead dominates and 16 threads can be no faster than one. Measure with
  `RAYON_NUM_THREADS=1` against the default before assuming parallelism helps.
* Set pool sizes explicitly when several runtimes coexist (Tokio `worker_threads`,
  `rayon::ThreadPoolBuilder::num_threads`, library thread env vars).

### Batch across every boundary

A boundary crossing has a fixed cost. Pay it once per batch, not once per item:

* Channels: send `Vec<T>` chunks instead of one message per item.
* Databases: one transaction and a prepared statement for N rows, not N autocommits.
* Syscalls: buffered readers and writers, `write_all` of a built buffer, not per-byte
  writes.
* Locks: take the lock once, do the batch, release — not lock/unlock per element.
* GPU/accelerators: batch inputs into one kernel launch; per-item launches are
  latency-bound. On CPU, padding a batch can cost more than it saves — measure both.
* `spawn_blocking`/`rayon::spawn`: one task per batch, not per tiny item.

### Keep the critical section tiny

* Contended locks turn into futex syscalls and sleeping threads. Hold a lock only to read
  or swap state; do the work outside it.
* Prefer ownership by a single thread or task with a channel in front (an actor) over a
  widely shared `Arc<Mutex<_>>`.
* Use atomics for simple counters and flags; `Ordering::Relaxed` is enough for a
  standalone counter or a "something happened" flag.
* Shard hot shared maps (per-core or per-key-hash) when one lock is the bottleneck.

### Async is cheaper, not free

* A Tokio task switch is much cheaper than an OS thread switch, but each `.await` that
  actually suspends is still a switch. Avoid wrapping trivial synchronous work in tasks.
* Blocking inside a worker thread stalls every task on it; see
  `references/async-concurrency.md`.
* A CLI that does one thing at a time is often best on
  `#[tokio::main(flavor = "current_thread")]` — no cross-thread wakeups at all.

### The small-scale version: pointer chasing

A cache miss is a context switch in miniature: the CPU stalls waiting on memory.

* Prefer contiguous `Vec<T>` over `Vec<Box<T>>`, linked lists, or trees of `Rc`.
* Iterate data in memory order; avoid random access into large structures in hot loops.

## Allocation

* Reuse buffers across iterations: `clear()` keeps capacity.
* Pre-size with `with_capacity`/`reserve` when the size is known or bounded.
* Build strings with `write!` into one `String` (`use std::fmt::Write`) instead of
  `format!` + `push_str` per piece.
* Avoid `collect()` of an intermediate that is iterated once.
* `to_owned()` at the boundary where ownership is really needed, not at every layer.
* Consider `SmallVec`/`ArrayVec` or an arena (`bumpalo`) only after allocation shows up
  in a profile — they are extra dependencies.

```rust
let mut line = String::new();
while reader.read_line(&mut line)? != 0 {
    process(line.trim_end());
    line.clear();
}
```

## Data layout and cache locality

* Keep hot fields together and cold fields out of the hot struct (split, or `Box` the
  cold part).
* Box large, rare enum variants so the common variant does not pay for their size
  (Clippy's `large_enum_variant`).
* Struct-of-arrays beats array-of-structs when a loop touches one field of many records.
* `HashMap` uses SipHash by default to resist hash-flooding. Switch to `FxHashMap`/`ahash`
  only for trusted keys and only when hashing shows up in a profile.

## I/O

* Wrap `File`/`TcpStream` in `BufReader`/`BufWriter`; each unbuffered call is a syscall.
* Lock stdout once for bulk output; `println!` locks and may flush on every line.
* On Linux, `std::io::copy` between files, sockets, and pipes can use
  `copy_file_range`/`sendfile`/`splice`, moving bytes without passing them through user
  space.
* Read whole small files with `fs::read`/`fs::read_to_string`; stream large ones.
* Keep logs off the hot path: filter by level before formatting, and buffer.

```rust
let stdout = io::stdout();
let mut out = BufWriter::new(stdout.lock());
for row in &rows {
    writeln!(out, "{row}")?;
}
out.flush()?;
```

## Build profile

* `lto = "thin"` and `codegen-units = 1` in `[profile.release]` usually give a free 5–20%
  for binaries; measure compile-time cost.
* `panic = "abort"` shrinks binaries but disables unwinding (`catch_unwind`, panic
  recovery in threads). Use it only when nothing relies on unwinding.
* `-C target-cpu=native` only for binaries built and run on the same machine, never for
  distributed release artifacts.
* Accelerated math backends (MKL, Accelerate, CUDA) belong behind opt-in Cargo features
  so default builds and prebuilt binaries stay portable.

```toml
[profile.release]
lto = "thin"
codegen-units = 1
```

## When not to optimize

* Code that is not on a measured hot path: keep it simple.
* A 50 ms operation a human triggers once is not worth a new dependency or an `unsafe`
  block. The same operation run 100,000 times in a batch job may be.
* Lifetimes spread across a whole API to save one small copy — copying 64 bytes is often
  cheaper than the complexity and the refcount or borrow it replaces.
* A new runtime or backend dependency (a second inference engine, a custom allocator) when
  the gain is real but the portability, build, or binary-size cost is larger. State both
  sides with numbers and let the user decide.
