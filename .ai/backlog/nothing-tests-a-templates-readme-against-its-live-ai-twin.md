---
created: 2026-08-14
source: the-doc-layer-says-one-thing-once
---

# Nothing pins `templates/archive-README.md` to `.ai/archive/README.md`, though they are kept identical

`templates/hooks/` has `hooks-in-sync.test.sh`; the payload READMEs have nothing, so their twinning is
byte-identical only for as long as somebody remembers. This pass edited both by hand and verified with
`cmp` twice. Mirror the hooks test over the pairs that are meant to match — deliberately not the ones
that aren't, which is most of them. Detail:
`.ai/archive/the-doc-layer-says-one-thing-once`.
