---
decision: 0018
status: active
date: 2026-08-25
supersedes: 0004
---

# 0018 — An archive entry is a receipt, and a backlog entry carries its own finding

## Context

`0004` established the archive because squash merges destroy a change doc's worked state, and paid for
it by having backlog entries point at the archive for their findings rather than inline them. Both
halves aged badly. Its own `## Revisit when` named ~30 changes as the trigger; at 46 entries averaging
134 lines, an entry had become a second copy of everything the close had just promoted to
`docs/decisions/`, `CONTEXT.md` and the gotchas. The pointer half made that copy load-bearing: a queued
follow-up could not be read without opening a folder nothing maintains.

## Decision

`dw-land` trims the doc as it archives it, to frontmatter, the H1, the task list as `dw-next` left it,
and only the `## Notes` lines whose findings no durable target took — deleting `## Goal`,
`## Decisions`, `## Anchors` and `## References`, and keeping `## Why rejected` where there is one. A
backlog entry writes its finding inline and never points here. The archive stays what `0004` made it —
history, not a promotion target — but it is now a receipt that a change landed and what it did, not a
record of how the thinking went.

## Trade-off

The reasoning is given up: how a change was framed, what it decided along the way, and where it was
anchored survive only in the diff and the commit messages, which are the places nobody reads by slug.
Keeping them was the safer option and is what `0004` chose — but an entry nothing reads costs
attention on every listing, and the sections deleted here are precisely the ones the promotion step
has already harvested. Notes are the deliberate exception: what found no durable home is the only
residue worth carrying, so it stays.

## Revisit when

A session is observed needing a deleted section — reaching for an archived `## Decisions` or
`## Anchors` and finding it gone — or the trimmed mean climbs back over ~40 lines, which would mean
`## Tasks` and `## Notes` have grown into what the four deleted sections used to be.
