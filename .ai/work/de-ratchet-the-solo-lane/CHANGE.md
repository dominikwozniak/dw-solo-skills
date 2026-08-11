---
change: de-ratchet-the-solo-lane
branch: de-ratchet-the-solo-lane
created: 2026-08-11
status: building # shaping | building | landed
---

# Change — remove the duplication, then give the durable layer a ceiling

## Goal

Three numbers move, and one behaviour changes:

- `skills/*/SKILL.md` — 11 812 words → **under 7000**, with no behaviour removed.
- The doc layer — 7 files / 9804 words → **3 files / ~4k**, and `validate-docs.sh` 269 → ~80 lines,
  because 5 of its 6 checks only ever guarded prose written twice.
- `evals/` 1287 → ~790 lines, and the decision-record enforcement 489 → 0.
- `dw-land` phase 3 stops being append-only, and two caps in `validate-artifacts.sh` make that
  checkable: `## Gotchas` ≤ 12 entries, `.ai/backlog/` ≤ 8 files.

You know it worked when `cat skills/*/SKILL.md | wc -w` is under 7000; the pre-push gate is five
commands, not seven, and all five pass; adding a 13th gotcha makes `pnpm validate:artifacts` fail
with the count and the cap; and `grep -rn "CONTRIBUTING.md\|SKILL-ANATOMY\|docs/DESIGN.md"` over
tracked files (excluding `.ai/archive/` and `docs/decisions/`) returns nothing.

**This is a large change — nine tasks.** It is deliberately not split; see the first decision.

## Decisions

- **One change, not three.** An earlier pass split this into docs / skills / governor. The split
  test in `dw-shape` ("could each land alone and leave the repo green?") returns a false positive
  here, because this change is almost entirely deletion and nearly any deletion passes it. What
  decided it: `skills/dw-land/SKILL.md` is substantially rewritten by two of the three and
  `AGENTS.md` by two of the three — merge conflicts, not ordering facts; the backlog arithmetic
  landed on exactly the cap with zero headroom; and three version-bump negotiations instead of one
  against a `validate-manifests.sh` that checks the numbers are _equal_, not that either _moved_.
  Splitting buys reviewability, and this repo has one reader. **Risk isolation comes from task
  ordering instead** — tasks 1–7 are mechanical, task 8 is the only editorial one, and per-task
  commits let a bad skill cut be dropped while everything before it stays green.
- **The environment is the source of truth for the pre-push gate.** `package.json` states it. Three
  markdown copies existed only so `validate-docs.sh` check 6 could compare them, and
  `.ai/archive/contributing-pre-push-gate-list-is-stale` is proof one already drifted.
- **`README.md` loses the Arguments column, keeps the `⭑` markers.** The column copies each skill's
  `argument-hint`, so it needs check 5 plus the `awk -F'|' '{print $4}'` fragility
  `.ai/backlog/validator-blind-spots.md` flags. `⭑` has no source elsewhere, so check 3 earns its
  keep.
- **`docs/DESIGN.md` is archived, not deleted.** The rationale is worth having and not worth keeping
  in sync. Its live rules move into `AGENTS.md`, the file an agent actually loads.
- **`trigger.ts` goes, `routing.ts` stays.** `routing.ts` catches a real failure — a new description
  shifts every term's idf and can knock an unrelated skill off rank-1. `trigger.ts` is paid, never
  in CI, and needs `--go`; `validate-evals.sh` guards a contract one checklist line states as well.
- **Caps, not a byte budget.** `.ai/work/eager-doc-size-budget/` proposed a `PostToolUse` hook
  measuring lines and bytes. A byte cap does not stop duplication — you can sit under budget and
  still say a thing twice — and it costs a hook, a test, a template, a settings wire and a version
  bump to enforce a number that change's own `## Decisions` admits this repo would not declare.
  Entry counts do the load-bearing half in ~30 lines of a script that already runs. **Rejected**,
  not deferred (task 5).
- **21 → 12 gotchas is a thematic merge, not a cull.** Four worktree traps, four pnpm traps, three
  git-history traps and two lint-hook traps are cousins. Grouping lands exactly on 12 and loses no
  trap. Deleting nine real traps would be the wrong reading of the cap.
- **`docs/decisions/` survives; its enforcement does not.** 229 lines of records guarded by 489
  lines of script, test and reference — ratio 2.1 : 1, and three of the last six PRs were about that
  contract. One reader does not need a parser to notice a malformed record they wrote.
- **The caps live in `validate-artifacts.sh`, not a new script.** It already runs in CI and already
  dogfoods this repo's own tracked artifacts.

## Tasks

- [x] 1. **Collapse the doc layer.** `README.md`: drop the Arguments column (header and every row)
      and the three `docs/DESIGN.md` pointers at `:37`, `:104`, `:150-151`; update the
      project-structure listing. `AGENTS.md`: absorb the live rules from `docs/DESIGN.md` — the loop
      (`:6-16`), the symlink canon (`:158-176`), the explicit-only list (`:184-197`), the `.ai/`
      layout (`:36-71`) — and replace `## Before you push` with a pointer at `package.json`. Then
      `git rm CONTRIBUTING.md docs/SKILL-ANATOMY.md`, `git mv docs/DESIGN.md` to
      `.ai/archive/design-rationale.md`, and fix the dangling pointers at `CONTEXT.md:4` and
      `CLAUDE.local.md:81`.
- [x] 2. **Shrink `scripts/validate-docs.sh`** 269 → ~80. Delete check 5 (`:155-204`) and check 6
      (`:205-269`). Collapse `EXPLICIT_LIST_DOCS`, `GATE_LIST_DOCS`, `GATE_TABLE_DOC`, `DESIGN` and
      `CONTRIBUTING` (`:27-38`) to `README` alone. Rewrite the header comment for four checks.
- [x] 3. **Freeze the evals.** `git rm evals/trigger.ts scripts/validate-evals.sh`; drop
      `validate:evals` from `package.json:16` and `.github/workflows/evals-routing.yaml:28`; rewrite
      `evals/README.md` for one tier; fold the skills↔cases contract into one line of the
      `AGENTS.md` add-a-skill checklist. Then `git rm` the three backlog entries that are work on
      the frozen tier — `routing-baseline-remeasure.md`, `stemmer-derivational-audit.md`,
      `boilerplate-idf-zero-claim-is-unsupported.md`.
- [x] 4. **Delete the decision-record machinery** (489 lines). `git rm` the canon
      `scripts/runtime/check-decisions.sh`, its test `scripts/tests/check-decisions.test.sh` and the
      symlink `plugins/dw-solo/scripts/check-decisions.sh`; drop the basename from `RUNTIME_SCRIPTS`
      in `scripts/validate-manifests.sh`; remove the call at `skills/dw-land/SKILL.md:83-86`. Then
      collapse the contract stated in three files — `docs/decisions/README.md`,
      `templates/decisions-README.md`, `skills/dw-land/references/decision-record.md` — so the
      three-part bar lives once, in the reference, with the two READMEs pointing at it.
- [x] 5. **Bring the durable layer under the caps, before the caps exist** — so each half is green
      alone. `## Gotchas` 21 → 12 by thematic merge: worktree (4→1), pnpm (4→1), git history (3→1),
      lint hooks (2→1), eight standalone entries untouched, every trap kept as a sub-bullet.
      `.ai/backlog/` to ≤ 8: apply the absorption bar, rewrite `validator-blind-spots.md` to its one
      surviving bullet, decide `shape-time-parking-for-the-left-out-list.md` explicitly, and
      question whether `grateful-me-app-v2-8-leftovers.md` belongs in this repo. `git rm -r` the
      `.ai/work/skill-and-docs-drift/` folder — five of its six items are resolved by tasks 1–4;
      re-file survivors as tasks here. Reject `.ai/work/eager-doc-size-budget/` with the reason from
      the fifth decision.
- [ ] 6. **Add the caps to `scripts/validate-artifacts.sh`.** Replace the `check-decisions.sh` pass
      (`:41-55`) with two counts: `## Gotchas` entries in `AGENTS.md` (`grep -c '^- \*\*'` scoped to
      the section) ≤ 12, and `.ai/backlog/*.md` excluding `README.md` ≤ 8. Fail with the count and
      the cap. Rewrite the header comment — `:11-17` says there is deliberately no `.ai/` schema
      sweep, so state that a file **count** is not a schema.
- [ ] 7. **`dw-land` phase 3 — promote by replacing.** One lead-in sentence before the four
      promotion bullets: re-read the target and delete what this change supersedes, then write. Per
      bullet: a retired gotcha is deleted rather than left beside its replacement; an absorbed
      backlog entry is `git rm`'d.
- [ ] 8. **Prune the skill bodies** — 11 812 → ~6k words, no behaviour removed. Delete the opening
      rationale from all 11 skills (`dw-land:18-20`, `dw-check:14-16`, `dw-shape:14-16`,
      `dw-grill:7-11`, `dw-next:14-25`, and the rest). De-duplicate the two PR #19 rules: the
      backlog bar stays once at `dw-land:101-105`, and `dw-next:83-91` keeps one sentence — _never
      park a `## Goal` gap_ — losing the other eight lines; trim `dw-land:60-67` from eight lines to
      two. De-duplicate the default-branch rule: `dw-check:20`, `dw-land:36`, `dw-shape:32-42` and
      `dw-ship:38` each become a short reference to `dw-git:31`/`:88`, but keep `dw-land`'s
      `origin/<branch>` fallback, which is a real extra constraint. Collapse `dw-shape:78-121` (44
      lines for one decision) to ~15. Leave `description:` frontmatter alone unless it restates the
      body.
- [ ] 9. **Bump and gate.** Three plugins are touched, one bump each, `marketplace.json` and the
      owning `plugin.json` identical: `dw-solo` (skills plus a removed runtime script),
      `dw-solo-setup` (`templates/decisions-README.md`), `dw-solo-extras` (`dw-handoff` body). Then
      the full gate, now five commands.

## Anchors

- `.inspirations/mattpocock-skills/skills/productivity/writing-for-agents/SKILL.md` — the no-op
  test, `duplication`, `sediment`, `sprawl`, and the warning that an agent told to "streamline"
  optimises for length because length is what it can see. The standard task 8 is measured against;
  read it before starting that task.
- `scripts/validate-docs.sh:27-38` — the doc-list variables that collapse to `README` alone;
  `:82-135` check 3 (stays), `:155-204` check 5 and `:205-269` check 6 (both go); `:1-20` the header
  comment stating "six checks".
- `README.md:50-101` — the task-router table whose 4th pipe field is the Arguments column;
  `:141-153` the project-structure listing.
- `AGENTS.md:50-70` — the add-a-skill checklist; steps 4 and 6 name docs being deleted. `:33` and
  `:56` point at `docs/DESIGN.md` / `docs/SKILL-ANATOMY.md`.
- `docs/DESIGN.md:158-176` (symlink canon), `:184-197` (explicit-only list), `:36-71` (`.ai/`
  layout), `:6-16` (the loop) — the sections that move rather than archive.
- `scripts/validate-artifacts.sh:11-17` — the note saying there is deliberately no `.ai/` schema
  sweep; `:41-55` the `check-decisions.sh` pass the caps replace.
- `skills/dw-land/SKILL.md:71-125` — phase 3, the four promotion bullets and the archive step;
  `:83-86` is the `check-decisions.sh` call.
- `scripts/validate-manifests.sh` — `RUNTIME_SCRIPTS` lists `check-decisions.sh`; removing the file
  without the entry fails the build.
- `.github/workflows/evals-routing.yaml:28-29` — two run steps; only line 28 goes.
- `.ai/backlog/validator-blind-spots.md` — first bullet (the hardcoded `awk` field index) is made
  moot by task 1, third bullet is task 4; only the `validate-manifests.sh` bullet survives.
- `.ai/archive/contributing-pre-push-gate-list-is-stale/` — the gate copy that already drifted.

## Notes

- **Task 8 is unexercised until reinstall** (`## Gotchas`). Claude Code serves
  `~/.claude/plugins/cache/dw-solo-skills/dw-solo/<version>/`, so a cut cannot be judged by invoking
  the skill in the session that made it. Read the canon text instead.
- **Two boundaries must survive task 8 as steps, not intro prose**, or they get walked past:
  `dw-land:14-15` ("not a review pipeline") and `dw-check:16`. `## Gotchas` records that this exact
  constraint was already violated once because it was written as a tone-setting sentence.
- **Task 5 must not delete the `## Gotchas` entry about `validate-manifests.sh` checking versions
  are _equal_ rather than _moved_** — task 9 bumps three plugins, and that is the trap that catches
  a parallel change taking the number first.
- `docs/decisions/0002-reset-the-skill-set.md` references `DESIGN.md` and `SKILL-ANATOMY.md` at
  `:34`, `:39`, `:53`. Leave them: an archived record describes the world at the time it was
  written.
- `.lintstagedrc.json` needs no change — no new file type. But `prettier --check .` grades the whole
  tree, so run `pnpm format` before pushing.
- Gate after this change is five, not seven:
  `pnpm lint && pnpm format && pnpm validate:manifests && pnpm validate:artifacts && pnpm validate:docs && pnpm eval:routing`.
- Seeded from `.ai/backlog/re-triage-the-backlog-against-the-absorption-bar.md`, whose two items are
  task 5.

### Build log

- **Task 1.** `validate:docs` is red between this commit and task 2's, by construction: checks 3, 5
  and 6 read `docs/DESIGN.md`, the Arguments column and `CONTRIBUTING.md` respectively, and task 1
  removes all three. The pre-commit hook doesn't run `validate:docs`, so the commits go through;
  don't read the red as a mistake before task 2 lands.
- **Task 1 — the explicit-only list did not move into `AGENTS.md`.** `docs/DESIGN.md:184-197` was two
  things: the _rule_ for what makes a skill explicit-only, and a _list_ of the four that are. Only
  the rule was absorbed; re-listing the names would have recreated exactly the second unchecked copy
  this change exists to delete (task 2 collapses `EXPLICIT_LIST_DOCS` to `README` alone, so an
  `AGENTS.md` list would be guarded by nothing). `AGENTS.md` points at README's `⭑` list instead.
- **`CLAUDE.local.md:81` still points at `docs/DESIGN.md`** — unfixable from this worktree (see
  `## Gotchas`), and gitignored, so no commit here delivers it. Fix by hand in the main tree; the
  line is the `**Domain**` bullet under `## Project specifics`.
- `evals/routing.ts:74` also named `docs/SKILL-ANATOMY.md` in a comment — not in the task text, but
  it is a dangling pointer the task's own grep criterion covers, so it was fixed here.
- `docs/DESIGN.md` → `.ai/archive/design-rationale.md` gained a four-line frozen banner and its two
  relative links re-pointed (`../README.md` → `../../README.md`), so the archived copy doesn't read
  as live guidance with broken links.
- **Task 2 landed at 156 lines, not the `~80` the goal estimated.** The two deleted checks were 115
  lines; what remains is 26 lines of header comment and four checks whose logic is load-bearing —
  check 3 alone is ~50 lines because it reads a wrapped prose paragraph in both directions. Cutting
  to 80 would have meant deleting working checks to hit a number, which is the failure mode the task
  8 anchor warns about. `EXPLICIT_LIST_DOCS` stays a list of one rather than a hardcoded filename, so
  a future doc that grows a skill list plugs in with one edit.
- **Task 3 — two of the three named backlog entries were not frozen-tier work.** The task's premise
  was that all three die with `trigger.ts`; checking them says otherwise, and `routing.ts` is the tier
  that _survives_:
  - `routing-baseline-remeasure.md` — **deleted as specified.** Its method was
    `node evals/trigger.ts --go --trials 3 dw-git`, so the entry has no way to be actioned any more.
    Its one durable observation (`dw-git` scores zero on two prompts since `44c06c7`) is already in
    `evals/README.md`'s baseline section.
  - `boilerplate-idf-zero-claim-is-unsupported.md` — **absorbed, not deleted.** It reported a false
    sentence in `evals/README.md:261` and `evals/routing.ts:124`, and task 3 rewrites that README
    anyway, so fixing it cost less than describing it (the absorption bar). Both sentences now say
    what happens: `use` is in 7 of 11 descriptions and `say` in 5, so boilerplate gets cheap, never
    free. The `idf 0` branch at `routing.ts:655` kept its wording plus a comment saying why it has
    never printed.
  - `stemmer-derivational-audit.md` — **restored.** It is `--explain`-driven work on the surviving
    tier, unaffected by the deletion. That leaves `.ai/backlog/` at 9 entries, one over the cap, so
    task 5 has one more absorb-or-drop decision than the shape assumed.
- **Task 4 had three consumers the task text didn't name**, all of which would have broken quietly:
  - `plugins/dw-solo-setup/scripts/check-decisions.sh` — a **second** shipped symlink, so
    `validate-manifests.sh` failed on a dangling link until it went too. That directory is now empty
    and gone; no `dw-solo-setup` skill invokes a plugin-level script.
  - `skills/dw-doctor/scripts/doctor.sh` ran the script over a consumer repo's `docs/decisions/`, with
    a warn branch for "could not find it beside this plugin". Left alone, every consumer would get
    that warning forever. The check is now presence-only, and the `$0`-relative candidate list went
    with it.
  - `scripts/validate-artifacts.sh` pass 2 was the dogfood run. Deleted here rather than in task 6, so
    that this commit leaves `pnpm validate:artifacts` green instead of red-until-task-6.
- **Task 5 — `## Gotchas` is 21 traps in 12 entries, all 21 kept.** Groups: worktree (4 → 1: local
  memory, no git hooks, hook-fix-doesn't-apply, compound shell), git history (3 → 1: shared index,
  rebase resurrection, rewind blocked), lint hooks (2 → 1), pnpm (4 → 1). Eight standalone entries
  untouched — including the `validate-manifests.sh` versions-are-_equal_ one that task 9 depends on.
  The section intro now states the cap and says a thirteenth means merging or retiring, never
  appending. Both stale citations fixed: the self-test-fixture entry frames
  `check-decisions.test.sh` as gone, and the `${CLAUDE_PLUGIN_ROOT}` entry states the three-layout
  rule directly instead of pointing at the candidate list task 4 deleted.
- **Task 5 — the backlog is 8, and the arithmetic differs from the shape's.** Task 3 left 9 (the
  stemmer entry was wrongly slated for deletion), so this needed one more decision than planned:
  - `grateful-me-app-v2-8-leftovers.md` — **deleted.** It is work in another repo, by hand, in that
    repo; `de-ratchet` should not spend one of eight slots on a TODO this repo cannot action. Worth
    re-parking in `grateful-me-app-v2` itself if that PR is still open.
  - `shape-time-parking-for-the-left-out-list.md` — **merged**, not dropped. Its false-promise half
    (`dw-grill` says `dw-shape` files the left-out list; `dw-shape` has no such step) is a one-line
    deletion in a file task 8 already opens, so task 8 absorbs it. The feature half moved into a new
    bundled entry.
  - `validator-blind-spots.md` — **rewritten to one bullet.** The `awk -F'|' '{print $4}'` index died
    with the Arguments column (task 1); the three-copies-of-the-decision-contract bullet died in task 4. What survives is the base-ref blind spot, which is the same fact as the `## Gotchas` entry.
  - `loop-prose-disagrees-with-the-bodies.md` — **new**, holding the three survivors of
    `.ai/work/skill-and-docs-drift/` (2 of its 5 items were resolved, not 5 of 6 as the shape
    assumed): `dw-ship`'s review nudge missing on the fast path, `dw-ship` ordering `dw-land` before a
    CI result that cannot exist yet, and the shape-time parking feature. **These are follow-ups, not
    tasks here** — none is in this change's `## Goal`, and all three are behaviour changes to the
    loop, which de-ratcheting is not.
  - `dw-shape`'s `description` promises "one durable `CHANGE.md`" while the body writes N — a
    contradiction rather than a restatement, so task 8 fixes it (and the idf shift means task 9's
    `eval:routing` run is what proves it safe).
- **Task 5 — `eager-doc-size-budget` is archived as `status: rejected`** with a `## Why rejected`
  giving the reason from the fifth decision. No `pr:` field: it was never claimed, so there is no
  closed PR to name. `.ai/work/eager-doc-size-budget/` is left as an **empty directory on disk** —
  `rmdir` is in `block-dangerous-commands.sh`, and git tracks no empty directories, so the commit is
  clean either way. Remove it by hand if it bothers you.
- **Two `## Gotchas` entries now cite files this change deleted** — the self-test-fixture one names
  `check-decisions.test.sh`, and the `${CLAUDE_PLUGIN_ROOT}` one points at doctor.sh's candidate list.
  Both lessons stand; the citations need rewording, which task 5 does while merging.
- **Task 3 also touched `docs/decisions/0005`**, whose `## Trade-off` named `validate-evals.sh` as the
  thing paying back the locality cost. The decision itself (evals at the repo root) is unchanged — only
  that sentence was stale, so it now records that the validator was deleted here and the contract moved
  to the checklist. Not the same as `0002`, which is left alone because it _describes a past world_.
