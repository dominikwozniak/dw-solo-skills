---
created: 2026-08-01
---

# Self-tests for `block-non-pnpm.sh` and `link-local-memory.sh`

What is left of a wider sweep: the other four targets moved to the bundles that already open those
files — `doctor.sh` and `typecheck-on-stop.sh` to `setup-payload-sweep`, the two validator fixtures to
`validator-blind-spots` — and `lint-on-edit` got its test in `skill-routing-evals`. These two hooks
are untested and nothing else is going to touch them.
