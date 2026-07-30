---
name: dw-git
description: >-
  One skill for every git operation in this project — commit, push, sync, branch, stash — applying
  the repo's own `## Git conventions` from `CLAUDE.local.md` instead of generic defaults. Use for any
  git intent — committing, pushing, rebasing, branching, stashing — or when someone says "commit",
  "push", "sync with main".
argument-hint: "Which git op? e.g. commit, push, sync, branch, stash"
---

# dw-git — all git ops, by the project's own conventions

One skill, every git operation. The point is consistency: read the conventions the repo already
documents and apply them, rather than guessing per-commit.

This is the solo lane's `dw-git`. It assumes **one reader** — you — so there is no ticket-key
convention and no PR ceremony. If you work in a shared repo with a tracker, you want the team lane's
`dw-git` instead (the `dw-skills` marketplace, plugin `dw-misc`), which adds `[ABC-123]` subject
prefixes and a `gh pr create` flow.

## What it reads

Before any operation, read `CLAUDE.local.md` (repo root) if present and look for a
`## Git conventions` block. Those values **override** the defaults below — commit format, default
branch, branch naming, trailer policy, rebase-vs-merge, signing. If there's no `CLAUDE.local.md` or
no such block, use the documented defaults.

dw-git writes **no `.ai/` artifact** — its durable output is the git history itself (commits,
branches). It's an action skill, not a document-producing one.

## Operations

### commit

**Defaults** (overridden by `## Git conventions`):

- Format: `type: description` — a [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/)
  type, imperative, lowercase, no trailing period, ≤72 chars.
- Body: what + why for non-trivial changes; omit for trivial ones.
- **NO** `Co-Authored-By` trailer, **NO** "Generated with Claude Code" footer (unless the conventions
  say otherwise).
- One logical change per commit — split when session work spans concerns.

**Workflow:**

1. `git status --short` — see everything.
2. Classify: session work (created/edited this conversation) vs pre-existing / unrelated. **Stage
   session work by name** (`git add path1 path2`); never `git add .` / `git add -A` unless the user
   explicitly asks.
3. Exclude sensitive files (`.env`, credentials, keys) — warn, don't stage.
4. `git diff --staged` — review what's actually staged.
5. Commit — `-m` for the subject, repeat `-m` for the body (no heredoc needed for a short body). Use
   plain `git commit` and follow the project's signing convention from `CLAUDE.local.md`; don't add
   `-S` or run `git config` to change signing. Surface an error only if the commit genuinely fails.
6. `git log --oneline -1` — confirm.

### push

**Defaults:**

- Plain `git push` for feature branches.
- Force-push is blocked by `block-dangerous-commands.sh` when installed; otherwise refuse it manually.
- Pushing to `main` / `master` needs explicit confirmation first.

**Workflow:**

1. `git rev-parse --abbrev-ref HEAD`. If it's a protected branch, confirm before pushing.
2. Upstream check: `git rev-parse --abbrev-ref @{u} 2>/dev/null`.
3. No upstream → `git push -u origin "$(git rev-parse --abbrev-ref HEAD)"`; else `git push`.
4. Report the result.

### sync — "sync with main", "rebase"

**Defaults:** rebase, not merge. Refuse on a dirty tree — ask the user to commit or stash first.

```bash
git fetch origin
git rebase origin/<default-branch>
```

Resolve the default branch from `## Git conventions`, else
`git symbolic-ref --short refs/remotes/origin/HEAD`. On conflicts: report them and **stop** — do not
auto-resolve.

### branch — "new branch", "switch branch"

Use `git switch -c` (not `git checkout -b`). Name it a plain kebab-case slug of the change
(`fix-token-refresh`, `add-csv-export`); prompt for the slug if not given.

### stash — "stash my work"

Always with a message: `git stash push -m "<what's being saved>"`. Never bare `git stash`.

## Notes

- Every branch read uses `git rev-parse --abbrev-ref HEAD`, never `git branch --show-current` — the
  latter prints an empty string on a detached HEAD, which silently turns a branch check into a
  no-match. This is the primitive the rest of the lane uses, so branch resolution agrees everywhere.
- Defaults assume `block-dangerous-commands.sh` is installed (via `dw-init`). If it isn't, manually
  refuse the same patterns (force-push, hard-reset, `clean -d`/`-f`).
- Modern verbs throughout: `git switch` / `git restore` over `git checkout`.
- **No PR flow here on purpose.** A repo only you read rarely needs one; when you do want a PR, run
  `gh pr create` directly — it's one command and doesn't need a skill to wrap it.

**Next:** `dw-land` for a single verdict on the change — correct · fits · blast radius · proven —
before you merge it.

$ARGUMENTS
