# dw-solo-skills — agent instructions

A Claude Code skills catalog for repos only you read, distributed as an installable plugin
marketplace — not a code project.

The fuller, team-weight lane lives in a separate repo,
[`dw-skills`](https://github.com/dominikwozniak/dw-skills). Keep this one thin: every skill here
assumes **one reader**, and a change that needs a second reader's trust belongs there instead.

## Layout — and the one rule

```
skills/<name>/SKILL.md           the canon for every skill. EDIT HERE.
plugins/dw-solo/                 plugin.json + git-tracked symlinks (mode 120000) → the canon
scripts/runtime/<script>.sh      shipped scripts — symlinked into the plugin
scripts/<script>.sh              repo CI tooling, never shipped (validate-*.sh, lint.sh)
scripts/tests/<script>.test.sh   bash self-tests
templates/                       payload copied verbatim INTO a target project (hooks, settings.json)
.claude-plugin/marketplace.json  makes this repo installable as a plugin source
```

**Always edit the canon above; use it instead of any `plugins/…` path**, since every one of those is
a symlink back to it — `plugins/dw-solo/skills/`, `scripts/` and `templates/` alike.

Skill bodies invoke a shipped script as `${CLAUDE_PLUGIN_ROOT}/scripts/<script>.sh` — install
dereferences the symlink, so the path resolves. A script used by only **one** skill needs no canon:
bundle it in `skills/<name>/scripts/` and invoke it via `<this-skill-dir>/…`, as `dw-doctor` does.
Why it's built this way: [`docs/DESIGN.md`](docs/DESIGN.md), "The symlink canon".

## Vendored from `dw-skills` — fix in both

These are **copies**, not references, and nothing can detect drift across the repo boundary:

- `templates/hooks/*.sh` (7 files) — byte-identical to the `dw-skills` canon.
  `scripts/tests/hooks-in-sync.test.sh` only pins them to _this_ repo's `.claude/hooks/`.
- `scripts/runtime/slugify.sh` — byte-identical.

`dw-git`, `dw-doctor` and `dw-setup-precommit` are **forks**, simplified for one reader. They are
expected to diverge; don't re-sync them.

## Adding a skill

1. `skills/<name>/SKILL.md` — kebab-case `name` matching the directory, a `description` that is
   routing signal only, `disable-model-invocation: true` if explicit-invoke only. Shape:
   [`docs/SKILL-ANATOMY.md`](docs/SKILL-ANATOMY.md); copy a near neighbour like `dw-shape`.
2. `ln -s ../../../skills/<name> plugins/dw-solo/skills/<name>` and `git add` the symlink.
3. Bump the plugin's patch version in **both** `.claude-plugin/marketplace.json` and
   `plugins/dw-solo/.claude-plugin/plugin.json` — keep the two identical.
4. Name the skill everywhere the docs list skills: the README **task-router** row, the **loop
   diagram** if it joins the core loop, and — if explicit-invoke — the `⭑` marker plus the
   explicit-only lists in README **and** `docs/DESIGN.md`.
5. End the body with a `**Next:**` line naming a skill that exists **in this repo** — a pointer at a
   team-lane skill is a dead end here, and `validate:docs` fails it.
6. `pnpm lint && pnpm format && pnpm validate:manifests && pnpm validate:docs`.

Steps 3–5 are CI-enforced. The validators name the exact missing entry — run them rather than
re-deriving the checklist by hand.

## Adding a shipped (plugin-level) script

1. Put the real file once at `scripts/runtime/<script>.sh` and `chmod +x` it.
2. `ln -s ../../../scripts/runtime/<script>.sh plugins/dw-solo/scripts/<script>.sh` and `git add`
   the symlink (must be mode 120000).
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

- **`pnpm lint` OOMs locally.** `agnix` over the whole tree can die with "terminated abnormally" under
  memory pressure; `scripts/lint.sh` turns that into a hard error rather than a silent pass. Re-run it,
  or lint only the staged paths the way `.husky/pre-commit` does. CI has the headroom.
- **`templates/hooks/` and `scripts/runtime/slugify.sh` are vendored** from `dw-skills`. A fix here
  does not reach that repo, and no test can see across the boundary — apply it twice.
