# `docs/decisions/` — why the code is shaped this way

One record per decision, `<NNNN>-<kebab-slug>.md`, append-only. `dw-land` writes them at close,
`dw-shape` reads them before the next change. **Once `0001` exists it is the worked example — copy its
shape.**

No index here on purpose: `ls` sorts them and every slug states its decision.

Ceiling: **40 lines** per record, enforced by the same checker as `AGENTS.md`'s budget. Size only —
the bar and the shape stay editorial. Delete the line to switch it off; raise the number and you have
chosen to, which is the point.

The contract — the three-part bar a decision has to clear, the frontmatter and section shape, and how a
record is superseded rather than rewritten — is **not restated here**. It lives once, in
`references/decision-record.md` inside the installed plugin, because that is the file `dw-land` reads
every time it writes a record. A second copy here would be the one nobody reads and the one that goes
stale.

What a word _means_ goes in `CONTEXT.md`; a trap that cost real time goes in a `## Gotchas` — an
existing root section where the repo already keeps one, else the routed topic file covering the trap.
Both are common; a record is rare.
