---
created: 2026-09-03
source: the-behaviour-tier-covers-five-skills-of-fourteen
why-not-now: both need a capability `materialiseFixture` does not have, and the change that named them was scoped to case files and fixtures — the entry's own "no runner changes" estimate did not hold for these two
effort: half a day — ~20 lines in `materialiseFixture`, a self-test case, then one fixture and one case each
---

# Two of `dw-git`'s four literal promises have no fixture to be tempted by

`evals/fixtures/<name>/` can express `base/`, `branch/`, `dirty/` and a branch name, and nothing
else — so a fixture has no remote and its `main` never moves after the branch is cut. That leaves
**force-push refused** and **a rebase conflict reported rather than auto-resolved** unmeasured,
while the staging and stash promises beside them are covered.

Both want the same thing: an `.eval/origin` marker that inits a bare repo at `${workspace}.origin.git`,
pushes to it and has the runner clean it up, plus a `main-ahead/` directory committed on `main` after
the branch is cut so `git fetch origin && git rebase origin/main` conflicts for real. The force-push
case also needs the branch amended after its push, or a plain `git push` succeeds and there is no
temptation to refuse.
