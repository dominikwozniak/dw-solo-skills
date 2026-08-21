---
name: dw-init
description: >-
  Scaffold a private/solo repo for the solo loop — `.ai/` (work / backlog / archive),
  `docs/decisions/`, `CONTEXT.md`, a tracked `AGENTS.md` with a Task Router and a size budget, the
  guardrail hooks, settings with a derived allow-list, and an optional pre-commit. Explicit-invoke
  only.
argument-hint: "bare detects the stack from disk · any project context to seed"
disable-model-invocation: true
---

# dw-init — scaffold a repo for the solo lane

Everything the loop assumes a repo has, written in one gated pass: the `.ai/` state the skills read
and write, the durable homes they promote into, the guardrail hooks, and a settings file whose
allow-list is **derived from the project rather than guessed**.

## What it writes

| Path                                | Tracked?          | Purpose                                                  |
| ----------------------------------- | ----------------- | -------------------------------------------------------- |
| `.ai/work/`                         | **tracked**       | one folder per change (`dw-shape` writes `CHANGE.md`)    |
| `.ai/README.md`                     | **tracked**       | what `.ai/` is and who owns it                           |
| `.ai/backlog/` + its `README.md`    | **tracked**       | one file per follow-up, between changes                  |
| `.ai/archive/` + its `README.md`    | **tracked**       | landed change docs — history, not guidance               |
| `docs/decisions/` + its `README.md` | **tracked**       | durable decision records (`dw-land` promotes here)       |
| `CONTEXT.md`                        | **tracked**       | the project's glossary — terms only                      |
| `VERIFY.md`                         | **tracked**       | how to start this project and drive a feature by hand    |
| `AGENTS.md`                         | **tracked**       | the one always-loaded file: rules, commands, Task Router |
| `CLAUDE.md`                         | **tracked**       | a symlink to `AGENTS.md` — never a second copy           |
| `scripts/check-agents-docs.mjs`     | **tracked**       | the gate on that file's budget, router and commands      |
| `.claude/settings.json`             | **tracked**       | permissions (ask + deny + derived allow) and hook wiring |
| `.claude/hooks/*.sh`                | **tracked**       | the guardrail scripts those settings reference           |
| `.worktreeinclude`                  | **tracked**       | gitignored files a fresh worktree should carry in        |
| `.gitignore`                        | tracked           | a managed marker block for the personal files            |
| `.husky/` + `.lintstagedrc.json`    | tracked, optional | the pre-commit twin of the hooks — only when opted in    |

Deliberately absent: `.ai/verify/` and `.ai/handoffs/` — the solo lane has one thin closing pass
that writes no artifact, and no one to hand off to. The root `VERIFY.md` is **not** that folder: one
file saying how to drive the project, written once and read by every change, never a per-change
artifact. Also absent: **`CLAUDE.local.md`**. Agent memory
is tracked `AGENTS.md`, because a gitignored file survives neither a fresh clone nor a
`git worktree`, and a second always-loaded file forks the corpus in two — `docs/decisions/` in a
scaffolded repo carries the record. Personal, cross-project notes belong in `~/.claude/CLAUDE.md`.
`.gitignore` still names `CLAUDE.local.md` so a stray one is never committed, and the hooks still
read it when they find one, so a repo scaffolded before this keeps working untouched.

Also absent: an empty `docs/agents/`. The Task Router ships with rows for what the scaffold actually
creates, and the topic layer grows only when `dw-land` promotes into it — a new topic file and its
router row in the same commit.

Templates come from `${CLAUDE_PLUGIN_ROOT}/templates/` — this lane's own payload.
(`${CLAUDE_PLUGIN_ROOT}` is the env var Claude Code substitutes to this plugin's install dir.)

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
- What already exists: `AGENTS.md`, `CLAUDE.md` (a real file? a symlink? to what?), a legacy
  `CLAUDE.local.md`, `.claude/settings*`, `.gitignore`, `CONTEXT.md`, `docs/`. This is rarely a
  greenfield tree, and step 3 must diff against reality. A repo already carrying a real `CLAUDE.md`
  with content is the case to slow down on — it becomes `AGENTS.md` plus a symlink, which is a
  rename the user has to approve at the gate, not a clobber.

### 2. Pick the hooks

Five are always offered because they're stack-agnostic: `block-dangerous-commands`,
`block-env-access`, `enforce-commit-hygiene`, `credential-leak-guard` and `large-file-guard`. Add the
JS/TS ones only where that stack is actually present: `block-non-pnpm`, `lint-on-edit`,
`typecheck-on-stop`. On a stack with no lint or typecheck hook, offer the five alone and say the rest
are stack-specific rather than silently writing nothing.

`guard-plugin-canon` is **shape-specific, not stack-specific** — offer it only where step 1 found a
`plugins/` directory whose entries are symlinks back into the tree. It refuses an edit aimed through
one of those links and names the canon instead, so on a repo with no such layout it is a hook that
can never fire.

### 3. HARD STOP — show what you're about to write

List every path, marked **tracked** or **ignored**, with a diff for anything that already exists.
Add three things that aren't paths: **the `permissions.allow` list derived in step 1**, so what the
agent may run without asking is approved rather than assumed; **the optional pre-commit offer**
(step 5), so the one gate covers it; and, when the repo already has a real `CLAUDE.md`, **the
`git mv CLAUDE.md AGENTS.md` rename** it needs, spelled out — that one moves a file the user wrote and
must never be inferred from silence. **Wait for explicit confirmation.** Scaffolding mutates the repo
and a wrong clobber is expensive — this gate is not optional even though the rest of the lane is
light.

### 4. Write

- `mkdir -p .ai/work .ai/backlog .ai/archive docs/decisions docs/agents`; seed `.ai/work` with
  `.gitkeep` (the other four get READMEs). **Remove a `.gitkeep` that a README now supersedes** — an earlier version
  seeded `docs/decisions/.gitkeep`, so a repo scaffolded then and re-run now keeps a redundant one
  beside the README, and the next reader cannot tell which is the convention.
- `.ai/README.md` — copy `${CLAUDE_PLUGIN_ROOT}/templates/work-README.md` verbatim. It states the
  lifecycle a reader gets wrong: a `CHANGE.md` leaves `work/` at merge — archived, never deleted.
- `.ai/backlog/README.md`, `.ai/archive/README.md` and `docs/decisions/README.md` — copy
  `${CLAUDE_PLUGIN_ROOT}/templates/backlog-README.md`,
  `${CLAUDE_PLUGIN_ROOT}/templates/archive-README.md` and
  `${CLAUDE_PLUGIN_ROOT}/templates/decisions-README.md` verbatim.
  `docs/agents/README.md` — copy `${CLAUDE_PLUGIN_ROOT}/templates/agents-docs-README.md` verbatim. It
  is the contract the template's Task Router row points at, so the row and the file arrive together or
  path sync fails on the first run.
  **Existing entries in any of the three dirs are left alone** — they carry real content from
  earlier changes.
  A legacy single-file `.ai/BACKLOG.md`, if present, is named at the gate: offer to split it into
  per-file entries, never clobber or silently keep it.
- `CONTEXT.md` — if absent, create it with a one-line purpose statement (this project's glossary;
  terms only, no implementation detail) and nothing else. If it exists, leave it alone.
- `VERIFY.md` — if absent, create it the same way, and write exactly this much: a one-line purpose
  statement, the two invariants below, then the three headings with **one line under each naming what
  belongs there**. It holds what a green suite does not — **Launch** (the command that starts this
  project, on what port, with what disposable state), **Doctor** (one read-only check answering "is
  this instance worth driving?"), **Drive** (the commands, each paired with the observable result it
  should produce). The invariants go in before any of that is filled, both learned the hard way:
  cleanup removes instances and scratch state but **never the evidence**, and **kill what you started**
  rather than killing by process name. **Filling the three sections is not this skill's job**, and a
  project with nothing to launch leaves those lines as written — that is a finished `VERIFY.md`, not a
  stub owed to anyone. A library, a docs repo or a skills catalog has no instance to drive, and an
  honest empty section beats an invented command every session pays for. If it exists, leave it alone.
- `${CLAUDE_PLUGIN_ROOT}/templates/settings.json` → `.claude/settings.json`; **prune** the hook
  entries not selected, add the `permissions.allow` list (below), then confirm the file still parses
  as valid JSON.
- `AGENTS.md` — if absent, render `${CLAUDE_PLUGIN_ROOT}/templates/AGENTS.md`, substituting
  `{{PROJECT_NAME}}` `{{DEFAULT_BRANCH}}` `{{STACK}}` `{{TEST_COMMAND}}` `{{LINT_COMMAND}}`
  `{{TYPECHECK_COMMAND}}` `{{COMMIT_PATTERN}}` `{{COMMIT_TRAILER}}` `{{HOOKS_INSTALLED}}`
  `{{AGENTS_CHECK_COMMAND}}`. **Every placeholder gets
  a value or the line goes** — a `{{…}}` left in the file is read as content by the next session and
  `eval`ed as a command by the hooks, which is why they carry an explicit guard against exactly
  these tokens.
  - The commands come from step 1 **verbatim**; `none` where the manifests had none. Write `none`,
    not a plausible guess and not `_(none detected)_`: the hooks read `none` as "skip", and a command
    that doesn't exist fails on every edit.
  - `{{COMMIT_PATTERN}}` and `{{COMMIT_TRAILER}}` are policy, not detected commands, so ask rather
    than probe: derive the pattern from the log the repo already has (`git log --format=%s -30`) and
    propose it, and write `none` for the trailer unless the user says every commit must carry one.
    Both defaults live in `enforce-commit-hygiene.sh` — Conventional Commits for the pattern, `none`
    for the trailer — so an honest `none` is always a safe answer here.
  - `{{LINT_COMMAND}}` is the **per-file** form (`pnpm exec eslint --fix`, `ruff check --fix`), since
    `lint-on-edit` appends one path to it — not the whole-project script, which would re-lint the
    tree on every edit. Where the project only has the whole-project form, say so at the gate and
    write `none` rather than wiring a slow hook.
  - **Prune the Task Router row for anything this run didn't create.** The template ships a row
    pointing at `.claude/hooks/`, and that directory only exists if step 2 selected a hook — so a
    scaffold that declined them all fails its own `agents:check` on its first run, because path sync
    requires every routed path to exist. Same rule for any row whose target you skipped. A row is a
    promise that the file is there.
  - Idempotency is per-section: if `AGENTS.md` already exists, leave it alone and report which of the
    template's sections it is missing. Never merge a rendered template into a file someone wrote.
- `scripts/check-agents-docs.mjs` — copy `${CLAUDE_PLUGIN_ROOT}/templates/check-agents-docs.mjs`
  verbatim. Zero dependencies, Node built-ins only, and it finds the repo root by walking up from its
  own location to the nearest `AGENTS.md` — so `scripts/` is the conventional home, not a required
  one. It checks six things: the declared budget, that no `{{…}}` placeholder survived, Task Router
  coverage and path sync, that every `pnpm <script>` named in `AGENTS.md` exists, and that `CLAUDE.md`
  is a symlink. Under `docs/decisions/` it checks **size only**, and only where the folder's README
  declares a `Ceiling:` line — the bar, the shape and the numbering stay editorial, because a commit
  blocked over a record's shape teaches you to stop writing them.
  - `{{AGENTS_CHECK_COMMAND}}` is how `AGENTS.md`'s own header names its enforcement. With a
    `package.json`, add `"agents:check": "node scripts/check-agents-docs.mjs"` to `scripts` and render
    `pnpm agents:check`; where the repo has an aggregate gate script (`check`, `verify`), add it to
    that too. Without a `package.json`, render the bare `node scripts/check-agents-docs.mjs` — and say
    at the gate that the checker needs Node even where the project does not.
- `CLAUDE.md` — `ln -s AGENTS.md CLAUDE.md`. A **symlink**, never a copy: the harnesses load
  `CLAUDE.md`, the file is `AGENTS.md`, and a materialized second copy is the fork this whole layout
  exists to prevent. If a real `CLAUDE.md` with content is already there, it was approved at the gate
  as a rename — `git mv CLAUDE.md AGENTS.md`, then link — and its content stays; reconcile it against
  the template's sections afterwards rather than overwriting.
- The selected `${CLAUDE_PLUGIN_ROOT}/templates/hooks/*.sh` → `.claude/hooks/`, `chmod +x` each.
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

**Seed `.ai/backlog/` and `.ai/archive/` with their READMEs and nothing else** — no example entry, no
`TODO`, nothing standing in for one. On the next read a placeholder is indistinguishable from real
queued work, and a backlog you have to first decide isn't real is one you stop opening. The copied
`backlog-README.md` states the entry shape; entries arrive later, from `dw-land`.

### 5. Optional — wire the pre-commit

Only when opted in at the gate. `pnpm add -D husky lint-staged`, `pnpm exec husky init`, then write
`.husky/pre-commit` and `.lintstagedrc.json` from the shapes in `references/precommit.md` — globs
matched to the formatter and linter step 1 actually detected, never to a tool that isn't installed.
Typecheck and test lines are separate opt-ins: both run the whole project per commit. **`agents:check`
is not an opt-in** — it goes in uncommented and unguarded, because it reads a handful of files rather
than building the project, and the reference explains why a staged-paths guard on it leaks. On a repo
that's partly wired, fill the gaps and show diffs — never overwrite blind; the re-run rules are in
the reference. Worth having even solo: it catches the commits made outside a session, where no hook
fires.

Where the repo has no `package.json` and so no husky, say what that leaves uncovered rather than
inventing a gate: `AGENTS.md` can then drift past its budget until someone runs the checker by hand.

### 6. Reconcile tracking

The split is the whole point, so enforce it after writing: `.ai/`, `docs/decisions/`, `CONTEXT.md`,
`AGENTS.md`, `CLAUDE.md`, `.claude/settings.json` and `.claude/hooks/` (plus `.husky/` when written)
must **not** be ignored — remove any pre-existing rule that ignores them. `CLAUDE.local.md` and
`.claude/settings.local.json` must **be** ignored: nothing writes the first any more, and the rule
is what keeps a stray one from being committed.

`git add` the `CLAUDE.md` symlink and confirm git recorded it as one — `git ls-files -s CLAUDE.md`
must show mode `120000`. A repo with `core.symlinks=false` stores the link as a text file holding the
target's name, which reads as a one-line `CLAUDE.md` and silently un-forks nothing; say so rather
than leaving it.

### 7. Report

List what was written and which paths to `git add`. If the pre-commit was declined, say what that
leaves uncovered: commits made outside a session run with no formatter and no guardrails. Name the
`_(…)_` placeholders left in `AGENTS.md` for the user to fill — the template ships the sections, only
they know this project's invariants.

## References

- `references/precommit.md` — detection signals, glob→command mapping, the `.husky/pre-commit` and
  `.lintstagedrc.json` shapes, and the idempotent re-run rules. Read it before step 5.

**Next:** `dw-shape` to open the first change, or `dw-doctor` to verify the scaffold actually fires.

$ARGUMENTS
