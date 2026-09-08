# Worktrees — what `worktree.sh` gives you, and what it doesn't

Worktrees live at `.claude/worktrees/<slug>` on branch `<slug>`; `scripts/runtime/worktree.sh` owns
create and remove. A `claude -w <slug>` session spells the branch `worktree-<slug>` instead, which
is why `dw-next` strips that prefix before matching a change doc.

## Gotchas

- **The session can leave the worktree between one skill invocation and the next, and say nothing.**
  A `/dw-…` command arrived with the shell back in the **main tree on the default branch** after
  several invocations had run inside the worktree. Nothing errors: `git diff <base>...HEAD` comes back
  empty, so a closing verdict grades the change as "no diff" and its promotion commit lands on the
  default branch. **Re-assert the worktree at the top of any skill that reads a diff or commits** —
  `pwd` plus the branch, then re-enter with the worktree path if it drifted. Nothing is lost when it
  happens: only the session's working directory moved.
- **A worktree is not the main tree, and every way it differs reads as something else.**
  Seven traps, one root cause: the worktree gets tracked files and a branch, and nothing else.
  - **A legacy `CLAUDE.local.md` is absent.** It is gitignored, no checkout delivers it, and nothing
    links it in. A repo still keeping its lint or typecheck bullet there resolves neither inside a
    worktree, and both hooks fall through to their probes without a word. Those bullets belong in
    tracked `AGENTS.md`, which is what a checkout delivers.
  - **It runs no git hooks at all.** `core.hooksPath` is `.husky/_`, which `husky init` generates and
    gitignores — so the checkout has `.husky/pre-commit` and no `_/`, git finds no hooks directory,
    and every commit skips prettier, agnix and the manifest version check **without printing
    anything**. Run `pnpm install` before your first commit; `worktree.sh create` warns on stderr, and
    the warning is easy to scroll past.
  - **A hook fix made here doesn't take effect here.** Claude Code resolves `.claude/hooks/` from
    `${CLAUDE_PROJECT_DIR}`, the **main tree**, so the session keeps firing `main`'s copy until the
    branch merges. Verify by invoking the worktree copy directly with a synthetic payload.
  - **The session refuses shell it cannot read, and it reads as a permission problem.** Where the
    harness isolated the session — `claude -w`, a subagent worktree, the desktop app — every Bash call
    must be statically provable to leave the tree outside the worktree alone, and what defeats the
    proof is unreadability, not length: a `for` loop, a heredoc feeding an interpreter, a computed or
    globbed program name, a `../../..` path. A chain of plain git commands passes. Reissue as plain
    separate commands. This is not the dangerous-command hook; the message names the worktree, not a
    blocked pattern.
  - **A `PreToolUse` hook that rewrites commands makes plain git unrunnable, invisibly.** That same
    guard refuses a git command carried by a wrapper it cannot read through, and the session never sees
    the wrapper: `rtk hook claude` returns `git status --short` as `rtk git status --short` in
    `updatedInput`, and the refusal reads "runs rtk with a git command among its operands". So a bare
    `git status` is refused while `git rev-parse` and `git switch` work — the two verbs rtk leaves
    alone. The guard has no off switch, so the rewrite stands down instead:
    `~/.claude/hooks/rtk-hook-guard.sh` passes a git-naming command through unrewritten whenever the
    cwd is a linked worktree.
  - **Gitignored material a change doc anchors at is absent.** `/.inspirations/` and `/TASK.md` are
    gitignored, so a `CHANGE.md` whose `## Anchors` cites one points at nothing from here. Read it
    through the main tree's absolute path; the harness allows that read even though it refuses writes
    outside the worktree.
  - **That same absolute path silently reads `main`'s copy of anything _tracked_.** Both trees hold
    identical relative paths, so the main-tree and worktree spellings of `skills/dw-next/SKILL.md`
    both exist and differ by every commit on the branch. `Edit` **refuses** the main-tree path, `Read`
    **succeeds silently** — so nothing is corrupted and you reason about the wrong text. The tell is
    line numbers disagreeing with a `grep` run in the worktree. Prefer relative paths; they cannot get
    this wrong.
