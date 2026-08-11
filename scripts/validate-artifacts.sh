#!/usr/bin/env bash
# One pass, backing `pnpm validate:artifacts` and the validate-artifacts CI workflow: every self-test
# under scripts/tests/ — synthetic cases proving the shipped scripts behave (slugify derives paths
# deterministically, worktree.sh creates and tears down), the guardrail hooks block what they claim,
# and this repo's own .claude/hooks/ stay byte-identical to the templates/ canon it ships.
#
# There used to be a second pass: check-decisions.sh over this repo's own docs/decisions/. The script,
# its 235-line test and the pass all went in `de-ratchet-the-solo-lane` — 489 lines of enforcement
# over 229 lines of records, in a repo with one reader who does not need a parser to notice a
# malformed record they just wrote.
#
# NOTE: there is deliberately no `.ai/` schema sweep here. This lane's CHANGE.md is a goal, a decision
# list and a task checklist — no status table, no SHA column, no edge graph — so a validator over it
# could only check that prose exists.
set -uo pipefail
export LC_ALL=C

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"

FAILED=0

echo "Running self-tests..."
found=0
for t in "$ROOT"/scripts/tests/*.test.sh; do
  [ -f "$t" ] || continue
  found=1
  echo "• $(basename "$t")"
  bash "$t" || FAILED=1
done

if [ "$found" -eq 0 ]; then
  echo "::error::no self-tests found under scripts/tests/ — expected at least one"
  exit 1
fi

echo
if [ "$FAILED" -eq 0 ]; then
  echo "All artifact checks passed."
else
  echo "Artifact validation FAILED."
fi
exit $FAILED
