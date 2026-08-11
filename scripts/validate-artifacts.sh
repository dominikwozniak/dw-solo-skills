#!/usr/bin/env bash
# Two passes, both backing `pnpm validate:artifacts` and the validate-artifacts CI workflow:
#
#   1. every self-test under scripts/tests/ — synthetic cases proving the shipped scripts behave
#      (slugify derives paths deterministically, worktree.sh creates and tears down), the guardrail
#      hooks block what they claim, and this repo's own .claude/hooks/ stay byte-identical to the
#      templates/ canon it ships.
#   2. the two caps on the durable layer — `## Gotchas` entries and `.ai/backlog/` files. Both grow
#      by append and nothing ever asked them to stop, which is how 21 gotchas and 12 queued ideas
#      happen. The cap is not a size limit; it forces the choice the append silently skipped —
#      merge this trap into the cousin it belongs with, absorb this entry into the change that found
#      it, or admit an old one is no longer true.
#
# NOTE: pass 2 is a COUNT, not a schema, and it is not a precedent for one — there is still
# deliberately no `.ai/` sweep here. A count knows nothing about what is inside the files; it only
# refuses to let the pile grow without a decision. This lane's CHANGE.md is a goal, a decision list
# and a task checklist — no status table, no SHA column, no edge graph — so a validator reading one
# could only check that prose exists.
#
# A third pass used to run check-decisions.sh over this repo's own docs/decisions/. The script, its
# 235-line test and the pass all went in `de-ratchet-the-solo-lane`: 489 lines of enforcement over
# 229 lines of records, in a repo with one reader who does not need a parser to notice a malformed
# record they just wrote.
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

# --- the caps on the durable layer -------------------------------------------
GOTCHAS_CAP=12
BACKLOG_CAP=8

echo
echo "Checking the durable layer against its caps..."

# Top-level entries only: an entry opens at column 0 with `- **`, and a group's sub-bullets are
# indented, so a merge of four traps into one entry counts as the one entry it reads as. Scoped to the
# section because the same bullet style is used elsewhere in the file.
gotchas="$(awk '/^## Gotchas/{f=1;next} f&&/^## /{exit} f&&/^- \*\*/{c++} END{print c+0}' "$ROOT/AGENTS.md")"
if [ "$gotchas" -gt "$GOTCHAS_CAP" ]; then
  echo "::error::AGENTS.md ## Gotchas has $gotchas entries, cap is $GOTCHAS_CAP — merge a trap into the"
  echo "::error::  cousin it belongs with, or retire one that stopped being true. Never just append."
  FAILED=1
else
  echo "• ## Gotchas: $gotchas/$GOTCHAS_CAP entries"
fi

# README.md is the folder's own contract, not a queued idea.
backlog=0
for f in "$ROOT"/.ai/backlog/*.md; do
  [ -f "$f" ] || continue
  [ "$(basename "$f")" = "README.md" ] && continue
  backlog=$((backlog + 1))
done
if [ "$backlog" -gt "$BACKLOG_CAP" ]; then
  echo "::error::.ai/backlog/ holds $backlog entries, cap is $BACKLOG_CAP — bundle one with a cousin that"
  echo "::error::  ships alongside it, absorb the cheapest into the open change, or drop one that failed"
  echo "::error::  the month bar."
  FAILED=1
else
  echo "• .ai/backlog/: $backlog/$BACKLOG_CAP entries"
fi

echo
if [ "$FAILED" -eq 0 ]; then
  echo "All artifact checks passed."
else
  echo "Artifact validation FAILED."
fi
exit $FAILED
