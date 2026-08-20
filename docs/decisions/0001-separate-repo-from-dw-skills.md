---
decision: 0001
status: superseded
date: 2026-07-30
superseded-by: 0014
---

# 0001 — The thin lane lives in its own repo, with vendored hooks

## Context

This lane began as the `dw-solo` plugin inside
[`dw-skills`](https://github.com/dominikwozniak/dw-skills), sharing that repo's `templates/` canon,
`scripts/runtime/`, validators and CI. The shared `templates/` payload was shaped for the team
scaffolder, and this lane paid for that at runtime: `dw-init` had to replace a whole `## Workflow`
section in `CLAUDE.local.md` after copying it, was told not to copy `ai-README.md` at all (it
documented `runs/`/`verify/`/`handoffs/`, directories this lane never creates) and to hand-write a
replacement inline, and appended a gitignore block whose markers read `dw-bootstrap managed block`.

## Decision

The thin lane is its own marketplace repo with its own `templates/`, shaped for one reader. It ships
eight skills: the five loop skills, plus `dw-git`, `dw-doctor` and `dw-setup-precommit` **forked** from
the shared plugin and simplified — no ticket prefixes, no PR flow, no team-lane health checks.

`templates/hooks/*.sh` and `scripts/runtime/slugify.sh` are **vendored byte-identical copies**, not a
published dependency.

## Trade-off

Extracting 7 files of content required standing up ~40 files of infrastructure: three validators, the
self-tests, six CI workflows, prettier/agnix/husky config, and a second marketplace source to install
from. Measured before the split, only 3 of 96 commits had ever touched both lanes, and all three were
cross-cutting fixes that a single repo let you make once — those now cost two commits.

Publishing `templates/` and `scripts/runtime/` as a versioned package would have removed the drift risk
entirely, and was rejected as more upfront work than the duplication is worth at this size: a third
repo, a release flow, and version pinning in both consumers.

The accepted cost is that **hook fixes must be applied in both repos, and nothing can detect drift
across the boundary.** `hooks-in-sync.test.sh` only pins this repo's `.claude/hooks/` to its own
`templates/hooks/`.

## Revisit when

A hook fix is missed in one repo and ships broken — that is the failure this trade accepted, and one
real instance is enough to justify publishing `templates/` as a versioned dependency instead.
