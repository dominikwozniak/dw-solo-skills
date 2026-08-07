---
created: 2026-08-02
source: pnpm-v11-migration
---

# Settle the pnpm 11 pinning story, then propagate it to what ships

Two steps in order — the second is undecidable first. **Pinning**: the `pnpm/action-setup` SHA in all
three Node workflows is v4, predating `devEngines` support and reading only `packageManager`, so
bumping it retires the duplicated-version hazard in `## Gotchas` and would let `packageManager` be
dropped; the open Node half is `.nvmrc` / `engines.node` versus `devEngines.runtime` with
`onFail: "download"`. **Payload**: `doctor.sh:98-111` reads `.packageManager` and advises
`corepack enable` — both wrong under v11 and both contingent on the decision above. The designed but
unbuilt check D1 must flag an orphaned `package.json#pnpm` block's _existence_ rather than trust
pnpm's warning to enumerate what it drops, and detect a migrated lockfile via
`packageManagerDependencies`, not `lockfileVersion`. Bumps `dw-solo-setup`. `templates/` needs
nothing — it ships no `package.json`. Measured findings: `.ai/archive/pnpm-v11-migration` (Notes).
