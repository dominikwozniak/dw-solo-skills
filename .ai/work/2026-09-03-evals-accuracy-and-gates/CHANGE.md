---
change: evals-accuracy-and-gates
branch: evals-accuracy-and-gates
created: 2026-09-03
status: building # shaping | building | landed
---

# Change — the routing eval names its blank prompts and holds its own case-file contract

## Goal

`node evals/routing.ts` grows a `blank` column, a fifth gate behind `--max-blank`, a reverse
coverage check and the 3-positive / 2-negative floor the docs already promise; `evals/README.md`
records a baseline for the corpus that exists. You know it worked when the summary table
distinguishes a lost prompt from one that asserts nothing, when removing a case file fails the run,
when `--max-blank 2` fails and `--max-blank 3` passes, and when no number in `evals/README.md`
is derived from a corpus of 11.

## Decisions

- **A blank positive is counted and capped, never a hard error** — one of the three today
  (`dw-next`, "pick this back up …") is a trade `evals/README.md` recorded on 2026-08-18. A hard
  gate would fail the run on a loss this repo chose.
- **The rank-1 denominator does not change** — a blank positive is a real miss; the defect is that
  the table cannot say which kind of miss it is. Splitting the column fixes that without moving
  a number that six sections of prose are pinned to.
- **`--max-blank` pinned at 3, not 0** — the ratchet records today's state so it cannot grow
  silently. Widening the two descriptions with a real vocabulary gap is its own measurement.
- **Reverse coverage is a hard `fail()`** — symmetric with the two that already exist for a case
  file naming a dead skill and one naming an explicit-invoke skill.
- **`MIN_POSITIVE = 3` / `MIN_NEGATIVE = 2` in code** — `.inspirations/addyosmani-agent-skills`
  enforces the same two constants against the same Tier-2 design. All seven case files already
  clear it, so the floor costs nothing today and holds the contract tomorrow.
- **The old baselines stay in `evals/README.md`** — the file is a dated log of measurements. A
  superseded number is history, not an error.

## Tasks

- [x] 1. `evals/routing.ts` — the `blank` tally and column, `--max-blank` and its gate, the
      reverse coverage `fail()`, the 3/2 floor in `loadCases`, and the dead "Use when someone
      says" example out of the `STOPWORDS` comment. `package.json` pins `--max-blank 3`.
      `evals/cases/dw-check.json` and `dw-next.json` gain a `note` on each blank positive.
      `docs/agents/skills-and-plugins.md` step 6 and `CONTEXT.md`'s glossary follow the code.
- [x] 2. `evals/README.md` — a `Re-measured 2026-09-03` section, the `--explain` walkthrough
      recomputed at N=14, "five" → "seven", the dead idf example in Caveats, the checklist
      pointer, and the new gate/column documented in Case files and What gates.
- [x] 3. Backlog — fold the two vocabulary gaps into the existing stemmer audit entry; add the
      Tier-3 behavioural runner entry.

## Anchors

- `evals/routing.ts:472-479` — the positive-zero branch that `continue`s in silence; where the
  tally goes.
- `evals/routing.ts:506-517` — the `negBlank` branch it should be symmetric with.
- `evals/routing.ts:441-452` — the two existing per-case `fail()`s the reverse check joins.
- `evals/routing.ts:124-129` — the `STOPWORDS` comment citing "Use when someone says", a phrase
  now in zero `SKILL.md` files.
- `docs/agents/skills-and-plugins.md:49-54` — step 6, which says nothing validates the count.
- `.ai/backlog/2026-08-05-stemmer-derivational-audit.md` — already names
  "where did we leave off on this" as its own subject.

## References

- `https://www.philschmid.de/testing-skills` — the three dimensions (Outcome, Style, Efficiency),
  negative controls as a requirement, and the capability/preference/regression taxonomy.
- `.inspirations/addyosmani-agent-skills/scripts/run-evals.js` — the same Tier-2 design with
  `MIN_POSITIVE`/`MIN_NEGATIVE` enforced, plus the Tier-3 shape chosen for the backlog entry.
- `.inspirations/gstack/test/catalog-budget.test.ts` — a budget over the discovery surface alone,
  noted as out of scope here.

## Notes

- `shadowed` is 8, not 7 — the plan's number came from a summary that did not total the column.
- Two of the three blank positives were on file as _stemming_ failures in the backlog's stemmer
  audit; `--explain` reclassifies both as vocabulary gaps, so that entry gained a second half.
- `dw-shape`'s description never contains "shape"; its whole claim on the term is its `name`.
