# `.ai/` — tracked, one folder per change, no central index

Artifacts are real work documents, committed with the code — not scratch.

- **No shared index file.** A central registry becomes a merge-conflict magnet once tracked. Discovery
  is by directory name + per-file frontmatter instead: the resume step globs the work dirs and matches
  the current branch, so two branches never fight over one file.
- **One folder per change** (`.ai/work/<slug>/`) — parallel branches and worktrees don't collide.
- **One change is one goal**, and the count is one unless the pieces answer to **different** goals —
  asked at **shape time** rather than discovered mid-build. Not independent shippability, which is a
  good _task_'s property and splits work sharing a goal when borrowed one level up; `dw-shape` carries
  the test and the reason. A request carrying two unrelated goals is two folders, not one doc with two
  goals. Where two of them touch the same file, that's an **ordering** sentence in the `## Notes` of
  whichever lands second — never a dependency field, which would be the status column this lane exists
  to avoid.
- **The `branch: unclaimed` sentinel is load-bearing.** With no index, it is the only thing telling an
  unopened change from an open one, so anything touching `.ai/work/` must respect it. Who flips it and
  when belongs to `dw-start` and `dw-next`.
- **The promotion commit lands on the feature branch**, so a squash-merge carries it to the default
  branch — as it does the change folder's move to `.ai/archive/<slug>/`, which is the same commit. What
  gets promoted where is `CONTEXT.md`'s **Promotion** entry.
- **A work doc can come back from the dead, and the archive twin is how you tell.** Where the shaping
  commit was still local-only when the PR squashed, the rebase replays it on top of the squash and
  re-creates `.ai/work/<slug>/CHANGE.md` at its shaping-time state, for a change that has landed. Both
  halves of the pair then exist, and the `work/` one is the stale half — the check is whether
  `.ai/archive/<slug>/` is already there, never the date or the `status:`. `dw-ship` sweeps it as its
  last step; the procedure is there.
