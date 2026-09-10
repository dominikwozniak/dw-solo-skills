---
change: slug-of-this-change # the bare slug, no date — the identity across the lanes
branch: FILL — `git rev-parse --abbrev-ref HEAD` verbatim; a CHANGE.md exists only on its feature branch
created: YYYY-MM-DD
status: shaping # shaping | building | landed
---

# Change — [title, one line: what changes]

## Goal

What changes, and how you'd know it worked — one line per observable result, no line for anything
else. Observable, not aspirational — "the settings screen persists the toggle across a restart", not
"improve settings".

## Decisions

Decisions actually taken, plus the ones this change inherits or proposes — the call, then why, in
the lines the reasoning needs and none for template completeness. Delete the section if none were
needed. Four markers, and `dw-land` reads the last one:

- `[decision] — [why]` — taken here, settled.
- `[decision] (assumed) — [the default, and why]` — taken from a default rather than an answer (what
  `dw-grill` assumed or deferred). `dw-next` builds on it and asks only when the build proves it wrong.
- `[decision] (inherited: <NNNN>) — [the record's own rule, verbatim]` — a `docs/decisions/` record
  already binds a file this change touches. Never reworded: the norm a builder acts on is the
  record's own words.
- `[decision] (nominated) — [why it may deserve a record]` — a call `dw-next` judges worth a decision
  record but does not write. `dw-land` is the gate, and it rewrites this line in place: gone, where
  the call became a record; `(rejected: <leg>)` where a leg failed; `(unsettled: <what would settle
it>)` where none failed but the change did not show enough. The last two survive into the archive
  receipt — nothing else in this section does.

## Out of scope

What this change deliberately does not do, one line each with why — the left-out list's dropped
items, and the neighbouring work a reader would otherwise expect here. Delete only for a small change.

- [what stays out] — [why: a separate goal, a later change, not worth its cost]

## Tasks

<!-- Convention: `- [ ]` pending, `- [x]` done — `dw-next` flips the box in the task's own commit.
A box is ticked only once the proof it names exists: the check ran, not the code got written.
A task that stopped being necessary keeps its box and gains `**skip:** <reason>`; every later
invocation reads that as not remaining. Never rename a task title. -->

Every task carries the check that would prove it, one phrase on the line — a command, a file, a log
line, a run. A task no check can be named for is badly cut, not badly worded; step 3 recuts it.

- [ ] 1. [slice] — proof: [what checks it]
- [ ] 2. [slice] — proof: [what checks it]

## Anchors

Real referents this change follows or touches, each confirmed with Read or grep. Delete for a
small change.

- `path/to/file.ext:42` — [what it is and why it matters here]

## References

Resources the conversation pointed at — a URL, a doc, a sibling repo — one line each, and a sibling
file beside this doc where a finding outgrew a line: say what it holds and which task leans on it.
`dw-next` reads these before building. Delete the section when nothing was pointed at.

- `path-or-url` — [why it matters to this change]
- `research.md` — [what it holds, and the task that needs it]

## Notes

Appended while building — surprises, dead ends, things the next session needs, **one line each**;
the diff holds the detail. `dw-land` reads this when deciding what is durable enough to promote.
