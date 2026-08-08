---
created: 2026-08-05
source: routing-eval-explain-flag
---

# The "shared boilerplate lands on idf 0" claim is not true of this corpus

`evals/README.md:261` and the comment at `evals/routing.ts:124` both justify having no boilerplate
stopword list by saying the shared "Use when someone says" phrasing carries idf 0. `--explain` shows
it does not: `use` is in 7 of 11 descriptions, `say` in 5. The phrasing gets _cheap_, never free, so
the design works for a weaker reason than the one written down.

Correct both sentences to say what actually happens, and decide whether the
`in every description — idf 0` label at `evals/routing.ts:655` keeps its wording — no term in the
corpus reaches df 11, so that branch has never printed. Findings: `.ai/archive/routing-eval-explain-flag`.
