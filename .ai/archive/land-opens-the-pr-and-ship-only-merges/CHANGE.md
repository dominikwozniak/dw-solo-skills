---
change: land-opens-the-pr-and-ship-only-merges
branch: land-opens-the-pr-and-ship-only-merges
created: 2026-08-17
status: building # shaping | building | landed | rejected
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

- [x] 1. `skills/dw-land/SKILL.md`: after the close commit, same go: `git push -u` + `gh pr create` via dw-git, report ends with the PR link; default-branch path closes artifacts only and points Next at ship/push; rewrite the "shipping … belongs to dw-ship" disclaimer (merge still does).
- [x] 2. `skills/dw-ship/SKILL.md`: strip push/PR/HARD STOP; new flow — refuse while a `CHANGE.md` matches this branch ("run /dw-land first", stop, no come-back promise) → `gh pr checks` → `gh pr merge --squash --title "<PR title>"` → ExitWorktree → `worktree.sh remove` → `git pull` on default → sweep a resurrected `.ai/work/<slug>/` → report; default-branch fast path = `git push`. Fix the frontmatter drift and the argument-hint.
- [x] 3. Docs in the same breath: `AGENTS.md` loop paragraph (closing = `dw-land → dw-ship`, one decision each; drop "runs the closing pass itself"), `docs/agents/change-artifacts.md`, `CONTEXT.md` (Completion gate/Archive: PR opens at land, checks settle at ship; rejected ≡ cancelled), `.ai/archive/README.md` status note.
- [x] 4. `evals/cases/dw-land.json` reviewed against the new description; `pnpm eval:routing` ≥ 67; corpus baseline updated only on net growth; bump `plugins/dw-solo` + `marketplace.json`.

## Anchors

- `skills/dw-ship/SKILL.md:32` — the delegate-and-come-back round trip being removed
- `skills/dw-ship/SKILL.md:62` — the cleanup/sync section that stays and becomes the whole skill
- `skills/dw-land/SKILL.md:156` — the "no shipping" disclaimer to rewrite
- `AGENTS.md:44` — the one-command promise to rewrite
- commits `9eef63d`, `73e003a` — squash-merge resurrecting work docs; the sweep task closes this

## Notes

Land after or before the wave-1 siblings, rebasing over `marketplace.json` and the corpus baseline —
those two files conflict across all three.

**Task 1.** `pr:` cannot be written by the close commit any more — the PR doesn't exist until after
it. Step 4 backfills it in a second one-line commit that the squash folds away, rather than pushing
before the promotion commit to learn the number early; two pushes and a PR opened over an
unpromoted diff cost more than one throwaway commit. Task 1 leaves the corpus +287 words over the
baseline on its own; task 2's strip is what pays it back, so the ratchet is only green again for the
final tree (`pnpm validate:artifacts` fails mid-change by design — pre-commit doesn't run it).

Found while building: `pnpm lint <path>` misroutes to `eslint` in both trees, so `lint-on-edit` has
been passing silently. Parked in `.ai/backlog/`, since which of the three layers to fix is a
decision.

**Task 2.** `argument-hint` is **deleted**, not rewritten: with `pr` gone the skill takes no
arguments, and agnix warns on a hint whose body never reads `$ARGUMENTS`. The sweep's mechanism is
narrower than "squash-merge resurrects work docs" — `73e003a`/`9eef63d` say it exactly: a shaping
commit still **local-only** when its PR squashes gets replayed on top of the squash by
`git pull --rebase`. So the sweep matches on the `.ai/archive/<slug>/` twin, not on the shipped
slug — one shaping commit can carry several changes (this repo's `08f5b69` carries three) and the
siblings' docs are live work. The strip did not shrink dw-ship: −HARD STOP/−PR path is roughly
+sweep, ending +70 words.

Also stale now, for task 3: `dw-doctor`'s two codex lines (`SKILL.md:61`, `scripts/doctor.sh:74,91`)
credit `dw-ship` with a review/rescue route the strip removed.

**Task 3.** Four files past the shaped list, all made stale by tasks 1–2 rather than found stale:
`README.md`'s two router rows, `templates/AGENTS.md`'s loop sentence (the payload's own copy of the
one-command promise), and `dw-doctor`'s three codex/`gh` strings — those now name `dw-land`, which is
where the `/codex:review` offer moved, so dw-land gained the clause that makes them true. The `rejected
≡ cancelled` decision also needed a home in a **skill**, not only in the two READMEs: `dw-land
reject`'s first line now says both cases.

**Task 4.** The eval broke on a prompt belonging to **neither** edited skill, and the mechanism is
worth keeping: `dw-shape` stole `dw-git`'s "stage what I have and open a pull request against main"
because putting **open** in dw-land's description raised that term's document frequency, and `open`
was the only vocabulary word dw-git's description shared with the prompt at all — it said "open PR",
never "pull request", so `pull` and `request` were scoring for `dw-shape` and `dw-grill`. Editing one
skill's description reweights every other skill's, which no case file can localise. Fixed at the
cause: dw-git's description now names "open a pull request" and "stage", which also cut its shadowed
count 3 → 2. Rank-1 and negatives are back at base parity (20/30, 21/21) — verified by running the
eval against a `git archive` of `08f5b69` in a scratch dir, since ROOT is fixed to the script's own
tree.

Corpus baseline re-recorded at 13857 (was 13458): net growth, per the task. `dw-solo-setup` is bumped
alongside `dw-solo` — the shaped list named only the latter, but `dw-doctor` and `templates/` belong to
setup, and `validate-manifests.sh` checks only that the two copies of a version are equal, never that
either moved. The backlog now sits at 8/8, at the cap.

`AGENTS.md` hit 120/120 lines on the first draft. What came back out was the sentence naming the
land→ship window as where CI and review happen — a fact `dw-land` and `dw-ship` already state, so
the root file was the third copy, not the short one.
