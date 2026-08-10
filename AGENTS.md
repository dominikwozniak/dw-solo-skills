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
evals/routing.ts                 the free tier, in CI · evals/trigger.ts is the paid one, by hand
templates/                       payload copied verbatim INTO a target project (hooks, settings.json)
.claude-plugin/marketplace.json  makes this repo installable as a plugin source
```

**Always edit the canon above; use it instead of any `plugins/…` path**, since every one of those is
a symlink back to it — `plugins/*/skills/`, `scripts/` and `templates/` alike. Every canon skill is
shipped by exactly one plugin; `validate-manifests.sh` enforces the ownership in both directions.

Skill bodies invoke a shipped script as `${CLAUDE_PLUGIN_ROOT}/scripts/<script>.sh` — install
dereferences the symlink, so the path resolves. A script used by only **one** skill needs no canon:
bundle it in `skills/<name>/scripts/` and invoke it via `<this-skill-dir>/…`.
Why it's built this way: [`docs/DESIGN.md`](docs/DESIGN.md), "The symlink canon".

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
   signal only, `disable-model-invocation: true` if explicit-invoke only. Shape:
   [`docs/SKILL-ANATOMY.md`](docs/SKILL-ANATOMY.md) — copy a near neighbour and keep the section
   order.
2. `ln -s ../../../skills/<name> plugins/<plugin>/skills/<name>` in the **owning** plugin and
   `git add` the symlink — exactly one plugin per skill.
3. Bump the owning plugin's patch version in **both** `.claude-plugin/marketplace.json` and its
   `plugin.json` — keep the two identical. One bump covers a train of skills landing together.
4. Name the skill everywhere the docs list skills: the README **task-router** row — including its
   **Arguments** cell, condensed from the skill's own `argument-hint` (`—` if it takes none) — the
   **loop diagram** in README + `docs/DESIGN.md` if it joins the core loop (honor-system — no
   validator reads the diagram), and — if explicit-invoke — the `⭑` marker plus the explicit-only
   lists in README **and** `docs/DESIGN.md`.
5. End the body with a `**Next:**` line naming a skill that exists **in this repo** — a pointer at a
   team-lane skill is a dead end here, and `validate:docs` fails it. A cycle of new skills lands its
   `**Next:**` lines in one wiring commit at the end; `validate:docs` only checks pointers that
   exist.
6. **If the skill is model-invocable**, add `evals/cases/<name>.json` — at least 3 positives and 2
   negatives, each negative naming the `owner` that should win instead. `validate:evals` fails
   without it. If the skill is `disable-model-invocation: true`, do **not** add one: routing is never
   the model's decision there, and a case file for it would read as coverage while measuring nothing.
   Shape and conventions: [`evals/README.md`](evals/README.md).
7. `pnpm lint && pnpm format && pnpm validate:manifests && pnpm validate:docs && pnpm validate:evals && pnpm eval:routing`
   — the last one because a new description shifts every term's idf, so adding a skill can knock an
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

- **Test**: `pnpm validate:artifacts` (the bash self-tests in `scripts/tests/`, then
  `check-decisions.sh` over this repo's own `docs/decisions/`)
- **Lint**: `pnpm lint`
- **Format**: `pnpm format` (check) · `pnpm format:fix` (write)
- **Routing evals**: `pnpm eval:routing` (free, deterministic) · `pnpm validate:evals` (the
  skills ↔ case-files contract). The paid tier is `node evals/trigger.ts`, run by hand and never in
  CI — it spends subscription quota and does nothing without `--go`. See
  [`evals/README.md`](evals/README.md).

## Before you push

```bash
pnpm lint && pnpm format && pnpm validate:manifests && pnpm validate:artifacts && pnpm validate:docs && pnpm validate:evals && pnpm eval:routing
```

CI runs those seven plus a `trufflehog` secrets scan on every PR and push to `main`.

## Gotchas

Traps this repo has actually sprung, newest first.

- **A self-test whose fixture is the live repo is a content gate wearing a unit test's name.**
  `check-decisions.test.sh` had a case, `no-arg-checks-this-repo`, that ran the script with no
  argument — which resolves to this repo — and asserted total silence. So the real `docs/decisions/`
  was gated by a file nobody thinks of as a gate, under the heading `arguments:`, and more strictly
  than the contract allows: a `warn:` gap exits 0 by design and would still have failed it. It also
  proved less than it claimed — passing identically whether the script resolved the repo root or
  just `$PWD`. Build the argument case on a synthetic `git init` fixture and call it from a
  subdirectory; live-content checks belong in `validate-artifacts.sh`, where a failure names the
  folder rather than a test case.
- **`CLAUDE.local.md` cannot be edited from a `dw-start` worktree at all.** It is carried by the
  **link** class, and the harness resolves the symlink and refuses the write as leaving the
  worktree — and it is gitignored, so no commit can deliver the edit either. A change that updates
  the test/lint command therefore lands its `AGENTS.md` half and silently drops the
  `CLAUDE.local.md` half, which is exactly the pair "Keep this file current" says must move
  together. Schedule any `CLAUDE.local.md` edit as a main-tree step, before or after the worktree,
  never inside it.
- **`${CLAUDE_PLUGIN_ROOT}` is substituted into skill _bodies_, not exported into the shell those
  bodies run.** A skill body's `bash "${CLAUDE_PLUGIN_ROOT}/scripts/x.sh"` resolves because the text
  is expanded before the call — but a **bundled script** reading `$CLAUDE_PLUGIN_ROOT` at runtime
  gets an empty string, because it is not in the environment at all (confirmed by dumping `env` in a
  live session; the only `CLAUDE_*` vars there are `CLAUDE_CODE_*`, `CLAUDE_PID` and friends). Under
  `set -u` that is a hard error; without it, a silently wrong path. A bundled script that needs a
  sibling shipped script must resolve from its own `$0` — see the candidate list in
  `skills/dw-doctor/scripts/doctor.sh`, which covers the install layout _and_ both source layouts,
  since `skills/<name>/` and `plugins/<p>/skills/<name>/` sit at different depths from
  `scripts/runtime/`.
- **`git commit` commits the index, not what you staged — and the main tree's index is shared with
  every other session in it.** `git add <my-folder>` followed by `git commit` swept a concurrent
  session's staged rename into this change's `chore: shape …` commit: the sibling change's promotion
  from `.ai/backlog/` to `.ai/work/` now rides a PR that has nothing to do with it. Nothing warns —
  `git status` was clean of it at session start, and the other session staged its work in between.
  Parallel shaping in the main tree is the normal case here, so before committing there, run
  `git status --porcelain` **unscoped** and check every staged path is yours; commit with explicit
  pathspecs (`git commit -- <paths>`) when it isn't. Worth knowing what the fix isn't: once the
  commit is an ancestor of your branch, splitting it does **not** get the passenger out of the PR —
  a squash-merge flattens both halves into one commit anyway.
- **A worktree-isolated session refuses compound shell, and it reads as a permission problem.** Every
  `dw-start` session lands in one, and there the harness rejects any Bash call it cannot statically
  prove stays inside the worktree — `cmd; cmd` chains with a redirect, a `../../..` path, a heredoc.
  It cost three retries in one session before the pattern was obvious. Issue plain separate commands,
  and write a commit message to a file outside the repo and use `git commit -F <path>` (which the
  `.env`-in-a-message gotcha below wants anyway). This is not the dangerous-command hook — the message
  names the worktree, not a blocked pattern.
- **The skill you are running is not the skill you are editing.** Claude Code serves
  `~/.claude/plugins/cache/dw-solo-skills/dw-solo/<version>/`, which only changes on reinstall — so a
  session can review, invoke and reason about a body several versions behind the canon it is editing,
  with nothing announcing the gap. It cost a whole review pass here: `dw-check` ran from 0.4.0 while
  the canon said something materially different, and the discrepancy read as a missing feature. Two
  consequences: **never debug a skill by its behaviour in the session that edits it** — invoke the
  canon's text by hand instead — and treat every canon skill edit as **unexercised** until a
  post-reinstall run, because no test asserts skill body content by design.
- **`dw-land` is not a review pass, and the sentence saying so is easy to walk past.** Both
  `skills/dw-land/SKILL.md:14-15` ("a last look, **not a review pipeline**") and
  `skills/dw-check/SKILL.md:16` ("not a bottleneck this skill duplicates") forbid giving the closing
  verdict its own reviewer — and it was built anyway, three lines below the first of them, then
  reverted. Review delegation belongs to `dw-check`; the verdict's whole light layer is those two
  lines of prose. The general lesson, worth more than the instance: **a constraint written as an intro
  sentence does not act like a constraint** — if a boundary between two skills is load-bearing, put it
  in the step or in `docs/DESIGN.md`, not in the paragraph that sets the tone.
- **Rebasing onto a squash-merged `main` resurrects the merged change's own commits.** A squash-merge
  leaves no shared ancestor, so a branch shaped before it replays that change's `chore: shape …`
  commit as a new one — re-adding `.ai/work/<slug>/CHANGE.md` for work already archived. No conflict,
  no warning. After any rebase, diff `main..HEAD` and drop what you didn't write:
  `git rebase --onto main <stowaway-sha> <branch>`. Check the version bumps in the same pass — the
  other change may have taken the number yours targets, and `validate-manifests.sh` cannot see it.
- **Every way to rewind a branch is blocked by `block-dangerous-commands.sh`.** Not just
  `git reset --hard` — `git branch -f`, `git branch -D`, `git checkout .` and `git restore .` are all
  in `DANGEROUS_PATTERNS` too, so an agent cannot move a branch backwards at all and must hand the
  command to you. `git rebase` is not blocked, so prefer `rebase --onto` for anything reachable that
  way; otherwise expect to run the rewind yourself.
- **`validate-manifests.sh` checks the two versions are _equal_, not that either moved.** Change a
  shipped file — anything under `templates/` or `scripts/runtime/` — and CI stays green with no bump,
  while every installed consumer keeps the old copy. Nothing else catches it: the add-a-skill
  checklist only fires when a skill is added, and `dw-ship` never mentions versions at all. Bump the
  owning plugin by hand, in `marketplace.json` and its `plugin.json` together, whenever the diff
  touches the payload.
- **A hook fix does not take effect in the worktree session that makes it.** Claude Code resolves
  `.claude/hooks/` from `${CLAUDE_PROJECT_DIR}`, which is the **main tree** — so a worktree session
  keeps firing `main`'s copy of a hook until the branch merges. Fixing `lint-on-edit.sh` on a branch
  and watching it fail identically on the next edit is not the fix failing; it is a different file
  running. Verify the fix by invoking the worktree copy directly with a synthetic payload.
- **`.lintstagedrc.json`'s glob and `prettier --check .` disagree by construction.** Prettier checks
  every file it understands; lint-staged only formats the extensions listed. A new file type is
  therefore unformatted at commit and rejected at push, which reads as a lint failure in a green repo.
  Adding `evals/*.ts` needed `ts` in that glob. Add the extension when you add the first file of a
  kind.
- **`evals/*.ts` must never get the executable bit.** `lint-on-edit.sh` `eval`s its resolved lint
  command against the file path; the pre-fix version resolved to a bare space and executed the target.
  Fixed and pinned by `scripts/tests/lint-on-edit.test.sh`, but `main`'s copy stays broken until this
  merges (see above), so a `chmod +x` on a `.ts` file would still run it.
- **`CLAUDE.md` is a symlink to `AGENTS.md`, not a synced copy.** Edit `AGENTS.md` — Claude Code's
  `Edit` tool refuses to write through a symlink, and a change doc that treats them as two files
  schedules the same edit twice. There is one file; `## Gotchas`, the add-a-skill checklist and the
  layout rules all live in it.
- **`pnpm lint` can be hijacked before it reaches `scripts/lint.sh`.** With the `rtk` proxy hook
  active, `pnpm lint` is rewritten to `rtk lint` — an _ESLint_ wrapper — and dies with
  `Command "eslint" not found` while the repo is perfectly green. `pnpm format` is unaffected (rtk has
  no `format` command), which makes it look like a real lint failure. Verify with
  `bash scripts/lint.sh` or `node_modules/.bin/agnix .` directly. CI has no rtk.
- **`pnpm view` and `pnpm info` are broken here on purpose.** They delegate to npm, and
  `devEngines.packageManager.onFail: "error"` in `package.json` makes npm refuse to run in this repo
  — which is the point: it is the `pnpm/only-allow` replacement, now that the package is archived.
  The error is `EBADDEVENGINES ... does not match "npm"`. Everything else (`ci`, `dlx`, `outdated`,
  `audit`, `why`, `licenses`, `list`) is native and fine. To look a package up, run it from any other
  directory. Flip `onFail` to `ignore` if the guard ever costs more than it saves.
- **`packageManager` and `devEngines.packageManager` must state the same version.** Both say
  `11.18.0`; bump them together. If they diverge, pnpm warns once and _ignores_ `packageManager`,
  while CI's pinned `pnpm/action-setup` (v4 — it predates `devEngines` support) reads **only**
  `packageManager`. The result is local and CI silently running different pnpm versions.
- **A fresh worktree runs no git hooks at all.** `core.hooksPath` is `.husky/_`, which `husky init`
  generates and gitignores — so a `git worktree add` checkout has `.husky/pre-commit` and no `_/`,
  git finds no hooks directory, and every commit skips prettier, agnix and the manifest version check
  **without printing anything**. Run `pnpm install` in the worktree before your first commit;
  `worktree.sh create` now warns about it on stderr, but the warning is easy to scroll past.
- **`block-env-access.sh` inspects the whole Bash command, including a commit message.** Writing about
  `.env` in a commit body blocks the commit. The hook's quoted-prose escape only covers
  `git commit -m "…"`; a heredoc gives the matcher no quoting to see. Write the message to a file
  outside the repo and use `git commit -F <path>`.
- **`pnpm lint` OOMs locally.** `agnix` over the whole tree can die with "terminated abnormally" under
  memory pressure; `scripts/lint.sh` turns that into a hard error rather than a silent pass. Re-run it,
  or lint only the staged paths the way `.husky/pre-commit` does. CI has the headroom.
- **`templates/hooks/` and `scripts/runtime/slugify.sh` are vendored** from `dw-skills`. A fix here
  does not reach that repo, and no test can see across the boundary — apply it twice.
