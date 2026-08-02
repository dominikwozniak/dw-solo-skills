# dw-solo-skills — agent instructions

A Claude Code skills catalog for repos only you read, distributed as an installable plugin
marketplace — not a code project.

The fuller, team-weight lane lives in a separate repo,
[`dw-skills`](https://github.com/dominikwozniak/dw-skills). Keep this one thin: every skill here
assumes **one reader**, and a change that needs a second reader's trust belongs there instead.

## Layout — and the one rule

```
skills/<name>/SKILL.md           the canon for every skill. EDIT HERE.
plugins/dw-solo/                 the loop plugin — plugin.json + symlinks (mode 120000) → the canon
plugins/dw-solo-setup/           the setup plugin — dw-init, dw-doctor, the templates symlink
scripts/runtime/<script>.sh      shipped scripts — symlinked into the owning plugin
scripts/<script>.sh              repo CI tooling, never shipped (validate-*.sh, lint.sh)
scripts/tests/<script>.test.sh   bash self-tests
templates/                       payload copied verbatim INTO a target project (hooks, settings.json)
.claude-plugin/marketplace.json  makes this repo installable as a plugin source
```

**Always edit the canon above; use it instead of any `plugins/…` path**, since every one of those is
a symlink back to it — `plugins/*/skills/`, `scripts/` and `templates/` alike. Every canon skill is
shipped by exactly one plugin; `validate-manifests.sh` enforces the ownership in both directions.

Skill bodies invoke a shipped script as `${CLAUDE_PLUGIN_ROOT}/scripts/<script>.sh` — install
dereferences the symlink, so the path resolves. A script used by only **one** skill needs no canon:
bundle it in `skills/<name>/scripts/` and invoke it via `<this-skill-dir>/…`.
Why it's built this way: [`docs/DESIGN.md`](docs/DESIGN.md), "The symlink canon".

## Vendored from `dw-skills` — fix in both

These are **copies**, not references, and nothing can detect drift across the repo boundary:

- `templates/hooks/*.sh` (6 files — the team repo also ships a Ruby lint hook this Node-only lane
  deliberately drops; don't "re-sync" it back). `scripts/tests/hooks-in-sync.test.sh` only pins them
  to _this_ repo's `.claude/hooks/`.
- `scripts/runtime/slugify.sh` — byte-identical.

A skill copied from `dw-skills` is a **fork**, simplified for one reader — expected to diverge, never
re-synced. Current forks: `dw-grill`, `dw-shape`, `dw-next`, `dw-land`, `dw-git`, `dw-doctor`,
`dw-init` (which also absorbed the team lane's standalone pre-commit skill). `dw-start`, `dw-check`,
`dw-ship` and `scripts/runtime/worktree.sh` are this lane's own — they have no upstream.

## Adding a skill

1. `skills/<name>/SKILL.md` — kebab-case `name` matching the directory (the validators' regex is
   `dw-[a-z-]+` — lowercase letters and hyphens only, no digits), a `description` that is routing
   signal only, `disable-model-invocation: true` if explicit-invoke only. Shape:
   [`docs/SKILL-ANATOMY.md`](docs/SKILL-ANATOMY.md) — copy a near neighbour and keep the section
   order.
2. `ln -s ../../../skills/<name> plugins/<plugin>/skills/<name>` in the **owning** plugin and
   `git add` the symlink — exactly one plugin per skill.
3. Bump the owning plugin's patch version in **both** `.claude-plugin/marketplace.json` and its
   `plugin.json` — keep the two identical. One bump covers a train of skills landing together.
4. Name the skill everywhere the docs list skills: the README **task-router** row, the **loop
   diagram** in README + `docs/DESIGN.md` if it joins the core loop (honor-system — no validator
   reads the diagram), and — if explicit-invoke — the `⭑` marker plus the explicit-only lists in
   README **and** `docs/DESIGN.md`.
5. End the body with a `**Next:**` line naming a skill that exists **in this repo** — a pointer at a
   team-lane skill is a dead end here, and `validate:docs` fails it. A cycle of new skills lands its
   `**Next:**` lines in one wiring commit at the end; `validate:docs` only checks pointers that
   exist.
6. `pnpm lint && pnpm format && pnpm validate:manifests && pnpm validate:docs`.

Steps 2–5 are CI-enforced (bar the loop diagram, and CI checks the versions are _equal_, not that
they changed). The validators name the exact missing entry — run them rather than re-deriving the
checklist by hand.

## Adding a shipped (plugin-level) script

1. Put the real file once at `scripts/runtime/<script>.sh` and `chmod +x` it.
2. `ln -s ../../../scripts/runtime/<script>.sh plugins/<plugin>/scripts/<script>.sh` in every plugin
   whose skills invoke it, and `git add` the symlink (must be mode 120000).
3. Add the basename to `RUNTIME_SCRIPTS` in `scripts/validate-manifests.sh`, plus a
   `scripts/tests/<script>.test.sh` where it has logic worth pinning (anchor it to the repo root via
   `git rev-parse --show-toplevel`).

## Commands

This repo is Markdown / JSON / Shell — there is no build step and no typecheck.

- **Test**: `pnpm validate:artifacts` (the bash self-tests in `scripts/tests/`)
- **Lint**: `pnpm lint`
- **Format**: `pnpm format` (check) · `pnpm format:fix` (write)

## Before you push

```bash
pnpm lint && pnpm format && pnpm validate:manifests && pnpm validate:artifacts && pnpm validate:docs
```

CI runs those five plus a `trufflehog` secrets scan on every PR and push to `main`.

## Gotchas

Traps this repo has actually sprung, newest first.

- **`pnpm lint` can be hijacked before it reaches `scripts/lint.sh`.** With the `rtk` proxy hook
  active, `pnpm lint` is rewritten to `rtk lint` — an _ESLint_ wrapper — and dies with
  `Command "eslint" not found` while the repo is perfectly green. `pnpm format` is unaffected (rtk has
  no `format` command), which makes it look like a real lint failure. Verify with
  `bash scripts/lint.sh` or `node_modules/.bin/agnix .` directly. CI has no rtk.
- **`pnpm view` and `pnpm info` are broken here on purpose.** They delegate to npm, and
  `devEngines.packageManager.onFail: "error"` in `package.json` makes npm refuse to run in this repo
  — which is the point: it is the `pnpm/only-allow` replacement, now that the package is archived.
  The error is `EBADDEVENGINES ... does not match "npm"`. Everything else (`ci`, `dlx`, `outdated`,
  `audit`, `why`, `licenses`, `list`) is native and fine. To look a package up, run it from any other
  directory. Flip `onFail` to `ignore` if the guard ever costs more than it saves.
- **`packageManager` and `devEngines.packageManager` must state the same version.** Both say
  `11.18.0`; bump them together. If they diverge, pnpm warns once and _ignores_ `packageManager`,
  while CI's pinned `pnpm/action-setup` (v4 — it predates `devEngines` support) reads **only**
  `packageManager`. The result is local and CI silently running different pnpm versions.
- **A fresh worktree runs no git hooks at all.** `core.hooksPath` is `.husky/_`, which `husky init`
  generates and gitignores — so a `git worktree add` checkout has `.husky/pre-commit` and no `_/`,
  git finds no hooks directory, and every commit skips prettier, agnix and the manifest version check
  **without printing anything**. Run `pnpm install` in the worktree before your first commit;
  `worktree.sh create` now warns about it on stderr, but the warning is easy to scroll past.
- **`block-env-access.sh` inspects the whole Bash command, including a commit message.** Writing about
  `.env` in a commit body blocks the commit. The hook's quoted-prose escape only covers
  `git commit -m "…"`; a heredoc gives the matcher no quoting to see. Write the message to a file
  outside the repo and use `git commit -F <path>`.
- **`pnpm lint` OOMs locally.** `agnix` over the whole tree can die with "terminated abnormally" under
  memory pressure; `scripts/lint.sh` turns that into a hard error rather than a silent pass. Re-run it,
  or lint only the staged paths the way `.husky/pre-commit` does. CI has the headroom.
- **`templates/hooks/` and `scripts/runtime/slugify.sh` are vendored** from `dw-skills`. A fix here
  does not reach that repo, and no test can see across the boundary — apply it twice.
