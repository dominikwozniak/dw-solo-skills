# Backlog

Follow-ups and ideas not being worked on now. Newest first, one line each. The bar: if you would not
pick it up within a month, don't write it. The closing pass parks them here; the shaping step reads
this when opening the next change and deletes the line it takes.

- [2026-08-02] `pnpm-v11-payload` — teach `templates/`, `dw-init` and `dw-doctor` the pnpm 11 setup
  this repo now runs. Two measured findings drive it, both in PR #2: pnpm's warning about an orphaned
  `package.json#pnpm` block names **only** keys on its own relocation list (a second, equally dead key
  in the same block went unmentioned), so doctor check D1 must flag the block's existence rather than
  trust the warning; and `lockfileVersion` still reads `'9.0'` under v11 while the contents are no
  longer v10-compatible, so detect a migrated lockfile via `packageManagerDependencies`, not the
  version field. Also: `doctor.sh:99-113` still advises `corepack enable`, wrong under v11.
- [2026-08-02] Bump `pnpm/action-setup` past v4 in both workflows. The pinned SHA predates
  `devEngines` support and reads only `packageManager`; newer versions read `devEngines` and give it
  priority. Bumping retires the duplicated-version hazard and would let `packageManager` be dropped.
- [2026-08-02] Loop friction, run 2 (`dw-ship`/`dw-land`): a task whose done-condition is "CI passes"
  cannot be proven before the PR exists, so it cannot be landed before it is shipped — the reverse of
  the order `dw-ship` states. Workflows here only trigger on `pull_request` or a push to `main`, and
  there is no `workflow_dispatch`. Either the skills should name the PR-first path, or CI should gain
  a manual trigger.
- [2026-08-02] Decide `.nvmrc` / `engines.node` versus `devEngines.runtime`, parked deliberately by
  the pnpm 11 migration: CI pins Node via `node-version-file: .nvmrc`, and `onFail: "download"` would
  have pnpm fetch its own Node.
- [2026-08-02] An "optional companions" section in `dw-doctor`'s `doctor.sh`: WARN-tier (never
  FAIL) checks for `codex` on PATH + the `openai-codex` plugin dir (fix: `/codex:setup`), `ctx7`
  (fix: `pnpm add -g ctx7`), and `rtk` (fix: https://github.com/rtk-ai/rtk) — accelerators the
  loop now names, not guardrails. Cap codex depth at pointing to `/codex:setup`; never probe auth.
- [2026-08-02] `validate-manifests.sh` can't see a version collision: it checks marketplace.json and
  plugin.json are **equal**, never that the version grew. Two parallel changes both bumping `dw-solo`
  0.4.0 → 0.4.1 auto-merged with no conflict and no warning — caught by hand on 2026-08-02. Compare
  against the version on the default branch instead.
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
