---
created: 2026-08-01
---

# Test sweep for the untested shell

`doctor.sh` (261 lines, and the only script that runs on someone else's machine), `block-non-pnpm`,
`link-local-memory`, `typecheck-on-stop`, plus fixtures for `validate-docs.sh` and
`validate-manifests.sh` — `717f1e5` is proof a validator can pass silently while broken.
`lint-on-edit` came off this list: `scripts/tests/lint-on-edit.test.sh` landed in
`skill-routing-evals`.
