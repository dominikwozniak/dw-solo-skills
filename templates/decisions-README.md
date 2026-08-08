# `docs/decisions/` — one file per hard-to-reverse decision

Why the code is shaped the way it is. `dw-land` promotes a record here at the end of a change;
`dw-shape` reads the folder before shaping the next one. Durable — nothing here expires with the
change that wrote it.

## The bar

Write a record only if **all three** hold: it is **hard to reverse** (undoing it means touching many
places, migrating data, or breaking a published interface), it is **surprising** (a competent reader
would wonder why, or would reasonably have done it differently), and it cost a **real trade-off**
(you gave something up — if one option was simply better, that's a fact, not a decision).

If any of the three fails, don't write one. Most changes produce **zero** records, and that is the
correct number. A folder full of "chose the obvious library" entries is worse than an empty one,
because it teaches you to stop reading it.

## The shape

`<NNNN>-<slug>.md`, numbered next in sequence (`0001-`, `0002-`, …) and **never renumbered** — the
number is the record's name, and old records point at it. Frontmatter carries `decision`, `status`
(`active` | `superseded`), `date`, and `supersedes` / `superseded-by` where they apply. The body is
four H2s: **Context** (the constraint that forced a choice), **Decision** (what was chosen, present
tense), **Trade-off** (what was given up, and the option rejected), **Revisit when** (a concrete
trigger — a number, an event, a threshold, not "periodically").

The descriptive filenames are the index. There is no table of contents to keep in sync.

## Superseding

**Never rewrite a record.** When a decision is replaced, write a new one and flip the old to
`status: superseded` with `superseded-by: <NNNN>`, and point the new record back with
`supersedes: <NNNN>`. `dw-land` does the flip when it promotes the replacement.

Superseded records stay, and stay read. Why a settled choice was reopened is often the most useful
thing in the folder.

## Not here

What a word _means_ goes in `CONTEXT.md`, one line, no rationale. A trap that cost real time goes in
`## Gotchas` in `CLAUDE.md`. Both are common; a decision record is rare.
