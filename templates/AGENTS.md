# {{PROJECT_NAME}} — agent rules

> `CLAUDE.md` is a symlink to this file — **edit `AGENTS.md`**. Budget: **120 lines / 10 KB**,
> enforced by `{{AGENTS_CHECK_COMMAND}}`. Over budget is not a licence to trim the rules: move a
> topic into `docs/agents/<topic>.md` and add its Task Router row below, in the same commit. Never a
> second always-loaded file — one root, or the corpus forks. Personal notes (how you like to be
> talked to, what you are learning) belong in `~/.claude/CLAUDE.md`, which is not this repo's
> problem.

## Project

- **Stack**: {{STACK}}
- **Key directories**: _(where the real logic lives — one line, not a directory tree)_
- **Deployment target**: _(how and where it ships, or `none`)_

## Always

- **The existing layout wins.** Match the file naming, module boundaries and patterns already in the
  tree. No skill or reference doc restructures a directory that already exists.
- **This repo's rules beat skills, reference docs and defaults.** Where they collide, write the
  collision down and route to it — an undocumented collision is rediscovered every session.
- **Docs follow the change, in the same commit**: a new or renamed command, a dependency-policy
  shift, a trap learned the hard way, an architecture decision → update the matching doc, and add a
  router row when the doc is new.
- _(add this project's real invariants — start with whatever you have already had to say twice)_

## Ask First

- Anything that leaves the machine: pushing, publishing, deploying, calling an external service.
- A migration, a destructive data change, or anything that cannot be undone from git.
- Adding a dependency.
- _(add the ones specific to this project)_

## Never

- Never commit secrets, `.env` files or credentials. The guardrail hooks block the obvious paths,
  not every path.
- Never rewrite published history on `{{DEFAULT_BRANCH}}`.
- _(add the ones specific to this project — above all, the commands only a human should run)_

## Commands

- **Test**: {{TEST_COMMAND}}
- _(add the rest as they appear: format, build, migrate, the one command CI runs)_

Lint, typecheck and the two commit policies are the bullets under `## Solo lane` — **one copy
each**, because the guardrail hooks grep for them under those exact names.

## Task Router

Match the task against this table **before** researching or coding. One task often matches several
rows — read all of them. Explore on your own only what no row covers.

| task                                                               | read                       |
| ------------------------------------------------------------------ | -------------------------- |
| the loop, `.ai/work/`, what a `CHANGE.md` is and when it leaves    | `.ai/README.md`            |
| why the code is shaped this way; reopening a settled choice        | `docs/decisions/README.md` |
| what something is called here — any domain term                    | `CONTEXT.md`               |
| a follow-up worth keeping but not worth doing now                  | `.ai/backlog/README.md`    |
| a landed change's reasoning, after the fact                        | `.ai/archive/README.md`    |
| a blocked command, a hook that fired, a guardrail that looks wrong | `.claude/hooks/`           |

## Solo lane

`.ai/work/<slug>/CHANGE.md` is the state of the change in progress — tracked, so it survives a
`/clear`. The loop is `/dw-shape → /dw-start? → /dw-next ↺ → /dw-check? → /dw-ship`, and `/dw-ship`
runs `/dw-land` itself while the change doc is still open. Where each step promotes its durable
output is the Task Router above.

The four below are **grep-read by the hooks**, which is why they live here and nowhere else:
`lint-on-edit` appends one file path to the first, so it must accept one; `typecheck-on-stop` runs
the second over the whole project; `enforce-commit-hygiene` matches the third as an ERE against a
`-m` subject and requires the fourth as a trailer line. Write `none` where the project genuinely has
none — the hooks read that as "skip", and a stale rule is worse than an honest gap. The commit
pattern falls back to Conventional Commits if you delete its bullet; the trailer falls back to
`none`, so leave it `none` unless the project really wants one on every commit.

- **Lint command**: {{LINT_COMMAND}}
- **Typecheck command**: {{TYPECHECK_COMMAND}}
- **Commit pattern**: {{COMMIT_PATTERN}}
- **Commit trailer**: {{COMMIT_TRAILER}}

## Git conventions

Read by `dw-git` — these override its defaults and the global user memory's.

- `type(scope): subject` — [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/),
  lowercase, imperative. No ticket prefix _(add one here if this project gets a tracker)_.
- _(state the trailer policy outright: whether `Co-Authored-By` is wanted, and which footer, if any)_
- **Default branch**: `{{DEFAULT_BRANCH}}` — also the PR target. Branch off it with a kebab-case
  slug of the change.
- **Rebase, never merge**: `git pull --rebase`,
  `git fetch origin && git rebase origin/{{DEFAULT_BRANCH}}`.
- **Modern verbs** — `git switch` / `git restore` over `git checkout`.
- **Branch reads** — `git rev-parse --abbrev-ref HEAD`, never `git branch --show-current`, which
  returns empty on a detached HEAD.
- **One logical change per commit**, staged by name — never `git add -A`.

## Hooks installed

{{HOOKS_INSTALLED}}

Tracked in `.claude/hooks/`, so a fresh clone and a `git worktree` checkout get the same guardrails.
Every one opens with `command -v jq >/dev/null || exit 0` — **without `jq` on `PATH` they all
silently no-op**, and nothing says so. `/dw-doctor` is the check.
