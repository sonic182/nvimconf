# Ecto

On-demand reference for `elixir-development`.

Read this when the task touches schemas, changesets, queries, bulk writes,
transactions, or migrations. Applies to any project using Ecto, with or without
Phoenix.

Style and general Elixir idioms still come from `SKILL.md`.

## Schemas and changesets

Changesets are the boundary for casting, validating, and preparing external changes.

Rules:

* `cast/3` only fields the caller legitimately owns.
* Do not cast open or privileged field lists.
* Never cast fields such as `role`, `admin`, `org_id`, `tenant_id`, `user_id`, or
  `account_id` from untrusted params unless that is explicitly the intended API.
* Set privileged, tenant, scope, or ownership fields server-side.
* Do not cast lifecycle or audit columns — the fields that record what has happened to a
  row since it was created: `revoked_at`, `confirmed_at`, `deleted_at`, `last_used_at`,
  `failed_attempts`, `status` where a transition owns it. The system writes those when
  the event happens. A creation changeset that casts them lets a caller insert a record
  born already spent, or carrying an audit trail of events that never took place.
  An issuing changeset and a transition are different operations: keep them apart.
* Validate with targeted validators: `validate_required/2`, `validate_format/3`,
  `validate_number/3`, `validate_length/3`, `validate_inclusion/3`, or custom validators
  when domain-specific.
* Enforce database invariants with constraint helpers so database errors surface as
  changeset errors: `unique_constraint/3`, `foreign_key_constraint/3`,
  `check_constraint/3`, `exclusion_constraint/3`.
* Pair constraint helpers with matching migration constraints or indexes.
* Mark secret or PII fields with `redact: true` in schema field definitions when
  they must not leak through inspect/logging.
* Keep changesets focused. Prefer separate changeset functions for different callers
  or flows.

```elixir
# good — casts only fields the caller owns
def changeset(user, attrs) do
  user
  |> cast(attrs, [:name, :email])
  |> validate_required([:name, :email])
  |> validate_format(:email, ~r/@/)
  |> unique_constraint(:email)
end

# bad — mass assignment: caller can set role/org_id/admin
def changeset(user, attrs) do
  user
  |> cast(attrs, [:name, :email, :role, :org_id, :admin])
  |> validate_required([:name, :email])
end
```

Prefer separate changesets over option-driven shape shifting:

```elixir
def registration_changeset(user, attrs) do
  user
  |> cast(attrs, [:name, :email, :password])
  |> validate_required([:name, :email, :password])
end

def admin_update_changeset(user, attrs) do
  user
  |> cast(attrs, [:name, :email, :role])
  |> validate_required([:name, :email, :role])
end
```

## Queries

Rules:

* `Repo.get/2` returns `nil`; use it when absence is expected.
* `Repo.get!/2` raises; reserve it for setup, tests, or cases where absence is a bug.
* `Repo.one/1` raises `Ecto.MultipleResultsError` when the query matches more than one
  row. A function documented to return `nil` must therefore only accept predicates that
  can resolve a single row — a non-unique column belongs in the list function instead.
  Do not share one filter allowlist between a "one row" and a "many rows" function.
* Keep query composition in contexts or dedicated query modules, not controllers or
  LiveViews.
* Compose queries with `Ecto.Query`: `from`, `where`, `join`, `order_by`, `limit`,
  `select`, `preload`.
* Avoid N+1 queries. Preload associations explicitly with `Repo.preload/2` or query
  preloads.
* For large reads, select only needed fields.
* Do not interpolate user input into SQL fragments. Use placeholders.
* Keep tenant or authorization scope in every query that touches tenant-owned data.
* Prefer keyset pagination for large or frequently changing datasets when offset
  pagination becomes slow or unstable.

```elixir
# good — scoped to the tenant, returns a tagged tuple
def fetch_invoice(scope, id) do
  Invoice
  |> where([invoice], invoice.org_id == ^scope.org_id)
  |> where([invoice], invoice.id == ^id)
  |> Repo.one()
  |> case do
    nil -> {:error, :not_found}
    invoice -> {:ok, invoice}
  end
end

# bad — no tenant scope, raises instead of returning {:error, _}
def fetch_invoice(_scope, id) do
  {:ok, Repo.get!(Invoice, id)}
end
```

```elixir
where(query, [item], fragment("? ilike ?", item.name, ^"%#{term}%"))  # safe — parameterized
where(query, [item], fragment("name ilike '%#{term}%'"))              # unsafe — interpolated
```

## Bulk writes and state transitions

`Repo.update_all/3` and `Repo.delete_all/1` skip changesets, validations, and
`timestamps()` autogeneration, and they act on every row the query matches.

Rules:

* `update_all` does not set `updated_at`. Capture the time once and set it beside the
  columns you are changing, or a security-relevant change leaves rows looking untouched
  since insertion.
* A bulk update or delete must require its scope. Never let an absent, empty, or
  caller-supplied filter widen the statement to the whole table, and do not reuse a read
  function's permissive filter set for one — a key that is harmless in `list/1` can mean
  "every row" in `delete_all/1`.
* Put the state predicate in the statement's own `WHERE`, not in a read before it. That
  is what makes a transition happen exactly once under concurrency, and what stops a
  repeated call from overwriting the timestamp of the event that first caused it.
* Return the affected rows with `select/3` on the query rather than re-reading them, so
  the result reflects what the statement actually changed.
* Delete on the column that expresses the retention rule, not on "no longer usable". A
  row that was revoked or spent normally keeps its original expiry and stays as history
  until then; deleting on liveness drops that trail the moment it is written.

```elixir
# good — scope is a required argument, timestamps set, predicate in the UPDATE's WHERE
def revoke_all(account_code) when is_binary(account_code) do
  now = DateTime.utc_now(:second)

  {count, _rows} =
    Grant
    |> where([g], g.account_code == ^account_code and is_nil(g.revoked_at))
    |> Repo.update_all(set: [revoked_at: now, updated_at: now])

  count
end

# bad — filters come straight from the caller, so `[]` revokes every row in the table,
# and `updated_at` still claims the row has not changed since it was created
def revoke_all(filters) do
  Grant
  |> where(^filters)
  |> Repo.update_all(set: [revoked_at: DateTime.utc_now()])
end
```

A read-then-write is neither concurrent-safe nor idempotent:

```elixir
# bad — two callers both read a live row and both write. Calling it again also rewrites
# `revoked_at`, destroying the timestamp of the revocation that actually took effect
case Repo.get(Grant, id) do
  %Grant{revoked_at: nil} = grant ->
    grant |> Ecto.Changeset.change(revoked_at: now) |> Repo.update()
end

# good — the database decides. Zero rows updated means it had already happened, so the
# caller can return the row as it stands instead of changing it
Grant
|> where([g], g.id == ^id and is_nil(g.revoked_at))
|> select([g], g)
|> Repo.update_all(set: [revoked_at: now, updated_at: now])
```

Under `READ COMMITTED`, the second of two concurrent statements blocks on the row lock,
re-reads the committed row, no longer matches the predicate, and updates zero rows. Single
use is then the database's guarantee rather than the calling module's.

## Transactions and Ecto.Multi

Use transactions when several operations must succeed or fail together.

Prefer ordinary control flow in a transaction when the sequence is simple. Use
`Ecto.Multi` when the operations are dynamic, need names, are useful to inspect in tests,
or depend on previous operation results.

Rules:

* Use `Ecto.Multi` for multi-step writes that need atomicity and named operations.
* Use `Multi.run/3` when a step depends on previous results and may return
  `{:ok, value}` or `{:error, reason}`.
* Keep operation names stable and meaningful.
* Pattern match on `{:ok, changes}` and `{:error, failed_operation, failed_value, changes_so_far}`.
* Do not perform slow external API calls inside a database transaction unless the
  consistency requirement is explicit and worth the lock time.
* Prefer building changesets before the transaction when possible, so invalid changesets
  fail before the transaction starts.
* Use `Repo.transact/1` when the project uses modern Ecto naming. Use
  `Repo.transaction/1` when that is the project convention or version-compatible path.

Good:

```elixir
alias Ecto.Multi

def create_user_with_profile(attrs) do
  Multi.new()
  |> Multi.insert(:user, User.registration_changeset(%User{}, attrs))
  |> Multi.insert(:profile, fn %{user: user} ->
    Profile.changeset(%Profile{}, %{
      user_id: user.id,
      display_name: attrs["display_name"] || attrs[:display_name]
    })
  end)
  |> Repo.transact()
end
```

For non-database or validation-dependent steps:

```elixir
Multi.new()
|> Multi.insert(:invoice, Invoice.changeset(%Invoice{}, attrs))
|> Multi.run(:audit_log, fn repo, %{invoice: invoice} ->
  audit_log =
    AuditLog.changeset(%AuditLog{}, %{
      invoice_id: invoice.id,
      action: "invoice_created"
    })

  case repo.insert(audit_log) do
    {:ok, log} -> {:ok, log}
    {:error, changeset} -> {:error, changeset}
  end
end)
|> Repo.transact()
```

## Migrations

Prefer migrations that are safe in rolling deploys.

Rules:

* Prefer reversible `change/0`.
* If a migration is irreversible, use `up/0` and `down/0`, and make the tradeoff
  explicit.
* Pair database constraints and indexes with changeset constraint helpers.
* Keep migrations backward compatible for at least one deploy when old and new code
  may run against the same database.
* Sequence destructive changes across deploys:

  1. Add new nullable column or new table.
  2. Deploy code that writes both old and new shapes if needed.
  3. Backfill out of band or in safe batches.
  4. Deploy code that reads the new shape.
  5. Add constraints.
  6. Drop old columns later.
* Avoid renaming or dropping columns in the same deploy that introduces new code
  depending on the replacement.
* Avoid long locks on large tables.
* For PostgreSQL indexes on large tables, prefer concurrent indexes when needed.
* When using concurrent indexes, disable DDL transactions with
  `@disable_ddl_transaction true`.
* Keep non-transactional migrations short and carefully reviewed.
* Avoid `NOT NULL` with a default on large existing tables unless the database/version
  behavior is known to be safe.

Concurrent index example:

```elixir
defmodule MyApp.Repo.Migrations.AddInvoicesOrgStatusIndex do
  use Ecto.Migration

  @disable_ddl_transaction true

  def change do
    create index(:invoices, [:org_id, :status], concurrently: true)
  end
end
```

Constraint example (paired with the `unique_constraint(:email)` changeset shown in
Schemas and changesets above):

```elixir
def change do
  create unique_index(:users, [:email])
end
```
