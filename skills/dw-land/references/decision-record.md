# Decision records — the bar and the shape

`docs/decisions/<NNNN>-<slug>.md`, numbered next from the highest on disk; numbers are never
reused or renumbered.

## The bar — all three must hold, named out loud per candidate

1. **Hard to reverse** — undoing it means touching many places, migrating data, or breaking a
   published interface.
2. **Surprising** — a competent reader would wonder why, or would reasonably have done it
   differently.
3. **A real trade-off** — something was given up; an option that was simply better is a fact, not
   a decision.

Most changes produce **zero** records, and that is the correct number.

## The shape

```markdown
---
decision: <NNNN>
status: active # active | superseded
date: <YYYY-MM-DD>
rule: <one imperative line, ≤100 chars — what a reader is bound to>
touches:
  - <path or glob this record governs>
supersedes: <NNNN or omit>
superseded-by: <NNNN or omit>
---

# <NNNN> — <the decision, as a statement not a question>

## Context

What forced a choice. Two or three sentences — the constraint, not the history.

## Decision

What was chosen, stated plainly in the present tense.

## Trade-off

What was given up, and the rejected option, named.

## Revisit when

The concrete trigger that reopens this — a number, an event, a threshold; never "periodically".
```

## `rule:` and `touches:` — how the record is found again

A folder of records is only worth writing if the two or three governing the file in hand can be
reached without reading the rest. These two fields are that path, and they do different jobs:

- **`touches:` is the filter** — the paths or globs this record governs, so a reader about to edit
  one of them greps frontmatter and finds this record. Write what the decision _binds_, not every
  file the change happened to touch.
- **`rule:` is the norm** — one imperative line saying what a reader is bound to, so a hit can be
  acted on or dismissed without opening the file. It is not a summary of the record: the slug is
  already the title and `## Decision` is already the paragraph. If the line reads like a description
  rather than an instruction, it is the wrong line.

Neither is machine-checked, and that is deliberate — the shipped checker gates size over this folder
and never shape. A `touches:` path that leaves the tree is reported by a doc-layer audit, not by a
gate. Both fields are expected of a record written from now on; a record that predates them is found
by its slug and is never rewritten to add them.

## Superseding

Never rewrite or delete a record. The replacement gets the next number carrying `supersedes:`; the
old one is edited in exactly two fields — `status: superseded`, `superseded-by:` — in the same
pass. Glossary lines are different: `CONTEXT.md` says what a word means (terms only, no rationale);
`docs/decisions/` says why the code is shaped this way.
