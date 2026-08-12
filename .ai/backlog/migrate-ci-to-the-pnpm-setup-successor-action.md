---
created: 2026-08-12
source: pnpm-pin-in-one-field
---

# Migrate the three Node workflows to `pnpm/setup@v2`, the successor action

`pnpm/action-setup`'s own README now points at [`pnpm/setup`](https://github.com/pnpm/setup)
(v2.0.2, `84cb39b217b10273981911c288cd62326dc7c6d2`), which installs pnpm **and** the runtime in one
step, reads `devEngines.runtime` plus `devEngines.packageManager` with no inputs, and runs
`pnpm install` unless `install: false` — so `actions/setup-node` and `.nvmrc` would leave CI and
`devEngines.runtime` would become the Node pin. That is where the Node-pinning question this repo
keeps parking gets answered; `pnpm-pin-in-one-field` deliberately closed it as "no" while
`setup-node` still reads `.nvmrc`. Findings: `.ai/archive/pnpm-pin-in-one-field`.
