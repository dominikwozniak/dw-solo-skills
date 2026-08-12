---
change: own-root-under-budget-and-router
branch: unclaimed
created: 2026-08-12
status: shaping # shaping | building | landed
---

# Change — this repo's own root under a declared budget, with a task router

## Goal

This repo's `AGENTS.md` (288 lines / 21.6 KB on the de-ratchet base) declares
`Budget: **120 lines / 10 KB**` and holds it: boundaries, commands and a Task Router stay in the
root; procedure and the 12 `## Gotchas` entries move to routed topic files read on demand. The
config content of the gitignored `CLAUDE.local.md` (`## Git conventions`, the command bullets)
moves into `AGENTS.md`, mirroring what the scaffold now ships. You know it worked when the root is
within budget, `pnpm validate:docs` fails on an over-budget root or a topic file with no router
row, and a fresh clone gets the git conventions and the lint command without any gitignored file.

## Decisions

- **The root budget replaces the root-gotcha cap** — `validate-artifacts.sh`'s "`## Gotchas` ≤ 12
  in `AGENTS.md`" check chases a section this change empties; the budget plus router coverage in
  `validate-docs.sh` is the successor. The backlog cap stays.
- **Topic files grow from the existing 12 gotchas' themes, not from a designed taxonomy** — the
  de-ratchet merge already grouped them (worktrees, pnpm, git history, lint hooks); those groups
  are the first topic files, applying `dw-land`'s new growth rule retroactively.
- **`CLAUDE.local.md` here is deleted by the user, not the agent** — it is a personal, gitignored
  file; the change moves its config content and reports what remains (About-me placeholders,
  tools list), and the user decides the file's fate.

## Tasks

- [ ] 1. **Budget + router into the root.** Add the budget line and a `## Task Router` section to
      `AGENTS.md`; carve the root to boundaries/commands/routing; move the procedure-weight prose
      (symlink-canon walkthrough, add-a-skill details beyond the checklist, `.ai/` layout detail)
      into routed topic files (`docs/agents/…`, 2–4 files, sized to the content).
- [ ] 2. **Gotchas out of the root.** Move the 12 entries into the topic files their router rows
      name, thematic groups intact; delete the root section.
- [ ] 3. **Local memory in.** Move `## Git conventions` and the `**Lint/Typecheck/Test command**`
      bullets from `CLAUDE.local.md` into `AGENTS.md` (Solo-lane-style section); update
      `CLAUDE.local.md`-naming prose in README/AGENTS.md; report what's left in the local file for
      the user to delete.
- [ ] 4. **The checks.** `validate-docs.sh` gains root-budget and router-coverage checks (~2 checks
      in the existing script, no new file); re-point or drop the root-gotcha cap in
      `validate-artifacts.sh` per the first decision; full gate.

## Anchors

- `AGENTS.md` **on the `de-ratchet-the-solo-lane` branch** — 288 lines / 21,651 B; the absorbed
  DESIGN.md rules are the procedure-weight content task 1 moves out. Re-verify sections at claim.
- `/Users/dominik.wozniak/workspace/private/byarcadia-packages/grateful-me-app-v2/AGENTS.md` +
  `docs/agents/README.md` there — the target shape and the "what belongs in the root vs a topic
  file" rules.
- `scripts/validate-docs.sh` (post-de-ratchet: ~80 lines, four checks) — where the two new checks
  land.
- `scripts/validate-artifacts.sh` — the gotcha-cap check the first decision retires or re-points.
- `CLAUDE.local.md` (this repo, gitignored) — `## Git conventions` and `## Project specifics` are
  the content task 3 migrates.

## Notes

- **Lands after `setup-lives-in-tracked-agents-md`** — task 3 moves the `**Lint command**` line
  out of the file the current hooks grep; without that change's AGENTS.md-first chain,
  `lint-on-edit.sh` would silently lint nothing. Also waits on the de-ratchet merge itself: it
  edits the same `AGENTS.md`.
- No plugin bump: everything touched (own docs, `scripts/validate-*.sh`) is repo CI surface, not
  payload — unless task 3's prose edits reach a skill body; check at land time.
