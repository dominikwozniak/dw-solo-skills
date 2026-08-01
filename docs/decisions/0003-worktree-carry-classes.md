---
decision: 0003
status: active # active | superseded
date: 2026-08-01
---

# 0003 — Untracked files are carried into a worktree by class, not by one mechanism

## Context

`git worktree add` checks out tracked state only, so everything else in a working tree is missing in
a fresh worktree — and every gap fails silently rather than loudly. Claude Code's `.worktreeinclude`
solves one third of this, and only for the worktrees it creates itself; `git worktree add`, which
`worktree.sh create` uses, gets nothing. The obvious fix — copy everything gitignored that the user
names — is wrong for two of the three things actually missing.

## Decision

Untracked files get exactly one of four treatments, chosen by what the file **is**:

- **copy** — local config and secrets (`.env`, `config/secrets.json`), via `.worktreeinclude`;
- **link** — personal agent memory (`CLAUDE.local.md`), symlinked so there stays one source of truth;
- **regenerate** — installed dependencies and the tooling built from them (`node_modules/`,
  `.husky/_/`, `.venv`), never carried, only reported as missing;
- **absent** — build caches and scratch, correct by default.

`worktree.sh create` implements the first three and refuses `node_modules/`, `.claude/worktrees/`
and `.git` regardless of what `.worktreeinclude` says. Pattern matching is delegated entirely to git
— the intersection of `ls-files -o -i --exclude-standard` with `ls-files -o -i --exclude-from` — so
the rule cannot drift from what `claude -w` does.

## Trade-off

Three things were given up.

**The symlink cannot diverge.** Listing `CLAUDE.local.md` in `.worktreeinclude` like everything else
would have been one mechanism instead of two, and would let a worktree hold its own variant. It was
rejected because a copy diverges silently and the wrong half wins depending on which tree you edited
last — but if per-worktree local memory is ever wanted, this is the decision blocking it.

**The refusals cannot be overridden.** A user who genuinely wants `node_modules/` copied has no
escape hatch. Accepted because the include file is hand-written and the failure is destructive, not
annoying: a bare `*` matches 421 files in this repo, 394 of them dependencies, and `.claude/worktrees/`
would put worktrees inside a worktree.

**Delegating the matching to git costs two `ls-files` passes and drops filenames containing a
newline** (`comm` has no `-z`). A hand-rolled matcher would handle both, at the price of
reimplementing gitignore semantics that must stay identical to Claude Code's — the one thing worth
paying to avoid.

## Revisit when

Claude Code starts honouring `.worktreeinclude` for `git worktree add` itself, or grows a hook that
fires on worktree creation rather than session start — either would make `worktree.sh`'s copy and
link steps redundant rather than merely duplicated.
