# Backlog

Follow-ups and ideas not being worked on now. Newest first, one line each. The bar: if you would not
pick it up within a month, don't write it. The closing pass parks them here; the shaping step reads
this when opening the next change and deletes the line it takes.

- [2026-08-01] Fix `block-env-access.sh` so a commit message naming a dotenv file isn't blocked: the
  quoted-prose escape only survives `-m "…"`, not a heredoc. **Vendored from `dw-skills`** — apply the
  fix in both repos, and extend `scripts/tests/block-env-access.test.sh` with the heredoc case.
- [2026-08-01] Give `typecheck-on-stop.sh` a way to say "this repo has no typecheck". It `eval`s the
  `**Typecheck command**` value from `CLAUDE.local.md`, and the only value it skips is the
  `{{TYPECHECK_COMMAND}}` placeholder — which the same template's closing section calls a mistake.
- [2026-08-01] `EnterWorktree` doesn't fire `SessionStart`, so no `SessionStart` hook runs when a
  session enters a worktree mid-flight. `0003` routed `CLAUDE.local.md` around it; any other such hook
  is still silently skipped.
- [2026-08-01] Test sweep for the untested shell: `doctor.sh` (261 lines, and the only script that
  runs on someone else's machine), `block-non-pnpm`, `link-local-memory`, `lint-on-edit`,
  `typecheck-on-stop`, plus fixtures for `validate-docs.sh` and `validate-manifests.sh` — `717f1e5`
  is proof a validator can pass silently while broken.
- [2026-08-01] A "shared repo" placement option in `dw-init`: when two people knowingly use these
  skills in one repo, `## Git conventions` (and maybe `## Workflow`) belong in tracked `CLAUDE.md`
  rather than `CLAUDE.local.md`. Decide after real usage.
- [2026-08-01] Delta evals for the skills (the software-mansion pattern: with/without-skill runs,
  `should_trigger: false` negatives, contains/not_contains assertions) — worth wiring once the skill
  set stabilizes.
