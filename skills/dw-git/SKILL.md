---
name: dw-git
description: >-
  One skill for every git operation in this project — commit and save what you have, stage, push,
  open a pull request, sync with main, rebase, branch, park edits in a stash — applying the repo's
  own `## Git conventions` from `AGENTS.md` instead of generic defaults.
argument-hint: "Which git op? e.g. commit, push, open PR, sync, branch, stash"
---

# dw-git — all git ops, by the project's own conventions

Every git operation in one place, so the conventions live in exactly one place — the rest of the
loop delegates here by prose.

## What it reads

A `## Git conventions` block in `AGENTS.md` first, then in a legacy `CLAUDE.local.md` — first one
found wins, and its values **override** every default below: commit format, default branch, branch
naming, trailer policy, PR title, rebase-vs-merge, signing. With neither, use the defaults.

**Resolving the default branch** — the lookup every other skill borrows: `## Git conventions`,
else `git symbolic-ref --short refs/remotes/origin/HEAD`, else `main`.

**Which ref of it to diff against** — fetch, then take whichever of the two contains the other;
local is the default, because a local branch that is _ahead_ (an unpushed shape commit) makes
`origin/` pull commits the branch didn't write into the diff:

```bash
git fetch origin --quiet 2>/dev/null || true
base=<default-branch>
git rev-parse --verify --quiet origin/<default-branch> >/dev/null \
  && git merge-base --is-ancestor <default-branch> origin/<default-branch> \
  && base=origin/<default-branch>
```

Every branch read is `git rev-parse --abbrev-ref HEAD`, never `git branch --show-current` (empty
on a detached HEAD). Modern verbs throughout: `git switch` / `git restore` over `git checkout`.
This skill writes no `.ai/` artifact — its durable output is the git history itself.

## Operations

### commit

Subject shape and trailer are **declared, not inferred**: the `- **Commit pattern**:` and
`- **Commit trailer**:` bullets under `## Solo lane` are what `enforce-commit-hygiene.sh`
enforces; with neither bullet, Conventional Commits and no trailer. Beyond the pattern: imperative
mood, lowercase, ≤72 chars; a body saying what + why for non-trivial changes; **no** "Generated
with Claude Code" footer; one logical change per commit.

1. `git status --short`, then **stage session work by name** — never `git add .` / `-A`, which the
   hygiene hook refuses; exclude anything sensitive (`.env`, credentials, keys).
2. `git diff --staged` — review what's actually staged.
3. A `[TICKET-XXX] ` prefix only when the branch matches `^[A-Z]+-\d+` **and** the declared
   pattern admits it — a contradiction between the two is reported, not fought.
4. Commit with `-m` (repeat `-m` for the body), following the project's signing convention. A
   backtick inside a double-quoted `-m` is command substitution and vanishes silently — the
   hygiene hook refuses it; single-quote or use `-F` where it isn't installed.
5. Read the message back with `git cat-file -p HEAD` (not `git log`, which pagers and proxies may
   trim), then `git log --oneline -1` to confirm.

### push

Plain `git push`; no upstream → `git push -u origin "$(git rev-parse --abbrev-ref HEAD)"`.
Force-push is refused (hook-blocked where installed). Pushing to a protected branch
(`main`/`master`/`develop`) needs explicit confirmation first.

### PR — "open PR", "create pull request"

Push first if needed; base is the default branch. Title in the commit-subject format; body from
`.github/PULL_REQUEST_TEMPLATE.md` where it exists, else `## Summary` + `## Test plan`; no
attribution footer. `gh pr create --title … --body …`, then print the URL — `gh` over a GitHub
MCP server: less context, same result.

### sync — "sync with main", "rebase"

Rebase, never merge: `git fetch origin && git rebase origin/<default-branch>`. Refuse on a dirty
tree — commit or stash first. On conflicts, report and **stop**; never auto-resolve.

### branch

`git switch -c <kebab-slug>` — the same spelling the change docs under `.ai/work/` use; a ticket
prefix only where the project's conventions carry one.

### stash

Always with a message: `git stash push -m "<what's being saved>"` — never bare `git stash`.

**Next:** `dw-next` to get back to building.

$ARGUMENTS
