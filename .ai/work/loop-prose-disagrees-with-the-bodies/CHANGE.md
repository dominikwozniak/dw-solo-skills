---
change: loop-prose-disagrees-with-the-bodies
branch: loop-prose-disagrees-with-the-bodies
created: 2026-08-12
status: building # shaping | building | landed
---

# Change — three places where the loop's prose promises something no body does

## Goal

The three defects are gone from the bodies. One: the base ref for a review diff is stated **once**, in
`dw-git`'s borrowed default-branch lookup, as "whichever of local and `origin` contains the other" —
and `dw-land` and `dw-check` point at it instead of each carrying the wrong preference with its own
justification. Two: `dw-ship` names the skipped review on **both** paths, so a fast-path push reaches
the irreversible step having said so. Three: a done-condition observable only after push — "CI green" —
no longer reads as an unmet `## Goal` result at land time; `dw-land` says where it is verified and
`dw-ship` verifies it there. `dw-solo` is bumped in both manifests. You know it worked by reading the
four bodies: no `origin`-preference sentence survives outside `dw-git`, and neither `dw-ship` path is
silent about review.

## Decisions

- **One change, not three** — each item could land alone and leave the repo green, so the count test
  fires and the answer is no: three sentence-scale corrections in the same four skill bodies, one
  `dw-solo` bump, one gate run. Items 1–2 are cousins besides — both are "what the loop owes you at the
  irreversible step". Same bundling axis as `#9` and `two-gates-against-scope-shedding`.
- **Item 4 of the backlog entry is a separate change** — `.ai/work/shape-time-parking-for-the-left-out-list/`.
  It is a feature, not a correction: `dw-grill:86` already tells the truth ("at land time"), so nothing
  is presently wrong. Git history agrees it was never one scope — it was its own entry
  (`two-gates-against-scope-shedding`, 2ef0018), folded into this bundle by `de-ratchet-the-solo-lane`
  (1182f7f), the commit that installed `BACKLOG_CAP=8` and pruned the queue. That was a cap decision.
- **Item 2 is prose, not a `workflow_dispatch`** — CI green gets verified where the evidence exists
  (`dw-ship`'s stop) rather than made observable earlier at the cost of 7 workflow files and a manual
  dispatch step in the loop.
- **The rule lands in `dw-git`, not in a fourth place** — `dw-git:23-25` is already the one lookup every
  skill borrows ("resolving the default branch the way `dw-git` does"), so the ref choice belongs beside
  the name choice. Two skills then shrink to a pointer; net bytes go down.
- **No decision record** — undoing this is deleting paragraphs of markdown, so the hard-to-reverse leg
  of the three-part bar in `docs/decisions/README.md` fails. Same call `#7` and `#19` made.

## Tasks

- [x] 1. **The base-ref rule, stated once in `dw-git`.** Extend "Resolving the default branch"
      (`skills/dw-git/SKILL.md:23-25`) with the ref choice: `git fetch origin --quiet` first, then
      `git merge-base --is-ancestor origin/<d> <d>` → use the **local** ref (it contains origin), else
      use `origin/<d>` (local is behind). Name the diverged case — neither contains the other — and
      prefer the local ref there, since the branch was cut from it. Then **shrink**
      `skills/dw-land/SKILL.md:31-33` and `skills/dw-check/SKILL.md:19-20` to a pointer ("the base ref
      resolved the way `dw-git` does"), deleting the stale-local justification from both.
- [x] 2. **`dw-ship`'s fast path owes the same nudge.** One sentence at `skills/dw-ship/SKILL.md:37-38`,
      **inside the step, not the preamble** — the standing lesson is that a constraint written as an
      intro sentence does not act like one. A fast-path push to the default branch is the irreversible
      step too, so if the change skipped `dw-check`, say so before pushing. A nudge, not a gate: the
      closing pass is deliberately not a review pipeline.
- [x] 3. **Land-before-CI, resolved where CI is observable.** `skills/dw-land/SKILL.md:61-65` (the
      completion gate) gets the carve-out: a done-condition observable **only after push** is not an
      unmet Goal result at land time; it is verified at `dw-ship`'s stop, and the verdict says which
      task carries it. `skills/dw-ship/SKILL.md` gains the matching half in **both** paths — the PR path
      checks the PR's checks before the merge go (`:48-51`), the fast path watches the run its own push
      triggers (`:37-38`). Both halves or neither: half of this ships a new disagreement.
- [x] 4. **One `dw-solo` bump, then the full gate.** Read the current version off `main` at build time
      rather than trusting `0.4.14` — `.ai/work/setup-lives-in-tracked-agents-md` bumps `dw-solo` too,
      and the rebase-onto-squashed-`main` trap applies. `.claude-plugin/marketplace.json:13` and
      `plugins/dw-solo/.claude-plugin/plugin.json:3`, kept identical. No `description:` field changes,
      so `eval:routing` should be unmoved — run it anyway, since that is the check that catches an idf
      shift.

## Anchors

- `skills/dw-git/SKILL.md:23-25` — "**Resolving the default branch** is the one lookup every other
  skill borrows from here". Task 1's single home.
- `skills/dw-land/SKILL.md:30-33` — the `origin` preference plus the stale-local justification that
  argues the opposite case. `:61-65` — the completion gate from
  `.ai/archive/two-gates-against-scope-shedding`, which task 3 amends rather than replaces.
- `skills/dw-check/SKILL.md:19-20` — the same preference with no justification at all.
- `skills/dw-ship/SKILL.md:31-33` (landed-first precondition, the ordering item 2 is about), `:36-42`
  (path selection — the silent fast path), `:44-51` (PR path, where the nudge already exists at
  `:48-50` and is the model for task 2's wording).
- `.github/workflows/*.yaml` — all 7 trigger on `pull_request` + `push: branches: [main]`, four with
  `paths:` filters on top. The evidence that no green exists at land time.
- `.ai/archive/two-gates-against-scope-shedding/CHANGE.md` — the precedent for bundling on "same
  files, one bump, one gate run", and the source of the two items inherited from `skill-and-docs-drift`.

## Notes

- **Unexercised on merge, by design.** Every edit is prose in a skill body and nothing in this repo
  asserts skill body content; any `dw-ship` / `dw-land` / `dw-check` run during the work serves the
  cached `0.4.14` from `~/.claude/plugins/cache/`. Say that in the PR rather than implying coverage.
- **Task 1 verified against live refs, and the real case is worse than the recorded one.** In this
  worktree local `main` (0a92831) led `origin/main` (77179f6) by two shape commits;
  `git merge-base --is-ancestor origin/main main` exits 0, so the new rule picks the local ref and
  `main..HEAD` shows one commit. The old `origin/main..HEAD` shows three — including
  `c477a0a chore: shape block-env-heredoc-escape`, **another session's change doc**. So the defect is
  not only "your own unpushed shape commit"; on a repo where several changes are shaped on the default
  branch it pulls other people's work into your review diff.
- Task 1 also renamed the diff placeholder to `<base>` in both borrowers (`dw-land:30`,
  `dw-check:32`), since `<default-branch>` reads as the local ref and the whole point is that the ref
  is a separate choice from the name.
- **Task 3's carve-out is written generically, not against this repo's CI.** `dw-land` ships to any
  consumer repo, so the condition is "the project's workflows only run on a pull request or a push to
  the default branch", not a claim about `.github/workflows/` here. The bar is stated as _the evidence
  does not exist yet_, never _gathering it is inconvenient_ — otherwise the carve-out becomes the
  escape hatch the completion gate was built to close.
- **The gate is six commands, not seven.** `pnpm validate:evals` does not exist — added in 7eb684c,
  deleted in 1182f7f — and `CLAUDE.local.md` still lists it, so the documented pre-push gate dies on a
  missing script. Parked as `.ai/backlog/local-memory-s-pre-push-gate-names-a-deleted-script.md`
  rather than fixed here: a worktree cannot write that file. Everything that does exist ran green —
  `lint` 0 errors, `format`, `manifests` (`dw-solo=0.4.15` synced), `artifacts` (38 self-tests,
  Gotchas 12/12, backlog 5/8 before this entry), `docs`, `eval:routing` rank-1 67% · 20/30 · 21/21,
  unmoved as predicted since no `description:` changed.
- **`dw-solo` 0.4.15 was free, and it was worth checking.** The live `block-env-heredoc-escape` branch
  bumps `dw-solo-setup` to 0.1.13 and leaves `dw-solo` alone, so the two do not collide. Read both
  numbers off the sibling branch, not just `main` — `main` cannot show a bump that hasn't merged.
- **Two candidate terms for `dw-land` to weigh** against `CONTEXT.md`: **base ref** (task 1's
  local-vs-`origin` choice) and **pending on the push** (task 3's third state beside delivered and
  undelivered). Neither is certain to earn a glossary line; the second is the stronger candidate,
  since it names a verdict state the gate now has to distinguish.
- **Ordering** — `shape-time-parking-for-the-left-out-list` is shaped alongside this and touches
  different bodies (`dw-shape` / `dw-grill`), but both bump `dw-solo`. Whichever lands second re-reads
  the version from `main`, never from a change doc.
