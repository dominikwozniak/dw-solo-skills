# `.ai/backlog/` — one file per follow-up

Ideas not being worked on now. `dw-land` parks them here; `dw-shape` takes one as the seed of a new
change (`git mv` → `.ai/work/<slug>/CHANGE.md`) — the slug travels backlog → work → archive.

Shape of an entry, `<slug>.md`: frontmatter `created: YYYY-MM-DD` (optional `source:` naming the
change that parked it), an H1 saying what-and-why in one line, at most ~3 lines of context.
Findings go by pointer to `.ai/archive/<slug>` — never inlined. No status, no priority, and
nothing validates these files, deliberately.

One exception to the three lines: an entry may **bundle** several small fixes as a bullet list when
they ship together — same version bump, same gate run, one PR. Say in the lead sentence what makes
them one change, and keep each bullet to what a session needs to find the code.

**Bundle by what a change must bump and re-verify**, never by topic. Topic-grouping produces bundles
whose halves cannot ship in one PR, which is worse than leaving them apart.

**When to drop an entry**, since nothing else prunes this directory: no work in this repo can close
it; it names its own decisive counter-argument; it is already covered — check _every_ branch and
worktree, not just the default one; or it fails the month bar. Read the entry against the code it
cites before deciding, and prefer merging a near-duplicate to keeping both.

The bar: if you would not pick it up within a month, don't write it.
