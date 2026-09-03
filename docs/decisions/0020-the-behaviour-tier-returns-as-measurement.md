---
decision: 0020
status: active
date: 2026-09-03
---

# 0020 — the behaviour tier returns, as a measurement and never as a gate

## Context

`de-ratchet-the-solo-lane` deleted `evals/trigger.ts` a month ago: it spent subscription quota, could
not run in CI for want of a login, and answered a question — which skill fired — that the free
routing eval already answers well enough. Nothing replaced it, and nothing since has measured the
other question. Of the three dimensions a skill can be judged on, only efficiency has a check
(`check-skill-corpus.mjs` ratchets the corpus); whether a skill keeps its word once it is running has
never been measured at all. The loop's sharpest promises are refusals — `dw-land` will not round an
undelivered goal up, `dw-ship` will not merge an unlanded change — and a refusal that quietly stops
happening is invisible to every check this repo owns.

## Decision

`evals/behaviour.ts` runs one skill in a throwaway git fixture and has a second model grade the
trace. It is a **measurement**, not a gate: `--go` before anything runs, never in the `scripts` block
of `package.json`, never in CI. Results are recorded in `evals/README.md` with a date, an `n` and a
cost, the way `Asking the real router` already records its one.

Cases live in `evals/behaviour/<skill>.json`, not as a block inside the routing case files. The
routing eval fails a case file for a `disable-model-invocation` skill and seven of fourteen skills
are exactly that, so one file per skill across both tiers would have made half the corpus untestable
— including `dw-ship`, whose entire first step is the kind of refusal this tier exists to hold.

## Trade-off

It costs money — $0.30 to $1.16 per case, measured — and it is nondeterministic, so a single run is a
smoke test rather than a result. Both were true of `trigger.ts` and both remain true here; what
changed is that the question is now one nothing else answers. The price of keeping it out of CI is
that a skill body can regress between deliberate runs and nobody will be told.

The rejected option was waiting for `claude plugin eval`, which subsumes most of this and has a
`--ablation with-without` arm this does not. It is in the CLI already and returns
`plugin eval is currently in early access` on this account, with no date; its eval directory also
sits below the plugin, against `0005`. Waiting would have left the dimension unmeasured for an
unknown period in exchange for work already done here.

`0006` deletes a validator whose only job is comparing two hand-kept copies, and that still stands —
this is not one. It compares a skill against its own promises, and its verdict is a report rather
than an exit code anyone's push depends on.

## Revisit when

`claude plugin eval` becomes available on this account — then the two eval directories, this one and
the one that tool expects below each plugin, must be reconciled rather than both kept.
