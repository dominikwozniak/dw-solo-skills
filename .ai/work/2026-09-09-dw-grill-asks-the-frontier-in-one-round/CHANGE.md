---
change: dw-grill-asks-the-frontier-in-one-round
branch: dw-grill-asks-the-frontier-in-one-round
created: 2026-09-09
status: building
---

# Change — dw-grill asks the whole frontier in one round, and only what is the user's to answer

## Goal

One goal in one sentence: the interview asks only what is genuinely the user's to decide, and asks
it in as few turns as the dependency order allows.

- A round arrives as **one message** carrying every question whose prerequisites are already
  settled, numbered, each with the answer the skill would pick.
- A question whose answer depends on another still open in the same round is held to the next
  round, so batching costs nothing that asking serially bought.
- No round has a fixed size, and the interview closes when the **frontier is empty** rather than
  when a counter runs out.
- A playback lands after every round whatever its size, still offering the same three ways forward.
- A question whose answer could be observed by running something is answered by running it, and the
  round reports the observation instead of the question.
- A lookup in flight blocks only the questions downstream of it; the rest of the frontier is asked
  in the same message.
- `pnpm eval:routing` still reports rank-1 27/27 against `--min-rank1 96` after the `description`
  loses two of its clauses.

## Decisions

- **The round is the frontier, not a count** — one message carries every question whose
  prerequisites are settled. Ordering inside the round stays hardest-first (scope →
  security/privacy → UX → detail), which is what the cap's ordering rule was really for. Taken from
  `.inspirations/mattpocock-skills/skills/productivity/grilling/SKILL.md:6-8,18`.
- **Batching is safe by construction** — a question whose answer depends on another still open in
  the round belongs to a later round. Nothing in a batch can be closed by its own siblings, so
  step 5's "Resolve the tree, not the list" keeps working untouched. This is the whole reason the
  turn cost can drop without the interview getting dumber.
- **The cap of five goes, three days after `0af5d1a` argued it** (nominated) — the cap bought
  "choose what is worth asking", and two rules already in the skill do that better: facts are looked
  up rather than asked (step 2), and a decision with one sensible default is assumed and said out
  loud in the same message (step 3). The cap was a proxy for that filter; the frontier plus those
  two rules are the filter. Worth a record because it reverses a recent argued call, and the next
  reader will otherwise re-add the cap.
- **The playback survives, per round rather than per fifth question** — that was the half of
  `0af5d1a` with no prior behaviour behind it, and a round of nine needs it more than a round of five.
- **A fact you would have to run something to see is still a fact** — step 2 excludes anything
  "discoverable in the repo or environment", which reads as reading. Behaviour, timing, output and
  cost are observable too, and asking the user to guess at them spends a slot on something a command
  answers better.
- **A spike is offered, never built inside the interview** — pstack settles an empirical fork by
  sketching it (`poteto-mode/SKILL.md:20`), but this skill's hard rule is "Do not start
  implementing, and write nothing" (`skills/dw-grill/SKILL.md:53`) and both behaviour cases assert
  it. So: read-only probes run during the round; where only throwaway code would settle the fork,
  the skill names it as a spike and offers it at the playback as a fourth way forward. Taking the
  whole pstack rule would break the one contract this skill has.
- **A lookup in flight does not stall the round** — a fact a subagent is still fetching is an
  unsettled prerequisite for the questions downstream of it and for nothing else
  (`grilling/SKILL.md:20`). Without this the frontier would serialise on its slowest lookup and give
  back the turns the batching just won.
- **`description` loses "one question at a time" and "in rounds of five"** — leaving them ships a
  routing signal that contradicts the body. `docs/agents/skills-and-plugins.md:123` settles the
  worry: the idf risk is a reason to run the eval, never a reason to leave a `description` wrong.
- **`frontier` becomes a `CONTEXT.md` term** — the word carries the whole mechanic and the glossary
  has no grill or round term today.
- Inherited from `0009`, my extract because the record predates `rule:` — the corpus may shrink
  freely and may only grow through a commit that re-records `scripts/skill-corpus.baseline.json`
  with `--update-baseline`.
- Inherited from `0020`, my extract because the record predates `rule:` — the behaviour tier is a
  measurement, never a gate: `--go` before anything runs, never in `package.json`'s `scripts`,
  never in CI.

## Out of scope

- Evidence on the ticked box — `proof:` in the task line, `dw-next` ticking only after the named
  check ran, `dw-land` reading the boxes instead of re-deriving. Carries two more borrowings with
  it: `attack-the-premise` into `dw-next` step 3, and the falsifiable half of `build-the-lever` into
  `dw-land` phase 3. A separate goal, and the change straight after this one.
- "Every claim carries its evidence or its label" — declined on purpose, not deferred: the global
  user memory already forbids claiming behaviour from inference, and no scaffolded repo has shown it
  needs the rule.
- The rest of the pstack and mattpocock harvest — declined per the plan's table.
- Teaching `dw-shape` anything about frontiers — it synthesises, it does not interview.

## Tasks

<!-- Convention: `- [ ]` pending, `- [x]` done — `dw-next` flips the box in the task's own commit.
A task that stopped being necessary keeps its box and gains `**skip:** <reason>`; every later
invocation reads that as not remaining. Never rename a task title. -->

- [x] 1. `dw-grill` asks by frontier — steps 3, 4 and 6 rewritten around the frontier and the empty
      frontier as the close condition, the `description` rewritten, `frontier` added to `CONTEXT.md`,
      the corpus baseline re-recorded and `dw-solo` bumped in both manifests, all in one commit
- [x] 2. `dw-grill` step 2 settles by running rather than asking — a fact needing a command is still
      a fact, a lookup in flight blocks only what depends on it, and a fork only throwaway code can
      settle is named as a spike and offered at the playback rather than built
- [ ] 3. The README's task-router row stops promising five questions a round
- [ ] 4. The behaviour cases follow the frontier premise — case 1 loses its "at the point where a
      sixth would come" framing, case 2's third expectation stops counting questions, and neither
      loses its "nothing is written to disk" assertion

## Anchors

- `skills/dw-grill/SKILL.md:5` — the `description` clauses to cut; the file is 57 lines / 663 words
- `skills/dw-grill/SKILL.md:24` — "Facts … are looked up, never asked", the sentence task 2 widens
- `skills/dw-grill/SKILL.md:30` — "Spend the round well — five questions a round", the cap
- `skills/dw-grill/SKILL.md:36` — "One question per message", from the original fork `19811ac`
- `skills/dw-grill/SKILL.md:40` — "Resolve the tree, not the list", the rule batching must not break
- `skills/dw-grill/SKILL.md:53` — "Do not start implementing, and write nothing", the contract that
  keeps the spike out of the interview
- `README.md:74` — the router row reading "five questions a round, played back between rounds"
- `evals/behaviour/dw-grill.json:3,8,23` — the note, case 1's prompt, case 2's third expectation;
  both cases also assert nothing reaches disk, and that assertion stays
- `evals/cases/dw-grill.json` — 4 positives, 3 negatives; none quotes a clause being cut, so the
  exposure here is idf rather than wording
- `scripts/skill-corpus.baseline.json` — 12767 words total, `dw-grill` 663
- `CONTEXT.md` — the glossary; no grill, round or frontier term today

## References

- `.inspirations/mattpocock-skills/skills/productivity/grilling/SKILL.md` — the frontier mechanic and
  the non-blocking lookup rule, read at `3cca18b`; tasks 1 and 2 lean on it
- `.inspirations/cursor-plugins/pstack/skills/poteto-mode/SKILL.md:20` — the ask-versus-probe
  classifier, read at `f8abedd`; task 2 takes its first half and rejects its second
- `0af5d1a` — the commit whose cap half this reverses and whose playback half it keeps; its body
  carries the argument the nominated decision has to answer
- `docs/agents/skills-and-plugins.md:123` — the settled position on editing a shipped `description`
- `~/.claude/plans/co-jeszcze-z-pstack-snug-fox.md` — the harvest plan this change is section A of;
  its decline table is why `## Out of scope` is as short as it is

## Notes

- Step 5's cadence word had to move with the batch ("after each answer" → "after each round's
  answers"); `## Decisions` claimed step 5 stayed untouched, and the rule did, the cadence did not.
- The `description` edit dropped `eval:routing` to 26/27 on one `dw-land` positive, a 0.153 tie with
  `dw-next` decided by order. Cause: `close` is `dw-land`'s argument word, its phase 2 heading and
  what a user types, and it was missing from the only text the router reads. Named in the same
  commit; 27/27 restored and `dw-land ↔ dw-ship` fell 0.216 → 0.212.
