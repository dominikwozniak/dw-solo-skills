# dw-solo-skills — agent instructions

> `CLAUDE.md` is a symlink to this file — **edit `AGENTS.md`**. Budget: **120 lines / 10 KB**,
> enforced by `pnpm validate:docs`. Over budget is not a licence to trim a rule: move a topic into
> `docs/agents/<topic>.md` and add its Task Router row, in the same commit. A trap learned the hard
> way is appended to that topic file's `## Gotchas`, never to this one. See
> [`docs/agents/README.md`](docs/agents/README.md).

A skills catalog, not a code project. Keep it thin: every skill here assumes **one reader**, and a
change needing a second reader's trust belongs in the team-weight lane,
[`dw-skills`](https://github.com/dominikwozniak/dw-skills).

## Layout — and the one rule

```
skills/<name>/SKILL.md           the canon for every skill. EDIT HERE.
plugins/dw-solo/                 the loop plugin — plugin.json + symlinks (mode 120000) → the canon
plugins/dw-solo-setup/           the setup plugin — dw-init, dw-doctor, the templates symlink
plugins/dw-solo-extras/          the off-loop plugin — dw-handoff
scripts/runtime/<script>.sh      shipped scripts — symlinked into the owning plugin
scripts/<script>.{sh,mjs}        repo CI tooling, never shipped (validate-*.sh, check-skill-corpus.mjs)
scripts/tests/<script>.test.sh   bash self-tests
evals/cases/<name>.json          routing cases — one per model-invocable skill, never shipped
evals/routing.ts                 the routing eval — free, deterministic, in CI
templates/                       payload copied INTO a target project — hooks, settings.json,
                                 AGENTS.md, check-agents-docs.mjs, gitignore-block.txt,
                                 worktreeinclude.txt, the .ai/ and docs/decisions/ READMEs
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
a forced sequence.

## Commands

Markdown / JSON / Shell plus dependency-free TypeScript under `evals/` that Node runs directly — no
build step, no typecheck.

- **Test**: `pnpm validate:artifacts` — self-tests, the backlog cap, the skill-corpus ratchet
- **Format**: `pnpm format` (check) · `pnpm format:fix` (write)
- **Routing evals**: `pnpm eval:routing` — free, deterministic, in CI ([`evals/README.md`](evals/README.md))

Lint, typecheck and the two commit policies are the bullets under `## Solo lane` — **one copy
each**, because the guardrail hooks grep for them under those exact names.

## Before you push

Run every check in the `scripts` block of `package.json`. That block **is** the gate, deliberately
not restated here — the prose copies drifted (`.ai/archive/contributing-pre-push-gate-list-is-stale/`).
CI runs the same set plus a `trufflehog` secrets scan, on every PR and push to `main`.

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

## Solo lane

`.ai/work/<slug>/CHANGE.md` is the state of the change in progress — tracked, so it survives a
`/clear`. Where each step promotes its durable output is the Task Router above.

The four below are **grep-read by the hooks**, so they live here and nowhere else: `lint-on-edit`
appends one file path to the first, so it must accept one; `typecheck-on-stop` runs the second over
the whole project; `enforce-commit-hygiene` matches the third as an ERE against a `-m` subject and
requires the fourth as a trailer line. `none` disables any of them, standing alone on the line.

- **Lint command**: `pnpm lint`
- **Typecheck command**: none
- **Commit pattern**: `^(build|chore|ci|docs|feat|fix|perf|refactor|revert|style|test)(\([a-z0-9-]+\))?!?: .+`
- **Commit trailer**: `Co-Authored-By:`

## Git conventions

Read by `dw-git` — these override its defaults and the global user memory's.

- `type(scope): subject` — [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/),
  lowercase, imperative. Scope is the plugin or skill the change belongs to (`feat(dw-ship):`,
  `fix(validate-docs):`); omit it for repo-wide work (`docs:`, `chore:`). No ticket prefix — this
  repo has no external tracker.
- **Body**: prose paragraphs explaining _why_, not a bullet list of files. Match the existing log.
- **Trailer**: `Co-Authored-By: <the model that wrote it> <noreply@anthropic.com>`. No "Generated
  with Claude Code" footer.
- **Default branch**: `main` — also the PR target. Branch off it with a kebab-case slug of the
  change.
- **Rebase, never merge**: `git pull --rebase`, `git fetch origin && git rebase origin/main`.
- **Modern verbs** — `git switch` / `git restore` over `git checkout`.
- **Branch reads** — `git rev-parse --abbrev-ref HEAD`, never `git branch --show-current`, which
  returns empty on a detached HEAD.
- **One logical change per commit**, staged by name — never `git add -A`. Exception: a cycle of new
  skills whose `**Next:**` pointers are mutual lands as one commit, because `validate:docs` fails a
  pointer at a skill not yet on disk.
