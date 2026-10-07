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
