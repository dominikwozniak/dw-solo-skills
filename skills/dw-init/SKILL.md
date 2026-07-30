---
name: dw-init
description: >-
  Scaffold a private/solo repo for the `dw-grill → dw-shape → dw-next → dw-land` loop —
  `.ai/work/`, `docs/decisions/`, `CONTEXT.md`, a `## Gotchas` section in `CLAUDE.md`, and the
  guardrail hooks. Sized for a repo only you read. Explicit-invoke only. Use when setting up one of
  your own projects, or when someone says "init this project", "set up the solo loop".
argument-hint: "any project context to seed (stack, what it is)"
disable-model-invocation: true
---

# dw-init — scaffold a repo for the solo lane

The setup step for **your own** projects. A team scaffold gives a repo tracked specs, verification
artifacts and handoffs, because other people will read them; this one scaffolds a repo where you are
the only reader, and drops everything that only pays off with an audience.

## What it writes

| Path                    | Tracked?           | Purpose                                                        |
| ----------------------- | ------------------ | -------------------------------------------------------------- |
| `.ai/work/`             | **tracked**        | one folder per change (`dw-shape` writes `CHANGE.md`)          |
| `.ai/README.md`         | **tracked**        | three lines saying what `.ai/` is and who owns it              |
| `.ai/BACKLOG.md`        | **tracked**        | follow-ups and parked ideas, between changes                   |
| `docs/decisions/`       | **tracked**        | durable decision records (`dw-land` promotes here)             |
| `CONTEXT.md`            | **tracked**        | the project's glossary — terms only                            |
| `CLAUDE.md`             | **tracked**        | `## Commands` + `## Gotchas` — `dw-land` appends to the latter |
| `.claude/settings.json` | **tracked**        | permissions (ask + deny + derived allow), hooks, lane switch   |
| `.claude/hooks/*.sh`    | **tracked**        | the guardrail scripts those settings reference                 |
| `CLAUDE.local.md`       | personal / ignored | your commands, git conventions, and the loop                   |
| `.gitignore`            | tracked            | a managed marker block for the personal files                  |

Note what is **absent** versus a team scaffold: no `.ai/verify/`, no `.ai/handoffs/`. This lane has one
quality pass that writes no artifact, and no one to hand off to.

Templates come from `${CLAUDE_PLUGIN_ROOT}/templates/` — this plugin's own canon, already shaped for
this lane, so every file is copied as-is with no post-copy rewriting.
(`${CLAUDE_PLUGIN_ROOT}` is the env var Claude Code substitutes to this plugin's install dir.)

## Workflow

### 1. Detect — never assume the stack

- Repo root (`git rev-parse --show-toplevel`) and default branch
  (`git symbolic-ref --short refs/remotes/origin/HEAD`, else `init.defaultBranch`, else `main`).
- Test / lint / typecheck commands from the manifests actually present — `package.json` scripts,
  `Gemfile` + `bin/`, `Cargo.toml`, `pyproject.toml`, `go.mod`, `Makefile`. Read the real commands;
  don't invent them. **Keep this list** — it becomes the `permissions.allow` entries in step 4, and a
  command you didn't find here must not appear there.
- What already exists: `CLAUDE.md`, `CLAUDE.local.md`, `.claude/settings*`, `.gitignore`, `CONTEXT.md`,
  `docs/`. This is rarely a greenfield tree, and step 3 must diff against reality.

### 2. Pick the hooks

Three are always offered because they're stack-agnostic: `block-dangerous-commands`,
`block-env-access`, and `link-local-memory` (a `SessionStart` hook that symlinks the main tree's
gitignored `CLAUDE.local.md` into a `git worktree`, so `dw-git` and the lint/typecheck hooks still see
the project's conventions there — a silent no-op outside a worktree). Add the stack-specific ones only
where the stack is actually present — `block-non-pnpm`, `lint-on-edit`, `typecheck-on-stop` for JS/TS,
`lint-on-edit-rb` for Ruby. On a stack with no lint or typecheck hook, offer the three alone and say
the rest are stack-specific rather than silently writing nothing.

### 3. HARD STOP — show what you're about to write

List every path, marked **tracked** or **ignored**, with a diff for anything that already exists. Add two
things that aren't paths: **the `permissions.allow` list you derived in step 1**, so what the agent may
run without asking is approved rather than assumed, and **the team-lane plugins you're about to disable
for this repo**, since that changes which skills exist here. **Wait for explicit confirmation.**
Scaffolding mutates the repo and a wrong clobber is expensive — this gate is not optional even though the
rest of the lane is light.

### 4. Write

- `mkdir -p .ai/work docs/decisions` and seed each with `.gitkeep`.
- `${CLAUDE_PLUGIN_ROOT}/templates/work-README.md` → `.ai/README.md`, copied as-is. It already states
  the asymmetry that is the one thing a reader gets wrong: `CHANGE.md` does not survive a merge,
  `BACKLOG.md` does.
- `.ai/BACKLOG.md` — if absent, write the shape below. **If it exists, leave it alone** — it is the one
  file here that carries real content from earlier changes, and clobbering it loses queued work.
- `CONTEXT.md` — if absent, create it with a one-line purpose statement (this project's glossary;
  terms only, no implementation detail) and nothing else. If it exists, leave it alone.
- `${CLAUDE_PLUGIN_ROOT}/templates/settings.json` → `.claude/settings.json`; **prune** the hook
  entries not selected, add the `permissions.allow` list (below), then confirm the file still parses as
  valid JSON.
- `CLAUDE.md` — seed **two** sections. Idempotency is per-section: create the file with just them if
  it's absent, append whichever one is missing, and leave an existing one alone. Both go in tracked
  `CLAUDE.md` rather than `CLAUDE.local.md` because they have to be **auto-loaded** (so the next session
  actually reads them), **tracked** (so they outlive the machine), and in **one** place.
  - `## Commands` — the test / lint / typecheck commands **exactly as detected in step 1**, one line
    each, and `_(none detected)_` where the manifests had none. Same rule as `permissions.allow`:
    never write a command you didn't find. This is the only copy that survives a fresh clone or is
    readable by an agent that reads `AGENTS.md` rather than `CLAUDE.local.md`, which is why it is
    tracked; `CLAUDE.local.md` keeps its own copy because the lint and typecheck **hooks grep that
    file**, so the two are both load-bearing and must agree.
  - `## Gotchas` — one line of purpose (traps this project has actually sprung, newest first) and
    nothing else. `dw-land` appends to it.
- The selected `${CLAUDE_PLUGIN_ROOT}/templates/hooks/*.sh` → `.claude/hooks/`, `chmod +x` each.
- `CLAUDE.local.md` — if absent, render `${CLAUDE_PLUGIN_ROOT}/templates/CLAUDE.local.md` and
  substitute `{{PROJECT_NAME}}` `{{DEFAULT_BRANCH}}` `{{STACK}}` `{{TEST_COMMAND}}`
  `{{LINT_COMMAND}}` `{{TYPECHECK_COMMAND}}` `{{HOOKS_INSTALLED}}`. The template already carries this
  lane's `## Workflow`, so there is no section to rewrite afterwards. If it exists, leave it alone.
- Append `${CLAUDE_PLUGIN_ROOT}/templates/gitignore-block.txt` to `.gitignore` between its markers.
  **Idempotent**: if the markers are already there, replace the block in place, never duplicate it.
- **Switch the lane off for the team plugins** — after `.claude/settings.json` exists, run
  `claude plugin disable dw-planning --scope project` and `claude plugin disable dw-quality --scope project`.
  Then confirm the file still parses as valid JSON: the CLI rewrites it (it also reorders the
  `permissions` keys), so re-check rather than assume.

**The `permissions.allow` list — derived, never invented.** The template ships `ask` and `deny` only,
so nothing is pre-approved and every check waits on a prompt unless a global setting happens to cover
it. This is the difference between a lane that runs and one that idles, so build the list from what
step 1 actually found:

- **The project's own checks, exactly as detected.** Match the wildcard style already used in the
  template's `ask` list — a bare entry plus an argument form, e.g. `Bash(pnpm test)` and
  `Bash(pnpm test *)`. **Never allowlist a script that isn't in the manifest**: an entry for a command
  that doesn't exist is worse than no entry, because it reads as verified.
- **The read-only git surface every skill in this lane uses** — `git status`, `git diff`, `git log`,
  `git rev-parse`, `git symbolic-ref`, in the same two forms. (`git rev-parse --abbrev-ref HEAD` is
  how this lane resolves the branch; `git branch --show-current` is deliberately not used, since it
  returns empty on a detached HEAD.)

**Write nothing that overlaps `ask` or `deny`.** Don't reason about which list wins — just never add an
entry that could match `git commit`, `git push`, anything in the template's `ask` list, or anything
touching `.env`. Adding write or network commands here is not a speed optimisation; it removes the gate
the rest of the lane is built around.

**The lane switch — use the CLI, never hand-write the key.** `claude plugin disable dw-planning --scope
project` adds an `enabledPlugins` entry to `.claude/settings.json`, keyed `dw-planning@` plus the
marketplace id and set to `false` — **with the correct id filled in for you**. Write that key by hand and
you have to know the id, and a wrong one is **silently ignored**: no error, no warning, the team lane
simply stays on. The CLI is the only way to get it right without guessing, so use it even though the
result is only two lines of JSON.

`dw-planning` and `dw-quality` ship from a **different marketplace** (`dw-skills`) than this plugin, so
in most repos they simply aren't installed and there is nothing to switch off. The step stays because
the one case it guards is real and silent: a repo that has both lanes installed has two skills
competing for "start a feature", and no description wording fixes that.

Two consequences worth stating: it only works for a plugin that is actually **installed** here — if
neither team plugin is, there is nothing to disable, so skip it and say so rather than treating the
failure as an error. And it **only ever disables**: never run `claude plugin enable` from this skill.
Enabling is an install-time decision, and a scaffolder that switches plugins on is one that can
surprise you.

The `.ai/BACKLOG.md` to write — this is the **whole file**, verbatim:

```markdown
# Backlog

Follow-ups and ideas not being worked on now. Newest first, one line each. The bar: if you would not
pick it up within a month, don't write it. `dw-land` parks them here when it closes a change;
`dw-shape` reads this when opening the next one and deletes the line it takes.
```

**Seed it with no entries** — no example line, no `TODO`, nothing standing in for one. On the next read a
placeholder is indistinguishable from real queued work, and a backlog you have to first decide isn't
real is one you stop opening. Entries arrive later, one line each, in the form
`- [YYYY-MM-DD] what it is and why it matters`.

Keep it exactly this flat. It has **no status column, no priority, no frontmatter** on purpose: the
moment it grows a schema it is the validated status table this lane exists to avoid. Nothing checks
it, and that is the point — a flat list has no invariant that can break silently.

The `## Workflow` block to write:

```markdown
## Workflow

- Loop: `/dw-shape → /dw-next`, then `/dw-land` before the PR. `/dw-grill` first when the idea is fuzzy.
- One change at a time lives in `.ai/work/<slug>/CHANGE.md` — tracked, and deleted by `/dw-land` at merge.
- `/dw-next` bare answers "where were we" from disk; `/dw-next go` builds the next task.
- Durable knowledge is promoted out, not accumulated: decisions → `docs/decisions/`, terms → `CONTEXT.md`.
- Follow-ups and out-of-scope ideas go to `.ai/BACKLOG.md` — `/dw-land` parks them, `/dw-shape` picks the next one up.
```

### 5. Reconcile tracking

The split is the whole point, so enforce it after writing: `.ai/`, `docs/decisions/`, `CONTEXT.md`,
`CLAUDE.md`, `.claude/settings.json` and `.claude/hooks/` must **not** be ignored — remove any
pre-existing rule that ignores them. `CLAUDE.local.md` and `.claude/settings.local.json` must **be**
ignored.

### 6. Report

List what was written and which paths to `git add`, and name the team-lane plugins now disabled for this
repo — running both lanes in one project is what makes two skills compete for the same request, and the
scaffold has just settled it. If a disable didn't apply (the plugin wasn't installed, or the command
failed), say that plainly instead of reporting a lane switch that isn't there.

**Next:** `dw-shape` to open the first change, or `dw-git` to commit the scaffold.

$ARGUMENTS
