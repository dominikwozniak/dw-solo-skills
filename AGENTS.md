# dw-solo-skills — agent instructions

A Claude Code skills catalog for repos only you read, distributed as an installable plugin
marketplace — not a code project.

The fuller, team-weight lane lives in a separate repo,
[`dw-skills`](https://github.com/dominikwozniak/dw-skills). Keep this one thin: every skill here
assumes **one reader**, and a change that needs a second reader's trust belongs there instead.

## Layout — and the one rule

```
skills/<name>/SKILL.md           the canon for every skill. EDIT HERE.
plugins/dw-solo/                 the loop plugin — plugin.json + symlinks (mode 120000) → the canon
plugins/dw-solo-setup/           the setup plugin — dw-init, dw-doctor, the templates symlink
plugins/dw-solo-extras/          the off-loop plugin — dw-handoff
scripts/runtime/<script>.sh      shipped scripts — symlinked into the owning plugin
scripts/<script>.sh              repo CI tooling, never shipped (validate-*.sh, lint.sh)
scripts/tests/<script>.test.sh   bash self-tests
evals/cases/<name>.json          routing cases — one per model-invocable skill, never shipped
evals/routing.ts                 the routing eval — free, deterministic, in CI
templates/                       payload copied verbatim INTO a target project (hooks, settings.json)
.claude-plugin/marketplace.json  makes this repo installable as a plugin source
```

**Always edit the canon above; use it instead of any `plugins/…` path**, since every one of those is
a symlink back to it — `plugins/*/skills/`, `scripts/` and `templates/` alike. That rule is
absolute. Every canon skill is shipped by exactly one plugin; `validate-manifests.sh` enforces the
ownership in both directions, and `scripts/tests/hooks-in-sync.test.sh` pins this repo's own
`.claude/hooks/` to the `templates/hooks/` canon it ships, so the hooks you run are the hooks you
ship.

The indirection works because `claude plugin install` **dereferences** symlinks — the plugin gets a
real copy in the plugin cache. So skill bodies invoke a shipped script as
`${CLAUDE_PLUGIN_ROOT}/scripts/<script>.sh` and the path resolves; `templates/` gets the same
treatment (`plugins/dw-solo-setup/templates -> ../../templates`, read as
`${CLAUDE_PLUGIN_ROOT}/templates/…`, since only the scaffolder consumes the payload). A script used
by only **one** skill needs no canon: bundle it in `skills/<name>/scripts/` and invoke it via
`<this-skill-dir>/…`.

## The loop

```
dw-grill? → dw-shape → dw-start? → dw-next ↺ → dw-check? → dw-land → dw-ship
  fuzzy      plan it    worktree     build        gate       close     merge
```

`?` marks the opt-in steps. The mandatory spine is `dw-shape → dw-next → dw-ship`; a small serial
change never leaves the default branch, and `dw-ship` runs the closing pass itself when the change
doc is still there — so a finished change needs one command. Skills connect through artifacts, never
a forced sequence: the shared `CHANGE.md`, and a `**Next:**` pointer at the end of each body that
`validate-docs.sh` checks names a skill existing **in this repo**.

## `.ai/` — tracked, one folder per change, no central index

Artifacts are real work documents, committed with the code — not scratch.

- **No shared index file.** A central registry becomes a merge-conflict magnet once tracked.
  Discovery is by directory name + per-file frontmatter, so two branches never fight over one file.
- **One folder per change** (`.ai/work/<slug>/`) — parallel branches and worktrees don't collide.
- **One change is one independently shippable scope** — "could each piece land on its own and leave
  the repo green?", asked at **shape time** rather than discovered mid-build. A request carrying two
  such scopes is two folders, not one doc with two goals. Where two of them touch the same file,
  that's an **ordering** sentence in the `## Notes` of whichever lands second — never a dependency
  field, which would be the status column this lane exists to avoid.
- **Branch-matched resume.** A change doc records its branch; the resume step globs the work dirs,
  matches the current branch, and reports the first unticked box.
- **Branch reads use `git rev-parse --abbrev-ref HEAD`**, never `git branch --show-current`, which
  returns an empty string on a detached HEAD and silently turns a branch match into a no-match.
- **The claim protocol.** A change shaped on the default branch records the literal sentinel
  `branch: unclaimed`; `dw-start` claims right after creating the worktree, and `dw-next` offers a
  claim when its branch-grep misses (stripping the `worktree-` prefix a `claude -w` session's branch
  carries). A claim is one frontmatter edit — the sentinel flips to the verbatim
  `git rev-parse --abbrev-ref HEAD` — committed **immediately**, because `.ai/` is tracked and an
  uncommitted claim is invisible to every other session. Anything touching `.ai/work/` must respect
  the sentinel.
- **Worktrees live at `.claude/worktrees/<slug>` on branch `<slug>`** (`scripts/runtime/worktree.sh`
  owns create/remove), and the closing pass's promotion commit lands **on the feature branch**, so a
  squash-merge carries the durable residue to the default branch.

## Explicit-only skills

A skill is marked `disable-model-invocation: true` for either of two reasons: it **acts outward** —
on branch topology, on the remote, or on a fresh repo's tooling — so the model never reaches for it
unbidden, or **only you can see its moment has come**, where a model left to guess fires it at the
wrong time or not at all. The cost is deliberate: an explicit-only skill is invisible to the model,
so no other skill can reach it by prose either — anything the loop must be able to delegate to stays
model-invocable. Which skills those currently are is the `⭑` list in `README.md`, kept in sync by
`validate-docs.sh`.

## Vendored from `dw-skills` — fix in both

These are **copies**, not references, and nothing can detect drift across the repo boundary:

- `templates/hooks/*.sh` (6 files — the team repo also ships a Ruby lint hook this Node-only lane
  deliberately drops; don't "re-sync" it back). `scripts/tests/hooks-in-sync.test.sh` only pins them
  to _this_ repo's `.claude/hooks/`.
- `scripts/runtime/slugify.sh` — byte-identical.

A skill copied from `dw-skills` is a **fork**, simplified for one reader — expected to diverge, never
re-synced. Current forks: `dw-grill`, `dw-shape`, `dw-next`, `dw-land`, `dw-git`, `dw-doctor`,
`dw-init` (which also absorbed the team lane's standalone pre-commit skill), and `dw-handoff` — which
shares only the team skill's name: it writes one overwritten `HANDOFF.md` inside the change folder
instead of a dated record under `.ai/handoffs/`, so treat the two as unrelated. `dw-start`,
`dw-check`, `dw-ship` and `scripts/runtime/worktree.sh` are this lane's own — they have no upstream.

## Adding a skill

1. `skills/<name>/SKILL.md` — kebab-case `name` matching the directory (the validators' regex is
   `dw-[a-z-]+` — lowercase letters and hyphens only, no digits), a `description` that is routing
   signal only, `disable-model-invocation: true` if explicit-invoke only. For the shape, copy a near
   neighbour and keep its section order — the skills on disk are the anatomy.
2. `ln -s ../../../skills/<name> plugins/<plugin>/skills/<name>` in the **owning** plugin and
   `git add` the symlink — exactly one plugin per skill.
3. Bump the owning plugin's patch version in **both** `.claude-plugin/marketplace.json` and its
   `plugin.json` — keep the two identical. One bump covers a train of skills landing together.
4. Name the skill everywhere the docs list skills: the README **task-router** row, the **loop
   diagram** in README + `## The loop` above if it joins the core loop (honor-system — no validator
   reads the diagram), and — if explicit-invoke — the `⭑` marker plus the explicit-only list in
   README.
5. End the body with a `**Next:**` line naming a skill that exists **in this repo** — a pointer at a
   team-lane skill is a dead end here, and `validate:docs` fails it. A cycle of new skills lands its
   `**Next:**` lines in one wiring commit at the end; `validate:docs` only checks pointers that
   exist.
6. **Exactly one `evals/cases/<name>.json` per model-invocable skill, and none for an explicit-invoke
   one** — at least 3 positives and 2 negatives, each negative naming the `owner` that should win
   instead. Nothing validates that count any more, so it is yours to hold: a missing file is a skill
   measured by nothing, an orphan file is a case file measuring nothing, and a file for a
   `disable-model-invocation: true` skill reads as coverage while measuring a decision the model never
   makes. Shape and conventions: [`evals/README.md`](evals/README.md).
7. `pnpm lint && pnpm format && pnpm validate:manifests && pnpm validate:docs && pnpm eval:routing` —
   the last one because a new description shifts every term's idf, so adding a skill can knock an
   _existing_ one off rank-1 and fail CI's floor without your own case file scoring badly at all.

Steps 2–6 are CI-enforced (bar the loop diagram, and CI checks the versions are _equal_, not that
they changed). The validators name the exact missing entry — run them rather than re-deriving the
checklist by hand.

## Adding a shipped (plugin-level) script

1. Put the real file once at `scripts/runtime/<script>.sh` and `chmod +x` it.
2. `ln -s ../../../scripts/runtime/<script>.sh plugins/<plugin>/scripts/<script>.sh` in every plugin
   whose skills invoke it, and `git add` the symlink (must be mode 120000).
3. Add the basename to `RUNTIME_SCRIPTS` in `scripts/validate-manifests.sh`, plus a
   `scripts/tests/<script>.test.sh` where it has logic worth pinning (anchor it to the repo root via
   `git rev-parse --show-toplevel`).

## Commands

This repo is Markdown / JSON / Shell plus a little dependency-free TypeScript under `evals/` — there
is no build step and no typecheck. Node runs the `.ts` files directly.

- **Test**: `pnpm validate:artifacts` (the bash self-tests in `scripts/tests/`)
- **Lint**: `pnpm lint`
- **Format**: `pnpm format` (check) · `pnpm format:fix` (write)
- **Routing evals**: `pnpm eval:routing` — free, deterministic, in CI. The one tier there is; the
  paid `claude -p` tier was deleted, see [`evals/README.md`](evals/README.md).

## Before you push

Run every check in the `scripts` block of `package.json` — `lint`, `format`, each `validate:*` and
`eval:routing`. That block is the gate; the list is deliberately not restated in prose, because the
prose copies drifted from it (see `.ai/archive/contributing-pre-push-gate-list-is-stale/`). CI runs
the same set plus a `trufflehog` secrets scan on every PR and push to `main`.

## Gotchas

Traps this repo has actually sprung, newest first. **This section is capped** —
`validate-artifacts.sh` holds the number and fails with it. One over means merging cousins into a
single entry or retiring a trap that stopped being true, never appending. Sub-bullets are how one entry
holds four traps.

- **A `dw-start` worktree is not the main tree, and every way it differs reads as something else.**
  Four traps, one root cause: the worktree gets tracked files and a branch, and nothing else.
  - **`CLAUDE.local.md` cannot be edited from one.** Link-class carry, so the harness refuses the
    write as leaving the worktree — and it is gitignored, so no commit delivers it either. A change
    touching the test/lint command lands its `AGENTS.md` half and silently drops the other. Do those
    edits in the main tree.
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
- **A self-test whose fixture is the live repo is a content gate under a unit test's name.** The case
  that taught this is gone with its script (`check-decisions.test.sh`), and the shape outlives it: a
  `no-arg` case ran the script against this repo and demanded silence — gating `docs/decisions/` from
  under the heading `arguments:`, and stricter than the contract it was testing. Use a synthetic
  fixture; live-content checks belong in `validate-artifacts.sh`.
- **`${CLAUDE_PLUGIN_ROOT}` is substituted into skill _bodies_, not exported into the shell those
  bodies run.** A skill body's `bash "${CLAUDE_PLUGIN_ROOT}/scripts/x.sh"` resolves because the text
  is expanded before the call — but a **bundled script** reading `$CLAUDE_PLUGIN_ROOT` at runtime
  gets an empty string, because it is not in the environment at all (confirmed by dumping `env` in a
  live session; the only `CLAUDE_*` vars there are `CLAUDE_CODE_*`, `CLAUDE_PID` and friends). Under
  `set -u` that is a hard error; without it, a silently wrong path. A bundled script that needs a
  sibling shipped script must resolve from its own `$0`, and must cover three layouts, because
  `skills/<name>/` and `plugins/<p>/skills/<name>/` sit at different depths from `scripts/runtime/`.
- **Git history: three ways a branch ends up holding work you didn't write.**
  - **`git commit` commits the index, not what you staged — and the main tree's index is shared with
    every other session in it.** `git add <my-folder>` then `git commit` swept a concurrent session's
    staged rename into this change's `chore: shape …` commit. Nothing warns: `git status` was clean
    at session start and the other session staged in between. Parallel shaping in the main tree is
    the normal case here, so run `git status --porcelain` **unscoped** before committing there and
    commit with explicit pathspecs (`git commit -- <paths>`). What the fix isn't: once the commit is
    an ancestor of your branch, splitting it does **not** get the passenger out of the PR — a
    squash-merge flattens both halves into one commit anyway.
  - **Rebasing onto a squash-merged `main` resurrects the merged change's own commits.** No shared
    ancestor survives the squash, so a branch shaped before it replays that change's `chore: shape …`
    commit as a new one, re-adding a `CHANGE.md` for work already archived. No conflict, no warning.
    After any rebase, diff `main..HEAD` and drop what you didn't write:
    `git rebase --onto main <stowaway-sha> <branch>`. Check the version bumps in the same pass — the
    other change may have taken the number yours targets.
  - **Every way to rewind a branch is blocked by `block-dangerous-commands.sh`.** Not just
    `git reset --hard` — `git branch -f`, `git branch -D`, `git checkout .` and `git restore .` are
    all in `DANGEROUS_PATTERNS`, so an agent cannot move a branch backwards at all and must hand the
    command to you. `git rebase` is not blocked, so prefer `rebase --onto` where it reaches;
    otherwise expect to run the rewind yourself.
- **The skill you are running is not the skill you are editing.** Claude Code serves
  `~/.claude/plugins/cache/dw-solo-skills/dw-solo/<version>/`, which only changes on reinstall — so a
  session can review, invoke and reason about a body several versions behind the canon it is editing,
  with nothing announcing the gap. It cost a whole review pass here: `dw-check` ran from 0.4.0 while
  the canon said something materially different, and the discrepancy read as a missing feature. Two
  consequences: **never debug a skill by its behaviour in the session that edits it** — invoke the
  canon's text by hand instead — and treat every canon skill edit as **unexercised** until a
  post-reinstall run, because no test asserts skill body content by design.
- **`dw-land` is not a review pass, and the sentence saying so is easy to walk past.** Both
  `skills/dw-land/SKILL.md` ("a last look, **not a review pipeline**") and `skills/dw-check/SKILL.md`
  ("not a bottleneck this skill duplicates") forbid giving the closing verdict its own reviewer — and
  it was built anyway, three lines below the first of them, then reverted. Review delegation belongs
  to `dw-check`. The general lesson, worth more than the instance: **a constraint written as an intro
  sentence does not act like a constraint** — if a boundary between two skills is load-bearing, put it
  in the step itself, not in the paragraph that sets the tone.
- **`validate-manifests.sh` checks the two versions are _equal_, not that either moved.** Change a
  shipped file — anything under `templates/` or `scripts/runtime/` — and CI stays green with no bump,
  while every installed consumer keeps the old copy. Nothing else catches it: the add-a-skill
  checklist only fires when a skill is added, and `dw-ship` never mentions versions at all. Bump the
  owning plugin by hand, in `marketplace.json` and its `plugin.json` together, whenever the diff
  touches the payload.
- **The two lint hooks disagree with the gate, in opposite directions.**
  - **`.lintstagedrc.json`'s glob and `prettier --check .` disagree by construction.** Prettier checks
    every file it understands; lint-staged only formats the extensions listed, so a new file type is
    unformatted at commit and rejected at push — which reads as a lint failure in a green repo.
    Adding `evals/*.ts` needed `ts` in that glob. Add the extension with the first file of a kind.
  - **`evals/*.ts` must never get the executable bit.** `lint-on-edit.sh` `eval`s its resolved lint
    command against the file path; the pre-fix version resolved to a bare space and executed the
    target. Fixed and pinned by `scripts/tests/lint-on-edit.test.sh`.
- **`CLAUDE.md` is a symlink to `AGENTS.md`, not a synced copy.** Edit `AGENTS.md` — Claude Code's
  `Edit` tool refuses to write through a symlink, and a change doc that treats them as two files
  schedules the same edit twice. There is one file; `## Gotchas`, the add-a-skill checklist and the
  layout rules all live in it.
- **pnpm here is four traps deep, and three of them look like a broken repo.**
  - **`pnpm lint` can be hijacked before it reaches `scripts/lint.sh`.** With the `rtk` proxy hook
    active it is rewritten to `rtk lint` — an _ESLint_ wrapper — and dies with
    `Command "eslint" not found` while the repo is perfectly green. `pnpm format` is unaffected (rtk
    has no `format` command), which makes it look like a real lint failure. Verify with
    `bash scripts/lint.sh` or `node_modules/.bin/agnix .`. CI has no rtk.
  - **`pnpm lint` also OOMs locally.** `agnix` over the whole tree can die with "terminated
    abnormally" under memory pressure; `scripts/lint.sh` turns that into a hard error rather than a
    silent pass. Re-run it, or lint only the staged paths the way `.husky/pre-commit` does. CI has
    the headroom.
  - **`pnpm view` and `pnpm info` are broken here on purpose.** They delegate to npm, and
    `devEngines.packageManager.onFail: "error"` makes npm refuse to run in this repo — which is the
    point: it replaces `pnpm/only-allow`, now archived. The error is
    `EBADDEVENGINES ... does not match "npm"`. Everything else (`ci`, `dlx`, `outdated`, `audit`,
    `why`, `licenses`, `list`) is native and fine. Look a package up from any other directory, or
    flip `onFail` to `ignore` if the guard ever costs more than it saves.
  - **`packageManager` and `devEngines.packageManager` must state the same version.** Both say
    `11.18.0`; bump them together. If they diverge, pnpm warns once and _ignores_ `packageManager`,
    while CI's pinned `pnpm/action-setup` (v4 — it predates `devEngines`) reads **only**
    `packageManager`, so local and CI silently run different pnpm versions.
- **`block-env-access.sh` inspects the whole Bash command, and now stops reading at a `<<`.** Commit
  messages are fine either way — quoted prose passes, and heredoc bodies are dropped before
  tokenizing, so `git commit -F - <<'MSG'` no longer blocks. But that drop is unconditional: a
  literal `<<` anywhere in a command starts body mode and **nothing below it is scanned**. The other
  half is that a bare `.env` token still blocks anywhere, so a probe of the hook cannot be typed
  literally — build the string (`D=$(printf ".%s" env)`) or your own test call never runs.
- **`templates/hooks/` and `scripts/runtime/slugify.sh` are vendored** from `dw-skills`. A fix here
  does not reach that repo, and no test can see across the boundary — apply it twice.
