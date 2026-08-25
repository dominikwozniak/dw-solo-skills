---
decision: 0017
status: active
date: 2026-08-25
---

# 0017 — `reference` keeps all three of its senses

## Context

Three things in this repo answer to "reference": a `## References` line in a `CHANGE.md`, pointing at
something outside the change; a `skills/<name>/references/<file>.md`, which is progressive disclosure
for a skill; and a scaffolded project's own `references/` folder, where grateful-me-v2 keeps five
submodules. Making the first of them load-bearing — `dw-grill` plays pointers back, `dw-shape` writes
them down, `dw-land` promotes the stale ones — put all three in the same commits and forced the
question of whether one should be renamed.

## Decision

None of the three is renamed. The word carries all three senses, and `CONTEXT.md` disambiguates them
as separate glossary entries instead.

## Trade-off

A rename buys unambiguous vocabulary. It costs an edit to every skill using the word, both shipped
`*-README.md` twins, `validate-docs.sh` check 6, and the `references/` layer of any project already
scaffolded — for a catalog whose whole premise is one reader who knows which sense is meant. What was
given up is real, not nominal: a reader meeting `skills/dw-land/references/promote.md` and a change
doc's `## References` in one diff has to disambiguate from context, and the corpus offers no help.

## Revisit when

A second person reads this repo, or a fourth meaning of the word appears. Either one turns an
ambiguity that context resolves into a cost that context does not.
