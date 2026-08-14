---
created: 2026-08-14
source: the-doc-layer-says-one-thing-once
---

# `scripts/lint.sh` drops the file path `lint-on-edit` appends, so the root's "must accept one" is false

It always runs `agnix .` over the whole tree, which makes every edit a full-tree lint (slow, and the
OOM applies) and contradicts both `AGENTS.md`'s Solo lane paragraph and `.husky/pre-commit`. Left out
of the doc pass deliberately: a code bug, and a docs change must not change lint behaviour. Fix the
script to the claim, not the claim to the script. Detail:
`.ai/archive/the-doc-layer-says-one-thing-once`.
