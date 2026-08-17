---
created: 2026-08-17
source: land-opens-the-pr-and-ship-only-merges
---

# `pnpm lint <path>` misroutes to `eslint`, so `lint-on-edit` lints nothing

The declared **Lint command** is `pnpm lint` and the hook appends one file path — but the pnpm
shorthand with an argument resolves away from the `lint` script and dies on `Command "eslint" not
found`, exit 0, output `undefined`. Bare `pnpm lint` and `pnpm run lint <path>` both work, so the
guardrail has been silently passing since the shorthand was declared. Whether the fix is the bullet
(`pnpm run lint`), `scripts/lint.sh`, or the hook's invocation is the decision to make.
