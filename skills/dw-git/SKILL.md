---
name: dw-git
description: >-
  One skill for every git operation in this project — commit, push, open PR, sync (rebase), branch,
  stash — applying the repo's own `## Git conventions` from `CLAUDE.local.md` instead of generic
  defaults. Use for any git intent, however it's phrased.
argument-hint: "Which git op? e.g. commit, push, open PR, sync, branch, stash"
---

# dw-git — all git ops, by the project's own conventions

Every git operation in one place, so the conventions live in exactly one place: the rest of the loop
delegates here by prose — the build step commits the way this skill does, the ship step pushes and
opens PRs the way this skill does.

## What it reads

Before any operation, read `CLAUDE.local.md` (repo root) if present and look for a
`## Git conventions` block. Those values **override** the defaults below — commit format, default
branch, branch naming, trailer policy, PR title format, rebase-vs-merge, signing. If there's no
`CLAUDE.local.md` or no such block, use the documented defaults.

**Resolving the default branch** is the one lookup every other skill borrows from here: take it from
`## Git conventions`, else `git symbolic-ref --short refs/remotes/origin/HEAD`, else `main`. Never
assume `main` outright.

**Which ref of it to diff against** is the second half of that lookup, and every skill that reviews a
diff borrows it too. Fetch, then take whichever of the two already contains the other:

```bash
git fetch origin --quiet 2>/dev/null || true
base=<default-branch>                                        # the default — see below
git rev-parse --verify --quiet origin/<default-branch> >/dev/null \
  && git merge-base --is-ancestor <default-branch> origin/<default-branch> \
  && base=origin/<default-branch>                            # origin contains local, so it is ahead
```

**Never prefer `origin/` by reflex.** It is wrong exactly when the local branch is _ahead_ — the
normal state while an unpushed `chore: shape …` commit sits on it: the merge-base reaches back past
that commit, so the diff under review swallows work the branch didn't write. Only a local branch that
has _fallen behind_ earns the remote ref, and that is the one thing the check settles. Local is the
**default** because the two cases it can't settle have no better answer: **diverged**, where neither
contains the other — say so, and use local, since the branch was cut from it — and **no `origin` at
all**. Keep the `rev-parse` guard: `--is-ancestor` exits 128 on a ref that doesn't exist, not 1, so a
chain that falls through to `origin/` on failure hands back a ref that won't resolve.

dw-git writes **no `.ai/` artifact** — its durable output is the git history itself.

## Operations

### commit

**Defaults** (overridden by `## Git conventions`):

- Format: `[TICKET-XXX] type: description` if the branch matches `^[A-Z]+-\d+`,
  else `type: description`.
- Subject: [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/)
  type, imperative, lowercase, no trailing period, ≤72 chars.
- Body: what + why for non-trivial changes; omit for trivial ones.
- **NO** `Co-Authored-By` trailer, **NO** "Generated with Claude Code" footer
  (unless the conventions say otherwise).
- One logical change per commit — split when session work spans concerns.

**Workflow:**

1. `git status --short` — see everything.
2. Classify: session work (created/edited this conversation) vs pre-existing /
   unrelated. **Stage session work by name** (`git add path1 path2`); never
   `git add .` / `git add -A` unless the user explicitly asks.
3. Exclude sensitive files (`.env`, credentials, keys) — warn, don't stage.
4. `git diff --staged` — review what's actually staged.
5. Ticket key from branch: `git rev-parse --abbrev-ref HEAD | grep -oE '^[A-Z]+-[0-9]+'`.
   If found, prefix `[KEY] `.
6. Commit — `-m` for the subject, repeat `-m` for the body (no heredoc needed for a
   short body). Use plain `git commit` and follow the project's signing convention
   from `CLAUDE.local.md`; don't add `-S` or run `git config` to change signing.
   Surface an error only if the commit genuinely fails.
7. `git log --oneline -1` — confirm.

### push

**Defaults:**

- Plain `git push` for feature branches.
- Force-push is blocked by `block-dangerous-commands.sh` when installed; otherwise
  refuse it manually.
- Pushing to `main` / `master` / `develop` needs explicit confirmation first.

**Workflow:**

1. `git rev-parse --abbrev-ref HEAD`. If it's a protected branch, confirm before pushing.
2. Upstream check: `git rev-parse --abbrev-ref @{u} 2>/dev/null`.
3. No upstream → `git push -u origin "$(git rev-parse --abbrev-ref HEAD)"`; else `git push`.
4. Report the result.

### PR — "open PR", "create pull request"

**Defaults:**

- Title: same format as the commit subject.
- Body: summary + test plan derived from the commits since the base branch; **no**
  attribution footer.
- Use `.github/PULL_REQUEST_TEMPLATE.md` as the body skeleton if it exists.
- Create via `gh pr create` — never the web UI, and `gh` over a GitHub MCP server:
  less context, same result.

**Workflow:**

1. Push the branch first if it isn't pushed (see **push**).
2. Base branch: the default branch, resolved as above.
3. Build the body (PR template if present, else `## Summary` bullets +
   `## Test plan` checklist).
4. `gh pr create --title "..." --body "..."`; print the PR URL.

### sync — "sync with main", "rebase"

**Defaults:** rebase, not merge. Refuse on a dirty tree — ask the user to commit
or stash first.

```bash
git fetch origin
git rebase origin/<default-branch>
```

On conflicts: report them and **stop** — do not auto-resolve.

### branch — "new branch", "switch branch"

Use `git switch -c` (not `git checkout -b`). Default name: the kebab slug of what the branch is
for — the same spelling the change docs under `.ai/work/` use. Prefix a ticket key only when the
project's conventions carry one.

### stash — "stash my work"

Always with a message: `git stash push -m "<what's being saved>"`. Never bare
`git stash`.

## Notes

- Every branch read is `git rev-parse --abbrev-ref HEAD`, never `git branch --show-current` —
  the latter prints an empty string on a detached HEAD, which silently turns a branch check
  into a no-match.
- Defaults assume `block-dangerous-commands.sh` is installed (via the scaffolder).
  If it isn't, manually refuse the same patterns (force-push, hard-reset,
  `clean -d`/`-f`).
- Modern verbs throughout: `git switch` / `git restore` over `git checkout`.

**Next:** `dw-next` to get back to building.

$ARGUMENTS
