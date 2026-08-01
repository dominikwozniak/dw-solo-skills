---
name: dw-init
description: >-
  Scaffold a private/solo repo for the solo loop — `.ai/work/`, `.ai/BACKLOG.md`,
  `docs/decisions/`, `CONTEXT.md`, `## Commands` + `## Gotchas` in `CLAUDE.md`, the guardrail
  hooks, settings with a derived allow-list, and an optional pre-commit. For a repo where you are
  the only reader. Explicit-invoke only. Use when setting up one of your own projects, or when
  someone says "init this project", "set up the solo loop".
argument-hint: "any project context to seed (stack, what it is)"
disable-model-invocation: true
---

# dw-init — scaffold a repo for the solo lane

The setup step for **your own** projects: everything the loop assumes a repo has, written in one
gated pass — the `.ai/` state the skills read and write, the durable homes they promote into, the
guardrail hooks, and a settings file whose allow-list is derived from the project rather than
guessed. It drops everything that only pays off with an audience: no verification artifacts, no
handoffs, no status tables.

## What it writes

| Path                             | Tracked?           | Purpose                                                        |
| -------------------------------- | ------------------ | -------------------------------------------------------------- |
| `.ai/work/`                      | **tracked**        | one folder per change (`dw-shape` writes `CHANGE.md`)          |
| `.ai/README.md`                  | **tracked**        | what `.ai/` is and who owns it                                 |
| `.ai/BACKLOG.md`                 | **tracked**        | follow-ups and parked ideas, between changes                   |
| `docs/decisions/`                | **tracked**        | durable decision records (`dw-land` promotes here)             |
| `CONTEXT.md`                     | **tracked**        | the project's glossary — terms only                            |
| `CLAUDE.md`                      | **tracked**        | `## Commands` + `## Gotchas` — `dw-land` appends to the latter |
| `.claude/settings.json`          | **tracked**        | permissions (ask + deny + derived allow) and hook wiring       |
| `.claude/hooks/*.sh`             | **tracked**        | the guardrail scripts those settings reference                 |
| `CLAUDE.local.md`                | personal / ignored | your commands, git conventions, and the loop                   |
| `.worktreeinclude`               | **tracked**        | gitignored files a fresh worktree should carry in              |
| `.gitignore`                     | tracked            | a managed marker block for the personal files                  |
| `.husky/` + `.lintstagedrc.json` | tracked, optional  | the pre-commit twin of the hooks — only when opted in          |

Deliberately absent: `.ai/verify/` and `.ai/handoffs/` — the solo lane has one thin closing pass
that writes no artifact, and no one to hand off to.

Templates come from `${CLAUDE_PLUGIN_ROOT}/templates/` — this lane's own payload; the guardrail
hooks in it are vendored copies of the team repo's canon. (`${CLAUDE_PLUGIN_ROOT}` is the env var
Claude Code substitutes to this plugin's install dir.)

## Workflow

### 1. Detect — never assume the stack

- Repo root (`git rev-parse --show-toplevel`) and default branch
  (`git symbolic-ref --short refs/remotes/origin/HEAD`, else `init.defaultBranch`, else `main`).
- Test / lint / typecheck commands from the manifests actually present — `package.json` scripts,
  `Makefile`, `pyproject.toml`, `go.mod`. Read the real commands; don't invent them. **Keep this
  list** — it becomes the `permissions.allow` entries in step 4, and a command you didn't find here
  must not appear there.
- Pre-commit signals for step 5: formatter and linter deps/configs, a `test`/`typecheck` script —
  the detection table in `references/precommit.md`.
- What already exists: `CLAUDE.md`, `CLAUDE.local.md`, `.claude/settings*`, `.gitignore`,
  `CONTEXT.md`, `docs/`. This is rarely a greenfield tree, and step 3 must diff against reality.

### 2. Pick the hooks

Three are always offered because they're stack-agnostic: `block-dangerous-commands`,
`block-env-access`, and `link-local-memory` (a `SessionStart` hook that symlinks the main tree's
gitignored `CLAUDE.local.md` into a `git worktree` — which `dw-start` and `claude -w` sessions
depend on — a silent no-op outside a worktree). Add the JS/TS ones only where that stack is
actually present: `block-non-pnpm`, `lint-on-edit`, `typecheck-on-stop`. On a stack with no lint or
typecheck hook, offer the three alone and say the rest are stack-specific rather than silently
writing nothing.

### 3. HARD STOP — show what you're about to write

List every path, marked **tracked** or **ignored**, with a diff for anything that already exists.
Add two things that aren't paths: **the `permissions.allow` list derived in step 1**, so what the
agent may run without asking is approved rather than assumed, and **the optional pre-commit offer**
(step 5), so the one gate covers it. **Wait for explicit confirmation.** Scaffolding mutates the
repo and a wrong clobber is expensive — this gate is not optional even though the rest of the lane
is light.

### 4. Write

- `mkdir -p .ai/work docs/decisions` and seed each with `.gitkeep`.
- `.ai/README.md` — copy `${CLAUDE_PLUGIN_ROOT}/templates/work-README.md` verbatim. It states the
  one asymmetry a reader gets wrong: `CHANGE.md` does not survive a merge, `BACKLOG.md` does.
- `.ai/BACKLOG.md` — if absent, write the shape below. **If it exists, leave it alone** — it is the
  one file here that carries real content from earlier changes, and clobbering it loses queued work.
- `CONTEXT.md` — if absent, create it with a one-line purpose statement (this project's glossary;
  terms only, no implementation detail) and nothing else. If it exists, leave it alone.
- `${CLAUDE_PLUGIN_ROOT}/templates/settings.json` → `.claude/settings.json`; **prune** the hook
  entries not selected, add the `permissions.allow` list (below), then confirm the file still parses
  as valid JSON.
- `CLAUDE.md` — seed **two** sections. Idempotency is per-section: create the file with just them if
  it's absent, append whichever one is missing, and leave an existing one alone. Both go in tracked
  `CLAUDE.md` because they have to be **auto-loaded**, **tracked**, and in **one** place.
  - `## Commands` — the test / lint / typecheck commands **exactly as detected in step 1**, one line
    each, and `_(none detected)_` where the manifests had none. This is the only copy that survives
    a fresh clone; `CLAUDE.local.md` keeps its own copy because the lint and typecheck **hooks grep
    that file**, so the two are both load-bearing and must agree.
  - `## Gotchas` — one line of purpose (traps this project has actually sprung, newest first) and
    nothing else. `dw-land` appends to it.
- The selected `${CLAUDE_PLUGIN_ROOT}/templates/hooks/*.sh` → `.claude/hooks/`, `chmod +x` each.
- `CLAUDE.local.md` — if absent, render `${CLAUDE_PLUGIN_ROOT}/templates/CLAUDE.local.md` and
  substitute `{{PROJECT_NAME}}` `{{DEFAULT_BRANCH}}` `{{STACK}}` `{{TEST_COMMAND}}`
  `{{LINT_COMMAND}}` `{{TYPECHECK_COMMAND}}` `{{HOOKS_INSTALLED}}`. The template ships this lane's
  loop and `## Git conventions`; reconcile the rendered copy with what step 1 actually found.
- `.worktreeinclude` — if absent, copy `${CLAUDE_PLUGIN_ROOT}/templates/worktreeinclude.txt`
  verbatim. **If it exists, leave it alone.** Every line ships commented out, so it copies nothing
  until the user names a file; that is deliberate, because an uncommented guess would copy a secret
  nobody asked for. Tracked, and it earns its keep twice: Claude Code reads it for `claude -w`
  worktrees, `worktree.sh create` reads it for the loop's own. Say at the gate that it starts empty
  and the user should add their `.env` line.
- Append `${CLAUDE_PLUGIN_ROOT}/templates/gitignore-block.txt` to `.gitignore` between its markers.
  **Idempotent**: if the markers are already there, replace the block in place, never duplicate it.

**The `permissions.allow` list — derived, never invented.** The template ships `ask` and `deny`
only, so nothing is pre-approved and every check waits on a prompt unless a global setting happens
to cover it. This is the difference between a lane that runs and one that idles, so build the list
from what step 1 actually found:

- **The project's own checks, exactly as detected.** Match the wildcard style already used in the
  template's `ask` list — a bare entry plus an argument form, e.g. `Bash(pnpm test)` and
  `Bash(pnpm test *)`. **Never allowlist a script that isn't in the manifest**: an entry for a
  command that doesn't exist is worse than no entry, because it reads as verified.
- **The read-only git surface this lane uses** — `git status`, `git diff`, `git log`,
  `git rev-parse`, `git symbolic-ref`, `git branch --list`, `git worktree list`, in the same two
  forms.

**Write nothing that overlaps `ask` or `deny`.** Don't reason about which list wins — just never add
an entry that could match `git commit`, `git push`, anything in the template's `ask` list, or
anything touching `.env`. Adding write or network commands here is not a speed optimisation; it
removes the gate the rest of the lane is built around.

The `.ai/BACKLOG.md` to write — this is the **whole file**, verbatim:

```markdown
# Backlog

Follow-ups and ideas not being worked on now. Newest first, one line each. The bar: if you would not
pick it up within a month, don't write it. `dw-land` parks them here when it closes a change;
`dw-shape` reads this when opening the next one and deletes the line it takes.
```

**Seed it with no entries** — no example line, no `TODO`, nothing standing in for one. On the next
read a placeholder is indistinguishable from real queued work, and a backlog you have to first
decide isn't real is one you stop opening. Entries arrive later, one line each, in the form
`- [YYYY-MM-DD] what it is and why it matters`.

Keep it exactly this flat. It has **no status column, no priority, no frontmatter** on purpose: the
moment it grows a schema it is the validated plan this lane exists to avoid — and nothing validates
it, deliberately.

### 5. Optional — wire the pre-commit

Only when opted in at the gate. `pnpm add -D husky lint-staged`, `pnpm exec husky init`, then write
`.husky/pre-commit` and `.lintstagedrc.json` from the shapes in `references/precommit.md` — globs
matched to the formatter and linter step 1 actually detected, never to a tool that isn't installed.
Typecheck and test lines are separate opt-ins: both run the whole project per commit. On a repo
that's partly wired, fill the gaps and show diffs — never overwrite blind; the re-run rules are in
the reference. Worth having even solo: it catches the commits made outside a session, where no hook
fires.

### 6. Reconcile tracking

The split is the whole point, so enforce it after writing: `.ai/`, `docs/decisions/`, `CONTEXT.md`,
`CLAUDE.md`, `.claude/settings.json` and `.claude/hooks/` (plus `.husky/` when written) must
**not** be ignored — remove any pre-existing rule that ignores them. `CLAUDE.local.md` and
`.claude/settings.local.json` must **be** ignored.

### 7. Report

List what was written and which paths to `git add`. If the pre-commit was declined, say what that
leaves uncovered: commits made outside a session run with no formatter and no guardrails.

## References

- `references/precommit.md` — detection signals, glob→command mapping, the `.husky/pre-commit` and
  `.lintstagedrc.json` shapes, and the idempotent re-run rules. Read it before step 5.

**Next:** `dw-shape` to open the first change, or `dw-doctor` to verify the scaffold actually fires.

$ARGUMENTS
