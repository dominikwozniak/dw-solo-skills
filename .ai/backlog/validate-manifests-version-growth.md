---
created: 2026-08-02
---

# `validate-manifests.sh` can't see a version collision

It checks marketplace.json and plugin.json are **equal**, never that the version grew. Two
parallel changes both bumping `dw-solo` 0.4.0 → 0.4.1 auto-merged with no conflict and no warning
— caught by hand on 2026-08-02. Compare against the version on the default branch instead.

Happened again the same day: `argument-hint-parity` bumped `dw-solo-setup` to 0.1.5 while
`skill-routing-evals` merged the same number first. The rebase raised no conflict and the validator
stayed green; only comparing against `main` by hand caught it.
