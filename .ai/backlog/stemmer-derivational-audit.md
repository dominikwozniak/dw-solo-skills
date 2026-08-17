---
created: 2026-08-05
---

# Audit the DERIVATIONAL table against real case prompts

The 21-entry suffix table in `stem()` is suspected over-engineering: `ization`/`ational`/`iveness`
and friends are academic English, and the corpus is 11 imperative skill descriptions. `--explain`
(shipped 2026-08-05) makes the question answerable instead of arguable.

Run `--explain` over every prompt in `evals/cases/*.json` and record which stems any ranking actually
depends on. If no rank-1 result turns on a `DERIVATIONAL` mapping, replace the table with a minimal
strip — `s` / `ing` / `ed` / trailing `e` — then re-pin the measured baseline in `evals/README.md` and
the `--min-rank1` floor to whatever the numbers become. The floor is a ratchet, so it moves only with
a recorded reason.

Nothing is decided in advance: the table stays if the data says a mapping is load-bearing. The point
is to decide it on `--explain` output rather than on taste.

Two `dw-next` positives give the audit its first real cases, and they fail identically before and after
`start-builds-and-next-builds-by-default` — verified against a `git archive` of `main`, so neither is
that change's doing. `"what is still unticked on the change I am in the middle of"` lands at rank 4
because no description carries "unticked"; the description it lost to previously said **"unchecked"**
and still lost, which is precisely a `DERIVATIONAL` question rather than a vocabulary one.
`"where did we leave off on this"` finds no discriminating term at all. Adding either word verbatim
would lift rank-1 to 23/31 while gaming the eval — `evals/cases/dw-next.json` keeps its positives as
paraphrases on purpose — so the fix has to come from the stem table or not at all. Findings:
`.ai/archive/start-builds-and-next-builds-by-default`.

`check-delegates-to-codex-by-default` adds two more cases and, more usefully, a **contrast that splits
the two failure classes this audit is trying to tell apart.** `dw-check`'s two failing positives are
the stemming kind: `"give what I have written so far a once-over before I carry on"` loses to
`dw-grill` and `"anything wrong with the code I just wrote? point me at the lines"` loses to `dw-next`,
both identically before and after that change's description rewrite — verified the same way, against a
`git archive` of `main`. But a candidate positive probed and rejected there is the **vocabulary** kind:
`"have a second model go over this diff before I move on"` lands rank 3 because no description carries
"second model" at all, while `"move on"` hands the prompt to `dw-next`. No stem table reaches that one.
Run `--explain` on all three together — if the two that look like stemming failures also turn out to
depend on nothing in `DERIVATIONAL`, the table is unimplicated by every case on file and the strip is
safe. Findings: `.ai/archive/check-delegates-to-codex-by-default`.
