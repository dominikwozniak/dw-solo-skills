---
created: 2026-08-02
source: pnpm-v11-migration
---

# Settle how pnpm and Node are pinned for CI

The `pnpm/action-setup` SHA pinned in all three workflows is v4 — it predates `devEngines` support and
reads only `packageManager`, so bumping it retires the duplicated-version hazard in `## Gotchas` and
would let `packageManager` be dropped. That bump is also the precondition for the open Node half,
parked deliberately by the migration: CI pins Node via `node-version-file: .nvmrc`, while
`devEngines.runtime` with `onFail: "download"` would have pnpm fetch its own. Context:
`.ai/archive/pnpm-v11-migration` (Notes).
