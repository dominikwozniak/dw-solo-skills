---
created: 2026-08-10
source: two-gates-against-scope-shedding
---

# Close the `dw-grill` → `dw-shape` hole: the "deliberately left out" list is promised but never filed

`skills/dw-grill/SKILL.md:90` says `dw-shape` files that list into `.ai/backlog/`; `dw-shape` has no
such step — it only reads the backlog (`:71-74`) and consumes an entry (`:134-146`). So the pile
reaches disk only at land time, when parking is cheapest. Moving it to shape time is the deepest fix
for scope shedding available, and the counterpart to the two land-side gates in
`.ai/archive/two-gates-against-scope-shedding`.
