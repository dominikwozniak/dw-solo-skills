# `.ai/` — tracked, one folder per change, no central index

Artifacts are real work documents, committed with the code — not scratch.

- **No shared index file.** A central registry becomes a merge-conflict magnet once tracked. Discovery
  is by directory name + per-file frontmatter instead: the resume step globs the work dirs and matches
  the current branch, so two branches never fight over one file.
- **One folder per change** (`.ai/work/<slug>/`) — parallel branches and worktrees don't collide.
- **One change is one independently shippable scope** — "could each piece land on its own and leave
  the repo green?", asked at **shape time** rather than discovered mid-build. A request carrying two
  such scopes is two folders, not one doc with two goals. Where two of them touch the same file,
  that's an **ordering** sentence in the `## Notes` of whichever lands second — never a dependency
  field, which would be the status column this lane exists to avoid.
- **The `branch: unclaimed` sentinel is load-bearing.** With no index, it is the only thing telling an
  unopened change from an open one, so anything touching `.ai/work/` must respect it. Who flips it and
  when belongs to `dw-start` and `dw-next`.
- **The promotion commit lands on the feature branch**, so a squash-merge carries it to the default
  branch — as it does the change folder's move to `.ai/archive/<slug>/`, which is the same commit. What
  gets promoted where is `CONTEXT.md`'s **Promotion** entry.
