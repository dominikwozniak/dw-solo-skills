# `.ai/` — tracked, one folder per change, no central index

Artifacts are real work documents, committed with the code — not scratch.

- **No shared index file.** A central registry becomes a merge-conflict magnet once tracked. Discovery
  is by directory name + per-file frontmatter instead: the resume step globs the work dirs and matches
  the current branch, so two branches never fight over one file.
- **One folder per change** (`.ai/work/<date>-<slug>/`) — parallel branches and worktrees don't collide.
- **One change is one goal**, and the count is one unless the pieces answer to **different** goals —
  asked at **shape time** rather than discovered mid-build. Not independent shippability, which is a
  good _task_'s property and splits work sharing a goal when borrowed one level up; `dw-shape` carries
  the test and the reason. A request carrying two unrelated goals is two folders, not one doc with two
  goals. Where two of them touch the same file, that's an **ordering** sentence in the `## Notes` of
  whichever lands second — never a dependency field, which would be the status column this lane exists
  to avoid.
- **A change doc exists only on its feature branch** ([`0019`](../decisions/0019-a-change-doc-exists-only-on-its-feature-branch.md)).
  The unopened queue is `.ai/backlog/`, one entry per idea; `dw-shape` on the default branch writes
  there or switches to a new branch first, and `dw-start` opens a worktree whose `dw-shape` expands
  the entry. There is no `branch: unclaimed` sentinel and no claim step any more — the branch field
  is written once, verbatim, at shape time.
- **The promotion commit lands on the feature branch**, so a squash-merge carries it to the default
  branch — as it does the change folder's move to `.ai/archive/<date>-<slug>/`, which is the same commit. What
  gets promoted where is `CONTEXT.md`'s **Promotion** entry.
- **Residue after a squash: the archive twin is how you tell.** A local-only commit on the default
  branch that created a lane entry a landed branch consumed is replayed by the post-squash rebase,
  re-creating the entry for a change that already landed. The check is whether the **bare slug** is
  already in `.ai/archive/` with `landed:` or `rejected:` — never the date prefix, which the lanes
  stamp separately. `dw-ship`'s last step looks once; with shaping confined to feature branches the
  answer is almost always "nothing".

## Gotchas

- **`templates/*-README.md` and the live `.ai/*/README.md` are edited in parallel by hand, and nothing
  pins them.** They are not byte-identical twins: each live one is the template plus a paragraph only
  this repo needs (the cap, `rejected` covers cancelled), so `cmp` can't gate them and a template-only
  edit leaves the live file — the one a reader of the folder actually opens, and the one `dw-land` is
  pointed at for the backlog's two bars — describing the old behaviour. Landed that way twice in one
  change here. Edit both halves in the same commit, then `diff` them and confirm the only difference is
  the repo-specific paragraph.

- **What one file says about another's contents goes stale silently.** Adding a sixth promote target
  left the count wrong in `dw-land`'s body, in its `## References` row and in both `*-README.md`
  twins — and those twins legitimately counted one fewer, excluding the archive move that the
  since-retired `promote.md` included, so the two numbers differed on purpose. Separately, shifting lines inside a `SKILL.md` broke
  three `## Anchors` ranges in an _unclaimed sibling_ `CHANGE.md` — which no promote target reads,
  since the reference target reads the landing change's own `## References`. Before committing a
  structural edit to a skill, grep the count words and `git grep` the file's path across `.ai/work/`.

- **A script that splits a `CHANGE.md` at its first `## Notes` truncates the file**, because a task can
  quote that heading inline while describing where a finding goes. It ate a task and the whole
  `## Anchors` section here, and two commits shipped short before anyone noticed — the file still
  parsed, still rendered, and the missing task was one the change had already done. Anchor such a split
  to the heading at line start (`^## Notes`), or rewrite the section in place instead of rebuilding the
  file around it.
