On-demand reference for `pr-reviewer`. Read this when the PR is primarily Python.

### Context-gathering expansions

- Web/API changes:
  - route declarations and handler wiring
  - request parsing/validation and response schemas
  - error mapping and status-code consistency
- Auth/security:
  - auth middleware/dependencies/decorators
  - permission checks on read and write paths
  - secrets/config handling and trust boundaries
- Data/persistence:
  - models, migrations, query builders, repositories/services
  - transaction boundaries, locking, idempotency, retry behavior
  - indexes and query selectivity for new access patterns
- Async/background work:
  - blocking calls inside async handlers
  - task cancellation/timeout/retry behavior
  - queue worker semantics and duplicate processing risks
- Packaging/config:
  - dependency changes, Python version constraints, env var defaults
  - backward compatibility and rollout risk

### Review dimensions add-ons

- Typing/reliability (`typing` correctness, pydantic/dataclass/schema drift, runtime validation)

### Python-specific review checklist

- API and validation:
  - request/response schema compatibility preserved?
  - input validation strict enough at trust boundaries?
  - error responses stable and intentional?
- Data consistency:
  - transaction scope correct for multi-write flows?
  - race conditions around read-modify-write paths?
  - migration is backward-compatible for rolling deploys?
- Async/concurrency:
  - any blocking DB/HTTP/file calls inside `async def` without offloading?
  - proper timeout/cancellation handling?
  - shared mutable state guarded?
- Security:
  - auth checks present on every sensitive endpoint/action?
  - unsafe dynamic eval/import/deserialization patterns?
  - secrets/tokens avoided in logs and API responses?
- Reliability:
  - retries idempotent and bounded?
  - exception handling preserves observability and correct status codes?
  - cache invalidation/update logic coherent with source of truth?
- Documentation:
  - if new user-facing features or endpoints were added, are they reflected in the project's docs system (Sphinx, MkDocs, SSG, OpenAPI/auto-generated docs, README, etc.)?
  - if a docs system is present but new features have no docs entry, flag it as a minor issue.

Tooling suggestions when relevant:
- `ruff check .`
- `ruff format --check .` (or project formatter)
- `mypy .` (or pyright, based on project standard)
- `pytest -q`
