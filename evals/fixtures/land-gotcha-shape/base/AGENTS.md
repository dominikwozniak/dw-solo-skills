# demo-service — agent instructions

> `CLAUDE.md` is a symlink to this file — edit `AGENTS.md`. Budget: **60 lines / 6 KB**, enforced by
> `pnpm agents:check`.

A small internal service. Keep it thin.

## Commands

- **Test**: `pnpm test`
- **Docs gate**: `pnpm agents:check`

## Task Router

| task                                  | read                       |
| ------------------------------------- | -------------------------- |
| the test runner, the docs gate, CI    | `docs/agents/tooling.md`   |
| what belongs in which agent-docs file | `docs/agents/README.md`    |
| why the code is shaped this way       | `docs/decisions/README.md` |
| a domain term                         | `CONTEXT.md`               |

## Solo lane

- **Lint command**: none
- **Typecheck command**: none
- **Commit pattern**: `^(build|chore|ci|docs|feat|fix|perf|refactor|revert|style|test)(\([a-z0-9-]+\))?!?: .+`
- **Commit trailer**: `Co-Authored-By:`

## Git conventions

- `type(scope): subject` — Conventional Commits, lowercase, imperative.
- **Body**: prose paragraphs explaining _why_.
- **Trailer**: `Co-Authored-By: <the model that wrote it> <noreply@anthropic.com>`
- **Default branch**: `main` — also the PR target.
- **Rebase, never merge**.
- **One logical change per commit**, staged by name — never `git add -A`.
