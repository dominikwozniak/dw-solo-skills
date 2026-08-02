---
created: 2026-08-02
source: skill-routing-evals
---

# Make `validate-manifests.sh` require a version bump when the shipped payload changes

It only checks `marketplace.json` and `plugin.json` agree, so a fix to `templates/` or
`scripts/runtime/` merges green and never reaches an installed consumer — which is what happened to
the `lint-on-edit.sh` fix in this change until the closing pass caught it. A diff-aware check needs a
base ref, so it may belong in CI rather than the validator; the `## Gotchas` line is the stopgap.
