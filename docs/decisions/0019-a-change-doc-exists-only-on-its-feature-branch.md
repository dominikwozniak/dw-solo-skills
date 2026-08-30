---
decision: 0019
status: active
date: 2026-08-30
---

# 0019 — a change doc exists only on its feature branch

## Context

Shaping on the default branch with `branch: unclaimed` put a change doc's creation on one lineage
and its archive move on another. Whenever the shaping commit was still local-only at squash time,
the post-squash rebase replayed it and resurrected the doc — swept by hand or by `dw-ship` fourteen
times across this repo and grateful-me-app-v2, its only active consumer. The sentinel also carried
a whole claim protocol (`claiming.md`, `dw-start`'s flip, `dw-next`'s ladder) that existed only to
tell an unopened change from an open one.

## Decision

A `CHANGE.md` under `.ai/work/` exists only on its feature branch — `branch:` is written once,
verbatim, at shape time. The unopened queue is `.ai/backlog/`, one entry per idea; `dw-shape` on
the default branch writes there (or switches to a new branch first), and `dw-start` opens a
worktree in which `dw-shape` expands the entry. The claim protocol is deleted.

## Trade-off

A planning sitting can no longer park fully shaped specs on the default branch — a queued idea is a
few backlog lines, and the full shaping happens when a branch picks it up. The richer up-front doc
was rarely still accurate by build time, but repos that used plan sessions to think in writing lose
that parking spot.

## Revisit when

A second concurrent writer appears (the sentinel was also a lock), or backlog entries prove too
thin to carry a plan-session's decisions to the branch that builds them.
