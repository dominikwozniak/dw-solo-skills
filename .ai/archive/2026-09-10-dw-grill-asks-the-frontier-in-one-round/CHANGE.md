---
change: dw-grill-asks-the-frontier-in-one-round
branch: dw-grill-asks-the-frontier-in-one-round
created: 2026-09-09
status: landed # shaping | building | landed
landed: 2026-09-10
pr: https://github.com/dominikwozniak/dw-solo-skills/pull/66
---

# Change — dw-grill asks the whole frontier in one round, and only what is the user's to answer

## Decisions

- **The cap of five goes, three days after `0af5d1a` argued it**
  (rejected: hard to reverse, and no trade-off was ceded — reverting is one commit over one skill
  file, a README row, an eval fixture and a baseline re-record, with no published interface and no
  migrated data; and the nomination's own wording, "the frontier plus those two rules **are** the
  filter", describes an option that was simply better, which the bar calls a fact rather than a
  decision. The guard the record was wanted for already lives in the skill: "A large frontier is
  not a reason to hold questions back".)

## Tasks

- [x] 1. `dw-grill` asks by frontier — steps 3, 4 and 6 rewritten around the frontier and the empty
      frontier as the close condition, the `description` rewritten, `frontier` added to `CONTEXT.md`,
      the corpus baseline re-recorded and `dw-solo` bumped in both manifests, all in one commit
- [x] 2. `dw-grill` step 2 settles by running rather than asking — a fact needing a command is still
      a fact, a lookup in flight blocks only what depends on it, and a fork only throwaway code can
      settle is named as a spike and offered at the playback rather than built
- [x] 3. The README's task-router row stops promising five questions a round
- [x] 4. The behaviour cases follow the frontier premise — case 1 loses its "at the point where a
      sixth would come" framing, case 2's third expectation stops counting questions, and neither
      loses its "nothing is written to disk" assertion

## Notes

- The resolve-the-tree step's cadence word had to move with the batch ("after each answer" → "after
  each round's answers"); `## Decisions` claimed that step stayed untouched, and the rule did, the
  cadence did not.
- The `description` edit dropped `eval:routing` to 26/27 on one `dw-land` positive, a 0.153 tie with
  `dw-next` decided by order. Cause: `close` is `dw-land`'s argument word, its phase 2 heading and
  what a user types, and it was missing from the only text the router reads. Named in the same
  commit; 27/27 restored and `dw-land ↔ dw-ship` fell 0.216 → 0.212.
- Nothing measured the batching itself, so case 3 is new: a single-goal idea expecting at least six
  numbered questions in one response, a count no five-question cap could produce.
- An empty frontier and a finished interview are different states when a lookup is still running,
  and the close step conflated them; it now needs both.
- Requiring no outstanding lookup at the close then made a hung lookup an unreachable terminal
  state. A lookup that fails stops being one and its subject becomes an ordinary question.
- Step 2 had grown to seven clauses against one per step elsewhere, so classifying a fact and going
  to look it up are now separate steps; the file runs eight. Step numbers drifted in this doc as a
  result, which is why its own references are by name.
- The behaviour tier was deliberately not run (`0020` makes `--go` a spend), so the uncapped round
  is argued and reviewed but never observed: the rung for that claim stops below "ran it".
- Two review rounds, three findings then one, and the second round's finding was created by the
  first round's fix — closing a premature close bought a deadlock.
