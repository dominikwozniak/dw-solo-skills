# `.ai/archive/` — finished changes, kept as history

Change docs moved here by `dw-land` at close: `status: landed`, plus `landed:` date and `pr:` in
the frontmatter.

A turned-down idea ends here too — `dw-land reject` writes `status: rejected` with a `rejected:`
date, the closed-unmerged `pr:` if there was one, and a `## Why rejected` section, which is the only
part of such a doc worth keeping. An idea rejected before it was ever shaped is written straight
here, having never passed through `.ai/work/`.

**`rejected` covers cancelled**, and there is deliberately no third status: work abandoned half-built
archives the same way an idea turned down does. What killed it differs, which is what
`## Why rejected` is for; nothing reads the frontmatter to tell the two apart.

**History, not guidance** — nothing browses this folder for advice; the durable layer lives in
`docs/decisions/`, `CONTEXT.md` and wherever the repo keeps its `## Gotchas`. It is reached by **exact slug**,
never read in general: `dw-shape` treats a slug already here as taken, and when that doc is
`status: rejected` it reads the `## Why rejected` and stops, so the same idea is not shaped twice.
Backlog entries may point here for a change's findings (its `## Notes`).
