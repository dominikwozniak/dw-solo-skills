---
created: 2026-08-10
source: validate-decision-records
---

# Run `check-decisions.sh` over this repo's own `docs/decisions/` from `scripts/validate-artifacts.sh`

The script ships to consumer repos and `dw-land` runs it there at close time, but this repo's own
five records are only checked when someone happens to close a change here. CI would hold the
dogfood folder to the same contract on every push. See `.ai/archive/validate-decision-records/`.
