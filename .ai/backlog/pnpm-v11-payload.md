---
created: 2026-08-02
source: pnpm-v11-migration
---

# Teach `templates/`, `dw-init` and `dw-doctor` the pnpm 11 setup this repo now runs

Doctor check D1 must flag an orphaned `package.json#pnpm` block's existence rather than trust
pnpm's warning, and detect a migrated lockfile via `packageManagerDependencies`, not
`lockfileVersion`. `doctor.sh:99-113` still advises `corepack enable` — wrong under v11.
Measured findings: `.ai/archive/pnpm-v11-migration` (Notes).
