---
change: slug-of-this-change
branch: FILL — `unclaimed` when shaping on the default branch, else `git rev-parse --abbrev-ref HEAD` verbatim (never HEAD, never this placeholder)
created: YYYY-MM-DD
status: shaping # shaping | building | landed
---

# Change — [title, one line: what changes]

## Goal

One short paragraph: what changes, and how you'd know it worked. Observable, not aspirational —
"the settings screen persists the toggle across a restart", not "improve settings".

## Decisions

Only decisions actually taken, with the one-line reason. Delete the section if none were needed —
an empty heading is noise.

- [decision] — [why]

## Tasks

Thin vertical slices, each independently committable and leaving the project green. Order is a hint,
not a gate. `dw-next` ticks these.

- [ ] 1. [slice]
- [ ] 2. [slice]

## Anchors

Real referents this change follows or touches, each confirmed with Read or grep. Delete for a small
change.

- `path/to/file.ext:42` — [what it is and why it matters here]

## Notes

Appended while building — surprises, dead ends, things the next session needs. `dw-land` reads this
when deciding what is durable enough to promote to `docs/decisions/`, `CONTEXT.md`, or `## Gotchas`.
