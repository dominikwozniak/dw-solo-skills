---
created: 2026-08-02
---

# `validate-manifests.sh` can't see a version that didn't move, because it has no base ref

It only checks that `marketplace.json` and the owning `plugin.json` are **equal**, which misses both
failures a base ref would catch: a version that didn't grow (two parallel changes took the same number
and auto-merged, twice on 2026-08-02, caught by hand) and a shipped-payload change under `templates/`
or `scripts/runtime/` that merges green with no bump. Needing a base ref may put the check in CI
rather than in the validator. Write the fixture alongside it — `717f1e5` is proof a validator can pass
silently while broken. Detail: `.ai/archive/skill-routing-evals`.

Hit again by `the-doc-layer-says-one-thing-once`, which edited `templates/` in two rounds and bumped
`dw-solo-setup` by hand both times — twice relying on the reader the check cannot be. And again by
`start-builds-and-next-builds-by-default`: `scripts/runtime/worktree.sh` and three skill bodies moved,
`dw-solo` and `dw-solo-extras` were both bumped by hand, and the check would have stayed green had
either been forgotten.

This entry was three bullets. `de-ratchet-the-solo-lane` closed the other two: the hardcoded
`awk -F'|' '{print $4}'` Arguments-cell index went with the column, and the decision-record contract no
longer states itself in three files.
