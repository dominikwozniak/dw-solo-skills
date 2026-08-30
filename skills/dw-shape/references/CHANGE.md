---
change: slug-of-this-change # the bare slug, no date — the identity across the lanes
branch: FILL — `git rev-parse --abbrev-ref HEAD` verbatim; a CHANGE.md exists only on its feature branch
created: YYYY-MM-DD
status: shaping # shaping | building | landed
---

# Change — [title, one line: what changes]

## Goal

~5 lines at most: what changes, and how you'd know it worked. Observable, not aspirational — "the
settings screen persists the toggle across a restart", not "improve settings".

## Decisions

Only decisions actually taken, one line each — the call, then why. Delete the section if none were
needed.

- [decision] — [why]

## Tasks

<!-- Convention: `- [ ]` pending, `- [x]` done — `dw-next` flips the box in the task's own commit.
A task that stopped being necessary keeps its box and gains `**skip:** <reason>`; every later
invocation reads that as not remaining. Never rename a task title. -->

- [ ] 1. [slice]
- [ ] 2. [slice]

## Anchors

Real referents this change follows or touches, each confirmed with Read or grep. Delete for a
small change.

- `path/to/file.ext:42` — [what it is and why it matters here]

## References

Resources the conversation pointed at — a URL, a doc, a sibling repo — one line each. `dw-next`
reads these before building. Delete the section when nothing was pointed at.

- `path-or-url` — [why it matters to this change]

## Notes

Appended while building — surprises, dead ends, things the next session needs, **one line each**;
the diff holds the detail. `dw-land` reads this when deciding what is durable enough to promote.
