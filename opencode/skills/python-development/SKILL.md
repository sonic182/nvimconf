---
name: python-development
description: |
  Expert Python assistant for writing, reviewing, and refactoring idiomatic, modern Python (3.12+) code. Use for any task that introduces or changes Python code. Enforces PEP 8, PEP 257, and PEP 484/585/604/695 typing conventions across formatting, naming, imports, docs, typespecs, error handling, classes, dataclasses, and collections, while avoiding common anti-patterns. Web (FastAPI/Django), async, and packaging specifics live in references/web-async-packaging.md (loaded on demand).

  Use for: any new or modified Python code, modules, classes, dataclasses, type hints, async code, tests, docs, and code review/refactoring.
  Do not use for: non-Python code, infra unrelated to Python, or pure architecture with no Python code.
---

# SKILL.md — Python

Reference for generating and reviewing Python code. Ground all decisions in:

- PEP 8 — Style Guide: https://peps.python.org/pep-0008/
- PEP 257 — Docstring Conventions: https://peps.python.org/pep-0257/
- PEP 484 / 585 / 604 / 695 — typing (hints, builtin generics, `X | Y` unions, `type`/`def f[T]` syntax)
- The Ruff rule set (re-implements Flake8 + plugins, isort, pydocstyle, pyupgrade): https://docs.astral.sh/ruff/rules/

For FastAPI/Django, async, ORM, and packaging detail, read `references/web-async-packaging.md`.

## Core Principles

- Write idiomatic, readable Python that already matches `ruff format` (Black-compatible).
- Target Python 3.12+; use modern syntax (`list[int]`, `X | None`, `type` aliases, PEP 695 generics).
- Prefer simple functions over clever abstractions; "explicit is better than implicit" (PEP 20).
- Prefer specific exceptions and clear return values over silent failures or bare `except`.
- Type-annotate all public function signatures; let inference handle obvious locals.

## Formatting

Most of this is applied automatically by `ruff format`; the rules are here so generated code is correct before formatting.

- Indentation: 4 spaces per level, never tabs. Continuation lines align with the opening delimiter or use a hanging indent.
- Max line length: 88 (Ruff/Black default; PEP 8 permits 79). Docstrings/comments to 72–79.
- Unix line endings, trailing newline, no trailing whitespace.
- Spaces around binary operators and after commas/colons in expressions; **no** space before a comma, before a call's `(`, or just inside brackets/parens/braces.
- No spaces around `=` for keyword arguments and defaults **without** an annotation; **with** an annotation, spaces around `=`: `def f(x: int = 0)`.
- Two blank lines around top-level `def`/`class`; one blank line between methods.
- Imports at the top, one module per line, grouped stdlib / third-party / first-party with a blank line between groups, sorted within each group (isort/Ruff `I`).
- Prefer implicit line joining inside parentheses over backslashes. For long collections/calls, put one item per line with a trailing comma and the closing bracket on its own line.

```python
# good — spaces around binary ops, none inside brackets, trailing comma in multiline
total = price + tax
items = [
    "first",
    "second",
]
result = some_function(
    foo,
    bar,
    timeout=30,
)

# good — annotated default gets spaces around =, plain default does not
def connect(host: str, port: int = 5432, *, verbose=False) -> Connection: ...

# bad
total = price+tax            # missing spaces
items = [ "first" ]          # spaces inside brackets
def f(x: int=0): ...         # annotated default needs spaces around =
```

## Naming

- Functions, variables, methods, modules, packages: `snake_case`
- Classes, exceptions, type variables/aliases: `CapWords` (`HTTPClient` — keep acronyms upper)
- Constants: `UPPER_SNAKE_CASE` at module level
- Boolean-ish predicates read as questions: `is_valid`, `has_items`, `should_retry`
- "Internal" names: single leading underscore (`_helper`); name-mangled: double leading (`__cache`); avoid trailing-underscore unless dodging a keyword (`class_`, `id_`)
- Never use `l`, `O`, `I` as single-char names; avoid shadowing builtins (`list`, `id`, `type`, `input`)
- Filenames: short, all-lowercase `snake_case.py`, matching the importable module name

```python
# good
def is_admin(user: User) -> bool: ...
class HTTPClient: ...
MAX_RETRIES = 3

# bad
def isAdmin(user): ...        # camelCase
class httpClient: ...         # class should be CapWords, acronym upper
maxRetries = 3                # constant should be UPPER_SNAKE_CASE
```

## Module Layout

Order the top of a module like this, with a blank line between groups:

1. Module docstring (`"""..."""`) as the very first statement
2. `from __future__ import annotations` (if needed for forward refs on < 3.13 patterns)
3. `__all__` (optional, near the top after the docstring/future import)
4. Imports: stdlib, then third-party, then first-party — each group blank-line separated and sorted
5. Module constants (`UPPER_SNAKE_CASE`)
6. Module-level type aliases (`type Json = ...`)
7. Classes and functions
8. `if __name__ == "__main__":` guard at the bottom for scripts

Also:

- One leading module docstring, immediately after any shebang/encoding line.
- Prefer absolute imports; use explicit relative imports (`from . import x`) only within a package.
- Never use wildcard imports (`from x import *`) except to re-export in a package `__init__`.
- Keep one cohesive concept per module; split when it grows unfocused (no hard "one class per file" rule as in some languages).

```python
"""Token utilities."""

from __future__ import annotations

import re

from myapp.models import User

MAX_LEN = 256

type ParseResult = tuple[bool, str | None]


class Token:
    """A parsed token."""
```

## Docs and Typespecs

- Use PEP 257 docstrings: triple-double-quoted, summary line in the imperative, closing `"""` on its own line for multiline.
- Document every public module, class, and function; omit obvious docstrings on trivial private helpers.
- Annotate all public signatures. Use builtin generics (`list[str]`, `dict[str, int]`), `X | None` instead of `Optional[X]`, and `X | Y` instead of `Union`.
- Use PEP 695 syntax for new generics and aliases: `def first[T](items: Sequence[T]) -> T` and `type Json = ...`. Treat the old `TypeVar`/`Generic` ceremony as legacy.
- Prefer `collections.abc` (`Sequence`, `Mapping`, `Iterable`) for parameters; return concrete types.
- Use `Protocol` for structural typing instead of forcing inheritance; `@override` (3.12) on overriding methods.

```python
def parse(value: str) -> tuple[bool, str | None]:
    """Parse a token, returning (ok, error).

    Examples:
        >>> parse("abc")
        (True, None)
    """
    if not value:
        return False, "empty"
    return True, None


def first[T](items: Sequence[T]) -> T:
    """Return the first item."""
    return items[0]


type Json = None | bool | int | float | str | list["Json"] | dict[str, "Json"]
```

## Expressions and Control Flow

- Prefer comprehensions for simple maps/filters; fall back to a loop when logic is non-trivial. Don't nest more than two `for`/`if` clauses in one comprehension.
- Use truthiness for emptiness (`if not items:`), but compare to `None` with `is`/`is not`, and to singletons with `is`.
- Use `==`/`!=` for value comparison; chain comparisons (`0 <= x < n`) where natural.
- Prefer `enumerate`, `zip`, `dict.items()` over manual indexing.
- Use a ternary for a simple either/or; don't nest ternaries.
- Use `match`/`case` (3.10+) for structural branching over many shapes; a plain `if`/`elif` for two or three.
- Use context managers (`with`) for any resource with setup/teardown.

```python
# good
names = [u.name for u in users if u.active]
if value is None: ...
if not items: ...
label = "on" if enabled else "off"

with open(path, encoding="utf-8") as f:
    data = f.read()

# bad
names = []
for u in users:               # use a comprehension
    if u.active:
        names.append(u.name)
if value == None: ...         # compare to None with `is`
if len(items) == 0: ...       # use truthiness
```

## Error Handling

### Raise specific exceptions

Raise the most specific built-in or a custom subclass; never raise bare `Exception`. Messages are lowercase, no trailing period.

```python
# good
if port < 0:
    raise ValueError("port must be non-negative")

# bad
if port < 0:
    raise Exception("Bad port.")     # too broad, wrong message style
```

### Catch narrowly

Catch the specific exception(s) you expect; never use a bare `except:` or blanket `except Exception` unless you re-raise or log-and-reraise. Keep the `try` body minimal.

```python
# good
try:
    config = json.loads(raw)
except json.JSONDecodeError as exc:
    raise ConfigError("invalid config") from exc

# bad
try:
    config = json.loads(raw)
    apply(config)             # too much in the try; mixes failure sources
except Exception:             # too broad, swallows real bugs
    config = {}
```

### Chain, don't swallow

Use `raise ... from exc` to preserve context. Use `else` for the success path and `finally` for cleanup (or a context manager). Define custom exceptions ending in `Error`, rooted at one base per package.

```python
class AppError(Exception):
    """Base for all application errors."""


class NotFoundError(AppError):
    """Raised when a resource is missing."""
```

### Return values vs. exceptions

For expected, recoverable outcomes prefer a return value (`None`, a sentinel, or a result object) over control-flow-by-exception. Reserve exceptions for genuinely exceptional conditions.

```python
def find_user(users: dict[int, User], id_: int) -> User | None:
    return users.get(id_)
```

## Classes and Dataclasses

- Reach for a `@dataclass` (or `frozen=True` for value objects) before a hand-written `__init__`/`__eq__`/`__repr__`. Use `slots=True` for memory-sensitive, attribute-fixed classes.
- Don't use mutable default arguments; use `field(default_factory=list)` in dataclasses and `None` + assignment elsewhere.
- Prefer composition over deep inheritance; use `Protocol` for duck-typed contracts.
- Use `@property` for computed read-only attributes; don't write Java-style `get_x`/`set_x`.
- Use `@classmethod` for alternative constructors, `@staticmethod` sparingly (a module function is often clearer).
- Use `enum.Enum`/`StrEnum` for fixed sets of named values instead of bare string/int constants.

```python
from dataclasses import dataclass, field


@dataclass(frozen=True, slots=True)
class Point:
    x: float
    y: float

    @property
    def magnitude(self) -> float:
        return (self.x**2 + self.y**2) ** 0.5


@dataclass
class Cart:
    items: list[str] = field(default_factory=list)   # never `items: list = []`
```

## Collections and Strings

- Pick the right type: `list` for ordered/mutable, `tuple` for fixed records, `set` for membership/dedup, `dict` for keyed lookup.
- Use `dict.get(key, default)` / `dict.setdefault`, `collections.defaultdict`, `collections.Counter` instead of manual key-presence dances.
- Iterate directly; use `enumerate`/`zip`; avoid building an index just to index back in.
- Use f-strings for formatting; never `%` or `.format` for new code. Keep expressions in f-strings simple.
- Join with `"".join(parts)` instead of `+=` in a loop. Use `pathlib.Path` over `os.path` string munging.
- Prefer generators for large/streamed sequences to avoid materializing everything.

```python
# good
counts = Counter(words)
greeting = f"hello {name}"
path = Path("data") / "in.csv"
total = sum(line_cost(x) for x in rows)

# bad
greeting = "hello %s" % name
path = "data" + "/" + "in.csv"
```

## Testing

- Use `pytest`: plain `assert`, fixtures over `setUp`, `@pytest.mark.parametrize` for cases.
- One behavior per test; name `test_<unit>_<condition>_<expected>`.
- Use `tmp_path`/`monkeypatch` fixtures; avoid real network/disk/clock — fake or mock at the boundary.
- Assert on behavior and return values, not implementation details. Use `pytest.raises` for error paths.

```python
import pytest

from myapp.token import parse


@pytest.mark.parametrize(
    ("value", "expected"),
    [("abc", (True, None)), ("", (False, "empty"))],
)
def test_parse_returns_expected(value, expected):
    assert parse(value) == expected


def test_parse_rejects_none():
    with pytest.raises(TypeError):
        parse(None)
```

## Comments

- Comments explain *why*, not *what*; keep them in sync with the code or delete them.
- Block comments: `# ` (one space) on the line(s) above the code, at the code's indentation. Inline comments: at least two spaces before `#`, used sparingly.
- Capitalize sentences; annotations are uppercase + colon + space: `TODO:`, `FIXME:`, `XXX:`, `HACK:`. Don't leave commented-out code.

```python
# Normalize external input before matching.
attrs = normalize(attrs)

x = compute()  # inline note, two spaces before the hash
```

## Anti-Patterns to Avoid

### Code

```python
def add(item, items=[]):          # bad — mutable default shared across calls
def add(item, items=None):        # good — default None, create inside

except Exception: pass            # bad — silently swallows everything
except KeyError: ...              # good — catch what you expect

if type(x) == int:                # bad — use isinstance
if isinstance(x, int):            # good

d = {}; d.get("k") or fallback    # bad when 0/"" are valid — `or` masks falsy values
d.get("k", fallback)              # good — explicit default

config = json.loads(open(p).read())   # bad — file never closed
with open(p) as f: config = json.loads(f.read())   # good
```

### Design

- Don't vary return *type* by argument value; split into separate functions instead.
- Avoid many boolean flag parameters; pass an enum/option or split the function. Use keyword-only args (`*,`) for clarity.
- Avoid primitive obsession; model domain concepts as dataclasses/enums, not loose tuples and dicts.
- Don't use exceptions for normal control flow; don't raise broad exceptions for expected misses.
- Avoid global mutable state; pass dependencies in. Avoid deep inheritance — prefer composition/Protocols.

### Typing

- Don't annotate with bare `list`/`dict`; parameterize (`list[str]`). Don't overuse `Any` — it disables checking.
- Prefer `collections.abc` types in parameters over concrete ones for flexibility.
- Don't mix the legacy `Optional`/`Union`/`TypeVar` ceremony into new 3.12+ code; use `| None`, `|`, and PEP 695.

```python
# bad — Any defeats the checker; bare dict is unparameterized
def handle(payload: Any) -> dict: ...

# good
def handle(payload: Mapping[str, object]) -> dict[str, int]: ...
```

## Tooling

```sh
ruff format --check          # formatting (Black-compatible)
ruff check                   # lint: PEP 8, isort, bugbear, pyupgrade, etc.
ruff check --fix             # auto-fix safe lint issues
mypy .                       # static type checking (or: pyright)
pytest                       # tests
uv sync                      # reproducible env from pyproject.toml + lockfile
```
