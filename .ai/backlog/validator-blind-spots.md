---
created: 2026-08-02
---

# Two things the validators pass silently, and the fixtures that would have caught both

Bundled because both edit `scripts/validate-*.sh`, neither ships, and the fixtures are free while the
files are already open — `717f1e5` is proof a validator can pass silently while broken.

- `validate-docs.sh:157` hardcodes Arguments as the 4th pipe field (`awk -F'|' '{print $4}'`). All
  four task-router tables agree today, but a fifth or a reordered column would have it grade the
  wrong cell and pass — the silent green it exists to prevent. Derive the index from the header row,
  roughly three lines. Detail: `.ai/archive/argument-hint-parity`.
- `validate-manifests.sh` only checks `marketplace.json` and `plugin.json` are **equal**, missing both
  failures a base ref would catch: a version that didn't grow (two parallel changes took the same
  number and auto-merged, twice on 2026-08-02, caught by hand) and a shipped-payload change under
  `templates/` or `scripts/runtime/` that merges green with no bump. Needing a base ref may put it in
  CI rather than the validator. Detail: `.ai/archive/skill-routing-evals`.
- The decision-record contract now states itself in three files nothing ties together:
  `templates/decisions-README.md`, `skills/dw-land/references/decision-record.md` and
  `docs/decisions/README.md`. They are deliberately not byte-identical, so no diff can check them —
  the cheap version asserts each states the bar as **all three**, which is the clause that has
  already drifted once. Detail: `.ai/archive/decision-record-contract-for-consumer-repos`.
- Fixtures for both validators, taken off `shell-test-sweep` — write them here, where the behaviour
  being pinned is the behaviour being changed.
