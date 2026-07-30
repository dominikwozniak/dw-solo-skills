# {{PROJECT_NAME}} — local agent memory

Personal Claude Code memory for this project. Gitignored. `dw-init` dropped this
file — edit freely.

## About me — dev profile & preferences

Context for the agent. Read before starting a task.

- **Background**: _(your primary stack; what you're newer at on this project)_
- **Communication language**: _(e.g. English; or "Polish mixed with English, technical
  terms in EN". Code, names, identifiers, commits — always EN.)_
- **Learning mode**: _(minimal / verbose; when to add analogies from a stack you know)_
- **Anything else the agent should assume about you** on this repo.

## Workflow

- Loop: `/dw-shape → /dw-next`, then `/dw-land` before the merge. `/dw-grill` first when the idea is fuzzy.
- One change at a time lives in `.ai/work/<slug>/CHANGE.md` — tracked, and deleted by `/dw-land` at merge.
- `/dw-next` bare answers "where were we" from disk; `/dw-next go` builds the next task.
- Durable knowledge is promoted out, not accumulated: decisions → `docs/decisions/`, terms → `CONTEXT.md`, traps → `## Gotchas` in `CLAUDE.md`.
- Follow-ups and out-of-scope ideas go to `.ai/BACKLOG.md` — `/dw-land` parks them, `/dw-shape` picks the next one up.

## Tools active in this session

- **gh CLI** — preferred over MCP for GitHub ops.
- _(add the rest you actually use: rtk, caveman, claude-mem, Linear/Atlassian/Notion via MCP,
  Sentry/Playwright via CLI. Check `claude mcp list`; drop bullets you don't use.)_

## Git conventions

Read by the `dw-git` skill. Overrides global defaults.

- **Commit format**: `type: description` —
  [Conventional Commits 1.0](https://www.conventionalcommits.org/en/v1.0.0/). No ticket prefix; this
  repo has no external tracker. _(Add one back here if it ever gets one.)_
- **Default branch**: {{DEFAULT_BRANCH}}
- **Branch naming**: a plain kebab-case slug of the change (`fix-token-refresh`, `add-csv-export`).
- _(state your trailer policy, e.g. NO `Co-Authored-By`, NO "Generated with Claude Code" footer.)_
- **Rebase by default**: `git pull --rebase`, `git fetch origin && git rebase origin/{{DEFAULT_BRANCH}}`.
- **Modern verbs**: `git switch` / `git restore` over `git checkout`.
- **Branch reads**: `git rev-parse --abbrev-ref HEAD`, never `git branch --show-current` (the latter
  returns empty on a detached HEAD).
- **One logical change per commit.** Split when session work spans multiple concerns.

## Project specifics

- **Stack**: {{STACK}}
- **Test command**: {{TEST_COMMAND}}
- **Lint command**: {{LINT_COMMAND}}
- **Typecheck command**: {{TYPECHECK_COMMAND}}
- **Domain**: _(one-line gist, or a pointer to `CLAUDE.md` / `CONTEXT.md`)_
- **Key directories**: _(where the business logic lives)_
- **Deployment target**: _(how/where it ships)_

## Hooks installed

{{HOOKS_INSTALLED}}

Hook scripts live in `.claude/hooks/` and are **tracked** — so a fresh clone, and a
`git worktree` checkout, get the same guardrails.

## Keep this file current

This file is the source of truth for the agent _and_ the hooks. If any of these change, update the
matching line here in the same commit:

- Test / lint / typecheck command → **two places, same commit**: `## Project specifics` here, because
  the lint and typecheck hooks grep this file for those exact names, **and** `## Commands` in tracked
  `CLAUDE.md`, which is the copy that survives a fresh clone and is readable by an agent that reads
  `AGENTS.md`. Both are load-bearing; if they disagree, the hooks and the skills disagree.
- Default branch renamed → `## Git conventions` (`dw-git` reads it).
- Stack, key directories, deployment target shifts → `## Project specifics`.
- New tool installed (MCP server, CLI) or one removed → `## Tools active in this session`.
- New hook wired in `.claude/settings.json` → add a line under `## Hooks installed`.

Traps this project has actually sprung go in `## Gotchas` in tracked `CLAUDE.md`, not here — that one
is auto-loaded, so the next session reads it unasked. `dw-land` appends there.

Stale placeholders silently break the linter, typecheck, and commit flow.
