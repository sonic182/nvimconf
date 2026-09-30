# Async and Concurrency

On-demand reference for `rust-development`. Read this when the task touches `async`/`.await`,
Tokio, threads, rayon, locks, channels, `Send`/`Sync`, cancellation, or blocking work inside a
runtime. The performance reasoning behind these rules lives in `references/performance.md`
("Context switching is the enemy").

## Table of contents

- [Pick the execution model](#pick-the-execution-model)
- [Never block the runtime](#never-block-the-runtime)
- [Locks](#locks)
- [Channels and backpressure](#channels-and-backpressure)
- [Spawned tasks](#spawned-tasks)
- [Cancellation](#cancellation)
- [Send and Sync](#send-and-sync)
- [Shutdown](#shutdown)

---

## Pick the execution model

| Work | Use |
| --- | --- |
| Many concurrent I/O waits (sockets, HTTP, stdio protocols) | async on Tokio |
| CPU-bound data parallelism | `rayon` or scoped threads (`std::thread::scope`) |
| A few long-lived background loops | plain threads with channels |
| Blocking calls inside an async app (sync DB driver, file I/O, heavy CPU) | `spawn_blocking` or a dedicated pool |
| A CLI doing one thing at a time | synchronous code, or `current_thread` Tokio if a dependency is async |

Do not make code `async` just because the binary has a runtime. A synchronous function called
from async code is fine as long as it is fast.

Size the runtime deliberately: Tokio's multi-thread default is one worker per core, and it
does not know about rayon or a library's own threads (see `performance.md`, oversubscription).

```rust
let runtime = tokio::runtime::Builder::new_multi_thread()
    .worker_threads(config.worker_threads)
    .enable_all()
    .build()?;
```

## Never block the runtime

A worker thread that blocks stalls every task scheduled on it. Blocking includes:

* `std::fs`, `std::net`, sync database drivers (`rusqlite`), `std::thread::sleep`.
* CPU work longer than roughly 10–100 µs between `.await` points (hashing, parsing a large
  document, model inference).
* Waiting on a `std::sync::Mutex`, `Condvar`, or a sync channel `recv()`.

Move it off the workers:

```rust
let rows = tokio::task::spawn_blocking(move || store.load_all(&scope)).await??;
```

* `spawn_blocking` runs on a separate pool that grows up to 512 threads by default.
  Flooding it with tiny jobs creates hundreds of threads — batch instead.
* For heavy CPU work, prefer rayon and bridge the result back with a oneshot:

```rust
let (tx, rx) = tokio::sync::oneshot::channel();
rayon::spawn(move || {
    let _ = tx.send(embed_batch(&texts));
});
let vectors = rx.await??;
```

* Use `tokio::fs`/`tokio::time::sleep` for occasional async I/O. `tokio::fs` itself uses
  `spawn_blocking` internally, so for bulk file work one `spawn_blocking` around the whole
  sync operation is cheaper.

## Locks

* Default to `std::sync::Mutex` for short critical sections, even in async code. It is
  faster than `tokio::sync::Mutex` when the guard never crosses an `.await`.
* Use `tokio::sync::Mutex` only when the guard must be held across `.await`, and treat
  that as a design smell to revisit.
* Never hold a `std::sync::MutexGuard` across `.await`. The guard is `!Send`, so a spawned
  future holding it fails to compile on the multi-thread runtime — do not work around that
  error, restructure.
* Scope the guard so it drops before the await:

```rust
let snapshot = {
    let state = shared.lock().expect("state lock poisoned");
    state.pending.clone()
};
send_all(snapshot).await?;
```

* Acquire multiple locks in one consistent order everywhere, or you will deadlock.
* `RwLock` helps only with many readers, rare writers, and non-trivial read sections. For
  tiny sections, a `Mutex` is faster.
* Lock poisoning: `lock().expect("... poisoned")` is acceptable when a panic while holding
  the lock already means the process is broken. Otherwise recover with
  `into_inner()` on the error.
* Prefer an owning task plus a channel (actor) over shared state touched from many places.

## Channels and backpressure

* Use bounded channels by default (`tokio::sync::mpsc::channel(n)`). An unbounded channel
  turns a slow consumer into unbounded memory growth.
* Pick the channel for the context: `tokio::sync::mpsc` between async tasks,
  `std::sync::mpsc` or `crossbeam-channel` between threads, `oneshot` for one reply,
  `watch` for latest-value broadcast, `broadcast` for fan-out.
* Send batches, not single items, when throughput matters.
* Handle a closed channel (`send` returning `Err`) as the peer having shut down — usually
  stop the loop, do not panic.

## Spawned tasks

* A dropped `JoinHandle` detaches the task: its panic or error is lost. Await the handle,
  or collect tasks in a `JoinSet` and drain it.
* `JoinHandle::await` returns `Result<T, JoinError>`; a `JoinError` means the task panicked
  or was cancelled. Propagate or log it.
* Do not spawn per item for trivial work; a loop inside one task is cheaper.

```rust
let mut tasks = tokio::task::JoinSet::new();
for scope in scopes {
    let service = service.clone();
    tasks.spawn(async move { service.reembed(&scope).await });
}
while let Some(result) = tasks.join_next().await {
    result??;
}
```

## Cancellation

* Any `.await` is a point where the future can be dropped (by `select!`, a timeout, or a
  client disconnect). Ask what side effects already happened by then.
* Keep multi-step writes atomic (one DB transaction, write-to-temp-then-rename) so
  cancellation mid-way leaves no half state.
* In `tokio::select!` loops, use cancel-safe operations (`mpsc::Receiver::recv`,
  `sleep`); do not put a partially-consumed read (`read_exact`, a framed decoder
  mid-frame) in a `select!` arm that another branch can win repeatedly.
* Use `tokio::time::timeout` around external calls that can hang.

## Send and Sync

* Futures passed to `tokio::spawn` must be `Send + 'static`. Fix a non-`Send` error by
  dropping the offending value (`Rc`, `RefCell` borrow, `MutexGuard`) before the `.await`,
  not by switching to `spawn_local` blindly.
* `Arc<T>` shares ownership across threads; `Arc<Mutex<T>>` adds shared mutation. Reach
  for the second only when mutation is really shared.
* `unsafe impl Send`/`Sync` requires proving the type upholds the guarantee; treat it like
  any other `unsafe` block, with a `// SAFETY:` comment.
* Use `std::thread::scope` to borrow stack data in threads without `Arc` or `'static`.

```rust
std::thread::scope(|scope| {
    for chunk in items.chunks(chunk_size) {
        scope.spawn(|| process(chunk));
    }
});
```

## Shutdown

* Give long-running loops a shutdown signal (`tokio_util::sync::CancellationToken`, a
  `watch` channel, or closing the input channel) and await their completion.
* Flush buffered writers and commit or roll back open transactions before exit.
* Keep protocol output and logs separate: for stdio protocols (MCP, LSP), stdout carries
  only frames, and logs go to stderr or a file.
