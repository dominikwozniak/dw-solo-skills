---
created: 2026-08-12
source: migrate-ci-to-the-pnpm-setup-successor-action
---

# `dw-doctor` reads `devEngines.runtime` as the Node pin

The mirror of what `pnpm-pin-in-one-field` task 2 did for `packageManager`: `doctor.sh` takes the Node
floor from `engines.node` and hints `.nvmrc` twice (`:89`, `:95`), a file this repo no longer has —
still fair advice for a consumer repo that does, which is why it stayed out. Ships alone, bumps
`dw-solo-setup`, and touches `SKILL.md:31` too. Findings:
`.ai/archive/migrate-ci-to-the-pnpm-setup-successor-action`.
