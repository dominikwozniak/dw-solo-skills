---
change: gotcha-shape-and-speaking-gates
branch: gotcha-shape-and-speaking-gates
created: 2026-09-03
status: landed
landed: 2026-09-04
pr: https://github.com/dominikwozniak/dw-solo-skills/pull/56
---

# Change — the promoted trap gets a shape, and the silent size gates speak

## Tasks

<!-- Convention: `- [ ]` pending, `- [x]` done — `dw-next` flips the box in the task's own commit.
A task that stopped being necessary keeps its box and gains `**skip:** <reason>`; every later
invocation reads that as not remaining. Never rename a task title. -->

- [x] 1. The checker gains a shared declaration-prefix helper and a new section 7 — the two optional
      caps and the two shape checks, each silent when undeclared — with the ratchet renumbered to 8,
      `measured` hoisted to module scope, and cases in `scripts/tests/check-agents-docs.test.sh`.
- [x] 2. `templates/agents-docs-README.md` states the two declarations, the trap's shape, the
      positional order, and the ratchet's same-commit bargain.
- [x] 3. `skills/dw-land/SKILL.md` — three edits by replacement: the subtractive half of the lead-in,
      the `CONTEXT.md` bullet cap, and the gotcha's shape plus the baseline re-record.
- [x] 4. `dw-doctor` reports each switched-off size gate as `report info` with a copy-paste fix, plus
      one sentence in its `SKILL.md` and cases in `scripts/tests/doctor.test.sh`.
- [x] 5. `skills/dw-init/SKILL.md` — the `{"words": 0}` trap, the stale "empty `docs/agents/`" prose,
      the seed's position as the last action, and the forked-checker diff gate.
- [x] 6. This repo seeds `docs/agents/corpus.baseline.json` and `docs/agents/README.md` gains one
      clause: unbudgeted but ratcheted.
- [x] 7. Behaviour fixture `evals/fixtures/land-gotcha-shape/` plus case 3 in
      `evals/behaviour/dw-land.json`, the drift guard in `scripts/validate-artifacts.sh`, and the
      re-counted sentence in `evals/README.md`.
- [x] 8. Record `0022`, flip `0015`'s two fields, patch-bump `dw-solo` and `dw-solo-setup` in both
      manifests, and re-record `scripts/skill-corpus.baseline.json`.

## Notes

- The consumer's forked checker needs `.gitmodules` and `skills-lock.json`, and the shipped one
  flags its `pnpm only` mention and two `references/*` router rows — so the fork is not a copy
  with edits, and "run the shipped checker against that repo" is not a check you can do.
- The close itself found two defects in the checker this change had just written: a backticked
  prose mention of a label armed the gate (it armed this repo's own `CONTEXT.md`), and the shape
  rule ran before the declaration was validated, so a malformed one cascaded. Both fixed with
  regression cases; the first is why `declaredAfter` skips a backticked occurrence.
