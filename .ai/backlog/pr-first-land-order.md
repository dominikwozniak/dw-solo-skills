---
created: 2026-08-02
source: pnpm-v11-migration
---

# Name the PR-first path in `dw-ship`/`dw-land`, or give CI a manual trigger

A task whose done-condition is "CI passes" cannot be proven before the PR exists, so it cannot be
landed before it is shipped — the reverse of the order `dw-ship` states. Workflows here only
trigger on `pull_request` or a push to `main`; there is no `workflow_dispatch`.
