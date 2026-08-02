---
created: 2026-08-02
source: pnpm-v11-migration
---

# Bump `pnpm/action-setup` past v4 in both workflows

The pinned SHA predates `devEngines` support and reads only `packageManager`; newer versions read
`devEngines` and give it priority. Bumping retires the duplicated-version hazard and would let
`packageManager` be dropped. Context: `.ai/archive/pnpm-v11-migration` (Notes).
