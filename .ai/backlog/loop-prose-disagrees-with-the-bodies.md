---
created: 2026-08-11
source: skill-and-docs-drift, shape-time-parking-for-the-left-out-list
---

# Four places where the loop's prose promises something no body does

Bundled because all three are text in `skills/`, one `dw-solo` bump, one PR. What is left of
`.ai/work/skill-and-docs-drift/` after `de-ratchet-the-solo-lane` resolved its other two items (the
decision-record bar now reads "all three" in `dw-land`, and the `SKILL-ANATOMY.md` citation went with
the file).

- **`dw-ship` nudges toward a review only on the PR path.** The fast path reaches `git push` — the
  irreversible step — never mentioning that `dw-check` was skipped. Fix in `dw-ship`; the closing pass
  is deliberately not a review pipeline.
- **`dw-ship` orders `dw-land` before shipping, which a task whose done-condition is "CI passes"
  cannot satisfy.** The workflows trigger only on `pull_request` or a push to `main`, so there is no
  green to see yet at land time. Decide it as prose in `dw-ship` / `dw-land`, or add a
  `workflow_dispatch`.
- **"Prefer `origin/<default-branch>`" is wrong whenever the local default branch is _ahead_.**
  `dw-land` and `dw-check` both say to prefer the remote ref, and both justify it with the opposite
  case — a _stale local_ branch widening the merge-base. When local is ahead instead, which is the
  normal state while a `chore: shape …` commit sits unpushed, preferring origin pulls that commit into
  the diff under review. Seen in `de-ratchet-the-solo-lane`, where local `main` led `origin/main` by
  exactly that commit. The rule wants to be "whichever of the two is further ahead", stated once.
- **`dw-grill` promises `dw-shape` files the "deliberately left out" list into `.ai/backlog/`, and
  `dw-shape` has no such step** — it only reads the backlog and consumes an entry. The false promise
  was deleted in `de-ratchet-the-solo-lane`; what stays queued is the feature behind it. The pile
  reaches disk only at land time, and moving it to shape time is the deepest available fix for scope
  shedding — the counterpart to the two land-side gates in
  `.ai/archive/two-gates-against-scope-shedding`.

Sources: `.ai/archive/shape-splits-changes`, `.ai/archive/pnpm-v11-migration`.
