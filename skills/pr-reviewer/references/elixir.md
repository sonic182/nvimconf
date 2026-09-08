On-demand reference for `pr-reviewer`. Read this when the PR is primarily Elixir/Phoenix.

### Context-gathering expansions

- LiveView/component changes:
  - parent LiveView(s) and nested components
  - `.heex` templates, function components, slots usage
  - `mount/3`, `handle_params/3`, `apply_action/3`, `handle_event/3`, `handle_info/2`
  - navigation flows: `push_patch` / `push_navigate` / `live_patch`
- Auth/security:
  - router pipelines, session/CSRF/secure headers
  - LiveView `on_mount` hooks / policy modules
  - authorization enforced on mount **and** on events
  - tenant derivation: where does the current org/account come from? (session/`on_mount` = trustworthy; URL param/event payload = attacker-controlled)
- Data/persistence:
  - contexts, schemas, changesets, migrations
  - query composition, preloads/joins/filters/pagination
  - tenant scoping applied consistently in the context, not ad-hoc per call site
  - transaction boundaries and consistency
- Frontend integration:
  - JS hooks/assets and event payload shapes
  - form handling conventions and validation behavior

### Review dimensions add-ons

- Cleanliness/dead code (unused functions, clauses, assigns, aliases; commented-out blocks; unreachable branches)
- Migration & deploy safety (backward compatibility during rolling deploys, locks, index creation)

### LiveView-specific review checklist

- State & assigns:
  - can assigns used in HEEx be nil/unset after navigation?
  - any assigns grow unbounded or store large structs?
  - mismatched assign keys across branches?
  - do assigns hold secrets/PII that don't need to live in socket state?
- Events:
  - changed event names still emitted by templates/JS?
  - handlers idempotent where needed?
  - errors surfaced to UI vs silently swallowed?
  - does every event that acts on a resource ID re-check ownership/authorization? (mount-time checks don't protect later events; the client can send any ID)
- Navigation:
  - `live_action` routes consistent with `handle_params/apply_action`?
  - patch/navigate flows keep state consistent?
- PubSub / real-time:
  - are subscribed/broadcast topics scoped to the tenant (e.g. `"feed:#{org_id}"`)? A shared topic can leak one customer's data to another's live session.
  - is the topic derived from the authenticated session, not from a user-supplied param?

### Multi-tenancy & data-isolation checklist (cross-customer access)

This is where SaaS bugs are most expensive: a single unscoped query lets one customer read or mutate another's data. Check:

- **Every read/write to tenant-owned data is scoped by the tenant key.** The classic leak is `Repo.get(Resource, id)` / `Repo.get!(...)` with no `where org_id == ^current_org_id`. Enumerable or guessable IDs then become an IDOR. Safer pattern: scope first, then fetch.
  ```elixir
  # Risky: any id from any tenant resolves
  def get_invoice!(id), do: Repo.get!(Invoice, id)

  # Safer: a row only resolves within the caller's scope
  def get_invoice!(%Scope{org_id: org_id}, id) do
    Invoice
    |> where([i], i.org_id == ^org_id)
    |> Repo.get!(id)
  end
  ```
- **Scoping lives in the context (or a shared query helper), not copy-pasted per call site.** Centralizing it means a new query can't silently forget the filter.
- **The tenant is derived from the authenticated session**, via `on_mount`/plug, and stored in a trusted assign/`Scope`. If the org/account comes from a URL param, form field, or event payload, that's attacker-controlled — flag it.
- **Aggregates and counts are scoped too.** A dashboard `Repo.aggregate(Resource, :count)` or report that forgets the tenant filter leaks cross-tenant totals even when individual records are protected.
- **Associations don't sidestep the scope.** A preload or join can pull in related rows that belong to another tenant if the association itself isn't constrained.
- **Schema-/prefix-based tenancy** (Triplex, Ecto `prefix:`): confirm the prefix is set from the session on every query, including in async tasks and `handle_info`, where the process may not inherit it.
- **Background jobs / async tasks** (`Task.async`, Oban, `handle_info`) carry the tenant explicitly. They don't share the LiveView's assigns, so a job that re-fetches "the current org" from somewhere ambient is a common leak.
- **Tests:** is there at least one test proving tenant A cannot see/modify tenant B's resource (404/forbidden, not another tenant's row)? For new tenant-scoped endpoints, the absence of this test is at least a major concern.

### Dead-code & cleanup checklist

Dead code rots: it confuses future readers, hides bugs, and inflates the surface that needs maintaining. Flag, in the changed/related code:

- **Unused private functions, public functions with no remaining callers, and unused module attributes.**
- **Unused `alias` / `import` / `require` / `use`.**
- **Commented-out code blocks** left in the diff — these belong in git history, not the source.
- **Unreachable clauses / branches:** a `case`/`cond`/`with` branch that can't match, or a function clause shadowed by an earlier catch-all.
- **Orphaned LiveView wiring:** `handle_event/3` clauses for events no longer emitted by any template or JS hook; assigns set in `mount` that nothing renders; routes/`live_action`s with no path to them.
- **Permanently-off feature flags** and the branches they gate.
- **Stale TODO/FIXME** that the PR's own change resolves but didn't remove.

Caveat to always apply: a function can *look* unused but be reachable via metaprogramming (`apply/3`), a behaviour callback, a `@impl` contract, a macro, config references, or external callers (a library's public API). So **flag with reasoning and ask before recommending deletion** rather than asserting it's safe to remove. Tooling that helps surface real dead code:
- `mix compile --warnings-as-errors` (unused vars/functions/aliases)
- `mix xref graph` / `mix xref callers Module.fun` (find call sites)
- `mix credo --strict` (unused, complexity, readability)

### Elixir/Phoenix security footguns (quick scan)

Beyond tenancy, these recur often enough to check directly:

- **Atom exhaustion:** `String.to_atom/1` on user input is a denial-of-service vector (the atom table isn't garbage-collected). Prefer `String.to_existing_atom/1`. Same caution for `:erlang.binary_to_term/1` on untrusted input.
- **Mass assignment:** `cast/3` with an over-broad field list lets users set fields they shouldn't, like `role`, `org_id`, or `admin`. Cast only what the form legitimately owns; set privileged/scope fields server-side.
- **Raw/unsafe HTML:** `raw/1`, `Phoenix.HTML.raw`, or building HEEx from interpolated user strings can reintroduce XSS that auto-escaping otherwise prevents.
- **Sensitive data exposure:** secrets/PII written to logs, inspected structs, or LiveView assigns. Schemas holding secrets should use `redact: true` (or `@derive {Inspect, except: [...]}`) so they don't leak via `inspect`/logging.
- **SQL via fragments:** `fragment(...)` or raw SQL that interpolates user input rather than using parameter placeholders.
- **Transaction boundaries:** multi-step writes that aren't wrapped in `Ecto.Multi`/`Repo.transaction` can leave partial state on failure.

### Migration & deploy-safety checklist

In a rolling deploy, old and new code run against the same DB at once, so migrations must be backward compatible for at least one release:

- **Index creation locks the table** unless created `concurrently` (with `@disable_ddl_transaction true` and `@disable_migration_lock true`).
- **Adding `NOT NULL` with a default on a large table**, or backfilling rows inside the migration, can hold locks long enough to cause an outage — prefer add-nullable → backfill out-of-band → set constraint.
- **Destructive changes** (dropping/renaming a column or table the currently-running code still references) break the old version mid-deploy. Sequence them across releases.
- **Down/rollback path:** is the migration reversible, or at least is irreversibility intentional and called out?

Documentation:
- if new public functions/modules were added, do they have `@moduledoc`/`@doc` entries?
- if new user-facing features were added, are they reflected in the project's docs (HexDocs guides, markdown files, SSG, README)?
- if a docs system is present but new features have no docs entry, flag it as a minor issue.

Tooling suggestions when relevant:
- `mix format --check-formatted`
- `mix credo --strict`
- `mix dialyzer` (or staged adoption plan if noisy)
- `mix compile --warnings-as-errors` (catches dead/unused code)
- `mix xref` (call graphs / unreachable code)
