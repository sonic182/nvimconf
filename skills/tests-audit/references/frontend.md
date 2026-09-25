# Frontend (JS/TS unit, component, browser e2e)

On-demand reference for `tests-audit`. Read when the tests in scope are
Vitest/Jest unit or component tests (including web components such as Lit), or
browser e2e (Playwright).

## Commands

| Purpose | Command |
| --- | --- |
| Focused unit | `npx vitest run src/cart.test.ts -t "applies discount"` or `npx jest src/cart.test.ts -t "applies discount"` |
| Focused e2e | `npx playwright test e2e/checkout.spec.ts:30 --project=chromium` |
| Scoped suite (baseline) | the directory form of the above |
| Mutation targets | `npx vitest run <keeper> --coverage` / `npx jest <keeper> --coverage` to list the lines the keeper executes (execution, not assertion) |
| Gate | the project's lint and typecheck (`eslint <paths>`, `tsc --noEmit`) |

Use whichever runner the project already has. Mutation check: edit one
production line the keeper should guard, rerun the focused command, confirm
red, restore.

## Junk patterns

- `toMatchSnapshot()` / `toMatchInlineSnapshot()` on a whole rendered tree that
  nobody reads; replace with assertions on the user-visible contract.
- Queries by CSS class, tag nesting, or shadow-DOM internals when a role,
  label, or text query would express the contract.
- Assertions on component state, props, private fields, or reactive
  properties instead of the rendered result or dispatched events.
- `vi.mock` / `jest.mock` of the module under test.
- Per-test `fetch` mocks that re-implement the API, where a network-level fake
  (MSW, Playwright `page.route`) is the real boundary.
- `waitForTimeout` / `setTimeout` sleeps instead of web-first assertions
  (`await expect(locator).toBeVisible()`) or fake timers.
- e2e specs that replay what a component test already owns, or component tests
  that replay a critical flow the e2e spec owns.
- Server-rendered UI (LiveView, templates, HTMX) asserted in the backend suite
  and again in the browser for the same contract; keep the browser test only
  for what needs JS or real layout.

## Production seams to delete

- `export`s that only tests import.
- `__resetForTests()`-style helpers and test-only globals on `window`.
- `data-testid` on elements that already have an accessible role or name;
  keep it where no accessible query exists.

## Keepers to prefer

- User-visible behavior through the accessible tree (Testing Library
  `getByRole`, Playwright `getByRole`/`getByLabel`).
- One e2e spec per critical user flow, against a fake or seeded backend.
- Component tests for logic-heavy widgets (parsing, formatting, keyboard
  handling), not for static markup.

## Discovery recipes

```bash
rg -n 'toMatch(Inline)?Snapshot' --glob '*.{test,spec}.*'
rg -n 'waitForTimeout|setTimeout\(' --glob '*.{test,spec}.*'
rg -n '(vi|jest)\.mock\(' --glob '*.{test,spec}.*'
rg -n 'querySelector|\.shadowRoot|getByTestId' --glob '*.{test,spec}.*'
```
