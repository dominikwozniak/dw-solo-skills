---
created: 2026-08-02
source: skill-routing-evals
---

# Re-measure the routing corpus and re-pin `--min-rank1`

Two halves, one measurement. `dw-grill` and `dw-land` are the corpus's only 4/4 sheets and both reuse
their description's literal trigger language, which `evals/README.md` forbids as scoring the eval
against itself — so the 67% baseline is optimistic exactly on the skill the evals were built to
interrogate. `dw-git` holds 2 of 5 with two scoring **zero** since `44c06c7` removed its synonym
sentence, and whether a description should carry paraphrases at all is the real question — one
`node evals/trigger.ts --go --trials 3 dw-git` run answers it before anything is edited. Cheapest
once `routing-eval-explain-flag` lands `--explain`. Detail: `.ai/archive/skill-routing-evals`.
