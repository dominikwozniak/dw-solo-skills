---
created: 2026-08-02
---

# Compare the manifests against `main`, not just against each other

`validate-manifests.sh` only checks `marketplace.json` and `plugin.json` are **equal**, so it misses
both failures a base ref would catch: a version that didn't grow (two parallel changes bumped
`dw-solo-setup` to the same number and auto-merged, twice on 2026-08-02, caught by hand), and a
shipped-payload change under `templates/` or `scripts/runtime/` that merges green with no bump and
never reaches an installed consumer. Needing a base ref may put this in CI rather than the validator;
the two `## Gotchas` lines are the stopgap. Detail: `.ai/archive/skill-routing-evals`,
`.ai/archive/argument-hint-parity`.
