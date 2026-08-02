---
change: skill-arguments-reference
branch: unclaimed
created: 2026-08-02
status: shaping # shaping | building | landed
---

# Change — document each skill's arguments in the README router, and the conventions behind them

## Goal

A reader of the README can see every skill's modes without opening its `SKILL.md` — today the
`bare`/`go`/`all`/`close`/`pr` modes live only in each skill's `argument-hint` frontmatter, and the
README never mentions them. Known when: every router-table row carries an Arguments cell sourced
from its skill's `argument-hint`, and `docs/SKILL-ANATOMY.md` states the argument conventions a new
skill should follow and keep.

## Decisions

- **A column in the existing router tables, not a new doc** — the router is where skills are
  already listed and validated; a separate reference is one more place to rot.
- **Conventions live in `docs/SKILL-ANATOMY.md`** — it is the authors' doc and already owns the
  `argument-hint` field. The observable catalog patterns to write down: bare is always the safe
  default (report/verdict/list), a single lowercase word switches mode (`go`, `all`, `close`,
  `pr`), free text narrows focus (`dw-check`, `dw-grill`), hints separate options with `·` and
  state bare first.
- **No validator extension** — `validate-docs.sh` could only check the Arguments cell exists, not
  that it matches the hint; a presence check can't catch the drift that matters. Revisit if the
  column actually rots.

## Tasks

- [ ] 1. README: add an `Arguments` column to all four router tables (loop `:73-81`, anytime
      `:85-87`, off-loop `:91-93`, setup `:97-100`), each cell condensed from that skill's
      `argument-hint` (`bare · go · all` style; `—` for dw-doctor, which takes none). Extend step 4
      of "Adding a skill" (`CLAUDE.md:60` and the synced `AGENTS.md` copy) so a new skill also
      fills its Arguments cell.
- [ ] 2. `docs/SKILL-ANATOMY.md`: expand the `argument-hint` bullet (`:29`) into the conventions
      from Decisions, plus the maintenance rule — the hint is canon, the README cell mirrors it,
      change both in the same commit.

## Anchors

- `skills/*/SKILL.md` `argument-hint` lines — 10 skills carry one; `dw-doctor` has none.
- `README.md:73-81,85-87,91-93,97-100` — the four router tables getting the column.
- `docs/SKILL-ANATOMY.md:17,29` — the field's current, author-facing description.
- `CLAUDE.md:60` (= `AGENTS.md`, separate synced file, same edit) — the add-a-skill checklist step
  that names every doc site a new skill must touch.
- `scripts/validate-docs.sh:1-16` — the validator deliberately not extended (see Decisions).

## Notes

- Shaped on the claimed branch `ai-folder-lifecycle` (the main tree was unavailable to this
  session), so `branch: unclaimed` rides that PR: the change becomes claimable from `main` only
  after it merges. Both changes touch the README router table — building this one after
  `ai-folder-lifecycle` lands avoids the overlap.
