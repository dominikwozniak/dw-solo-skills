---
change: the-hot-loop-skills-stop-loading-what-they-never-use
branch: main
created: 2026-08-20
status: building # shaping | building | landed
---

# Change — the three skills that run on every change stop loading what they will not use

## Goal

Three blocks move out of the hot skill bodies into `references/`, intact, and one restatement is
deleted: `dw-land` 2773 → ~1650 words (its promotion procedure runs only after approval), `dw-next`
1573 → ~1400 (its claim ladder runs only when the branch grep misses), `dw-shape` 1908 → ~1760 (its
split execution runs only at N ≥ 2). Corpus 16776 → ~15330. Every fact in the moved text is still
findable after the move, proven per block rather than assumed.

## Decisions

- **Move or delete a second copy, never trim** — `docs/agents/README.md` records four contents lost to
  one shrinking pass; no task here reduces what the corpus says.
- **One change, not three** — one goal ("stop loading what you never use"); three files is depth.
- **`dw-init` is excluded** — the user's call, and size × invocation makes it the cheapest big file:
  biggest at 2656 words, loaded once per repo, and its `### 4. Write` always runs.
- **`docs/agents/tooling.md` is untouched** — `0008` binds the budget to the always-loaded root only
  and forbids trimming as the remedy; a routed file is read only by someone already on that subject.
- **`dw-land`'s backlog-entry restatement is deleted, not moved** — `templates/backlog-README.md`
  states the shape and both bars verbatim, and `dw-prune` already delegates there. A `0006` deletion.
- **Verification is per moved block, not per gate run** — 8-gram word stream plus fact-token diff; the
  format gate cannot see a lost sentence.
- **The missing `references/` check is built here, not queued** — this change adds the first three
  pointers, so it is where the gap starts to cost; `0013` exempts a disk validator from a self-test,
  which is what makes it small enough to absorb.

## Tasks

- [x] 1. `dw-land` `### 3. Close` → `skills/dw-land/references/promote.md`; body keeps the gate, the
      target order and the pointer. Delete the `:141-148` restatement, fact-token-checked against
      `templates/backlog-README.md` first.
- [ ] 2. `dw-next` claim ladder → `skills/dw-next/references/claiming.md`, plus the new
      `## References` section it has never had.
- [ ] 3. `dw-shape` split execution → `skills/dw-shape/references/splitting.md`; the split test and
      the `HARD STOP` stay in the body.
- [ ] 4. `validate-docs.sh` check 5 — every `references/<file>` a `SKILL.md` cites resolves on disk,
      in the shape of check 1. No self-test: `0013` exempts a disk validator.
- [ ] 5. `dw-solo` `0.4.25` → `0.4.26` in both manifests, then
      `node scripts/check-skill-corpus.mjs --update-baseline`, then the full gate.

## Anchors

- `skills/dw-land/SKILL.md:86-170` — the block that moves, 85 lines and 43% of the file.
- `skills/dw-land/SKILL.md:141-148` — the restatement that dies rather than moves.
- `templates/backlog-README.md` — already states the entry shape, findings-by-pointer and both bars.
- `skills/dw-prune/SKILL.md:25` — "states them … they are not restated here": the precedent to copy.
- `skills/dw-next/SKILL.md:28-47` — the claim ladder; the happy path is the line above it.
- `skills/dw-shape/SKILL.md:94-105` — the split execution, N ≥ 2 only.
- `skills/dw-land/references/decision-record.md` — the sibling reference file, the shape to match.
- `scripts/check-skill-corpus.mjs:129-131` — the ratchet walks `SKILL.md` only, so `references/` is free.
- `docs/agents/README.md:55-65` — the four-losses gotcha and the two diffs it prescribes.
- `docs/decisions/0008-root-budget-replaces-the-gotcha-cap.md` — why `tooling.md` stays as it is.
- `docs/decisions/0006-delete-the-second-copy-and-cap-the-pile.md` — the shape of task 1's deletion.
- `scripts/validate-docs.sh:63-73` — check 1, the existence-check shape task 4 copies.
- `docs/decisions/0013-a-validator-over-git-history-gets-a-self-test.md` — why task 4 gets no test.

## Notes

- Task 4 is what proves tasks 1-3: run it last against the three new pointers and it fails if any
  move left a dangling reference. Open them by hand before that, not instead of it.
- `validate:versions` is red from task 1 until task 5 bumps, the same as the previous change; the
  corpus ratchet stays green throughout because it permits shrinking freely.
- The fact-token diff earned its keep on task 1: the 8-gram read looked like a clean move, and the
  token check caught `source: <this change's slug>` dropped from the follow-ups bullet.
