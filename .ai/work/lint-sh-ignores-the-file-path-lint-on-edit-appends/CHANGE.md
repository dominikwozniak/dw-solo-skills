---
change: lint-sh-ignores-the-file-path-lint-on-edit-appends
branch: lint-sh-ignores-the-file-path-lint-on-edit-appends
created: 2026-08-15
status: building
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

- [x] 1. Forward arguments in `scripts/lint.sh`, defaulting to `.` when none are given, and drop the
      hardcoded `.` from `lint:fix` in `package.json`. Must be bash 3.2 safe: `set -u` plus an empty
      `"$@"` is an unbound-variable error on macOS's system bash, so branch on `$#` into an array
      rather than expanding `"$@"` bare.
- [x] 2. Add `scripts/tests/lint.test.sh` — a temp dir with a stub `node_modules/.bin/agnix` that
      records its argv, asserting: no args → `.`; one path → exactly that path; two paths → both, no
      `.`; a stub printing `terminated abnormally` still exits 1 even at exit code 0.
- [x] 3. Correct the docs the fix falsifies: `docs/agents/tooling.md:51–53` (the `lint-on-edit.sh`
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

**Task 1:** `lint:fix` lost the dot outright rather than gaining a `"$@"` — `agnix`'s own
`[PATHS]... [default: .]` already walks the tree when handed nothing, so `agnix --fix` covers both
the bare and the pathed call with no wrapper. Only `lint` needs a script, and only because of the
`terminated abnormally` grep. Scoping confirmed against the real binary: bare is 57 warnings,
`skills/dw-next/SKILL.md` is 1 info message.

**Task 2:** the test was run against the pre-fix script before being trusted — reverting `lint.sh` to
the hardcoded dot fails exactly the three argv cases (`one-path-forwarded`, `two-paths-forwarded`,
`spaced-path-not-split`) and passes the other ten, which is the shape a regression test should have.
Two cases beyond the shape earned their place: the spaced path (a `"$@"` that degrades to `$@` splits
it, and nothing else would notice) and `NODE_OPTIONS` reaching the stub (dropping the memory bump
looks harmless and re-opens the OOM). 13 cases, all green.

**Task 3 — a gotcha the capability creates, worth promoting to `docs/agents/tooling.md`'s Gotchas at
land time:** scoping now makes the `.agnix.toml` exclude list bypassable in practice, not just in
theory. `bash scripts/lint.sh docs/agents/tooling.md` reports **1 error** ("Agent file must have YAML
frontmatter") on a file the bare run never touches, because `docs/agents/**` is excluded from the
project walk and an explicit path is linted regardless. Bare `pnpm lint` is unchanged at 0 errors, 57
warnings. Nothing in the automated path hits this — `lint-on-edit` filters to `.ts/.js` and
`.husky/pre-commit` filters `templates/` itself — but a human scoping a lint by hand will.

Task 3 stayed off `.agnix.toml` and the shipped `templates/hooks/lint-on-edit.sh` on purpose. The
config comment ("an exclude only applies to the project walk") is still true, and the shipped hook's
"there is no `package.json scripts.lint` fallback: `pnpm lint` lints the whole project" is a claim
about an arbitrary target repo, not about this one — editing it would be a payload change needing a
plugin bump, for a sentence that has not become false. No manifest bump in this change: `scripts/`
and `docs/agents/` are repo tooling, and `.husky/pre-commit` is repo-local, none of them payload.

**`dw-check` (bare, self-review) — no correctness findings, two fit findings, both shipped:**

- The header added in task 1 made `scripts/lint.sh` a **third** home for "an exclude governs the
  project walk only" — after `.agnix.toml`'s NOTE and `.husky/pre-commit`'s local restatement. Landed
  one commit after `43c367c`, the change whose entire subject is that a fact lives in exactly one
  file. Trimmed to what the script owns, plus a pointer. **The trap generalises: a header written to
  explain a fix is the easiest place to re-copy a fact, because at that moment restating it feels
  like context rather than duplication.**
- `templates/hooks/lint-on-edit.sh:17` said `pnpm lint` lints the whole project — true of an
  arbitrary target repo, no longer true of this one, and this repo is an instance of what the
  template scaffolds. Reworded to the claim that survives: a **declared** Lint command is a promise
  it accepts a path, a script found by guessing is not. `.claude/hooks/` re-synced (`cmp`-identical,
  `hooks-in-sync` 33/33) and `dw-solo-setup` bumped `0.1.21` → `0.1.22` in both manifests.

**Contract verified end to end, not just unit-tested:** `pnpm lint <path>` forwards through pnpm
without `--` (1 info on the named file vs the tree's 57 warnings), and the real hook fed a real
`Write` event for `evals/routing.ts` exits 0. Locally `pnpm lint` must be run as `rtk proxy pnpm lint`
— the rtk hijack `tooling.md:96` documents, not a repo failure.

In this repo `lint-on-edit.sh` only ever fires on `evals/*.ts`, `scripts/*.mjs` and
`templates/check-agents-docs.mjs` — none of which agnix has rules for — so the practical win here is
speed and a true contract, not new findings. The contract matters for repos scaffolded from
`templates/`, where the same bullet is read by the same hook.
