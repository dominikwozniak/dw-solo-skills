# `docs/decisions/` — why this repo is shaped this way

One record per decision, `<NNNN>-<kebab-slug>.md`, append-only. `dw-land` writes them at close,
`dw-shape` reads them before the next change. **[`0011`](0011-bare-dw-next-builds-rather-than-reports.md) is the
worked example — copy its shape.**

No index here on purpose: `ls` sorts them and every slug states its decision.

Ceiling: **80 lines** per record, enforced by `pnpm validate:docs`. Eighty is what this folder already
supports — the longest record is 72 — not a claim that eighty is the right number. The payload seeds a
new repo with forty, where nothing has to be met first.

The contract — the three-part bar a decision has to clear, the frontmatter and section shape, and how
a record is superseded rather than rewritten — lives once, in
[`skills/dw-land/references/decision-record.md`](../../skills/dw-land/references/decision-record.md).
It is stated there because that is the file the skill actually reads while writing one. It used to be
restated here and in `templates/decisions-README.md` as well, which is three copies of one bar and two
of them unread.

Nothing enforces the contract mechanically any more. `check-decisions.sh` and its test were 489 lines
guarding 229 lines of records — worth it for a folder several people write to, not for this one.
