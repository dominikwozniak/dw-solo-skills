---
created: 2026-08-12
source: migrate-ci-to-the-pnpm-setup-successor-action
---

# Turn on `cache: true` in the four `pnpm/setup@v2` steps

The repo caches nothing today; now that one action owns install, the pnpm store cache is a one-line
input (`cache-dependency-path` already defaults to `pnpm-lock.yaml`). Left out deliberately: it
changes CI timing, so it wants its own green/red comparison against the baseline this PR just set —
setup was ~7s and the whole tree is 9 locked entries, so measure before assuming it pays.
Findings: `.ai/archive/migrate-ci-to-the-pnpm-setup-successor-action`.
