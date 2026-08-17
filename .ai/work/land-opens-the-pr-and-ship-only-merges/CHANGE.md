---
change: land-opens-the-pr-and-ship-only-merges
branch: land-opens-the-pr-and-ship-only-merges
created: 2026-08-17
status: shaping # shaping | building | landed | rejected
---

# Change — dw-land ends with an open PR; dw-ship only merges, cleans and syncs

## Goal

A finished change closes in two commands of one decision each: `dw-land` (verdict → go →
promote+archive → push + PR, report ends with the PR link) and `dw-ship` (merge → worktree/branch
cleanup → `git pull` on the default branch → sweep the squash-resurrected work doc). No HARD STOP
inside dw-ship, no ship→land→ship round trip.

## Decisions

- PR prep moves into dw-land, behind the same go — the land→ship window is where CI and
  `/codex:review` happen (grill 2026-08-17, variant B).
- Names stay, no dw-close — `close` collides with dw-land's mode; skills are named after the moment.
- rejected ≡ cancelled — one archive status covers ideas turned down and work abandoned mid-build.

## Tasks

- [ ] 1. `skills/dw-land/SKILL.md`: after the close commit, same go: `git push -u` + `gh pr create` via dw-git, report ends with the PR link; default-branch path closes artifacts only and points Next at ship/push; rewrite the "shipping … belongs to dw-ship" disclaimer (merge still does).
- [ ] 2. `skills/dw-ship/SKILL.md`: strip push/PR/HARD STOP; new flow — refuse while a `CHANGE.md` matches this branch ("run /dw-land first", stop, no come-back promise) → `gh pr checks` → `gh pr merge --squash --title "<PR title>"` → ExitWorktree → `worktree.sh remove` → `git pull` on default → sweep a resurrected `.ai/work/<slug>/` → report; default-branch fast path = `git push`. Fix the frontmatter drift and the argument-hint.
- [ ] 3. Docs in the same breath: `AGENTS.md` loop paragraph (closing = `dw-land → dw-ship`, one decision each; drop "runs the closing pass itself"), `docs/agents/change-artifacts.md`, `CONTEXT.md` (Completion gate/Archive: PR opens at land, checks settle at ship; rejected ≡ cancelled), `.ai/archive/README.md` status note.
- [ ] 4. `evals/cases/dw-land.json` reviewed against the new description; `pnpm eval:routing` ≥ 67; corpus baseline updated only on net growth; bump `plugins/dw-solo` + `marketplace.json`.

## Anchors

- `skills/dw-ship/SKILL.md:32` — the delegate-and-come-back round trip being removed
- `skills/dw-ship/SKILL.md:62` — the cleanup/sync section that stays and becomes the whole skill
- `skills/dw-land/SKILL.md:156` — the "no shipping" disclaimer to rewrite
- `AGENTS.md:44` — the one-command promise to rewrite
- commits `9eef63d`, `73e003a` — squash-merge resurrecting work docs; the sweep task closes this

## Notes

Land after or before the wave-1 siblings, rebasing over `marketplace.json` and the corpus baseline —
those two files conflict across all three.
