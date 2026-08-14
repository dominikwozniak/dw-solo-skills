---
created: 2026-08-14
source: skill-corpus-ratchet
---

# `templates/` ships the `docs/agents/` rule and the gate behind it, but never says what belongs there

A scaffolded repo gets `templates/AGENTS.md`'s "move a topic into `docs/agents/<topic>.md`" line and
`check-agents-docs.mjs`'s router-coverage failure, with no shipped counterpart to this repo's
`docs/agents/README.md` — so the consumer meets the contract first as a red gate. Candidate: a
`templates/agents-docs-README.md` seeded by `dw-init` beside the `.ai/` and `docs/decisions/` READMEs
it already writes. Watch the size: the local copy carries this repo's own history, and a payload
version has to be the contract only.

`the-doc-layer-says-one-thing-once` sharpened this rather than closing it: the template is now a
skeleton, so the surrounding prose that partly stood in for the contract is gone too. Its "no file
added" decision is what kept the candidate fix out.
