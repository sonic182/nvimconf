On-demand reference for `pr-reviewer`. Read this when the PR is primarily PHP. Apply the Slim/Blade sections only when those frameworks are present; follow repository-local architecture rules over this reference.

### Context-gathering expansions

- HTTP/UI changes:
  - route declarations, route ordering, groups, and middleware
  - controller/action input parsing, validation, redirects, and PSR-7 response handling
  - view/template data flow, shared view variables, escaping, and optional values
- Services/integrations:
  - API clients, auth headers, timeouts, error mapping, retries, and response normalization
  - which layer owns outbound HTTP, configuration, and business logic
- Auth/security:
  - authentication and authorization middleware on every read and write path
  - trusted tenant/account derivation and resource-scoped service calls
  - CSRF coverage for state-changing forms
- Data/persistence:
  - models, migrations, query builders, transactions, indexes, and pagination
  - consistency and race risks in read-modify-write flows
- Configuration/deploy:
  - dependency/version changes, new env vars, DI bindings, production-safe defaults, and backward-compatible URLs

### PHP-specific review checklist

- **Types and contracts**
  - New PHP files declare strict types if that is project convention.
  - Parameters, return types, nullable values, and array shapes match real callers and external responses.
  - Avoid loose comparisons for security-sensitive values; use `===` unless coercion is intentional.
  - The DI container can resolve each added constructor dependency and has no hidden service-locator or circular-dependency failure.

- **Slim / PSR-7**
  - Every handler returns `ResponseInterface`; status codes, headers, redirects, and response bodies are intentional.
  - Routes remain registration/wiring only. Check route order for collisions between static and parameterized paths.
  - Middleware is applied to the correct route/group and in a viable order (error handling, routing, auth/authorization, CSRF as applicable).
  - Controllers coordinate request/response flow; API/database details belong in their service or repository layer.
  - API failures have a user-safe fallback and do not expose exception messages or stack traces in production.

- **Blade / rendering**
  - Every variable passed to a template exists on success and error paths; optional API data has a deliberate fallback.
  - `{{ $value }}` remains escaped. Treat `{!! $value !!}` as XSS unless the value is demonstrably sanitized, trusted HTML.
  - Do not derive template names, includes, redirect locations, or file paths directly from request input.
  - Reuse the application's component/design conventions rather than duplicating markup. Check responsive behavior, semantic controls, labels, visible focus states, and contrast for UI changes.

- **External APIs and configuration**
  - Outbound HTTP lives in the repository's designated integration/service layer, not routes, controllers, or views.
  - API URLs, tokens, and timeouts are injected from configuration, never hardcoded or read ad hoc from the environment.
  - New env vars have safe defaults where appropriate and non-secret placeholders in `.env.example` (or the project's equivalent).
  - API clients set timeouts, distinguish transport/non-success/invalid-response failures, and normalize untrusted response data before templates use it.
  - Retries are bounded and only used for idempotent operations unless an idempotency key or equivalent protects writes.

### Multi-tenancy and data isolation

A resource ID from a path, query string, form, or client event is attacker-controlled. For tenant-owned data, check:

- The tenant/account is derived from authenticated session or token context, never accepted as a request-controlled scope.
- Each service call passes the authenticated tenant and credential context consistently; helpers and aggregate/count endpoints are scoped too.
- The backend response is appropriate for the expected scope before caching or rendering it.
- A changed create/update/delete path re-checks authorization for the exact resource, not only at login.
- Tests demonstrate tenant A cannot read or mutate tenant B's resource when the application supports tenancy.

Missing scoping that can expose another customer's data is **critical** unless context proves backend enforcement makes it impossible.

### PHP security footguns

- Raw Blade output, HTML concatenation, or reflected request values can create XSS.
- Unvalidated `Location` headers can create open redirects; allow-list destinations or use application-generated routes.
- Dynamic include/template paths from input can create local file inclusion.
- `file_get_contents()`/cURL/Guzzle URLs from input can create SSRF; validate allowed hosts and schemes.
- SQL built by concatenating input needs parameterization. ORM/query-builder calls still need authorization scoping.
- Do not log credentials, tokens, session IDs, or unnecessary PII.
- State-changing browser forms need CSRF protection; Slim does not provide it automatically.

### Persistence, migrations, and deploy safety

- Queries fetching tenant-owned resources include the tenant predicate before lookup; a bare lookup by client-provided ID is an IDOR risk.
- Check list endpoints for pagination, filters/indexes, N+1 database or API calls, and unbounded view data.
- Multi-write changes need an appropriate transaction boundary; retries must not duplicate effects.
- Rolling deployments require additive schema changes first. Avoid immediately dropping/renaming columns still read by the old application version.
- Large-table indexes, backfills, defaults, and `NOT NULL` changes can lock or rewrite tables; use the database's online/concurrent path or staged migration where available.
- A migration is reversible or explicitly acknowledged as irreversible; destructive data changes are critical unless the rollout plan proves safety.

### Dead code and documentation

Flag changed or directly related:

- unused imports, private methods, routes, templates, components, and commented-out code
- unreachable `if`/`switch` branches and stale TODO/FIXME comments resolved by the change
- orphaned route/controller/template wiring

A method may be called through framework routing, DI, reflection, Blade includes, or public API use. Explain the evidence and ask before recommending deletion.

For user-facing routes/features, check the repository's docs and UI catalog/story conventions. Missing required documentation is a minor concern.

PHPStan and custom architecture sniffs are authoritative when configured; use their CI results. If a project explicitly limits environment access or outbound HTTP to particular layers, treat violations as blocking according to that project's policy.
