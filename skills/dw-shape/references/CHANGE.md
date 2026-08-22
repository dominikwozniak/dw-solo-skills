---
change: slug-of-this-change # the bare slug, no date — this is the identity across the lanes
branch: FILL — `unclaimed` when shaping on the default branch, else `git rev-parse --abbrev-ref HEAD` verbatim (never HEAD, never this placeholder)
created: YYYY-MM-DD
status: shaping # shaping | building | landed
---

# Change — [title, one line: what changes]

## Goal

~5 lines at most: what changes, and how you'd know it worked. Observable, not aspirational — "the
settings screen persists the toggle across a restart", not "improve settings".

## Decisions

Only decisions actually taken, one line each — the call, then why. Delete the section if none were
needed; an empty heading is noise.

- [decision] — [why]

## Tasks

Thin vertical slices, each independently committable and leaving the project green. Order is a hint,
not a gate. `dw-next` ticks these — and where it finds one that stopped being necessary it leaves the
box unticked and appends a reason, which every later invocation reads as not remaining. That marker is
never available to a task the `## Goal` needs; write nothing here at shape time.

- [ ] 1. [slice]
- [ ] 2. [slice]
- [ ] 3. [slice] **skip:** [why this one turned out unnecessary — `dw-next` writes this, never you]

## Anchors

Real referents this change follows or touches, each confirmed with Read or grep. Delete for a small
change.

- `path/to/file.ext:42` — [what it is and why it matters here]

## Notes

Appended while building — surprises, dead ends, things the next session needs, **one line each**; the
diff holds the detail. `dw-land` reads this when deciding what is durable enough to promote to
`docs/decisions/`, `CONTEXT.md`, or `## Gotchas`.
