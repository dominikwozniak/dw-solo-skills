# dw-solo-skills — agent instructions

> `CLAUDE.md` is a symlink to this file — **edit `AGENTS.md`**. Budget: **120 lines / 10 KB**,
> enforced by `pnpm validate:docs`. Over budget is not a licence to trim a rule: move a topic into
> `docs/agents/<topic>.md` and add its Task Router row, in the same commit. A trap learned the hard
> way is appended to that topic file's `## Gotchas`, never to this one. See
> [`docs/agents/README.md`](docs/agents/README.md).

A Claude Code skills catalog for repos only you read, distributed as an installable plugin
marketplace — not a code project. The fuller, team-weight lane lives in a separate repo,
[`dw-skills`](https://github.com/dominikwozniak/dw-skills). Keep this one thin: every skill here
assumes **one reader**, and a change that needs a second reader's trust belongs there instead.

## Layout — and the one rule

```
skills/<name>/SKILL.md           the canon for every skill. EDIT HERE.
plugins/dw-solo/                 the loop plugin — plugin.json + symlinks (mode 120000) → the canon
plugins/dw-solo-setup/           the setup plugin — dw-init, dw-doctor, the templates symlink
plugins/dw-solo-extras/          the off-loop plugin — dw-handoff
scripts/runtime/<script>.sh      shipped scripts — symlinked into the owning plugin
scripts/<script>.sh              repo CI tooling, never shipped (validate-*.sh, lint.sh)
scripts/tests/<script>.test.sh   bash self-tests
evals/cases/<name>.json          routing cases — one per model-invocable skill, never shipped
evals/routing.ts                 the routing eval — free, deterministic, in CI
templates/                       payload copied INTO a target project (hooks, settings.json, AGENTS.md,
                                 check-agents-docs.mjs, the .ai/ and docs/decisions/ READMEs)
.claude-plugin/marketplace.json  makes this repo installable as a plugin source
```

**Always edit the canon above; use it instead of any `plugins/…` path**, since every one of those is
a symlink back to it — `plugins/*/skills/`, `scripts/` and `templates/` alike. That rule is
absolute. Why it works, and what a plugin must own for it to keep working:
[`docs/agents/skills-and-plugins.md`](docs/agents/skills-and-plugins.md).

## The loop

```
dw-grill? → dw-shape → dw-start? → dw-next ↺ → dw-check? → dw-land → dw-ship
  fuzzy      plan it    worktree     build        gate       close     merge
```

`?` marks the opt-in steps. The mandatory spine is `dw-shape → dw-next → dw-ship`; a small serial
change never leaves the default branch, and `dw-ship` runs the closing pass itself when the change
doc is still there — so a finished change needs one command. Skills connect through artifacts, never
a forced sequence: the shared `CHANGE.md`, and a `**Next:**` pointer at the end of each body that
`validate-docs.sh` checks names a skill existing **in this repo**.

## Commands

This repo is Markdown / JSON / Shell plus a little dependency-free TypeScript under `evals/` — there
is no build step and no typecheck. Node runs the `.ts` files directly.

- **Test**: `pnpm validate:artifacts` (the bash self-tests in `scripts/tests/`)
- **Lint**: `pnpm lint`
- **Format**: `pnpm format` (check) · `pnpm format:fix` (write)
- **Routing evals**: `pnpm eval:routing` — free, deterministic, in CI. The one tier there is; the
  paid tier was deleted, see [`evals/README.md`](evals/README.md).

## Before you push

Run every check in the `scripts` block of `package.json` — `lint`, `format`, each `validate:*` and
`eval:routing`. That block is the gate; the list is deliberately not restated in prose, because the
prose copies drifted from it (see `.ai/archive/contributing-pre-push-gate-list-is-stale/`). CI runs
the same set plus a `trufflehog` secrets scan on every PR and push to `main`.

## Task Router

Match the task against this table **before** researching or coding. One task often matches several
rows — read all of them. Explore on your own only what no row covers.

| task                                                                     | read                                |
| ------------------------------------------------------------------------ | ----------------------------------- |
| adding/renaming a skill, the symlink canon, plugin versions, evals cases | `docs/agents/skills-and-plugins.md` |
| a `dw-start` worktree behaving unlike the main tree                      | `docs/agents/worktrees.md`          |
| a rebase, a stray commit, rewinding a branch, a squash-merged base       | `docs/agents/git-history.md`        |
| lint/format failures, the hooks, self-tests, the pnpm/Node pins, CI      | `docs/agents/tooling.md`            |
| the loop, `.ai/work/`, what a `CHANGE.md` is and when it leaves          | `docs/agents/change-artifacts.md`   |
| editing this file or `docs/agents/*` — what belongs where                | `docs/agents/README.md`             |
| why the code is shaped this way; reopening a settled choice              | `docs/decisions/README.md`          |
| a follow-up worth keeping but not worth doing now                        | `.ai/backlog/README.md`             |
| a landed change's reasoning, after the fact                              | `.ai/archive/README.md`             |
| a blocked command, a hook that fired, a guardrail that looks wrong       | `.claude/hooks/`                    |
