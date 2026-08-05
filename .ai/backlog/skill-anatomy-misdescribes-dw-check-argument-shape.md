---
created: 2026-08-05
source: shape-splits-changes
---

# `docs/SKILL-ANATOMY.md` misdescribes `dw-check`'s argument shape

`:44-45` cites `dw-check` as an example of "free text narrows the focus **instead of** switching
mode". It now does both: `codex` switches mode, anything else narrows. That hybrid is a fifth
argument convention, documented in the skill body but not where the four conventions live — so the
next skill needing it has no precedent to copy.
