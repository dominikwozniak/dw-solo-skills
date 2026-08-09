# `docs/decisions/` — why the code is shaped this way

One record per decision, `<NNNN>-<kebab-slug>.md`, append-only. `dw-land` writes them at close from
its own template, `dw-shape` reads them before the next change. **Once `0001` exists it is the
worked example — copy its shape.**

No index here on purpose: `ls` sorts them and every slug states its decision.

## The bar — all three, or don't write one

1. **Hard to reverse** — undoing it means touching many places, migrating data, or breaking a
   published interface.
2. **Surprising** — a competent reader would wonder why it was done this way.
3. **A real trade-off** — you gave something up. If one option was simply better, that is a fact,
   not a decision.

Most changes produce **zero** records, and that is the correct number. A folder full of "chose the
obvious library" entries teaches you to stop opening it.

**Never rewrite one.** Mark the old `status: superseded` with `superseded-by:`, point the new one
back with `supersedes:`, and give it the next number — numbers are never reused. `dw-land` does this
when it promotes the replacement. Why a settled choice was reopened is often the most useful thing
here.

What a word _means_ goes in `CONTEXT.md`; a trap that cost real time goes in `## Gotchas` in
`CLAUDE.md`. Both are common; a record is rare.
