---
created: 2026-08-06
source: language-discipline-in-grill-and-next
---

# Auto-import `CONTEXT.md` instead of making each skill say "read it"

Three skills now carry their own copy of the instruction — `dw-shape`, `dw-grill` and `dw-next` — and
the fourth that needs it will carry a fourth. An `@CONTEXT.md` import, or a third `dw-init`-managed
`CLAUDE.md` block, would load the glossary once per session instead. Weigh it against the reason the
per-skill lines were chosen: `dw-solo` and `dw-solo-setup` install separately, so anything riding on
`dw-init` is absent for a loop-only install. See `.ai/archive/language-discipline-in-grill-and-next`.
