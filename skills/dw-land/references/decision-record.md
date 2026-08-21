# Decision records — the bar, the shape, and how one is replaced

`docs/decisions/<NNNN>-<slug>.md`, numbered next in sequence (`0001-`, `0002-`, …). Tracked, durable,
and read by `dw-shape` and `dw-land` on every later change — which is why the bar is high.

## The bar

Write a record only if **all three** hold:

1. **Hard to reverse** — undoing it later means touching many places, migrating data, or breaking a
   published interface.
2. **Surprising** — a competent person reading the code would wonder why it was done this way, or
   would reasonably have done it differently.
3. **A real trade-off** — you gave something up. If one option was simply better, that isn't a
   decision, it's a fact.

If any of the three fails, don't write one. Most changes produce **zero** records, and that is the
correct number: a folder full of "chose the obvious library" entries teaches you to stop reading it.

**Name the three out loud, per candidate** — in the verdict, one line: what makes it hard to reverse,
what is surprising, what was given up. A test applied in silence is a test skipped, and that is how a
fact gets written up as a decision, or one decision as two records.

## The shape

It fits the ceiling the folder's README declares, where it declares one, and `agents:check` holds you
to it. These five sections are the record; how you got here belongs in the change's archive entry.

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

## Superseding

**Never rewrite a record**, and never delete one. A replaced decision gets a new record at the next
number; the old one is edited in exactly two fields, `status: superseded` and `superseded-by: <NNNN>`,
and the new one carries `supersedes: <NNNN>` back. Numbers are never reused or renumbered — the old
number is what every pointer is made of.

**`dw-land` flips the old record** in the same pass that writes the new one. A record contradicting an
older one silently leaves two live answers to one question. Superseded records are **not** skipped on
a read: why a settled choice was reopened is often the most useful thing in the folder.

## Glossary lines vs decision records

`CONTEXT.md` says what a word _means_ here — terms only, one line each, no rationale, so code, commits
and conversation use one word for one thing. `docs/decisions/` says why the code is shaped this way.
Mixing them makes both useless, and a new term goes in `CONTEXT.md` even when no record is
warranted — the common case.
