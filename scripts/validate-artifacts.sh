#!/usr/bin/env bash
# Two passes, both backing `pnpm validate:artifacts` and the validate-artifacts CI workflow:
#
#   1. every self-test under scripts/tests/ — synthetic cases proving the shipped scripts behave
#      (slugify derives paths deterministically, check-decisions catches a malformed record), the
#      guardrail hooks block what they claim, and this repo's own .claude/hooks/ stay
#      byte-identical to the templates/ canon it ships.
#   2. check-decisions.sh over this repo's OWN docs/decisions/ — the dogfood pass. The script
#      ships to consumer repos and dw-land runs it there at close time, so without this the
#      records here are only ever read when someone happens to close a change in this repo.
#
# NOTE: there is deliberately no `.ai/` schema sweep here, and pass 2 is not a precedent for one.
# docs/decisions/ has a machine-parsed identity — `decision:` has to match the filename number and
# `superseded-by:` is a pointer made of that number — so a record can break silently and is worth
# gating. This lane's CHANGE.md has none of that: a goal, a decision list and a task checklist,
# with no status table, no SHA column and no edge graph. A validator over it could only check that
# prose exists.
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

# The dogfood pass. Findings go to stdout one per line, prefixed `error: ` or `warn: `; the script
# exits non-zero for errors only, so a `warn:` (a gap in the sequence — past tense, breaks nothing
# being written now) prints and does not fail the build. That routing is the script's contract,
# not this file's judgement: don't re-read the prefixes here.
echo
echo "Checking docs/decisions/ against the record contract..."
decisions_out="$(bash "$ROOT/scripts/runtime/check-decisions.sh" "$ROOT")"
decisions_rc=$?
[ -n "$decisions_out" ] && printf '%s\n' "$decisions_out"
if [ "$decisions_rc" -ne 0 ]; then
  FAILED=1
else
  [ -n "$decisions_out" ] || echo "• docs/decisions/ clean"
fi

echo
if [ "$FAILED" -eq 0 ]; then
  echo "All artifact checks passed."
else
  echo "Artifact validation FAILED."
fi
exit $FAILED
