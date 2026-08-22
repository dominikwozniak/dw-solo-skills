---
change: backlog-audit-script
branch: backlog-audit-script # deleted; never shaped, built from a plan file
created: 2026-08-07
status: rejected # shaping | building | landed | rejected
rejected: 2026-08-08
pr: "#10" # closed, not merged
---

# Tooling for backlog hygiene — a staleness report over `.ai/backlog/`

Pruning the backlog from 23 entries to 7 took four passes in one session. The question it raised —
should the mechanical part be a script? — was answered yes, built, and then answered no by review.

## What was built

`scripts/runtime/backlog-audit.sh` (194 lines) plus a 115-line self-test, a `plugins/dw-solo/scripts/`
symlink, a `RUNTIME_SCRIPTS` entry, a `dw-land` threshold nudge, six lines into both backlog READMEs
and two version bumps — 344 insertions. Per entry it reported the adding commit, age against the
month bar, dead citations, and which other branch already touched what the entry described.

## Why rejected

The one thing it existed for was broken. Its cross-branch check compared an entry's cited paths
against the branch diff by **exact string**, while entries cite in shorthand — `doctor.sh`,
`dw-land/SKILL.md` — which only its separate existence check knew how to resolve. 28 of ~30 citations
across all 7 live entries were shorthand, so the headline feature worked on **1 entry of 7**, and its
single reported hit came from the one full path in the set. It also enumerated only `refs/heads`,
missing the 7 branches that exist only on origin — the very blind spot it was written to close.

A three-line loop reports strictly more, because the full file list per branch surfaces a branch that
_adds_ backlog entries, which a per-entry loop cannot see at all:

```bash
git for-each-ref --format='%(refname:short)' refs/heads refs/remotes |
  while read -r b; do echo "== $b"; git diff --name-only "main...$b"; done
```

Secondary findings: `exists_path` piped `git ls-files` into `grep -q` under `pipefail`, so a SIGPIPE
on early match could call a live citation dead; the comment justifying the avoidance of
`--porcelain` rested on a false premise about `rtk`, which never sees git calls made _inside_ a
script; one of ten test cases asserted a regex whose left branch always matched; and the
cross-branch check had no test at all. Five bugs during development, five more in review, for a
report that runs about four times a year.

It should never have been a canon script either: `AGENTS.md:31-32` says a script used by **one**
skill belongs in `skills/<name>/scripts/`, and only `dw-land` invoked it.

The doc lines died with it. Drop criteria had landed in a README that `dw-init` copies once at
scaffold and no skill reads again, then duplicated into the shipped template as generic advice drawn
from a single prune. The `dw-land` nudge grew the longest step in a hot-loop skill to carry a
quarterly concern, gated on a threshold unreachable at 7 entries.

## What would justify revisiting

A backlog large enough that reading it end to end stops being practical — past ~20 entries with
several passes a year rather than one. Any rebuild must resolve citations before matching them
against a branch diff, not after, and must sweep `refs/remotes` as well as `refs/heads`.

## Residue

One follow-up parked: `.ai/backlog/start-branch-check-ignores-remote.md` — the local-only ref reads
in `dw-start`, `worktree.sh` and `dw-git` that this work turned up on the way past.
