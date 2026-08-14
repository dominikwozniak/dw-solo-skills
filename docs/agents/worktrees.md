# Worktrees — what `dw-start` gives you, and what it doesn't

Worktrees live at `.claude/worktrees/<slug>` on branch `<slug>`; `scripts/runtime/worktree.sh` owns
create and remove. A `claude -w <slug>` session spells the branch `worktree-<slug>` instead, which
is why `dw-next` strips that prefix before matching a change doc.

## Gotchas

- **A `dw-start` worktree is not the main tree, and every way it differs reads as something else.**
  Six traps, one root cause: the worktree gets tracked files and a branch, and nothing else.
  - **A legacy `CLAUDE.local.md` is simply absent from one.** It is gitignored, so no checkout
    delivers it, and nothing links it in any more — the link class retired with decision 0007, taking
    the `SessionStart` hook and `worktree.sh`'s link step with it. A repo still keeping its lint or
    typecheck bullet there resolves neither inside a worktree, and both hooks fall through to their
    probes without a word. Move those bullets into tracked `AGENTS.md`, which is where they belong and
    what a checkout delivers.
  - **It runs no git hooks at all.** `core.hooksPath` is `.husky/_`, which `husky init` generates and
    gitignores — so the checkout has `.husky/pre-commit` and no `_/`, git finds no hooks directory,
    and every commit skips prettier, agnix and the manifest version check **without printing
    anything**. Run `pnpm install` before your first commit; `worktree.sh create` warns on stderr,
    but the warning is easy to scroll past.
  - **A hook fix made here doesn't take effect here.** Claude Code resolves `.claude/hooks/` from
    `${CLAUDE_PROJECT_DIR}`, the **main tree**, so the session keeps firing `main`'s copy until the
    branch merges. Fixing `lint-on-edit.sh` and watching it fail identically is a different file
    running, not the fix failing. Verify by invoking the worktree copy directly with a synthetic
    payload.
  - **The session refuses compound shell, and it reads as a permission problem.** The harness rejects
    any Bash call it cannot statically prove stays inside the worktree — `cmd; cmd` chains with a
    redirect, a `../../..` path, a heredoc. Issue plain separate commands. This is not the
    dangerous-command hook; the message names the worktree, not a blocked pattern.
  - **Gitignored material a change doc anchors at is simply absent.** `/.inspirations/` and `/TASK.md`
    are gitignored, so a `CHANGE.md` whose `## Anchors` cites one — the standard a task is measured
    against, say — points at nothing from here. Read it through the main tree's absolute path; the
    harness allows the read even though it refuses writes outside the worktree.
  - **That same absolute path silently reads `main`'s copy of anything _tracked_.** Both trees hold
    identical relative paths, so `…/dw-solo-skills/skills/dw-git/SKILL.md` and
    `…/worktrees/<slug>/skills/dw-git/SKILL.md` both exist and differ by every commit on the branch.
    The asymmetry is the trap: `Edit` **refuses** the main-tree path, `Read` **succeeds silently** — so
    nothing is corrupted and you reason about the wrong text. The tell is line numbers disagreeing with
    a `grep` run in the worktree; the conclusion it invites is that a proxy is filtering the output.
    Prefer relative paths — they cannot get this wrong.
