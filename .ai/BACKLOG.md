# Backlog

Follow-ups and ideas not being worked on now. Newest first, one line each. The bar: if you would not
pick it up within a month, don't write it. The closing pass parks them here; the shaping step reads
this when opening the next change and deletes the line it takes.

- Rewrite `templates/CLAUDE.local.md` and `templates/work-README.md` — both still name `dw-shape` /
  `dw-next` / `dw-land` in prose, which no longer exist. Nothing validates the template payload, so
  this dangles silently until the new workflow skills land.
- Decide whether `scripts/runtime/slugify.sh` earns its place — kept through the skill wipe to hold
  the shipped-script path proven in CI, but it currently has no consumer.
