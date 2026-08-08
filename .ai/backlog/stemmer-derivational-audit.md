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
