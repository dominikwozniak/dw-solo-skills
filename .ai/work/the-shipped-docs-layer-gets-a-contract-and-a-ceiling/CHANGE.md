---
change: the-shipped-docs-layer-gets-a-contract-and-a-ceiling
branch: unclaimed
created: 2026-08-21
status: shaping # shaping | building | landed
---

# Change — a scaffolded repo learns what belongs in `docs/agents/` and what stops it growing silently

## Goal

A repo scaffolded by `dw-init` gets `docs/agents/README.md` stating the contract, a declared ceiling
on each `docs/decisions/<NNNN>-*.md`, and a word ratchet over `docs/agents/*.md`. You know it worked
when a record one line over its declared ceiling fails `agents:check`; when appending a word to any
topic file fails with the total, the baseline and the file that grew, and deleting one passes;
when `pnpm format:fix` moves neither number; and when `dw-land` names which of the three tests a
candidate record passes before writing it.

## Decisions

- **`templates/` only, not this repo** — `docs-diet` settled that `docs/agents/*.md` are unbudgeted
  here, where a human reads every diff. A consumer repo has no such reader.
- **The rejected `eager-doc-size-budget` stays rejected** — that was a `PostToolUse` hook with warn
  and block thresholds. Its revisit condition is met (`grateful-me-app-v2` wants a ceiling and will
  set one) and the mechanism it needed already shipped as `check-agents-docs.mjs`.
- **A cap for records, a ratchet for topic files** — a record has a closed shape, so a number is a
  fact; a topic file has none, so the baseline records what is rather than what is allowed.
- **One change, not two** — shipping a new red gate to consumers without the contract prose is the
  ambush the seed entry describes; the README is what makes the gate fair.
- **The prose halves are edits by replacement** — `promote.md` and `decision-record.md` come out at
  or below their current word counts. Nothing measures `references/*.md`, so this one is on trust.
- **Ceilings are declared in prose, not in the script** — same one-line grep-grade shape as the
  existing `Budget:` line, so a consumer sets its own and this repo owns no taste number.
- **The record ceiling is declared in the consumer's own `docs/decisions/README.md`** — seeded by
  `templates/decisions-README.md`, which states that the contract is not restated there. A local
  number the local gate reads is editorial discipline, not the bar or the shape; those stay
  single-copy in `decision-record.md`.

## Tasks

- [ ] 1. `templates/agents-docs-README.md` — the contract only: root vs topic file vs
      `docs/decisions/` vs `CONTEXT.md`, and the router-row-in-the-same-commit rule. Its router row
      in `templates/AGENTS.md`, and its copy line in `dw-init`'s scaffold list.
- [ ] 2. A ceiling pass in `templates/check-agents-docs.mjs` over `docs/decisions/<NNNN>-*.md`, read
      from a one-line declaration the template seeds into `docs/decisions/README.md`; cases in
      `scripts/tests/check-agents-docs.test.sh`.
- [ ] 3. The `docs/agents/*.md` word ratchet in the same script: a tracked baseline, growth only via
      `--update-baseline`, styled on `check-skill-corpus.mjs`; `dw-init` seeds the baseline; cases in
      the same test file.
- [ ] 4. `dw-land/references/decision-record.md` — the ceiling as part of the shape, and the rule
      that the three tests are named aloud per candidate. By replacement.
- [ ] 5. `dw-land/references/promote.md` — the same two clauses on the promote side, and the ratchet's
      "shrink before you add" consequence. By replacement.
- [ ] 6. Bump `dw-solo-setup` (templates, `dw-init`) and `dw-solo` (the two references), and
      re-record the corpus baseline only if `SKILL.md` words actually moved.

## Anchors

- `templates/check-agents-docs.mjs:50-53` — the comment saying only the eager files are budgeted, and
  the budget table the new passes sit beside.
- `scripts/check-skill-corpus.mjs:1-20` — the ratchet to copy: no threshold, words not lines, the
  `--update-baseline` bargain.
- `skills/dw-land/references/decision-record.md` — the record shape and the three tests, both edited.
- `docs/agents/README.md:20-25` — the "unbudgeted, which is where prose belongs" rule this change
  must not contradict for this repo.
- `.ai/archive/eager-doc-size-budget/CHANGE.md` — the rejection and its revisit condition.
- `templates/AGENTS.md:31-40` — the Task Router table that gains a row in task 1.
- `templates/decisions-README.md:9-13` — the "not restated here" rule the ceiling must not break.

## Notes

- Tasks 4-5 write no citation of this repo's own decisions, history or `docs/agents/` files: a shipped
  reference installs where `0009` means something else. `.ai/backlog/nothing-refuses-a-shipped-skill-citing-this-repo-s-own-decisions.md` is the gate that would catch it, and stays parked.
- Seeded from `.ai/backlog/templates-ship-the-docs-agents-contract.md`, whose own warning applies to
  task 1: the payload version is the contract only, never this repo's history.
- Evidence this is real, from `grateful-me-app-v2`: `tooling.md` 177 lines, `ui.md` 165,
  `solo-lane.md` 138; records `0003` 63 and `0004` 80 from one commit; and `4d17c8b`, a hand cleanup
  of prose a land had added.
