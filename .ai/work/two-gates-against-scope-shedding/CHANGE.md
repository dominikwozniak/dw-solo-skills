---
change: two-gates-against-scope-shedding
branch: two-gates-against-scope-shedding
created: 2026-08-10
status: building # shaping | building | landed
---

# Change — two gates so a change can't shed its own scope into the backlog

## Goal

`dw-land` and `dw-next` stop turning unfinished work into queue items. Two observable results, both
readable in the skill bodies: a change whose `## Goal` names an undelivered result closes as **not
ready** rather than **ready with follow-ups**, and a fix cheaper to do than to describe is a commit in
the change rather than a file in `.ai/backlog/`. The bar text says the same thing in all four places
that state it — both skills and both backlog READMEs — and both plugin versions move with it.

## Decisions

- **One change, not two** — the count test fires (each gate could land alone and leave the repo
  green) and the answer is no: two leaks, one remedy. They share the absorption-bar wording across
  three files, one `dw-solo` bump and one gate run, which is the axis `#9` used to bundle. Shipping
  either alone leaves one of the two observed failures in place.
- **No new verdict and no new status** — the Goal question already exists at `dw-land:48-49` and the
  third verdict **not ready** already exists at `:57-60`. The gate gives the existing question teeth
  instead of adding a `partial` status, which would make shedding a tidy first-class outcome.
- **The month bar stays; the absorption bar joins it** — "would you pick it up within a month" tests
  _will you ever_, and all five entries from `grateful-me-app-v2#8` pass it. The new bar tests
  _should this have been done now_.
- **The widening clause at `dw-land:85` is untouched** — "plus anything deliberately left out" reads
  like the culprit and is the opposite: it produced that PR's two sound entries (HeroUI migration, tag
  colours). Cutting it would drop those and keep both defects.
- **No new tooling and no `dw-doctor` check** — `.ai/archive/backlog-audit-script/` was built,
  reviewed twice and rejected, with a revisit bar of "past ~20 entries". The backlog is at 9. This is
  prose in skill bodies.
- **No decision record** — undoing this means deleting paragraphs of markdown, so the hard-to-reverse
  leg of the three-part bar in `docs/decisions/README.md` fails. Same call `#7` made for the same
  reason.
- **This is not a revert of `#7`** — that PR fixed the opposite failure (three of five change docs
  carrying four or more unrelated scopes) and shipped no test for when splitting is abandonment. This
  is the missing counterweight, and the PR body must say so, or a later session reads it as a
  reversal and undoes it.

## Tasks

- [x] 1. **Completion gate** — in `dw-land` step 2, after the three verdicts at `:57-60`: an unmet
      `## Goal` result is **not ready**, never **ready with follow-ups**. Read the Goal as a list of
      observable results and check each; the two ways out are finish it, or amend the Goal to state
      what it now claims and why the rest is gone, then re-run the verdict. Say explicitly that
      ticked boxes do not settle it — every box was ticked in `#8` while a Goal result was unmet. Put
      it **inside the step**, not the preamble.
- [x] 2. **Absorption bar, everywhere it is stated** — the same sentence in `dw-land:92-94` (beside
      the month bar), `.ai/backlog/README.md:15` and `templates/backlog-README.md:15`: if doing it now
      costs less than describing it, do it now; a fix that fits in a file this change already touched,
      or that is smaller than the entry describing it, is a commit here. Keep the two READMEs
      byte-identical — they are 927 B each today, and the template is what `dw-init` copies out. One
      commit, because splitting it ships a disagreement between a skill and its README.
- [x] 3. **`dw-next` gets its first bar** — extend the "Narrow and complete" bullet at `:80-83` with
      the absorption bar _and_ the rule that a gap in this change's `## Goal` is never a backlog
      entry: it is a new task in this `CHANGE.md`, or a Goal the user amends. Leave `:81` "a second
      task is free" alone — a second task keeps the work inside the change.
- [x] 4. **`docs/DESIGN.md`** — `:86` ("clears none of the above bars") and `:91-92` ("the other three
      each have a high bar, and an ordinary follow-up clears none of them") both stop being true once
      the bar exists. One sentence each. Cuttable if the change wants to be narrower; nothing
      validates it.
- [x] 5. **Both version bumps, then the full gate** — `dw-solo` `0.4.12` → `0.4.13` (tasks 1–3 touch
      its skills) and `dw-solo-setup` `0.1.10` → `0.1.11` (task 2 touches the payload), each in
      `.claude-plugin/marketplace.json` **and** `plugins/<p>/.claude-plugin/plugin.json`. Last task on
      purpose: `validate-manifests.sh` only checks the pairs are _equal_, so a forgotten bump ships
      green and every installed consumer keeps the old copy. Then run all seven gate commands.

## Anchors

- `skills/dw-land/SKILL.md:43-60` — step 2, "The verdict — one pass, four questions". `:48-49` is
  already the Goal question ("Correct? Does it do what the goal said"); `:57-60` are the three
  closing verdicts that currently let an unmet Goal exit as **ready with follow-ups**. Task 1 lands
  here.
- `skills/dw-land/SKILL.md:85-94` — "Promote the follow-ups". `:85` carries the widening clause that
  stays; `:92-94` carries the month bar the new bar joins.
- `skills/dw-next/SKILL.md:80-83` — "Narrow and complete", the only mid-build backlog writer and the
  one with no bar at all. This is the site `#8`'s "Follow-up for `dw-land` to park:" line came from.
- `.ai/backlog/README.md:15` and `templates/backlog-README.md:15` — the month bar, stated identically
  in both (927 B each). The second is payload, so it drives the `dw-solo-setup` bump.
- `docs/DESIGN.md:86` and `:91-95` — the table row and the paragraph that describe the backlog as the
  target with no bar of its own.
- `.claude-plugin/marketplace.json:13,21` — the two versions, with their twins at
  `plugins/dw-solo/.claude-plugin/plugin.json` and
  `plugins/dw-solo-setup/.claude-plugin/plugin.json`.

## Notes

- The interview that produced this, with the full evidence trail, is in the approved plan at
  `~/.claude/plans/zauwazylem-ze-backlog-bardzo-golden-kurzweil.md`. The prompting case is
  `byarcadia-app/grateful-me-app-v2#8`: `## Goal` named three observable results, the change doc
  itself records "Task 5 gap, and it is the one thing left unmet in the Goal", and it closed
  `status: landed` with all six tasks ticked and five backlog entries created.
- **Unexercised on merge, by design.** Every edit here is prose in a skill body and nothing asserts
  skill body content. Any `dw-land` / `dw-next` run during this work serves the cached `0.4.11` from
  `~/.claude/plugins/cache/`, so no line written here will have driven a run — the first real exercise
  is the next land after reinstall. Say that in the PR rather than implying coverage.
- **Two new terms for `dw-land` to consider promoting** to `CONTEXT.md`: **completion gate** and
  **absorption bar**. They fit the glossary's existing pattern (`HARD STOP`, `Claim`, `Promotion`).
- **Deliberately out, each its own change** — named here so `dw-land` parks them rather than
  rediscovering them:
  - `grateful-me-app-v2#8` is still open, so the Raleway gap and the one-line `## Precedencja` fix
    can be done before merge. Different repo, and by hand — canon edits here do not reach an
    installed plugin until reinstall.
  - This repo's own state: re-triage the 9 live backlog entries against the absorption bar, and fix
    `.ai/work/skill-and-docs-drift`, which is a backlog entry `git mv`'d into `work/` and never
    reshaped (no `change:`, `branch:` or `status:` frontmatter, no task checkboxes).
  - The `dw-grill` → `dw-shape` hole: `skills/dw-grill/SKILL.md:90` promises `dw-shape` files the
    "deliberately left out" list into `.ai/backlog/`, and `dw-shape` has no such step — it only reads
    (`:71-74`) and consumes (`:134-146`). So that pile reaches disk only at land time, when parking is
    cheapest. Closing it moves parking to shape time, where the alternative is taking it into the
    change. Deepest fix available; beyond this change's land-side scope.
- `TASK2.md` sits untracked in the main tree and belongs to another session. Commit with explicit
  pathspecs.
- **The absorption bar is now stated in four places, word-for-word**: `skills/dw-land/SKILL.md`
  (the "Promote the follow-ups" bullet), `skills/dw-next/SKILL.md` (the "Narrow and complete"
  sub-bullets), `.ai/backlog/README.md` and `templates/backlog-README.md`. The last two are
  byte-identical at 1217 B and nothing validates that — `diff` them after touching either. Rewording
  the bar means touching all four or shipping a disagreement.
- The two bars got names in the prose — **"Will you ever?"** and **"Should it have been done
  now?"** — so a later edit has something to refer to instead of re-describing them.
- `docs/DESIGN.md`'s promotion table needed `prettier --write` after the row edit: the new cell text
  changed the column width, and `pnpm format` fails on a hand-aligned table.
- The full gate ran green, all seven. No `description:` field changed, so `eval:routing` is unmoved
  (rank-1 67%, 20/30 · 21/21) — the run was for the idf side-effect the checklist warns about, and
  there was none.
