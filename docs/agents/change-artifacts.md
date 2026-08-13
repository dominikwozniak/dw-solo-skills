# `.ai/` — tracked, one folder per change, no central index

Artifacts are real work documents, committed with the code — not scratch.

- **No shared index file.** A central registry becomes a merge-conflict magnet once tracked.
  Discovery is by directory name + per-file frontmatter, so two branches never fight over one file.
- **One folder per change** (`.ai/work/<slug>/`) — parallel branches and worktrees don't collide.
- **One change is one independently shippable scope** — "could each piece land on its own and leave
  the repo green?", asked at **shape time** rather than discovered mid-build. A request carrying two
  such scopes is two folders, not one doc with two goals. Where two of them touch the same file,
  that's an **ordering** sentence in the `## Notes` of whichever lands second — never a dependency
  field, which would be the status column this lane exists to avoid.
- **Branch-matched resume.** A change doc records its branch; the resume step globs the work dirs,
  matches the current branch, and reports the first unticked box.
- **Branch reads use `git rev-parse --abbrev-ref HEAD`**, never `git branch --show-current`, which
  returns an empty string on a detached HEAD and silently turns a branch match into a no-match.

## The claim protocol

A change shaped on the default branch records the literal sentinel `branch: unclaimed`; `dw-start`
claims right after creating the worktree, and `dw-next` offers a claim when its branch-grep misses
(stripping the `worktree-` prefix a `claude -w` session's branch carries). A claim is one frontmatter
edit — the sentinel flips to the verbatim `git rev-parse --abbrev-ref HEAD` — committed
**immediately**, because `.ai/` is tracked and an uncommitted claim is invisible to every other
session. Anything touching `.ai/work/` must respect the sentinel.

## Where the durable residue goes

The closing pass promotes what outlives the change and archives the rest: decisions to
`docs/decisions/`, terms to `CONTEXT.md`, traps to the `## Gotchas` of the matching
`docs/agents/<topic>.md` (never the root — see [`README.md`](README.md)), follow-ups to
`.ai/backlog/`, and the change folder itself to `.ai/archive/<slug>/`. That promotion commit lands
**on the feature branch**, so a squash-merge carries it to the default branch.
