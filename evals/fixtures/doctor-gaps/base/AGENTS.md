# demo-service — agent instructions

A small internal service. Keep it thin.

## Commands

- **Test**: `pnpm test`

## Solo lane

- **Lint command**: `{{LINT_COMMAND}}`
- **Commit pattern**: `^(build|chore|ci|docs|feat|fix|perf|refactor|revert|style|test)(\([a-z0-9-]+\))?!?: .+`
- **Commit trailer**: `Co-Authored-By:`

## Git conventions

- `type(scope): subject` — Conventional Commits, lowercase, imperative.
- **Default branch**: `main` — also the PR target.
- **Rebase, never merge**.
- **One logical change per commit**, staged by name — never `git add -A`.
