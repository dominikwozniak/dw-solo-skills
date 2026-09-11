---
decision: 0027
status: active
date: 2026-09-11
rule: `dw-check` reads every diff itself in the main thread; the outside reviewer is offered after, never instead.
touches:
  - skills/dw-check/SKILL.md
  - skills/dw-doctor/scripts/doctor.sh
supersedes: 0012
---

# 0027 — `dw-check` reads the diff; codex confirms on request

## Context

`0012` made bare `dw-check` hand the diff to `codex:rescue` and skip the Claude read entirely, on the
ground that the cross-model pass is the only thing this gate adds over re-reading your own diff, and
that an option you have to remember goes unused. Both halves were right about behaviour and wrong
about where the risk sat.

The Codex subscription tier changed, and the plan now serves a weaker model. Under `0012` the gate's
entire verdict moved with it, because nothing else read the diff — a plan change was silently a
quality change. The dependency is the problem, not the model: any gate whose only reader lives behind
someone else's billing is one downgrade away from being worse than no gate.

`0012` also mis-stated what it was buying. The outside pass was never a gate — findings are quoted,
re-verified at a real `file:line`, and nothing is fixed without approval — so what it actually bought
was _who reads first_, at the price of a subagent round trip on every non-trivial run.

## Decision

`dw-check` reads the diff itself on every run, with this skill's own prose, inline in the main
thread — never `/code-review`, never a subagent, never an effort level, bounded by the five-finding
filter it already carries. The outside reviewer is offered in one line inside the stop that already
happens, and runs only on a yes. `codex` in the argument skips the ask; it overrides nothing else.

The triviality floor survives with a smaller job — below it, don't bother asking — so its numbers
stay in the skill. A missing plugin stops being a degradation and loses its line: the verdict is
already in, and `dw-doctor` names the install.

## Trade-off

The cheap bare path is back, and with it the exact failure `0012` was written to stop: a second
opinion behind an ask is a second opinion that goes unused, and the pass silently not happening is
harder to notice than a slow one. The defence is that the ask is now one line in a stop the run makes
anyway, not a mode you have to recall at typing time — but that is a weaker guarantee than doing it,
and it will be wrong for someone who says no by reflex.

This also re-litigates a settled question fourteen records later, which the folder is supposed to
resist. It clears the bar only because the premise moved: `0012` reasoned about a reviewer that was
free to lean on, and that reviewer's quality is now a billing decision.

Rejected: pinning a model in the skill so the strong one is named explicitly. Model names are
machine-local and go stale on a plan change or a rename, in a plugin other people install — the
codex config already decides, and should keep deciding.

## Revisit when

You decline the offer twice running on diffs that later turn out broken — which means the ask is too
easy to wave off and the pass should be back to automatic — or the inline review starts reaching for
`/code-review` or a subagent, which means step 2's bound is prose where it needs to be a rule.
