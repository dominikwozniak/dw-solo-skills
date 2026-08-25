---
change: the-archive-is-a-receipt-not-a-second-copy
branch: the-archive-is-a-receipt-not-a-second-copy
created: 2026-08-25
status: building # shaping | building | landed
---

# Change — an archive entry proves a change landed, and stops repeating what was promoted

## Goal

A landed change archives as its frontmatter, its title, its ticked tasks and whatever notes found no
durable home — not the whole working doc. Done when `dw-land` trims on the way in, both archive
READMEs describe that shape, `dw-next` stops writing paragraphs into `## Notes`, and a `reject` still
keeps its `## Why rejected`. A new entry lands near 15 lines where today's average is 90.

## Decisions

- The entry keeps frontmatter, the H1, the ticked task list and unpromoted notes; Goal, Decisions,
  Anchors and References go, because the archive is reached by slug and never read end to end.
- A note whose finding already became a decision record, a `CONTEXT.md` term, a Gotcha or a backlog
  entry is dropped — the archive never repeats something a durable target now holds.
- **A backlog entry carries its own finding.** Today `archive-README` says entries may point here for
  a change's `## Notes`; under the rule above that note is exactly the one dropped, so the pointer
  would dangle. The line goes, and `dw-land` inlines what the entry needs.
- `dw-next` gets the cause-side half: the one-line rule is already written twice and ignored, so
  trimming at close alone would run forever against prose that keeps being produced.
- No retro-trim — the 45 entries here and 32 in grateful-me-v2 stay. The archive is history nobody
  browses, so old bloat costs attention only when the folder is listed.
- Not reopening `0004`: its own "Revisit when" names ~30 changes and both repos are past it. The
  record amending it is `dw-land`'s to promote at close, not a task here.

## Tasks

- [x] 1. `promote.md`'s archive bullet — the `git mv` gains a trim: keep frontmatter, H1, ticked
      Tasks and unpromoted Notes; delete Goal, Decisions, Anchors, References.
- [x] 2. `promote.md` — a note whose finding went to a durable target is dropped from the archive,
      stated where each target already says what it deletes.
- [x] 3. `dw-land`'s `reject` mode — `## Why rejected` survives the trim, said where the mode is
      described, since that section is the only part of a rejected doc worth keeping.
- [x] 4. `templates/archive-README.md` and `.ai/archive/README.md` — describe the trimmed entry and
      drop the "backlog entries may point here" line. The two are **not** byte-identical; the live
      one carries an extra `rejected`-covers-cancelled paragraph that stays.
- [x] 5. `skills/dw-next/SKILL.md:114-119` — the one-line rule gains the action it lacks: a finding
      that outgrows one line is cut to one, its detail left to the diff and the commit message.
- [ ] 6. The other four copies of the dangling pointer, which the shape checklist missed: the
      backlog pair (`.ai/backlog/README.md`, `templates/backlog-README.md`) says findings go by
      pointer, "never inlined"; the work pair (`.ai/README.md`, `templates/work-README.md:55`, which
      are byte-identical) says the same in its promote-targets list. All four say the entry carries
      its finding instead.
- [ ] 7. Bump `dw-solo` and `dw-solo-setup` in both manifests, re-record the corpus baseline, run
      every check in the `scripts` block.

## Anchors

- `skills/dw-land/references/promote.md:97-108` — the archive bullet: a bare `git mv` plus three
  frontmatter flips, which is why nothing today shortens anything.
- `skills/dw-land/references/promote.md:1` — "the six targets, in order, and **what each one
  deletes**": the delete-half is the shape task 2 follows.
- `skills/dw-land/SKILL.md:143-154` — `reject`, and the refusal to write one without a reason.
- `skills/dw-next/SKILL.md:114-119` — "**One finding, one line.** […] a note that runs to a paragraph
  is a tax on every resume" — the rule that exists and does not bind.
- `skills/dw-shape/references/CHANGE.md` — `## Notes` says "one line each"; the second ignored copy.
- `templates/archive-README.md` — the "History, not guidance" paragraph, and the last line task 4
  removes; `.ai/archive/README.md` differs from it by exactly one paragraph (`diff` before editing).
- `scripts/validate-artifacts.sh` — the `## Gotchas` ≤ 12 and backlog ≤ 8 caps: the worked pattern
  for a cap, and the reason one is **not** added here (a shipped skill body cannot assume this
  repo's tooling — `docs/agents/skills-and-plugins.md:88-99`).

## References

- `~/.claude/plans/w-pracy-z-grateful-me-v2-ancient-sundae.md` — the grill playback and its
  post-approval corrections: the bloat is written at build time, and `### Build log` was never
  sanctioned.
- `docs/decisions/0004-archive-landed-changes.md` — why the archive exists at all (squash merges
  destroy the worked record) and the "~30 changes" revisit trigger this change answers.
- `.ai/archive/2026-08-12-de-ratchet-the-solo-lane/` — 313 lines, the worst case, and the source of
  the unsanctioned `### Build log` H3 that appears in exactly two entries.

## Notes

- Shaped alongside `carry-references-through-the-loop-and-keep-them-accurate`. **Lands second by
  preference**: that change makes `## References` a promote target, and task 1 here deletes the
  section from the archived doc — read as promote-then-drop, which only reads right in that order.
  Both edit `promote.md`, so the second rebases.
- The average is 90 lines across the 13 post-2026-08-17 entries, not the 135 the raw mean says: two 2026-08-12
  entries carrying an unsanctioned `### Build log` skew it. The lane already self-corrected once,
  which is why this change is about a floor, not a crisis.
- `.ai/backlog/2026-08-14-nothing-tests-a-templates-readme-against-its-live-ai-twin.md` stays parked
  and task 4 is its second reason to exist — this change edits both halves of that pair by hand
  again, exactly the thing the entry says nothing pins.
- A third unclaimed change sits beside these — `dw-grain-audits-reinvented-and-excess-code`, a 14th
  skill — and it already claims `dw-solo` `0.5.2` and a `--update-baseline`. Three changes cannot
  take the same number: whichever lands later re-reads both manifests and takes the next one, and
  re-records the corpus baseline against its own base. `validate-manifests.sh` only checks the two
  numbers are **equal**, never that either moved, so it will not catch a duplicate.
- The pointer the decision retires lives in six files, not the two task 4 names: the backlog pair and
  the work pair say it too — added as task 6.
