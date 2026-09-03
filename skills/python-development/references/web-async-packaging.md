# FastAPI/Django, Async, ORM, Packaging & Project Layout

On-demand reference for `python-development`. Read this when the task touches a web
framework (FastAPI, Django, Flask), `asyncio`, an ORM (SQLAlchemy, Django ORM), or
project/packaging structure. Style and idioms still come from `SKILL.md`; this file adds
framework and ecosystem specifics.

## Table of contents

- [Project layout & packaging](#project-layout--packaging)
- [Async (asyncio)](#async-asyncio)
- [Web layer: keep it thin](#web-layer-keep-it-thin)
- [FastAPI](#fastapi)
- [Django](#django)
- [ORM & data access](#orm--data-access)

---

## Project layout & packaging

- Use the **`src/` layout**: package code under `src/mypkg/`, tests under `tests/`. This
  prevents accidentally importing the source tree instead of the installed package.
- Single `pyproject.toml` (PEP 621) holds metadata, dependencies, and tool config
  (`[tool.ruff]`, `[tool.mypy]`, `[tool.pytest.ini_options]`). No `setup.py`/`setup.cfg`
  for new projects.
- Manage environments and dependencies with **uv** (or Poetry): commit the lockfile,
  `uv sync` for reproducible installs, `uv add`/`uv remove` to change deps. Never `pip
  install` into a global interpreter for a project.
- Pin a minimum Python version in `requires-python` and keep it consistent with the
  `target-version` in Ruff and `python_version` in mypy.
- Expose a console entry point via `[project.scripts]` rather than a loose top-level script.

```toml
[project]
name = "mypkg"
requires-python = ">=3.12"
dependencies = ["httpx>=0.27"]

[tool.ruff]
target-version = "py312"
line-length = 88

[tool.mypy]
python_version = "3.12"
strict = true
```

---

## Async (asyncio)

- Don't mix blocking and async: never call blocking I/O (sync DB driver, `requests`,
  `time.sleep`) inside a coroutine — it stalls the whole event loop. Use async libraries
  (`httpx.AsyncClient`, async DB drivers) or push blocking work to `asyncio.to_thread`.
- Run concurrent work with `asyncio.gather` or, preferably, a `TaskGroup` (3.11+) which
  cancels siblings on failure and propagates errors cleanly.
- Always `await` coroutines; a bare coroutine call does nothing and leaks a warning. Don't
  fire-and-forget without keeping a reference (tasks can be garbage-collected mid-flight).
- Use `async with`/`async for` for async context managers and iterators. Set timeouts
  (`asyncio.timeout`) on anything that can hang.
- Don't create a new event loop manually in app code; use `asyncio.run(main())` as the
  single entry point.

```python
import asyncio

import httpx


async def fetch_all(urls: list[str]) -> list[str]:
    async with httpx.AsyncClient() as client:
        async with asyncio.TaskGroup() as tg:
            tasks = [tg.create_task(client.get(u)) for u in urls]
    return [t.result().text for t in tasks]
```

---

## Web layer: keep it thin

- The view/route/handler layer parses and validates input, calls a service/domain
  function, and serializes the result. Business logic and persistence live below it, not
  in the handler.
- Don't reach into the ORM/session directly from a route in non-trivial apps; route →
  service → repository/ORM. Keep transactions and queries out of view functions.
- Validate and **authorize** on every request that reads or mutates a resource; never
  trust an ID in the path/body to belong to the current user. Re-check on each action, not
  just at login.
- Return typed, explicit responses; map domain errors to status codes in one place
  (exception handler / middleware), not ad hoc in each handler.

---

## FastAPI

- Define request/response shapes as **Pydantic models**; let FastAPI handle validation and
  serialization. Use separate input and output models — never accept a model that lets a
  client set privileged fields (`is_admin`, `owner_id`); set those server-side.
- Use **dependency injection** (`Depends`) for shared concerns: DB session, current user,
  settings. Put auth in a dependency and require it on protected routes.
- Prefer `async def` endpoints with async DB/HTTP clients; use plain `def` (run in a
  threadpool) only when the work is genuinely blocking and you can't go async.
- Raise `HTTPException` (or a custom exception with a registered handler) for error
  responses; don't return ad hoc error dicts with a 200.
- Type every path/query/body parameter; FastAPI derives validation and docs from the hints.

```python
from fastapi import Depends, FastAPI, HTTPException

app = FastAPI()


class UserIn(BaseModel):
    name: str
    email: EmailStr        # NOT is_admin / owner_id — set server-side


@app.post("/users", response_model=UserOut)
async def create_user(payload: UserIn, db: Session = Depends(get_db)) -> UserOut:
    if await users.exists(db, payload.email):
        raise HTTPException(status_code=409, detail="email already registered")
    return await users.create(db, payload)
```

---

## Django

- Keep business logic in services/model methods/managers, **not** in views or templates.
  Fat models or a service layer; thin views.
- Use the ORM through `QuerySet`s; compose with `filter`/`annotate`/`select_related`. Never
  build SQL by string-formatting user input — use the ORM or parameterized `raw()`.
- Validate via Forms / DRF serializers; whitelist the fields a request may set
  (`fields = [...]`), never blindly `Model(**request.data)` — that's mass assignment.
- Authorize with permission classes / `@login_required` / object-level checks; re-check
  ownership on detail/edit/delete views.
- Wrap multi-write operations in `transaction.atomic()` so partial failures roll back.
- Migrations: keep them reversible and backward-compatible across a rolling deploy;
  sequence destructive changes (add nullable → backfill out-of-band → constrain → drop)
  rather than breaking the running version. Add indexes concurrently on large tables.

---

## ORM & data access

- **Avoid N+1 queries**: eager-load relations you'll traverse — `select_related`
  (FK/one-to-one) / `prefetch_related` (many) in Django, `selectinload`/`joinedload` in
  SQLAlchemy — instead of loading inside a loop.
- Select only the columns/rows you need for large reads; paginate; stream with iterators
  rather than materializing huge result sets.
- Keep query composition in the data/service layer, not in views or serializers.
- Use transactions for multi-step writes that must all succeed or all fail; let DB
  constraints (unique, FK, check) enforce invariants and surface them as handled errors,
  rather than checking-then-inserting in a race.
- Never interpolate user input into raw SQL; always parameterize.

```python
# bad — N+1: one query per author inside the loop
for book in Book.objects.all():
    print(book.author.name)

# good — one extra query total
for book in Book.objects.select_related("author"):
    print(book.author.name)
```
