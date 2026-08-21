---
decision: 0015
status: active # active | superseded
date: 2026-08-21
---

# 0015 — the shipped agent-docs checker gates size, never shape

## Context

`check-agents-docs.mjs` ships verbatim into consumer repos and its header declared it checks nothing
under `docs/decisions/`, on the grounds that a validator there turns an editorial layer into a build
gate. `eager-doc-size-budget` was rejected on a neighbouring point: a per-file ceiling the flagship
would not set is a mechanism with no user. Meanwhile a consumer repo's routed layer grew at every
close, one justified paragraph at a time, and one commit there exists only to cut prose a close had
added.

## Decision

The checker gates **size** over the layers `AGENTS.md` routes to, and never shape. Records get a
`Ceiling:` declared in the folder's README; `docs/agents/` gets a word baseline that may shrink freely
and grows only through a commit that re-records it. Both are opt-in — a missing declaration or
baseline is neither checked nor mentioned — because records and topic files predate the passes in
every repo they land in.

A closed form gets a number and an open one gets a ratchet: a record has five sections, so a ceiling
is a fact about it, while a topic file is as long as its subject, so any number would be a guess.

## Trade-off

Two things were given up. **For records**, the principle that the durable layer is never a build gate:
the losing option was prose on trust, which is what the promotion step already used and what a tired
session skips. Shape, numbering and supersession stay editorial, so the concession is bounded to the
one failure a reader cannot repair by reading more carefully.

**For topic files**, a per-file cap: growth stays legal and costs a visible re-record instead. That
buys no protection against a corpus that grows deliberately every time — it only removes the silence.

The flagship declares the ceiling and leaves the ratchet unset, so the ratchet ships here with no
local user. That is the charge that killed `eager-doc-size-budget`, accepted on purpose this time:
`docs/agents/*.md` are unbudgeted in this repo by an earlier decision, and a repo where a human reads
every diff is not the repo the ratchet is for.

## Revisit when

A consumer repo re-records the topic baseline in three consecutive closes without cutting anything —
at which point the ratchet is a receipt for growth rather than a brake on it, and the honest answer is
either a cap or nothing.
