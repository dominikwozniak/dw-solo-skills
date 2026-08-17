---
change: check-delegates-to-codex-by-default
branch: check-delegates-to-codex-by-default
created: 2026-08-17
status: shaping # shaping | building | landed | rejected
---

# Change — bare dw-check delegates to codex, with a triviality floor

## Goal

Bare `dw-check` hands the diff to `codex:rescue` whenever the codex plugin is present. A trivial
diff — 2 files or fewer and under 50 lines — gets the self-review instead, and a missing plugin
falls back to self-review with a one-line install hint. Finding-by-finding verification before the
report stays.

## Decisions

- Default-on with degradation (gstack's shape), triviality floor from addyosmani (≤2 files,
  <50 lines) — the cross-model pass is the value; silent skipping was the failure mode.
- At an open PR, suggest `/codex:review --wait` — explicit-invoke, so the user types it; pairs with
  the land-opens-the-pr sibling, which makes the PR exist before the merge decision.

## Tasks

- [ ] 1. `skills/dw-check/SKILL.md`: rewrite step 2 ("Delegate only when asked for it" → codex by default, floor, fallback); keep `codex` as the force argument; update argument-hint and description.
- [ ] 2. `evals/cases/dw-check.json` reviewed; `pnpm eval:routing` ≥ 67; corpus baseline only on net growth; bump `plugins/dw-solo` + `marketplace.json`.

## Anchors

- `skills/dw-check/SKILL.md:36` — the step being rewritten
