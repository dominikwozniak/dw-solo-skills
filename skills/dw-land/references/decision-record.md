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

## Superseding

Never rewrite or delete a record. The replacement gets the next number carrying `supersedes:`; the
old one is edited in exactly two fields — `status: superseded`, `superseded-by:` — in the same
pass. Glossary lines are different: `CONTEXT.md` says what a word means (terms only, no rationale);
`docs/decisions/` says why the code is shaped this way.
