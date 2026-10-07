# oxlint-tsgolint: `oxlint-disable-next-line` no longer suppresses multi-line `no-unsafe-type-assertion`

Since `oxlint-tsgolint@7.0.2002`, a `// oxlint-disable-next-line typescript/no-unsafe-type-assertion` comment on the line before a multi-line `as` assertion no longer suppresses the diagnostic. It works with `oxlint-tsgolint@7.0.2001`. Single-line assertions are not affected.

## Reproduce

Use Node `22.18.0` (the version in `.nvmrc`):

```sh
git clone https://github.com/why-reproductions-are-required/oxlint-tsgolint-disable-next-line-multiline.git
cd oxlint-tsgolint-disable-next-line-multiline
npm ci
npm run lint
```

This installs `oxlint@1.87.0` and `oxlint-tsgolint@7.0.2003` (the latest releases) and lints [`src/index.ts`](src/index.ts) with only `typescript/no-unsafe-type-assertion` enabled:

```ts
declare const input: { a: number | string; b: number };

// Single-line assertion: the directive applies.
// oxlint-disable-next-line typescript/no-unsafe-type-assertion
export const single = { a: input.a } as { a: number };

// Multi-line assertion: the directive is on the line before the expression
// starts, exactly where typescript-eslint expects it.
// oxlint-disable-next-line typescript/no-unsafe-type-assertion
export const multi = {
  a: input.a,
  b: input.b,
} as { a: number; b: number };
```

**Actual:** exit code 1.

```
src/index.ts:10:22: error typescript(no-unsafe-type-assertion): Unsafe type assertion: type '{ a: number; b: number; }' is more narrow than the original type.
```

**Expected:** exit code 0. Both assertions are covered by a directive on the line before the expression.

## Compare versions

`npm run compare` installs each pair in a temporary directory and lints the same files. oxlint stays at `1.85.0` for the first three rows, so only `oxlint-tsgolint` changes:

| oxlint | oxlint-tsgolint | Result |
| --- | --- | --- |
| 1.85.0 | 7.0.2001 | exit 0 |
| 1.85.0 | 7.0.2002 | exit 1, `src/index.ts:10:22` |
| 1.85.0 | 7.0.2003 | exit 1, `src/index.ts:10:22` |
| 1.87.0 | 7.0.2003 | exit 1, `src/index.ts:10:22` |

## Cause

[oxc-project/tsgolint#1111](https://github.com/oxc-project/tsgolint/pull/1111), released in `7.0.2002`, changed the rule's primary range. It used to report the whole assertion node (`ctx.ReportNode(node, ...)`). It now reports from the `as` keyword to the end of the asserted type (`getAssertionRange`), and the expression becomes a secondary label.

`oxlint --type-aware -f json src` with `7.0.2003` shows the primary span on line 13, while the directive targets line 10:

```
line 10 col 22 len 31  Original expression has type `{ a: string | number; b: number; }`.
line 13 col 6  len 24  Asserted type is `{ a: number; b: number; }`.
line 13 col 3  len 27  (primary, unlabeled)
```

With `7.0.2001`, the diagnostic had one span starting at line 10, col 22, covering the whole assertion, so the directive matched. typescript-eslint also reports this rule on the whole node, so `eslint-disable-next-line` above the expression works there.

The `unix` and `github` reporters print the first label's position (`10:22`), which makes it look as if the reported line is the one right after the directive.

## Workarounds

- Move the directive to the line before `} as { ... }`.
- Wrap the statement in `// oxlint-disable typescript/no-unsafe-type-assertion` and `// oxlint-enable typescript/no-unsafe-type-assertion`.
