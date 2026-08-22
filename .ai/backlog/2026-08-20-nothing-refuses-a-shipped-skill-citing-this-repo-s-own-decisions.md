---
created: 2026-08-20
source: harvest-pstack-into-the-solo-lane
---

# Nothing refuses a shipped skill that cites this repo's own decisions, history or `docs/agents/` files

A `SKILL.md` installs into other people's projects, where `0010` is their tenth decision and
`docs/agents/README.md` is absent — so a citation that reads correctly here is wrong there. Six such
claims shipped in one change and the whole green gate saw none of them. A grep over `skills/*/SKILL.md`
for `docs/decisions/<NNNN>`, `docs/agents/`, and "this repo" outside the lane's own scaffolded paths
would; `0013` means it owes a self-test, which is why this is an entry rather than an inline fix.
Findings: `.ai/archive/2026-08-20-harvest-pstack-into-the-solo-lane`.
