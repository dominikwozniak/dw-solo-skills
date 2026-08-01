# The optional pre-commit — detection, mapping, shapes

Detail for `dw-init` step 5. Consolidated from the team lane's standalone pre-commit skill and
trimmed for one reader: the same wiring, one consent gate instead of five.

## Detection signals

Confirm a tool from any of these before wiring it. Ground the choice in something real — never
assume a config exists.

| Tool          | Signals (any one is enough)                                                                                |
| ------------- | ---------------------------------------------------------------------------------------------------------- |
| **prettier**  | `prettier` dep · `.prettierrc*` / `prettier.config.*` · `prettier` key in `package.json` · `format` script |
| **eslint**    | `eslint` dep · `eslint.config.*` / `.eslintrc*` · `lint` script                                            |
| **biome**     | `@biomejs/biome` dep · `biome.json` / `biome.jsonc`                                                        |
| **typecheck** | a `typecheck` script in `package.json` (don't infer from `tsconfig.json` alone)                            |
| **test**      | a `test` script in `package.json`                                                                          |

Biome is a combined formatter **and** linter — if it's the toolchain, one
`pnpm exec biome check --write` entry covers both; don't also wire prettier + eslint over the same
globs.

## Glob → command mapping (examples — adapt to what's detected)

All commands run via `pnpm exec`. Order matters: format first, then lint-fix, so the linter sees
formatted code. lint-staged passes the staged paths to each command, so `--write` / `--fix` operate
on exactly the files in the commit. Don't add a glob for a tool that isn't installed.

| Stack present       | Glob                        | Commands                                                 |
| ------------------- | --------------------------- | -------------------------------------------------------- |
| prettier + eslint   | `*.{js,jsx,ts,tsx,mjs,cjs}` | `pnpm exec prettier --write`, `pnpm exec eslint --fix`   |
| prettier only       | `*.{js,jsx,ts,tsx,mjs,cjs}` | `pnpm exec prettier --write`                             |
| prettier (non-code) | `*.{json,md,yml,yaml,css}`  | `pnpm exec prettier --write`                             |
| biome               | `*.{js,jsx,ts,tsx,json}`    | `pnpm exec biome check --write --no-errors-on-unmatched` |
| eslint, no prettier | `*.{js,jsx,ts,tsx}`         | `pnpm exec eslint --fix`                                 |

## The `.husky/pre-commit` shape

```
pnpm exec lint-staged

# Optional, opt-in at the dw-init gate. Uncomment only the lines whose script
# exists and you asked for — both run the WHOLE project on every commit, so
# they make commits slower and are often better left to CI.
# pnpm run typecheck
# pnpm run test
```

## The `.lintstagedrc.json` shape (prettier + eslint case)

```json
{
  "*.{js,jsx,ts,tsx,mjs,cjs}": ["pnpm exec prettier --write", "pnpm exec eslint --fix"],
  "*.{json,md,yml,yaml,css}": ["pnpm exec prettier --write"]
}
```

## Idempotent re-run

`dw-init` may run on a repo that's partly set up. Before writing:

- **`.husky/pre-commit` exists** — read it. If `pnpm exec lint-staged` is already there, don't
  duplicate; only add opted-in typecheck/test lines that are missing. Show the diff at the gate.
- **lint-staged config exists** (`.lintstagedrc*` or a `package.json` key) — merge into it rather
  than overwriting; surface any glob whose command points at a tool that's no longer installed.
- **husky / lint-staged already deps** — skip the install, keep the rest.
- **`"prepare": "husky"` already present** — leave it.

Never blow away existing config blind. The contract is fill-the-gaps + show-diffs, not replace.
