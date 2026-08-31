# {{PROJECT_NAME}} — agent rules

> `CLAUDE.md` is a symlink to this file — **edit `AGENTS.md`**. Budget: **120 lines / 10 KB**, enforced
> by `{{AGENTS_CHECK_COMMAND}}`. Over budget, move a topic into `docs/agents/<topic>.md` and add its
> Task Router row in the same commit — never trim a rule, never add a second always-loaded file, and
> keep personal notes in `~/.claude/CLAUDE.md` instead. Sections below are stubs; write your own prose.

## Project

- **Stack**: {{STACK}}
- _(key directories — where the real logic lives, one line, not a tree; and the deployment target)_

## Always

_(this project's invariants — start with whatever you have already had to say twice. Two worth seeding:
the existing layout wins over any skill's preference, and docs are updated before the change lands.)_

## Ask First

_(what takes a human's word first. Seed: anything leaving the machine — push, publish, deploy, an
external call; a migration or anything git cannot undo; a new dependency.)_

## Never

_(the hard lines. Seed: never commit secrets or `.env` — the hooks block the obvious paths, not every
one; never rewrite published history on `{{DEFAULT_BRANCH}}`; and the commands only a human should run.)_

## Commands

- **Test**: {{TEST_COMMAND}}
- _(add the rest as they appear: format, build, migrate, the one command CI runs)_

Lint, typecheck and the two commit policies are the bullets under `## Solo lane` — **one copy each**,
because the guardrail hooks grep for them under those exact names.

## Task Router

Match a task against this table **before** researching or coding, and read every row that applies.

| task                                                               | read                       |
| ------------------------------------------------------------------ | -------------------------- |
| editing this file or `docs/agents/*` — what belongs where          | `docs/agents/README.md`    |
| the loop, `.ai/work/`, what a `CHANGE.md` is and when it leaves    | `.ai/README.md`            |
| why the code is shaped this way; reopening a settled choice        | `docs/decisions/README.md` |
| what something is called here — any domain term                    | `CONTEXT.md`               |
| starting this project and driving a feature by hand to see it work | `VERIFY.md`                |
| a follow-up worth keeping but not worth doing now                  | `.ai/backlog/README.md`    |
| a landed change's reasoning, after the fact                        | `.ai/archive/README.md`    |
| a blocked command, a hook that fired, a guardrail that looks wrong | `.claude/hooks/`           |

## Solo lane

`.ai/work/<date>-<slug>/CHANGE.md` is the state of the change in progress — tracked, so it survives a
`/clear`. Where each step promotes its durable output is the Task Router above. The loop, `?` opt-in:
`/dw-grill? → /dw-shape → /dw-start? → /dw-next ↺ → /dw-check? → /dw-land → /dw-ship`. Closing takes
the last two, one decision each: `/dw-land` ends with an open PR, `/dw-ship` merges it.

The five below are **grep-read** — the first four by the hooks, the fifth by `worktree.sh` — so they
live here and nowhere else: `lint-on-edit` appends one file path to the first, so it must accept one;
`typecheck-on-commit` runs the second before a `git commit` that stages TS; `enforce-commit-hygiene`
matches the third as an ERE against a `-m` subject and requires the fourth as a trailer line; and
`worktree.sh create` prints the fifth as the one line that makes a fresh checkout buildable, since a
worktree gets tracked files and no installed dependencies. `none` disables any of them, standing
alone on the line — write it where the project genuinely has none, because a stale rule is worse than
an honest gap.

- **Lint command**: {{LINT_COMMAND}}
- **Typecheck command**: {{TYPECHECK_COMMAND}}
- **Commit pattern**: {{COMMIT_PATTERN}}
- **Commit trailer**: {{COMMIT_TRAILER}}
- **Bootstrap command**: {{BOOTSTRAP_COMMAND}}

## Git conventions

Read by `dw-git` — these override its defaults and the global user memory's.

- **Subject**: `type(scope): subject`, lowercase, imperative
  ([Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/)) _(ticket prefix, if any)_
- **Trailer**: _(whether `Co-Authored-By` is wanted, and which footer, if any — state it outright)_
- **Default branch**: `{{DEFAULT_BRANCH}}` — also the PR target; branch off it with a kebab-case slug
- **Rebase, never merge** — `git pull --rebase`,
  `git fetch origin && git rebase origin/{{DEFAULT_BRANCH}}`
- **Branch reads** — `git rev-parse --abbrev-ref HEAD`, never `git branch --show-current`, empty on a
  detached HEAD. _(add the rest: `git switch`/`git restore`, staging by name over `git add -A`)_

## Hooks installed

{{HOOKS_INSTALLED}}

Tracked in `.claude/hooks/`, so a fresh clone and a `git worktree` checkout get the same guardrails.
Every one opens with `command -v jq >/dev/null || exit 0` — **without `jq` on `PATH` they all silently
no-op**, and nothing says so; `/dw-doctor` is the check.
