---
change: evals-accuracy-and-gates
branch: evals-accuracy-and-gates
created: 2026-09-03
status: landed # shaping | building | landed
landed: 2026-09-03
---

# Change — the routing eval names its blank prompts and holds its own case-file contract

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
