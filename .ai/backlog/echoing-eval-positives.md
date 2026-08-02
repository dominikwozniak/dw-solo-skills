---
created: 2026-08-02
source: skill-routing-evals
---

# Rewrite the positives that echo their own description, in `dw-grill` and `dw-land`

Both score 4/4 — the only clean sheets in the corpus — and both reuse their description's literal
trigger language, which `evals/README.md` forbids as scoring the eval against itself. So the 67%
baseline is optimistic, and it is optimistic exactly on `dw-grill`, the skill the evals were built to
interrogate. Rewrite, re-measure, and re-pin `--min-rank1` to whatever comes out.
