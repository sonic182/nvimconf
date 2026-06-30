---
name: ast-grep-find
description: use ast-grep for structural code search before falling back to ripgrep or plain text search. apply when locating functions, calls, imports, JSX, decorators, error handling, unsafe APIs, duplicated expressions, refactor targets, or any code pattern where syntax-aware matching is more reliable than text matching.
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

Useful flags:

```bash
# show context around matches
ast-grep -p '<pattern>' -l <lang> -C 3 <path>

# output structured results for machine inspection
ast-grep -p '<pattern>' -l <lang> --json=pretty <path>

# restrict or exclude files
ast-grep -p '<pattern>' -l <lang> --globs 'src/**/*.ts' --globs '!**/*.test.ts' .

# inspect how the pattern is parsed
ast-grep -p '<pattern>' -l <lang> --debug-query=ast
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

Create a temporary rule file outside the source tree or in a scratch location:

```yaml
id: find-console-log
language: TypeScript
rule:
  pattern: console.log($$$ARGS)
message: found console.log
severity: info
```

Run it:

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

## Refinement loop

When results are wrong or empty:

1. Add `-l <lang>` if omitted.
2. Verify the pattern is valid code for that language.
3. Add surrounding syntax context instead of using a fragment that the parser cannot parse.
4. Run `--debug-query=ast` to inspect how the pattern is parsed.
5. Replace concrete code with metavariables one piece at a time.
6. Use `$$$ARGS` or `$$$BODY` when the number of nodes can vary.
7. Use a YAML rule with `constraints`, `kind`, `inside`, `has`, `precedes`, `follows`, `any`, `all`, or `not` when structure matters beyond a single pattern.
8. Only fall back to `rg` after trying a syntax-aware search and explaining why text search is more suitable.

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

