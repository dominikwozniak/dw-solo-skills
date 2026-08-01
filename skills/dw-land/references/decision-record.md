# Decision records — the shape, and the bar

`docs/decisions/<NNNN>-<slug>.md`, numbered next in sequence (`0001-`, `0002-`, …). Tracked, durable,
and read by `dw-shape` and `dw-land` on every later change — which is exactly why the bar for writing
one is high.

## The bar

Write a record only if **all three** hold:

1. **Hard to reverse** — undoing it later means touching many places, migrating data, or breaking a
   published interface.
2. **Surprising** — a competent person reading the code would wonder why it was done this way, or
   would reasonably have done it differently.
3. **A real trade-off** — you gave something up. If one option was simply better, that isn't a
   decision, it's a fact.

If any of the three fails, don't write one. Most changes produce **zero** records, and that is the
correct number. A `docs/decisions/` folder full of "chose the obvious library" entries is worse than
an empty one, because it teaches you to stop reading it.

**Never rewrite a record.** When a decision is replaced, mark the old one `superseded` and link
forward to the new one — the reason a settled choice was reopened is often the most useful thing in
the folder.

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

What forced a choice here. Two or three sentences; the constraint, not the history.

## Decision

What was chosen, stated plainly in the present tense: "Sessions are stored in the database, not in a
signed cookie."

## Trade-off

What was given up, and the option that was rejected. Name it — "a signed cookie would have avoided
the extra read per request, but can't be revoked". This is the part your future self actually needs.

## Revisit when

The concrete trigger that should reopen this. A number, an event, a threshold — not "periodically".
```

## Glossary lines vs decision records

`CONTEXT.md` and `docs/decisions/` answer different questions, and mixing them makes both useless:

- **`CONTEXT.md`** — what a word _means_ in this project. Terms only, one line each, no
  implementation detail and no rationale. It exists so the code, the commits and the conversation all
  use the same word for the same thing.
- **`docs/decisions/`** — why the code is shaped this way. One file per decision.

A new term goes in `CONTEXT.md` even when no decision record is warranted — that's the common case.
