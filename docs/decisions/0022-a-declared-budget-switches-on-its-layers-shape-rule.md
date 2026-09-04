---
decision: 0022
status: active # active | superseded
date: 2026-09-04
supersedes: 0015
---

# 0022 — a declared budget switches on its layer's one shape rule, and the doctor names a gate that is off

## Context

`0015` decided the shipped checker gates size and never shape, both gates opt-in and silent when
off, because a gate that lights an existing folder red on install day is one you switch off rather
than meet. The consumer repo then grew `docs/agents/` to 144 KB in 26 days, a hand cut took 8 KB
off, and the corpus regrew 26 KB in four days. Two of the shapes doing it were mechanically
decidable — a gotcha stamped with a date, a glossary term run out to a paragraph — and both were
written by `dw-land`'s closing sweep at this catalog's instruction. The repo also ran a forked
checker with no baseline and never learned it, because the one thing that could have said so was
built to be quiet.

## Decision

Declaring a layer's budget opts that layer into **both** its size cap and its one shape rule:
`Topic budget:` in `docs/agents/README.md` bans a bullet whose bold text opens with an ISO date,
`Term budget:` in `CONTEXT.md` holds a term to one bullet of two lines. A repo that declares nothing
keeps `0015` whole — neither size nor shape is checked, and neither is mentioned. The corpus ratchet
becomes the **opt-out** gate: `dw-init` seeds it, because a ratchet records what a corpus already is
and so is green the day it exists.

`dw-doctor` reports every one of these gates that is off, with the line or command that turns it on.
That does not reopen `0015`: `0015` constrains what the **checker** may say, and the doctor is a
read-only diagnostic that gates nothing.

## Trade-off

Shape is no longer purely editorial. The bounded version — one rule per layer, only where a repo
named a size — was chosen over both a hard shape contract and prose on trust; trust is what the
promotion step already used, and it is what filled the corpus.

The two caps ship with no local user, since this repo declares neither and keeps
`docs/agents/*.md` unbudgeted per `0008`. That is the charge that killed `eager-doc-size-budget`,
accepted a second time and offset: the ratchet `0015` shipped userless now has one here.

`0008`'s revisit condition is met — a consumer's `tooling.md` reached 371 lines, past skimming — and
it is cited as the evidence for a per-file cap rather than reopened, because the cap is scoped per
file, which is exactly what `0008` said it would take.

## Revisit when

A repo declares a topic budget and then raises the number twice without cutting anything, or the
dated-bullet ban is the reason a real trap goes unwritten. Either says the rule is being paid around
rather than met.
