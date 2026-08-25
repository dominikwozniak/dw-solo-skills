---
change: the-archive-is-a-receipt-not-a-second-copy
branch: the-archive-is-a-receipt-not-a-second-copy
created: 2026-08-25
status: landed # shaping | building | landed
landed: 2026-08-25
pr:
---

# Change — an archive entry proves a change landed, and stops repeating what was promoted

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
- [x] 6. The other four copies of the dangling pointer, which the shape checklist missed: the
      backlog pair (`.ai/backlog/README.md`, `templates/backlog-README.md`) says findings go by
      pointer, "never inlined"; the work pair (`.ai/README.md`, `templates/work-README.md:55`, which
      are byte-identical) says the same in its promote-targets list. All four say the entry carries
      its finding instead.
- [x] 7. Bump `dw-solo` and `dw-solo-setup` in both manifests, re-record the corpus baseline, run
      every check in the `scripts` block.

## Notes

- Landed second by preference behind `carry-references-through-the-loop-and-keep-them-accurate`, which
  merged mid-build: this rebased onto it, took `0.5.4` / `0.1.33`, and conflicted only on the
  work-README promote-target list.
- `.ai/backlog/2026-08-14-nothing-tests-a-templates-readme-against-its-live-ai-twin.md` stays parked,
  and this change is its second reason to exist — eight hand-edited copies of one rule.
