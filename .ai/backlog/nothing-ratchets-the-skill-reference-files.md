---
created: 2026-08-21
source: the-shipped-docs-layer-gets-a-contract-and-a-ceiling
---

# Nothing measures `skills/*/references/*.md`, so the reference layer can grow while the corpus ratchet reads green

`check-skill-corpus.mjs` counts `skills/*/SKILL.md` only. The references are the larger half of some
skills — `dw-land` is 156 lines of skill and 161 of reference — and every word of them loads when the
skill says to read one. Blocked on the baseline's shape: `words` is documented as reproducible with
`cat skills/*/SKILL.md | wc -w`, so widening the glob changes the recorded unit and needs `0009`
revisited rather than a wider glob.
