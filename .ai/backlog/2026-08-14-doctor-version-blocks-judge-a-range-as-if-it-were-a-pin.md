---
created: 2026-08-14
source: doctor-version-probes-read-only-and-read-devengines
---

# `doctor.sh`'s version blocks mishandle a declared range, each in its own way

The node block's ahead-of-pin branch calls any non-matching declaration a pin, so
`devEngines.runtime: ">=22.18.0"` reports `24.19.0 on PATH (devEngines pins >=22.18.0)`. The pnpm
block has the discriminator the node one lacks (`*[!0-9.]*` → "wants") but never checks membership:
a PATH pnpm outside `">=11.0.0 <12.0.0"` still reports OK. Findings:
`.ai/archive/2026-08-14-doctor-version-probes-read-only-and-read-devengines`.
