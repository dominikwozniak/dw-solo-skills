---
decision: 0004
status: superseded
date: 2026-08-02
superseded-by: 0018
---

# 0004 — Landed change docs are archived, not deleted

## Context

PRs here merge by squash, so a change doc's worked state — ticked tasks, answered `## Notes` —
reaches **no commit on `main`**: "git is the archive" was false, proven on PR #2. With the doc
dying at close, `dw-land` had nowhere to put findings except `.ai/BACKLOG.md`, which broke its own
one-line bar and produced merge conflicts between parallel branches by the second PR.

## Decision

`dw-land` moves `.ai/work/<slug>/` to `.ai/archive/<slug>/` at close — `status: landed`, stamped
`landed:` and `pr:` — and the backlog is one file per follow-up (`.ai/backlog/<slug>.md`) whose
findings point at the archive instead of being inlined. One slug travels backlog → work → archive.
This replaces the delete-at-merge half of the "persistent but disposable" pillar; the promotion
step (decisions / `CONTEXT.md` / Gotchas) is unchanged, and the archive is history, not a fifth
promotion target.

## Trade-off

`.ai/` now accumulates: an archived doc is stale prose a future session could mistake for live
guidance. Mitigated by the "history, not guidance" README and by every locator glob staying scoped
to `.ai/work/`. Deleting kept the tree minimal — but silently destroyed the worked record under
squash merges, and pushed archive-grade context into the backlog.

## Revisit when

A session is observed following an archived doc as if it were live guidance, or the archive grows
past ~30 changes and starts costing real attention (linter noise on its paths is the early signal).
