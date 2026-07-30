# dw-setup-precommit — detection & mapping reference

Detail the SKILL.md workflow points at. Read this when detecting tooling (step 2)
or re-running on a repo that's already partly wired.

## Detection signals

Confirm a tool from any of these before wiring it. Ground the choice in something
real — never assume a config exists.

| Tool          | Signals (any one is enough)                                                                                |
| ------------- | ---------------------------------------------------------------------------------------------------------- |
| **prettier**  | `prettier` dep · `.prettierrc*` / `prettier.config.*` · `prettier` key in `package.json` · `format` script |
| **eslint**    | `eslint` dep · `eslint.config.*` / `.eslintrc*` · `lint` script                                            |
| **biome**     | `@biomejs/biome` dep · `biome.json` / `biome.jsonc`                                                        |
| **oxlint**    | `oxlint` dep · `.oxlintrc.json`                                                                            |
| **typecheck** | a `typecheck` script in `package.json` (don't infer from `tsconfig.json` alone)                            |
| **test**      | a `test` script in `package.json`                                                                          |

Biome is a combined formatter **and** linter — if it's the toolchain, one
`pnpm exec biome check --write` entry covers both; don't also wire prettier +
eslint over the same globs.

## Glob → command mapping (examples — adapt to what's detected)

All commands run via `pnpm exec`. Order matters: format first, then lint-fix, so
the linter sees formatted code.

| Stack present       | Glob                        | Commands                                                 |
| ------------------- | --------------------------- | -------------------------------------------------------- |
| prettier + eslint   | `*.{js,jsx,ts,tsx,mjs,cjs}` | `pnpm exec prettier --write`, `pnpm exec eslint --fix`   |
| prettier only       | `*.{js,jsx,ts,tsx,mjs,cjs}` | `pnpm exec prettier --write`                             |
| prettier (non-code) | `*.{json,md,yml,yaml,css}`  | `pnpm exec prettier --write`                             |
| biome               | `*.{js,jsx,ts,tsx,json}`    | `pnpm exec biome check --write --no-errors-on-unmatched` |
| eslint, no prettier | `*.{js,jsx,ts,tsx}`         | `pnpm exec eslint --fix`                                 |

lint-staged passes the staged paths to each command, so `--write` / `--fix`
operate on exactly the files in the commit. Don't add a glob for a tool that
isn't installed.

## Consent question bank (step 3)

Ask these at the single HARD STOP gate, not scattered:

1. **Install the shared config?** "This writes `.husky/pre-commit` +
   `.lintstagedrc.json` and adds husky + lint-staged. It's committed to the repo
   and runs on every teammate's `git commit`. Proceed?"
2. **No formatter found — add prettier?** Only if step 2 found none. "Nothing
   formats this repo yet. Add prettier as a dev dep and format staged files? (You
   can decline and wire lint-only.)"
3. **Add `pnpm run typecheck` to the hook?** Only if the script exists. "Warning:
   typechecks the whole project on every commit — slower commits. Often better in
   CI. Add it?"
4. **Add `pnpm run test`?** Only if the script exists. Same slowness warning.
5. **Enforce pnpm at the git level?** "Add `only-allow pnpm` preinstall +
   `engine-strict` + corepack `packageManager`, so teammates can't use npm/yarn?
   (This is the git twin of the repo's `block-non-pnpm` Claude hook.)"

## Idempotent re-run

The skill may run on a repo that's partly set up. Before writing:

- **`.husky/pre-commit` exists** — read it. If `pnpm exec lint-staged` is already
  there, don't duplicate; only add opted-in typecheck/test lines that are missing.
  Show the diff at the gate before changing it.
- **lint-staged config exists** (`.lintstagedrc*` or a `package.json` key) — merge
  into it rather than overwriting; surface any glob whose command points at a tool
  that's no longer installed.
- **husky / lint-staged already deps** — skip the install, keep the rest.
- **`"prepare": "husky"` already present** — leave it.

Never blow away existing config blind. The contract is fill-the-gaps + show-diffs,
not replace.
