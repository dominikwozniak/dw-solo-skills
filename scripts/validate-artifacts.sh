#!/usr/bin/env bash
# Run every self-test under scripts/tests/ — synthetic cases proving the shipped script behaves
# (slugify derives paths deterministically), the guardrail hooks block what they claim, and this
# repo's own .claude/hooks/ stay byte-identical to the templates/ canon it ships.
# Backs `pnpm validate:artifacts` and the validate-artifacts CI workflow.
#
# NOTE: there is deliberately no `.ai/` schema sweep here. This lane's artifact is one CHANGE.md
# per change — a goal, a decision list and a task checklist. It has no machine-parsed status table,
# no SHA column and no edge graph, so there is nothing that can break silently and nothing worth
# gating. A validator over it would only be able to check that prose exists.
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
