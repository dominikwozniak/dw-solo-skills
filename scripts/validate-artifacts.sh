#!/usr/bin/env bash
# Two passes, both backing `pnpm validate:artifacts` and the validate-artifacts CI workflow:
#
#   1. every self-test under scripts/tests/ — synthetic cases proving the shipped scripts behave
#      (slugify derives paths deterministically, worktree.sh creates and tears down), the guardrail
#      hooks block what they claim, and this repo's own .claude/hooks/ stay byte-identical to the
#      templates/ canon it ships.
#   2. the cap on `.ai/backlog/`. It grows by append and nothing ever asked it to stop, which is how
#      12 queued ideas happen. The cap is not a size limit; it forces the choice the append silently
#      skipped — absorb this entry into the change that found it, bundle it with a cousin, or admit
#      it failed the bar.
#
# There used to be a second cap here, over `## Gotchas` entries in AGENTS.md, and it is gone because
# the section is: gotchas now live in the `docs/agents/<topic>.md` file the root's Task Router points
# at, and the root is held by the byte-and-line budget it declares, checked by validate-docs.sh. The
# cap and the budget were solving the same problem — traps crowding out rules in the one file every
# session loads — and the budget solves it without the side effect the cap had, which was to force
# unrelated traps to be merged into one entry purely to stay under a number.
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

# --- the cap on the durable layer --------------------------------------------
# This number is the single source. The prose beside the capped list says only THAT it is capped and
# points here, so raising the cap is one edit rather than four that drift (0006).
BACKLOG_CAP=8

echo
echo "Checking the durable layer against its cap..."

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
