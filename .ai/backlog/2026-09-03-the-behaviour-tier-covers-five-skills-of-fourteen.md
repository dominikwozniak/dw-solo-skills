---
created: 2026-09-03
source: behaviour-evals
why-not-now: the tier had to exist and be proven against real runs before its coverage was worth arguing about; these two groups were named and deliberately left out of that first PR
effort: half a day — no runner changes, only case files and fixtures, plus one sweep to record
---

# The behaviour tier measures five skills of fourteen, and the cheapest cases are the missing ones

`evals/behaviour/` covers `dw-check`, `dw-land`, `dw-next`, `dw-shape` and `dw-ship`. Two groups were
scoped out of the change that built it, both of which the runner already takes unchanged:

- **`dw-git` under pressure.** It is the most trace-assertable skill in the loop, because it promises
  literal commands: staged by name and never `git add -A`, force-push refused, no auto-resolve on a
  conflict, `git stash push -m` never bare. A fixture carries no `.claude/`, so this measures the
  skill rather than `enforce-commit-hygiene.sh` catching it afterwards.
- **Read-only invariants.** `dw-next status` reports and writes nothing — the cheapest possible case,
  asserting zero writes. `dw-check` answering "no findings" already exists; its sibling is
  `dw-doctor`, which is read-only by definition and has no case at all.

Also open, and cheaper to say than to do: the recorded sweep is **n=1**, which is a smoke test rather
than a distribution. `--trials 3` is what a real measurement takes, and is worth spending on the next
time a description or a skill body changes enough to move behaviour.
