---
change: backlog-discipline-one-change-bias-and-dw-prune
branch: unclaimed
created: 2026-08-18
status: shaping # shaping | building | landed
---

# Change — one change by default, an absorption bar with teeth, dw-prune, and no branch left on origin

## Goal

Four leaks in one lane, one goal: **nothing here accumulates unattended.** Observable when all four
read true.

1. `dw-shape` splits only on **different goals**. The independent-shippability test and "The answer is
   N, not two" are gone from `skills/dw-shape/SKILL.md`.
2. The absorption bar reads as a **default with a blocking test**, identically in the three places it
   is stated — `nothing blocks it and doing it costs less than describing it → the current change,
now` — and `dw-shape`'s "into this change" is the default of its three-way choice rather than one
   option of three.
3. `/dw-prune` exists, is `disable-model-invocation: true`, is shipped by `dw-solo-extras`, and
   `pnpm validate:docs` passes with it wired into `README.md`, `AGENTS.md` and
   `docs/agents/skills-and-plugins.md`.
4. `dw-ship` merges with `--delete-branch`, and `git branch -r` shows **10 fewer** branches than it
   does today.

Plus: three plugin versions bumped, the corpus baseline re-recorded, the whole gate green.

## Decisions

- **One change, and the count test is what says so.** The four pieces answer to one goal, share the
  `dw-solo` bump and one gate run, and item 1 above is literally the rule being installed. Splitting
  this would be the failure the change exists to fix, so the question is closed here.
- **`dw-shape` gains no copy of the two named bars.** Its "into this change" bullet gets the
  imperative and the bars stay a pointer at `.ai/backlog/README.md` — three canonical statements, not
  four. `.ai/archive/two-gates-against-scope-shedding` recorded the four-copy version and the
  reword-all-four-or-ship-a-disagreement cost that came with it.
- **`templates/backlog-README.md` moves with the bar, and that is not scope creep.** It is
  byte-identical to `.ai/backlog/README.md` for lines 1–19 and is what `dw-init` copies out; editing
  one and not the other ships a disagreement into every scaffolded repo. It costs the
  `dw-solo-setup` bump.
- **This is a narrowing of `shape-splits-changes`, not a revert.** That change fixed docs carrying
  four unrelated scopes and overshot by making shippability the test. Say so in the skill body in one
  clause and in the PR body, or a later session reads the diff as an undo and undoes it — exactly the
  trap `two-gates-against-scope-shedding` had to pre-empt in the other direction.
- **`dw-prune` is prose, not a validator.** `.ai/archive/backlog-audit-script/` was built, reviewed
  twice and rejected with a revisit bar of ~20 entries; the folder holds 6 after this seed moves out.
- **`dw-prune` is explicit-invoke because only the reader can see its moment.** Same reason as
  `dw-handoff`, not the acts-outward reason. The cost is real and accepted: no skill can delegate to
  it, so `dw-land` can only _name_ it.
- **The origin prune goes through `gh api`, after the list.** `.claude/hooks/block-dangerous-commands.sh:58`
  refuses `git push --delete` on purpose; showing the 10 branches and waiting for a go is the
  deliberation that guardrail exists to force, and the API call is the confirmed path, not a way round it.

## Tasks

**Standing rule for tasks 1–4:** a commit that moves any `skills/*/SKILL.md` re-records the ratchet in
that same commit — `node scripts/check-skill-corpus.mjs --update-baseline` — or pass 3 of
`validate:artifacts` fails on unrecorded growth. Order is a hint; task 6 depends on nothing.

- [ ] 1. **`dw-shape` biases to one change** — rewrite the "Then count the scopes" block
      (`skills/dw-shape/SKILL.md:78-95`): drop the shippability test and "The answer is N, not two";
      the test becomes _different goals_ — separate ideas that arrived in one sentence — with the
      reason shippability fails one level up (it is a good _task_'s property; nearly every pair of
      edits passes it, so it splits work sharing a goal, a version bump and one gate run). Keep the
      not-file-overlap clause, the `N ≥ 2` HARD STOP, the on-yes/on-no bullets and the
      shared-anchor-is-an-ordering-sentence rule. One clause naming the counterweight so the diff
      doesn't read as a revert. Then step 5's **"into this change"** bullet (`:124`) becomes the
      default: nothing blocking it and cheaper to do than to describe means it is a task in the
      checklist just read back, now.
- [ ] 2. **The absorption bar gets teeth, in all three copies** — `skills/dw-land/SKILL.md:136-138`
      (the canonical statement), `.ai/backlog/README.md:16-19`, `templates/backlog-README.md:16-19`.
      Add the blocking test and the imperative. `diff` the two READMEs afterwards: the only difference
      is the cap paragraph the template omits.
- [ ] 3. **`dw-ship` deletes the branch it merged** — `skills/dw-ship/SKILL.md:51-54` gains
      `--delete-branch`. Pin its interaction with step 4 or the next run reads a warning as a failure:
      the flag deletes **local and remote**, git refuses a branch checked out in a worktree, so on the
      worktree path gh drops the remote branch, warns about the local one, and `worktree.sh remove`
      (`:64`) still owns the local side. The fast path has no branch to delete.
- [ ] 4. **`dw-prune` joins `dw-solo-extras`** — new `skills/dw-prune/SKILL.md`, ~350 words,
      `disable-model-invocation: true`, **no eval case**. One pass over `.ai/backlog/*.md` (README
      excluded), four spoken outcomes per entry: stale or already done → `git rm` with the reason in
      the commit message; cheap and unblocked → do it now, here or in the open change; has a cousin
      that ships alongside it → bundle and rewrite that entry; stays → said out loud, nothing written.
      One commit at the end. It does not shape. `**Next:** dw-shape`. Tooling written as a condition
      ("where the repo caps the list"), never an assertion. Wiring in the same commit: the symlink
      `plugins/dw-solo-extras/skills/dw-prune`; `README.md` Off-loop row + `⭑` + the explicit-only
      paragraph + the skills badge `11` → `12` (both `alt` and URL) + a caption that no longer says
      only "when a session ends"; `AGENTS.md:12` layout line → `dw-handoff, dw-prune` (2 lines of
      headroom, keep it on one line); `docs/agents/skills-and-plugins.md:51-52` own-skill list;
      `plugins/dw-solo-extras/.claude-plugin/plugin.json` description (it says "Today that is one");
      and one clause in `dw-land`'s follow-ups bullet naming `dw-prune` for a full folder.
- [ ] 5. **Three bumps, then the whole gate** — `dw-solo` 0.4.22 → 0.4.23, `dw-solo-extras`
      0.1.4 → 0.1.5, `dw-solo-setup` 0.1.23 → 0.1.24, each in `.claude-plugin/marketplace.json`
      **and** its `plugin.json`. Last on purpose: `validate-manifests.sh` only checks the pair is
      _equal_. Then every script in the `scripts` block — `eval:routing` included, because a new
      `description` shifts every term's idf and can knock an existing skill under `--min-rank1 67`.
- [ ] 6. **The one-time origin prune** — 10 stale remote branches, all squash-merged PRs #26–#35 and
      no open PR anywhere: `worktree-own-root-under-budget-and-router`,
      `worktree-shape-time-parking-for-the-left-out-list`, `cache-the-pnpm-store-in-the-new-setup-step`,
      `doctor-version-probes-read-only-and-read-devengines`, `worktree-skill-corpus-ratchet`,
      `the-guardrail-hook-wave`, `the-doc-layer-says-one-thing-once`,
      `lint-sh-ignores-the-file-path-lint-on-edit-appends`, `land-opens-the-pr-and-ship-only-merges`,
      `start-builds-and-next-builds-by-default`. Show the list, get the go, then
      `gh api --method DELETE repos/dominikwozniak/dw-solo-skills/git/refs/heads/<branch>` per branch.
      No diff; the guardrail trap is in Notes for `dw-land`.

## Anchors

- `skills/dw-shape/SKILL.md:78-95` — the block task 1 rewrites. `:73-76` is the **Large** bullet that
  hands off to it and keeps its "cut it to the first shippable piece" escape (that is sizing, not
  splitting). `:119-138` is step 5, whose first bullet becomes the default.
- `skills/dw-land/SKILL.md:128-142` — "Promote the follow-ups": the bar at `:136-138`, the
  `git rm`-what-this-closed sentence already at `:139-142`, and where the `dw-prune` clause goes.
- `.ai/backlog/README.md:16-19` and `templates/backlog-README.md:16-19` — the twinned bar; 1805 B and
  1330 B today, identical for lines 1–19.
- `skills/dw-ship/SKILL.md:48-56` (merge) and `:58-70` (cleanup) — the two halves task 3 keeps consistent.
- `skills/dw-handoff/SKILL.md` — nearest neighbour: the other explicit-invoke extras skill. Copy its
  section order for `dw-prune`.
- `docs/agents/skills-and-plugins.md:58-92` — the add-a-skill checklist, steps 1–8. Its Gotchas at
  `:105-145` hold the three traps this change can hit: the two-repos assertion trap, the
  editing-a-skill-you-are-running trap, and the versions-are-equal-not-moved trap.
- `scripts/validate-docs.sh` checks 2–4 and `scripts/check-skill-corpus.mjs` — what fails when the
  wiring is incomplete. Baseline is 14206 words across 11 skills.
- `.ai/archive/shape-splits-changes/CHANGE.md` — why the shippability test was installed, and its own
  Notes on reviewing every _other_ step a new block changes the meaning of.
- `.ai/archive/two-gates-against-scope-shedding/CHANGE.md` — why the absorption bar exists, why both
  prior changes on this ground declined a decision record, and the four-copies note.

## Notes

- **The plan behind this**, with the full evidence trail, is
  `~/.claude/plans/dw-solo-dw-shape-we-ai-backlog-backlog-encapsulated-lecun.md`.
- **Wave 3 (`.ai/backlog/docs-diet.md`) stays parked** — explicitly last "so content settles first",
  and it shrinks the corpus this change grows. It also edits `dw-shape`, so rebase awareness at land.
- **Unexercised on merge, by design.** Every edit is prose in a skill body, nothing asserts skill body
  content, and this session serves `dw-solo/0.4.22` from the plugin cache. The first real exercise is
  the next run after reinstall — say that in the PR rather than implying coverage.
- **Two candidate glossary terms for `dw-land`** if the wording settles: nothing new is coined here,
  but **absorption bar** is used across the archive and is still absent from `CONTEXT.md`.
- `.gitignore` is modified in the working tree by another session's work. Stage by name, always.
