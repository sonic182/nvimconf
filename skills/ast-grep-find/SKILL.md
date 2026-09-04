---
name: ast-grep-find
description: |
    It is a must to use ast-grep when code search — use this skill before reaching for grep/ripgrep or similar plain text search. Apply when locating functions, calls, imports, JSX, decorators, error handling, unsafe APIs, duplicated expressions, refactor targets, or any code pattern where syntax-aware matching is more reliable than text matching.
---

# ast-grep-find

Use `ast-grep` (`ast-grep` or `sg`) as the default way to find code patterns in repositories. Prefer syntax-aware search over `rg` whenever the target is code structure rather than arbitrary text.

## Core rule

Reach for `ast-grep` before `rg` when searching for:

- function calls, method calls, constructors, imports, exports, decorators, annotations, JSX/TSX elements, object literals, class methods, assignments, conditions, try/catch blocks, callbacks, async/await, or other syntax-shaped code
- refactor candidates where whitespace, comments, formatting, or line breaks should not matter
- usages that need captured parts such as callee, arguments, imported names, receiver, property, or condition
- repeated subexpressions such as `$A == $A` or `$OBJ.$METHOD($$$ARGS)`

Use `rg` only when the target is not code syntax, such as comments, prose, configuration strings, generated text, log messages, filenames, or when `ast-grep` is unavailable or cannot parse the language.

## Outline: cheap navigation before reading whole files

Before reading a large unfamiliar file or directory end to end, run `ast-grep outline` first. It lists imports, exports, classes, functions, and members without dumping full source, so the far more expensive full read only happens for the parts that matter.

```bash
# single file: shows local structure (functions, types, classes) with line numbers
ast-grep outline src/queue.ts

# directory: defaults to exports per file — a map of the public surface
ast-grep outline src

# only exported symbols matching a name
ast-grep outline src --items exports --match 'Webhook'

# only certain symbol kinds
ast-grep outline src --type class,function

# richer output: signatures plus member digests
ast-grep outline src/queue.ts --view expanded
```

Typical directory output (`ast-grep outline src`):

```
src/db.ts
struct: Db
function: createDatabasePool, applyMigrations, createDb

src/api/errors.ts
class: ApiError
function: apiNotFound, createApiErrorHandler
constant: badRequest, unauthorized, notFound, conflict
```

Use this as the first move when exploring an unfamiliar repo or module, then open only the specific functions/classes the task touches — not every file in the directory.

## Rule development workflow (dump → test → scan)

For anything beyond a trivial one-line pattern, iterate on a small snippet before scanning the whole tree:

1. **Dump** the AST of a representative snippet to learn node kinds and structure:
   `ast-grep run --pattern '<snippet>' -l <lang> --debug-query=cst`
2. **Draft** a pattern or YAML rule targeting those kinds.
3. **Test** the rule against the snippet via stdin — no temp file, no full scan:
   `printf '%s' '<snippet>' | ast-grep scan --inline-rules '<yaml>' --json --stdin`
   If it does not match, remove sub-rules until it does, then add them back one at a time. For `inside`/`has`, add `stopBy: end`.
4. **Scan** the codebase only once the rule matches the snippet:
   `ast-grep scan --inline-rules '<yaml>' <path>`

## First checks

1. Check whether `ast-grep` is installed:

   ```bash
   command -v ast-grep || command -v sg
   ```

2. Prefer the full `ast-grep` command in portable instructions. On Linux, `sg` can refer to the system `setgroups` command, so do not assume `sg` means ast-grep.
3. Run searches from the repository root unless the user gives a narrower path.
4. Quote patterns with single quotes so shells do not expand `$META` variables.

## One-shot search workflow

Use `ast-grep run` implicitly or explicitly for quick lookups:

```bash
ast-grep -p '<pattern>' -l <lang> <path>
```

### Typed TypeScript functions

A function pattern without a return annotation does not match a typed declaration. Include it:

```bash
# Matches: export function createThing(input: Input): Output { ... }
ast-grep -p 'export function $NAME($$$ARGS): $RETURN { $$$BODY }' -l ts src

# Matches async functions returning Promise<...>
ast-grep -p 'async function $NAME($$$ARGS): $RETURN { $$$BODY }' -l ts src
```

### Elixir function heads

Elixir function definitions with guards have a different AST shape from
unguarded definitions. A pattern such as `def name($$$ARGS) do $$$BODY end`
does **not** match `def name($$$ARGS) when $COND do $$$BODY end`; include the
guard in the pattern instead:

```bash
# Broad guarded definitions
ast-grep -p 'def $NAME($$$ARGS) when $COND do $$$BODY end' -l elixir lib

# Exact guarded function, including multiline heads/default arguments
ast-grep -p 'def append_external_outbound_message($$$ARGS) when $COND do $$$BODY end' \
  -l elixir lib/athena/communications.ex
```

If a function may be guarded or unguarded, run both structural patterns (or use
an `any` YAML rule). Do not fall back to text search merely because an
unguarded `def` pattern returned no matches; first inspect the function head
with `--debug-query=cst` or try the guarded form.

Useful flags:

```bash
# show context around matches
ast-grep -p '<pattern>' -l <lang> -C 3 <path>

# structured results, human-readable (small result sets)
ast-grep -p '<pattern>' -l <lang> --json=pretty <path>

# structured results, one JSON object per line — memory-efficient for large codebases
ast-grep -p '<pattern>' -l <lang> --json=stream <path>

# restrict or exclude files
ast-grep -p '<pattern>' -l <lang> --globs 'src/**/*.ts' --globs '!**/*.test.ts' .
```

Three `--debug-query` formats (all require `-l`):

```bash
# pattern: how ast-grep parses your PATTERN — debug why a pattern is too broad/narrow
ast-grep -p '<pattern>' -l <lang> --debug-query=pattern

# cst: concrete syntax tree of TARGET code, incl. punctuation — debug why code won't match
ast-grep -p '<target code>' -l <lang> --debug-query=cst

# ast: named nodes only — a cleaner view for discovering node kinds
ast-grep -p '<target code>' -l <lang> --debug-query=ast
```

Omit `-l` only when extension-based language inference is likely to be correct. Include `-l` when using stdin, mixed-language folders, ambiguous extensions, or debugging a pattern.

## Pattern writing rules

Write patterns as valid code in the target language. ast-grep parses the pattern into an AST and matches syntax, not raw text.

Use metavariables:

- `$NAME` matches one AST node.
- `$$$NAME` matches zero or more AST nodes, commonly arguments, parameters, statements, array items, or object entries.
- Reusing the same metavariable name requires the same syntax to appear again.
- Names beginning with `_`, such as `$_`, are non-capturing wildcards.

Examples:

```bash
# JavaScript/TypeScript: find all console.log calls, regardless of arguments
ast-grep -p 'console.log($$$ARGS)' -l ts .

# TypeScript: find any call to a property/method with any args
ast-grep -p '$OBJ.$METHOD($$$ARGS)' -l ts src

# TypeScript: find optional-chaining refactor candidates
ast-grep -p '$PROP && $PROP()' -l ts src

# Python: find broad exception handlers
ast-grep -p 'except Exception as $E: $$$BODY' -l py .

# Python: find print calls
ast-grep -p 'print($$$ARGS)' -l py .

# Go: find fatal logging calls
ast-grep -p 'log.Fatal($$$ARGS)' -l go .

# Rust: find unwrap calls
ast-grep -p '$EXPR.unwrap()' -l rust .

# TSX/JSX: find components with a specific prop shape
ast-grep -p '<$COMP disabled={true} $$$PROPS />' -l tsx src
```

## Escalate from pattern to rule YAML

Use a YAML rule when a one-line pattern is too broad, when constraints are needed, or when the search will be reused.

Prefer `--inline-rules` for one-off searches — no temp file to create or clean up:

```bash
ast-grep scan --inline-rules '
id: find-console-log
language: TypeScript
rule:
  pattern: console.log($$$ARGS)' .
```

Write a `.yml` file (and run with `--rule`) only when the rule is genuinely reusable or lives in an ast-grep project:

```bash
ast-grep scan --rule /tmp/find-console-log.yml .
```

Add constraints when captured metavariables need filtering:

```yaml
id: numeric-console-log
language: JavaScript
rule:
  pattern: console.log($ARG)
constraints:
  ARG:
    kind: number
message: console.log called with a numeric literal
severity: info
```

Use `files` and `ignores` in reusable rules rather than piping through `rg`:

```yaml
id: no-prod-console-log
language: TypeScript
rule:
  pattern: console.log($$$ARGS)
files:
  - src/**/*.ts
ignores:
  - '**/*.test.ts'
  - '**/*.spec.ts'
message: avoid console.log in production code
severity: warning
```

Do not prefix YAML `files` or `ignores` entries with `./`; make them relative to the ast-grep project root.

### Switch cases need context

A `case` clause is not a complete TypeScript program, so give it a `switch` context:

```bash
ast-grep -p 'switch ($VALUE) { case $CASE: $$$BODY }' -l ts src
```

## Refinement loop

When results are wrong or empty:

1. Add `-l <lang>` if omitted.
2. Verify the pattern is valid code for that language.
3. Add surrounding syntax context instead of using a fragment that the parser cannot parse.
4. Run `--debug-query=pattern` to see how the pattern parsed, or `--debug-query=cst` on the target code to see what you must match.
5. Replace concrete code with metavariables one piece at a time.
6. Use `$$$ARGS` or `$$$BODY` when the number of nodes can vary.
7. For a relational rule (`inside`, `has`, `precedes`, `follows`) that returns nothing, add `stopBy: end` — by default the search stops at the immediate neighbor, so a deeper match is missed. This is the single most common cause of empty relational-rule results.
8. When a bare pattern is ambiguous or won't parse as a fragment, use the pattern object form to disambiguate:

   ```yaml
   rule:
     pattern:
       context: 'class C { $F }'   # surrounding code so the parser sees the right node
       selector: field_definition  # which node in the context is the actual matcher
       strictness: smart           # cst | smart | ast | relaxed | signature
   ```

9. Use a YAML rule with `constraints`, `kind`, `inside`, `has`, `precedes`, `follows`, `any`, `all`, or `not` when structure matters beyond a single pattern.
10. Only fall back to `rg` after trying a syntax-aware search and explaining why text search is more suitable.

Note: `ast-grep` exits with code 1 when there are simply no matches — that is not an error. For independent searches in one shell command, use separate commands, `;`, or `|| true`; `&&` stops at the first valid no-match.

## Blast radius before refactoring an API

Before changing a function, class, or module's public shape, search for its call sites and tests first, and report counts before touching anything:

```bash
ast-grep -p 'new WebhookService($$$ARGS)' -l ts .
ast-grep -p '$X.webhookService.$METHOD($$$ARGS)' -l ts .
ast-grep -p 'import { WebhookService } from $MOD' -l ts .
```

Report what was found (e.g. "3 instantiations, 12 callers of `deliverWebhook`, referenced in `webhook.service.test.ts`") before editing, so scope is known up front instead of discovered mid-refactor.

## Large migrations: classify variants, then codemod

For an API/framework migration touching many call sites:

1. Search broadly for the old API and count matches.
2. Group matches into structural variants (differing arg shapes, wrapped vs. bare calls, etc.) — a broad pattern plus a look at the matched snippets is usually enough.
3. Write the smallest `--rewrite` or YAML `fix` rule for the dominant variant; verify it against a representative snippet via stdin (see the dump → test → scan workflow above) before running it on the tree.
4. Apply with `--interactive` for review, or `--update-all` only once the rule is verified and the user has approved bulk changes.
5. Repeat per variant. Handle the small number of leftover/irregular cases by hand rather than forcing one rule to cover everything.

Prefer one verified deterministic rule applied to hundreds of matches over hand-editing each one — but never skip the verify-on-a-snippet step; an unverified rewrite rule applied with `--update-all` is how a migration turns into a rescue operation.

## Verify a change is actually complete

When a task's success condition is "no more occurrences of X" (e.g. "replace every direct `process.env` access with the config module", "route all webhook delivery through `deliverWebhook()`"), rerun the original search pattern after the edit and confirm it returns zero matches:

```bash
ast-grep -p 'process.env.$VAR' -l ts src/
```

Zero matches is the verifiable postcondition — don't rely on the diff looking complete or on having "gotten all of them" during editing.

## Reusable rule as an architecture guard

When a structural constraint should hold going forward (not just for one cleanup), write it as a named YAML rule with `severity: error` and check it with `ast-grep scan` alongside the project's normal verification (typecheck, lint, tests) rather than a one-off search — see the YAML rule examples above for the shape.

## Reporting results to the user

When presenting matches:

- State the ast-grep command used.
- Summarize what the pattern searched structurally.
- Include representative file paths and line references from the command output.
- Mention notable exclusions, language assumptions, and whether the search was exact, wildcarded, or constrained.
- If falling back to `rg`, say why ast-grep was not appropriate or did not work.

## Safe rewrite guidance

Do not apply rewrites unless the user asks for code changes. For exploratory refactors, show matches first.

When rewriting is requested:

```bash
ast-grep -p '<pattern>' --rewrite '<replacement>' -l <lang> --interactive <path>
```

Use `--interactive` for human-reviewed edits. Use `--update-all` only when the user explicitly approves bulk modification and the pattern has been validated on representative matches.

## Common translations from rg to ast-grep

Prefer these structural forms over text regexes:

```bash
# instead of: rg 'console\.log\('
ast-grep -p 'console.log($$$ARGS)' -l ts .

# instead of: rg 'import .* from'
ast-grep -p 'import { $$$IMPORTS } from "$MOD"' -l ts .

# instead of: rg 'useEffect\('
ast-grep -p 'useEffect($$$ARGS)' -l tsx src

# instead of: rg 'catch \(.*\)'
ast-grep -p 'try { $$$TRY } catch ($ERR) { $$$CATCH }' -l ts .

# instead of: rg 'if \(.*\) return'
ast-grep -p 'if ($COND) { return $RET }' -l ts .
```

## Fallback policy

Use `rg` after ast-grep only for:

- strings or comments that should be matched textually
- non-code files or unsupported languages
- generated/minified code where parsing is unreliable
- discovering candidate terms before a structural follow-up search
- repository inventory tasks such as listing filenames or config keys

If `rg` finds candidate syntax-shaped results, perform a second pass with ast-grep whenever feasible to reduce false positives.

