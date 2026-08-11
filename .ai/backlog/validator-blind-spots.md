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

This entry was three bullets. `de-ratchet-the-solo-lane` closed the other two: the hardcoded
`awk -F'|' '{print $4}'` Arguments-cell index went with the column, and the decision-record contract no
longer states itself in three files.
