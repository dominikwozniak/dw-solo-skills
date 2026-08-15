---
change: lint-sh-ignores-the-file-path-lint-on-edit-appends
branch: lint-sh-ignores-the-file-path-lint-on-edit-appends
created: 2026-08-15
status: shaping
---

# Change — `scripts/lint.sh` lints the paths it is handed, instead of always walking the tree

## Goal

`bash scripts/lint.sh path/to/file.md` lints only that file; with no arguments it still walks the
whole tree as today. That makes `AGENTS.md`'s "`lint-on-edit` appends one file path to the first, so
it must accept one" true rather than aspirational, and turns every edit under `evals/` from a
full-tree walk into a single-file check. Verified by a new `scripts/tests/lint.test.sh` that stubs
`agnix` and asserts the argv it receives, and by `pnpm validate:artifacts` staying green.

## Decisions

- **`lint.sh` stays a thin pass-through — it does not filter `templates/`** — `.husky/pre-commit`
  filters because it builds the path list itself from the staged set; a human or hook naming a path
  explicitly is making an explicit request, and a script that silently drops arguments is the same
  class of bug this change is fixing.
- **`lint:fix` gets the same treatment in the same commit** — `agnix --fix .` hardcodes the dot, so
  `pnpm lint:fix <path>` today lints the path _in addition to_ the whole tree. Same one-line class of
  bug, same file, no reason to leave the asymmetry behind.
- **`.husky/pre-commit` keeps calling `agnix` directly** — it needs `--fix` and a re-stage, which
  `lint.sh` does not do. Only its comment's rationale ("the repo `lint` script runs agnix over the
  whole tree") stops being true and gets corrected.
- **`NODE_OPTIONS=--max-old-space-size=8192` stays unconditional** — only the full walk needs it, but
  branching on argument count to save nothing is ceremony.

## Tasks

- [ ] 1. Forward arguments in `scripts/lint.sh`, defaulting to `.` when none are given, and drop the
      hardcoded `.` from `lint:fix` in `package.json`. Must be bash 3.2 safe: `set -u` plus an empty
      `"$@"` is an unbound-variable error on macOS's system bash, so branch on `$#` into an array
      rather than expanding `"$@"` bare.
- [ ] 2. Add `scripts/tests/lint.test.sh` — a temp dir with a stub `node_modules/.bin/agnix` that
      records its argv, asserting: no args → `.`; one path → exactly that path; two paths → both, no
      `.`; a stub printing `terminated abnormally` still exits 1 even at exit code 0.
- [ ] 3. Correct the docs the fix falsifies: `docs/agents/tooling.md:51–53` (the `lint-on-edit.sh`
      paragraph asserting the argument is ignored), its OOM gotcha at `:103` (the workaround is now
      `pnpm lint <path>`), and the stale rationale comment in `.husky/pre-commit`.

## Anchors

- `scripts/lint.sh:3` — `node_modules/.bin/agnix .`, the hardcoded dot this change replaces. The
  `terminated abnormally` grep below it must survive untouched.
- `.claude/hooks/lint-on-edit.sh:120` — `"$@" "$file_path"`, the append that makes the contract. The
  hook resolves `pnpm lint` from `AGENTS.md`, so `pnpm` must forward the extra arg to the script
  (it does, without `--`).
- `.husky/pre-commit:6–8` — the comment saying never to call the repo `lint` script here, and the
  `xargs pnpm exec agnix --fix` line that is the working precedent for handing agnix explicit paths.
- `.agnix.toml:12–14` — the note that an exclude governs only the project walk, not an explicit
  path. This is why the `templates/` decision above is a decision and not an oversight.
- `agnix --help` — `[PATHS]... [default: .]`, "when multiple paths are passed (e.g. from a pre-commit
  hook), only those paths are checked". The CLI already supports exactly this.
- `scripts/tests/lint-on-edit.test.sh` — the shape task 2 copies for stubbing and argv assertions.

## Notes

Prior context: this was parked at shape time by `the-doc-layer-says-one-thing-once`
(`.ai/archive/the-doc-layer-says-one-thing-once/CHANGE.md:124`) on the grounds that a docs change
must not change lint behaviour. Task 3 is the other half of that entry finally landing.

In this repo `lint-on-edit.sh` only ever fires on `evals/*.ts`, `scripts/*.mjs` and
`templates/check-agents-docs.mjs` — none of which agnix has rules for — so the practical win here is
speed and a true contract, not new findings. The contract matters for repos scaffolded from
`templates/`, where the same bullet is read by the same hook.
