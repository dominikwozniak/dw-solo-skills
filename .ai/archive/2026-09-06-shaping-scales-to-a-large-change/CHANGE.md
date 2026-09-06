---
change: shaping-scales-to-a-large-change
branch: shaping-scales-to-a-large-change
created: 2026-09-06
status: landed # shaping | building | landed
landed: 2026-09-06
---

# Change — dw-grill asks in rounds, and dw-shape carries a large change in one doc

## Tasks

- [x] 1. **`dw-grill` asks in rounds.**
- [x] 2. **`dw-shape` sizes by content and carries Large.**
- [x] 3. **The template.**
- [x] 4. **The readers, the payload and the glossary.**
- [x] 5. **Behaviour cases.**
- [x] 6. **Bumps, baseline, gate.**

## Notes

- The skill-corpus baseline was re-recorded in each commit that grew a body, not once at the end —
  `skills-and-plugins.md` step 7 asks for the same commit, and it keeps every commit green.
- Task 4's `dw-land` clause closed a drift older than this change: `work-README.md` and `dw-handoff`
  said `dw-land` removes a leftover `HANDOFF.md`, and its body never did.
- `node evals/behaviour.ts --go` was **not** run. The three new cases are listed by the free plan and
  remain unmeasured, and no case forces a sibling file to be written, so that mechanism is untested.
- **The delegated review found eight defects in what this branch had just written**, four of them the
  same stale cross-reference across two twin pairs. The one worth remembering: the fact-check rule
  added by task 2 shipped a claim about this repo's own archive, in a body that is read in repos with
  no such archive — the trap `skills-and-plugins.md` already records, walked into by the change whose
  own subject is shape-time claims that turn out false.
