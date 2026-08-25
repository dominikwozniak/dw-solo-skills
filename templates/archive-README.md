# `.ai/archive/` — finished changes, kept as history

Change docs moved here by `dw-land` at close: `status: landed`, plus `landed:` date and `pr:` in
the frontmatter. The folder is `<landed date>-<slug>`, re-stamped on the move — the work lane carried
the day the change was shaped, this one carries the day it landed, so the listing is ship order.

**An entry is a receipt, not a second copy of the change.** It keeps the frontmatter, the one-line
title, the task list as it was left — ticks and skip reasons — and any notes that found no durable
home. `dw-land` deletes `## Goal`, `## Decisions`, `## Anchors` and `## References` on the way in,
and drops every note whose finding it has just promoted: those sections steered work the diff now
holds, and a finding worth keeping lives in the durable layer instead of in a second copy here.

A turned-down idea ends here too — `dw-land reject` writes `status: rejected` with a `rejected:`
date, which is that folder's prefix, the closed-unmerged `pr:` if there was one, and a `## Why rejected` section, which is the only
part of such a doc worth keeping. An idea rejected before it was ever shaped is written straight
here, having never passed through `.ai/work/`.

**History, not guidance** — nothing browses this folder for advice; the durable layer lives in
`docs/decisions/`, `CONTEXT.md` and wherever the repo keeps its `## Gotchas`. It is reached by the **bare slug** —
`slugify.sh undate` a name, never compare the folder — and never read in general: `dw-shape` treats a
slug already here as taken, and when that doc is
`status: rejected` it reads the `## Why rejected` and stops, so the same idea is not shaped twice.
