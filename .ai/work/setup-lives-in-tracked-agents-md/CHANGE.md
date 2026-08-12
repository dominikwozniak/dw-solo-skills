---
change: setup-lives-in-tracked-agents-md
branch: worktree-setup-lives-in-tracked-agents-md
created: 2026-08-12
status: building # shaping | building | landed
---

# Change — the payload scaffolds tracked `AGENTS.md` with a task router, and `CLAUDE.local.md` retires

## Goal

`dw-init` on a fresh repo writes one always-loaded, **tracked** `AGENTS.md` (with a `CLAUDE.md`
symlink) instead of a gitignored `CLAUDE.local.md`: boundary sections, a Task Router seeded with
the solo-lane rows, the load-bearing `- **Lint command**:` / `- **Typecheck command**:` bullets,
`## Git conventions`, and a `Budget: **120 lines / 10 KB**` line — plus a generic
`check-agents-docs.mjs` wired into `pnpm check` and pre-push. You know it worked when a scratch
scaffold has no `CLAUDE.local.md`, its checker passes, `lint-on-edit.sh` resolves the lint command
from `AGENTS.md` given a synthetic PostToolUse payload, and `dw-land`'s promotion step names a
routed topic file — not the root — as a gotcha's home.

## Decisions

- **`CLAUDE.local.md` retires from the scaffold entirely** — grateful-me-app-v2's ADR
  (`docs/decisions/0001-agent-memory-in-tracked-agents-md.md` there) proved the shape: a gitignored
  memory file survives neither a fresh clone nor a worktree, and forks the corpus. Personal notes
  belong in the global `~/.claude/CLAUDE.md`. Hooks keep a **legacy fallback** (`AGENTS.md` →
  `CLAUDE.local.md` → probe), so already-scaffolded repos keep working untouched.
- **Enforcement is a repo-gate script, not a PostToolUse hook** — `eager-doc-size-budget` stays
  rejected. The shipped checker carries **no decision-record checks**: decision 0006 stands.
- **`dw-land`'s new promotion target rides here, not in its own change** — the scaffold and the
  loop must agree where durable residue lives; split, they'd ship a state where the scaffold has a
  router and the loop still appends to the root.
- **Router seeded with solo-lane rows only, no empty `docs/agents/`** — the corpus grows when
  `dw-land` promotes: no matching row → create the topic file **and** its row in the same commit.
- **The vendored hooks diverge from `dw-skills` until the fix is applied there too** — the
  AGENTS.md-first chain is backward-compatible for the team lane; apply it in that repo separately,
  nothing here blocks on it.
- **Decision 0003 (carry classes) gets a successor** — the link class loses its only member.
- The seed's `templates/CLAUDE.local.md:61` bullet (CONTEXT.md offered in parenthetical prose) is
  **moot**: the template it criticizes is the one retiring.

## Tasks

- [x] 1. **The scaffold itself.** New `templates/AGENTS.md` (skeleton: Always / Ask First / Never /
      Commands / Task Router with the solo-lane rows / Solo lane with the two command bullets /
      Git conventions; `Budget: **120 lines / 10 KB**` in the header prose; no `## Gotchas`
      section). Retire `templates/CLAUDE.local.md`. `dw-init`: write `AGENTS.md`, `ln -s` a
      `CLAUDE.md` symlink, drop the CLAUDE.local.md rendering step and its "two copies must agree"
      prose, fold in the seed's stale-`.gitkeep` clause; the gitignore block keeps ignoring a stray
      `CLAUDE.local.md`.
- [x] 2. **The hook chain.** `templates/hooks/lint-on-edit.sh` + `typecheck-on-stop.sh` resolve
      `AGENTS.md` → `CLAUDE.local.md` → probe (grateful-me's fork is the model), and a value of
      `none` means "skip", fixing the seed's `eval`-of-`none` bug. Update the byte-identical
      `.claude/hooks/` copies; extend `scripts/tests/lint-on-edit.test.sh` and give
      `typecheck-on-stop.sh` the self-test the seed asked for.
- [x] 3. **Retire the local-memory machinery.** `link-local-memory.sh` leaves the always-offered
      hook set in `dw-init` (template stays for legacy repos or goes — decide while there);
      `worktree.sh` link-carry becomes conditional on the file existing; adjust
      `worktree.test.sh:226-272`; write the decision record superseding 0003 (next free number).
- [x] 4. **The shipped checker.** New `templates/check-agents-docs.mjs` — zero deps: root budget
      read from the file's own prose declaration (`grep`-grade parsing, bare number = bytes, `KB` =
      ×1024, malformed = reject), router coverage (every `docs/agents/*.md` has a row), routed
      paths exist, every `pnpm <script>` named exists in `package.json`. `dw-init` copies it and
      wires `agents:check` into `package.json` + pre-push per `references/precommit.md`.
- [x] 5. **The skills that read the old file.** `dw-git` reads `## Git conventions` from
      `AGENTS.md` with CLAUDE.local.md fallback (description edit → run `pnpm eval:routing`);
      `dw-start` drops its link-report paragraph; `dw-shape`/`dw-next` chains already list
      AGENTS.md — verify, don't rewrite.
- [x] 6. **dw-doctor.** Replace the CLAUDE.local.md presence-warn with AGENTS.md presence + budget + router-row sanity; add the seed's codex WARN-tier check (never FAIL, no auth probe); give
      `doctor.sh` the self-test the seed asked for.
- [ ] 7. **Docs + bump.** Update the README rows and this repo's `AGENTS.md` prose that name
      `CLAUDE.local.md` as the scaffold's memory; bump `dw-solo-setup` and `dw-solo` once each in
      `marketplace.json` + owning `plugin.json`, identical; full five-command gate.

## Anchors

- `/Users/dominik.wozniak/workspace/private/byarcadia-packages/grateful-me-app-v2/AGENTS.md` — the
  live model (111/120 lines): section order, router row style, the Solo lane command bullets.
- `…/grateful-me-app-v2/.claude/hooks/lint-on-edit.sh` — the proven AGENTS.md-first resolution
  chain, including the BSD-grep POSIX-class fix.
- `…/grateful-me-app-v2/scripts/check-agents-docs.mjs` — checks 1–5 (budget, router coverage, path
  sync, command sync) are the generic subset to port; the rest is repo-specific, leave it.
- `…/grateful-me-app-v2/docs/decisions/0001-agent-memory-in-tracked-agents-md.md` — the ADR this
  change mirrors; copy its "Revisit when" triggers into ours.
- `templates/hooks/lint-on-edit.sh:36-45`, `templates/hooks/typecheck-on-stop.sh:29-32` — the
  hardcoded `CLAUDE.local.md` gate + grep to extend; **vendored** — apply in `dw-skills` too.
- `scripts/runtime/worktree.sh:122-131` + `scripts/tests/worktree.test.sh:226-272` — the link-carry
  and the test that pins it.
- `skills/dw-init/SKILL.md:22-36` (what-it-writes table), `:100-113` (the two-copies steps),
  `:163-166` (gitignore enforcement).
- `skills/dw-git/SKILL.md:5,19-22` — the description and the read to widen.
- `skills/dw-doctor/scripts/doctor.sh:270-274` — the presence-warn to replace.
- `skills/dw-land/SKILL.md` phase 3 promotion bullets — **line numbers moved on the base branch;
  re-verify there at claim time.**
- `docs/decisions/0003-worktree-carry-classes.md` — superseded by task 3's record.

## Notes

- **Waits on `de-ratchet-the-solo-lane` merging** — the anchors reference that branch's state
  (`dw-land` phase 3, the five-command gate, decision 0006), and it rewrites the same skill bodies.
  Do not claim before the merge.
- Seeded from `.ai/backlog/setup-payload-sweep.md` (`git mv`) — its three payload fixes are
  absorbed by tasks 2, 6 and 1; the CONTEXT.md bullet is moot (see Decisions).
- `own-root-under-budget-and-router` applies this shape to this repo itself and **lands after**
  this change — its lint-command move needs task 2's hook chain.
- **Lands after `pnpm-pin-in-one-field`, which rewrote `doctor.sh:98-138`** — the pnpm check now
  reads `devEngines.packageManager` and adds two parsing checks (an orphaned `package.json#pnpm`
  block, a pre-v11 lockfile) that have **no self-test**, because this change owns the harness. Task
  6's anchor `doctor.sh:270-274` is also stale — it is past EOF; the `CLAUDE.local.md` presence-warn
  it means is at `:227-230`. Both were verified by hand against a throwaway fixture repo, never in
  CI.

### Build log

- **The `de-ratchet-the-solo-lane` wait is over** — it merged as `1182f7f` (#20), with `1b5cd7e` and
  `f12862e` on top. Claimed against that base.
- **This environment cannot run `pnpm` at all.** The global pnpm is 11.21.0, `package.json` pins
  11.18.0 with `devEngines.packageManager.onFail: "error"`, so every `pnpm …` invocation refuses —
  including `.husky/pre-commit`, which dies on its first line. That is `pnpm-pin-in-one-field`'s
  scope, so the gate here is run as the underlying binaries (`bash scripts/lint.sh`,
  `node_modules/.bin/prettier --check .`, `bash scripts/validate-*.sh`, `node evals/routing.ts`) and
  every commit is `--no-verify` after replicating the hook by hand. Nothing about the change depends
  on it; it only explains the commit mechanics.
- **Task 1 moved the two hook-read command bullets to one copy, not two.** The shape called for them
  under `## Solo lane` while `## Commands` held its own lint/typecheck lines — that is the "two copies
  must agree" trap this change deletes from `dw-init`, re-created one section apart. `## Commands`
  now holds the test command and points at the two bullets; the bullets are the only copy, and the
  template says why they live there.
- **`templates/AGENTS.md` needed a `.husky/pre-commit` filter.** The staged-file glob matches
  `(^|/)AGENTS\.md`, so the payload template got handed to agnix explicitly — which overrides the
  `templates/**` exclude in `.agnix.toml` and warns on 11 paths that only exist after the scaffold is
  dropped. `templates/CLAUDE.local.md` never matched that glob, so the filter is new with this file.
- **`none` had to stop the chain, not just miss.** The seed described the bug as `eval`-of-`none`;
  the fix is bigger than a skip, because falling through to the eslint/tsc probe would contradict the
  very line that said the project has no linter. Both hooks now return the literal `none` as a
  sentinel and exit before the probes. Both self-tests prove the **stop** rather than a miss, by
  putting a working command in the legacy `CLAUDE.local.md` that a fall-through would run.
- **`typecheck-on-stop.sh` carried the same BSD `\s` bug `lint-on-edit.sh` was already fixed for**,
  in both its `grep -E` and its `sed -E` (`:\s*` matches a colon then zero literal `s`, so the
  capture kept its leading whitespace). It never bit, because a Stop hook `eval`s the command with no
  argument appended — a leading space is harmless there in a way it was not for the lint hook. Both
  extractors are now the same POSIX-class shape.
- **The typecheck test deliberately does not reach the `scripts.typecheck` / `tsc --noEmit` probes** —
  they need a working pnpm/npm/npx in the sandbox, which would make the verdict depend on the machine.
  The declared-value chain, the `none` sentinel, the changed-files gate and the exit-code contract are
  all covered; 26 cases.
- **`.claude/hooks/` has no `typecheck-on-stop.sh`** (deliberately unwired here — no TS), so only the
  lint hook needed re-copying. `hooks-in-sync.test.sh` checks the copy only where one exists.
- **`.ai/backlog/` is at 6 of 8** before this change parks anything. Applying the hook fix in
  `dw-skills` is one of the entries land time owes; leave room.
- **Task 3 decided the `link-local-memory` template stays.** Two reasons, and the first is hard:
  `hooks-in-sync.test.sh` requires a template for every hook in this repo's own `.claude/hooks/`, and
  this repo still wires it — retiring the file here is `own-root-under-budget-and-router`'s scope, and
  its `CLAUDE.local.md` is the user's to delete, not the agent's. The second is that legacy repos'
  worktrees genuinely still need it. So the retirement is from dw-init's **always-offered** set: it is
  now offered only when step 1 finds a `CLAUDE.local.md` already there.
- **`worktree.sh`'s link-carry was already conditional** (`[ -f "$src" ] || return 0` at what is now
  `:131`), so task 3 changed framing, not behaviour: the guard is documented as the thing that makes
  the step inert, and the messages say "legacy". The one new assertion that matters is that the
  absent case is **silent** — it is the ordinary path now, and a warning there would fire on every
  worktree of every repo scaffolded from here on.
- **0003 is flipped to `superseded` even though only its link class died.** Its copy, regenerate and
  absent classes are untouched and still implemented. The folder has no partial-supersession status
  and nothing validates one, so 0007 carries an explicit paragraph naming what it does and does not
  replace, and points the reader back at 0003 for the other three.
- **The checker got two checks the shape did not list, and one it did not.** Added: a leftover
  `{{PLACEHOLDER}}` is a failure (dw-init's own prose calls that hazard out — a stray token is read as
  content and `eval`ed as a command), and `CLAUDE.md` must be a symlink to `AGENTS.md` (the whole
  premise of the layout, and generic). Not added, deliberately: anything under `docs/decisions/`, with
  a test case asserting the absence so the next reader knows it is a decision and not an oversight.
- **A test against the shipped template caught a real bug in the shipped checker.** Every other case
  builds its own minimal `AGENTS.md`, so none would notice the two payload halves disagreeing. Adding
  one that renders `templates/AGENTS.md` the way dw-init does failed immediately: path sync scanned
  the whole router row, so the backticked **concepts** in the `task` column — `.ai/work/`,
  `CHANGE.md` — were read as routed targets, and no `CHANGE.md` exists at a repo root. Path sync is
  now scoped to the last cell, the `read` column, and both the bug and the template case are pinned.
- **`.lintstagedrc.json` needed `mjs`** — the `## Gotchas` trap firing exactly as written: prettier
  checks every extension it understands, lint-staged only the listed ones, so the first file of a new
  kind is unformatted at commit and rejected at push. `references/precommit.md` now carries the same
  warning for scaffolded repos, since the checker is the `.mjs` they all get.
- **`agents:check` is wired uncommented, unlike typecheck and test.** Those are opt-ins in the
  reference because they build the whole project; this reads `AGENTS.md` and the paths it routes to.
  It is guarded on `AGENTS.md`, `docs/agents/` or `package.json` being staged — the third because
  command sync is what catches a renamed script.
- **No pre-push exists in this scaffold.** The task said "+ pre-push per `references/precommit.md`";
  that reference only has a pre-commit, so the gate went there. Nothing was invented to hold it.
- **`dw-land`'s gotcha home rode in task 5, since no task owned it.** The Decisions say it lands here
  and the `## Goal` requires it, but tasks 1–7 never name it, and it is a skill reading the old file's
  home — task 5's subject. Resolution order: an **existing** `## Gotchas` section stays the home
  (which is what keeps this repo, and every already-scaffolded one, working), else the routed topic
  file, creating the file and its router row together when no row matches.
- **`dw-shape:52` and `dw-next:82` already list `AGENTS.md`** — verified, not rewritten, as the task
  asked. They name `CLAUDE.md` first, which is harmless: it is the symlink.
- **The `dw-git` description swap cost nothing measurable.** `pnpm eval:routing` returns 20/30 = 67%
  with the per-skill table matching `evals/README.md`'s dated baseline row for row. Two pair
  distances drifted ~0.01 **further apart** (idf shifts when a term changes across the corpus); the
  top pair is unchanged at 0.206, so the baseline snapshot stays as measured rather than being
  quietly refreshed.
- **A commit-message trap found the hard way, and it lives in `dw-git` now.** A backtick inside a
  `git commit -m "…"` string is command substitution: the shell runs the span and splices its output
  in, so the phrase is **gone from the message** while the commit still succeeds. It ate three phrases
  from task 4's commit before `git log -1 --format=%B` caught it. The rule went into `dw-git`'s commit
  step rather than `## Gotchas`, which is at its cap — and that is the right home anyway, since it is
  the skill that writes messages.
- **The anchor `doctor.sh:270-274` was past EOF, as `pnpm-pin-in-one-field` warned.** The real region
  was `227-231`. That change rewrites `98-113` (the pnpm block) — different region, no conflict, but it
  now has a self-test harness to add its cases to rather than leaving new parsing untested.
- **The doctor extracts the command value the way the hooks do, and that immediately caught a live
  bug in this repo.** The first draft used its own sed and reported `none — the`; the hooks take the
  **first backticked span**, so what `typecheck-on-stop.sh` would actually `eval` from this repo's
  `CLAUDE.local.md` is the literal `evals/*.ts`. Latent (the hook is not wired here), real, and
  unfixable from a worktree — merged into the existing backlog entry for that file's `## Project
specifics` block, which `own-root-under-budget-and-router` task 3 is about to move.
- **Two findings were merged into backlog cousins rather than added as entries**, per the folder's own
  rule — the vendored-hook carry joined the `dw-skills` heredoc entry, and the typecheck-bullet bug
  joined the `CLAUDE.local.md` entry. Backlog stays at 6/8.
- **The doctor's own gotcha check disappeared, and nothing replaced it.** It used to warn when
  `CLAUDE.md` had no `## Gotchas` / `## Commands` section. Both are gone: gotchas may now live in a
  routed topic file, and the commands are the two bullets, which the block checks directly. Warning
  about a missing root section would fail every correctly-scaffolded repo.
- **`AGENTS.md` gained a `## Project` section** the shape did not list (Stack / Key directories /
  Deployment target) — the old `CLAUDE.local.md`'s `## Project specifics` carried real orientation
  value and `{{STACK}}` had no other home. 94 lines / 5085 B rendered, so 26 lines of the budget are
  left for the project's own rules.
