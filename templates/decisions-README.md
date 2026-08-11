# `docs/decisions/` — why the code is shaped this way

One record per decision, `<NNNN>-<kebab-slug>.md`, append-only. `dw-land` writes them at close,
`dw-shape` reads them before the next change. **Once `0001` exists it is the worked example — copy its
shape.**

No index here on purpose: `ls` sorts them and every slug states its decision.

You don't have to keep the contract in your head, and it isn't restated here: `dw-land` reads it from
`references/decision-record.md` inside the installed plugin every time it writes one. What it says, in
one line each — a record needs **all three** of hard-to-reverse, surprising and a real trade-off, so
most changes produce **zero**; and a replaced record is **never rewritten or renumbered**, only marked
`status: superseded` with `superseded-by:` pointing at the new one.

What a word _means_ goes in `CONTEXT.md`; a trap that cost real time goes in `## Gotchas` in
`CLAUDE.md`. Both are common; a record is rare.
