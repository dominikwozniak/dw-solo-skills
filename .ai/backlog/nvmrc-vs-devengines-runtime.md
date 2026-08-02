---
created: 2026-08-02
source: pnpm-v11-migration
---

# Decide `.nvmrc` / `engines.node` versus `devEngines.runtime`

Parked deliberately by the pnpm 11 migration: CI pins Node via `node-version-file: .nvmrc`, and
`onFail: "download"` would have pnpm fetch its own Node.
