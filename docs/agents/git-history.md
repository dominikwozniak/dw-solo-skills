# Git — the procedures behind `## Git conventions`, and what goes wrong around them

The conventions themselves (commit format, trailer, branch naming, rebase over merge) are in the
root's `## Git conventions`, loaded every session. This file carries the procedures those rules
imply, and the traps that have actually sprung around them.

## Procedures

- **Commit** — `git status --porcelain` unscoped first (the index is shared, see below), stage by
  name, `git diff --staged` to review what is actually staged, then commit with `-m` (repeat `-m` for
  the body). A backtick inside a double-quoted `-m` is command substitution and vanishes silently;
  the hygiene hook refuses it — single-quote, or `-F` where the hook isn't installed. Read the message
  back with `git cat-file -p HEAD`, not `git log`, which pagers and proxies trim. `.env`, credentials
  and keys stay out, and leaving one out is said aloud.
- **Push** — plain `git push`; no upstream → `git push -u origin "$(git rev-parse --abbrev-ref HEAD)"`.
  Force-push is hook-refused; a push to `main` needs an explicit yes first.
- **PR** — push first if needed; `gh pr create` against `main`, title in the commit-subject shape,
  body `## Summary` + `## Test plan` (this repo has no PR template), no attribution footer, then
  print the URL. `gh` over a GitHub MCP server: less context, same result.
- **Sync** — `git fetch origin && git rebase origin/main`. Refuse on a dirty tree — commit or stash
  first. On a conflict report and **stop**; never auto-resolve.
- **Branch** — `git switch -c <kebab-slug>`, the same spelling the change docs under `.ai/work/` use.
- **Which ref to diff against** — `bash scripts/runtime/base-ref.sh` prints it: local `main` unless
  `origin/main` strictly contains it. Why local is the default is `CONTEXT.md`'s **Base ref** entry.

## Gotchas

- **`git add $paths` in zsh stages nothing, and the commit chained after it goes ahead anyway.** The
  session shell is zsh, which does not word-split an unquoted variable, so a newline-separated list
  of paths reached git as one pathspec, matched nothing, and `git add` said so — and the
  `git commit` sequenced after a `;` ran regardless, taking whatever was already in the index: here
  the `git rm` deletions alone, leaving 26 edits in the tree and a commit `validate:docs` would have
  failed on its own. The tell was lint-staged reporting no staged files. Pipe the list
  through `xargs git add`, and read `git show --stat HEAD` before trusting a many-file commit.
- **Three ways a branch ends up holding work you didn't write.**
  - **`git commit` commits the index, not what you staged — and the main tree's index is shared with
    every other session in it.** `git add <my-folder>` then `git commit` swept a concurrent session's
    staged rename into this change's `chore: shape …` commit. Nothing warns: `git status` was clean
    at session start and the other session staged in between. Parallel shaping in the main tree is
    the normal case here, so run `git status --porcelain` **unscoped** before committing there and
    commit with explicit pathspecs (`git commit -- <paths>`). What the fix isn't: once the commit is
    an ancestor of your branch, splitting it does **not** get the passenger out of the PR — a
    squash-merge flattens both halves into one commit anyway.
  - **Rebasing onto a squash-merged `main` resurrects the merged change's own commits** — and **you
    don't have to be the one who rebases.** No shared ancestor survives the squash, so a branch shaped
    before it replays that change's `chore: shape …` commit as a new one, re-adding a `CHANGE.md` for
    work already archived. The wider trigger: `main` is one ref shared by every worktree, so another
    session merging and rebasing it rewrites your base commit out from under you — your branch keeps
    descending from the orphan and `main..HEAD` grows their commits with no action of yours at all. It
    surfaces at land time, as a diff you cannot honestly grade. Either way, diff `main..HEAD` and drop
    what you didn't write: `git rebase --onto main <stowaway-sha> <branch>`, where the stowaway is your
    own old base. Check the version bumps in the same pass — the other change may have taken the number
    yours targets, which is exactly what `pnpm validate:versions` measures against `origin/main`'s tip;
    `git fetch` first, or it grades you against a stale base.
  - **Every way to rewind a branch is blocked by `block-dangerous-commands.sh`.** Not just
    `git reset --hard` — `git branch -f`, `git branch -D`, `git checkout .` and `git restore .` are
    all in `DANGEROUS_PATTERNS`, so an agent cannot move a branch backwards at all and must hand the
    command to you. `git rebase` is not blocked, so prefer `rebase --onto` where it reaches;
    otherwise expect to run the rewind yourself.
    - **One rewind does get through, and it is the one to use for a throwaway commit.** The patterns
      match `--hard` and the bare-dot forms, not a **mixed** `git reset HEAD~<n>` followed by
      `git restore <paths named individually>` — so dropping a probe commit you just made is an
      agent-runnable two-step, and only the blunt forms need you. It leaves untracked files alone,
      which is what you want when the probe added one.
