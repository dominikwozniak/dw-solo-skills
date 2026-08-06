---
created: 2026-08-06
source: language-discipline-in-grill-and-next
---

# Make `templates/CLAUDE.local.md`'s `**Domain**` placeholder point at `CONTEXT.md` for real

`templates/CLAUDE.local.md:61` offers `CONTEXT.md` as one option inside parenthetical prose, so a
scaffolded repo can end up with a glossary nothing points at. Now that three skills read that file,
the pointer is worth stating rather than suggesting. Payload change — bump `dw-solo-setup` in both
manifests. See `.ai/archive/language-discipline-in-grill-and-next`.
