---
created: 2026-08-14
source: the-doc-layer-says-one-thing-once
---

# Nothing pins `templates/archive-README.md` to `.ai/archive/README.md`, though they are kept identical

`templates/hooks/` has `hooks-in-sync.test.sh`; the payload READMEs have nothing, so their twinning is
byte-identical only for as long as somebody remembers. This pass edited both by hand and verified with
`cmp` twice. Mirror the hooks test over the pairs that are meant to match — deliberately not the ones
that aren't, which is most of them. Detail:
`.ai/archive/2026-08-14-the-doc-layer-says-one-thing-once`.

**Three pairs, not one**, and the check must be told each explicitly: `templates/archive-README.md` ↔
`.ai/archive/README.md` and `templates/backlog-README.md` ↔ `.ai/backlog/README.md` differ by one
repo-specific paragraph, while `templates/work-README.md` ↔ **`.ai/README.md`** is byte-identical —
and that third live twin sits at the top of `.ai/`, so any glob shaped `.ai/*/README.md` misses it.
It is the pair that drifted in `shaping-scales-to-a-large-change`, caught by a delegated review rather
than by anything in the repo.

Hit again in `decisions-get-a-gate-and-a-finder`: the archive pair needed the same seven-line paragraph edited twice by hand, and a delegated review is what noticed they are two independent files rather than a symlink pair.
