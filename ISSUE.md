> **Status (after filing):** already tracked in [oxc-project/oxc#27084](https://github.com/oxc-project/oxc/issues/27084) (oxlint matches type-aware line directives only against tsgolint's main range). Fix in progress: [oxc-project/oxc#27109](https://github.com/oxc-project/oxc/pull/27109). [oxc-project/tsgolint#1262](https://github.com/oxc-project/tsgolint/issues/1262) was closed as a duplicate.

**Title:** `no-unsafe-type-assertion`: `oxlint-disable-next-line` above a multi-line assertion no longer applies since 7.0.2002

---

### Summary

Since `oxlint-tsgolint@7.0.2002`, `// oxlint-disable-next-line typescript/no-unsafe-type-assertion` on the line before a multi-line `as` assertion no longer suppresses the diagnostic. It works with `7.0.2001`, and it is where typescript-eslint expects the comment. Single-line assertions are not affected.

### Reproduction

https://github.com/why-reproductions-are-required/oxlint-tsgolint-disable-next-line-multiline

```sh
git clone https://github.com/why-reproductions-are-required/oxlint-tsgolint-disable-next-line-multiline.git
cd oxlint-tsgolint-disable-next-line-multiline
npm ci
npm run lint
```

`oxlint@1.87.0`, `oxlint-tsgolint@7.0.2003`, only `typescript/no-unsafe-type-assertion` enabled:

```ts
declare const input: { a: number | string; b: number };

// oxlint-disable-next-line typescript/no-unsafe-type-assertion
export const single = { a: input.a } as { a: number };

// oxlint-disable-next-line typescript/no-unsafe-type-assertion
export const multi = {
  a: input.a,
  b: input.b,
} as { a: number; b: number };
```

**Actual:** the `multi` assertion is still reported (exit code 1).

**Expected:** no diagnostics, as with `7.0.2001`.

### Version comparison

`npm run compare` runs each pair in a fresh install:

| oxlint | oxlint-tsgolint | Result |
| --- | --- | --- |
| 1.85.0 | 7.0.2001 | exit 0 |
| 1.85.0 | 7.0.2002 | exit 1 |
| 1.85.0 | 7.0.2003 | exit 1 |
| 1.87.0 | 7.0.2003 | exit 1 |

### Cause

#1111 (part of #677) changed the rule's primary range from the whole assertion node (`ctx.ReportNode(node, ...)`) to `getAssertionRange`, which runs from the `as` keyword to the end of the asserted type. The expression is now a secondary label. oxlint matches `disable-next-line` against the primary span, which is now on the `} as { ... }` line:

```
line 10 col 22 len 31  Original expression has type `{ a: string | number; b: number; }`.
line 13 col 6  len 24  Asserted type is `{ a: number; b: number; }`.
line 13 col 3  len 27  (primary, unlabeled)
```

typescript-eslint reports this rule on the whole node, so existing suppressions in projects that migrated from `@typescript-eslint` (or that were written against `7.0.2001`) stop working after upgrading. With `reportUnusedDisableDirectives` enabled, each old directive also becomes an "Unused oxlint-disable directive" error. We hit this in four real projects while smoke-testing oxlint 1.87 / tsgolint 7.0.2003.

The `unix` and `github` reporters print the first label's position (`10:22`), so the output suggests the reported line is the one directly after the directive, which makes this hard to diagnose.

### Possible fixes

- Keep the whole assertion node as the primary range (matching typescript-eslint) and keep the new labels for the expression and asserted type, or
- If the narrower primary range is intended, suppression should consider where the diagnostic starts, not only the primary span. That part may belong in oxlint.

### Workarounds

- Move the directive to the line before `} as { ... }`.
- Use an `oxlint-disable` / `oxlint-enable` block around the statement.

### Environment

- oxlint 1.87.0, oxlint-tsgolint 7.0.2003 (also reproduced with oxlint 1.85.0)
- macOS arm64, Node 22.18.0

Related: #769 (the "Disable for this line" code action places the comment on the wrong line for a different rule).
