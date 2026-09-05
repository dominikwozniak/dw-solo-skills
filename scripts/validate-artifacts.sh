#!/usr/bin/env bash
# Three passes, all backing `pnpm validate:artifacts` and the validate-artifacts CI workflow:
#
#   1. every self-test under scripts/tests/ — synthetic cases proving the shipped scripts behave
#      (slugify derives paths deterministically, worktree.sh creates and tears down), the guardrail
#      hooks block what they claim, and this repo's own .claude/hooks/ stay byte-identical to the
#      templates/ canon it ships.
#   2. the cap on `.ai/backlog/`. It grows by append and nothing ever asked it to stop, which is how
#      12 queued ideas happen. The cap is not a size limit; it forces the choice the append silently
#      skipped — absorb this entry into the change that found it, bundle it with a cousin, or admit
#      it failed the bar.
#   3. the ratchet over skills/*/SKILL.md, via scripts/check-skill-corpus.mjs. The corpus grew 19% in
#      three days with nothing looking, because the only mechanical check over skill size was
#      decoration: agnix AS-012 fires at 500 body lines, the largest skill is 228, and agnix warnings
#      do not gate anyway — `bash scripts/lint.sh` exits 0 with dozens of them. The count and the
#      standing exception are in docs/agents/tooling.md's Gotchas; no number is repeated here,
#      because a warning count drifts and two copies of it drift apart.
#
# Passes 2 and 3 are the same bargain in two units. Neither sets a limit anybody chose: the cap
# forces a decision when the backlog grows, and the baseline forces one when the corpus does. Growth
# stays available in both, and costs a line in the diff that a reader can see and argue with.
#
# There used to be a second cap here, over `## Gotchas` entries in AGENTS.md, and it is gone because
# the section is: gotchas now live in the `docs/agents/<topic>.md` file the root's Task Router points
# at, and the root is held by the byte-and-line budget it declares, checked by validate-docs.sh. The
# cap and the budget were solving the same problem — traps crowding out rules in the one file every
# session loads — and the budget solves it without the side effect the cap had, which was to force
# unrelated traps to be merged into one entry purely to stay under a number.
#
# NOTE: passes 2 and 3 are COUNTS, not schemas, and they are not a precedent for one — there is still
# deliberately no `.ai/` sweep here, and pass 3 reads no skill's prose, only its size. A count knows
# nothing about what is inside the files; it only refuses to let the pile grow without a decision.
# This lane's CHANGE.md is a goal, a decision list and a task checklist — no status table, no SHA
# column, no edge graph — so a validator reading one could only check that prose exists.
#
# A pass over this repo's own docs/decisions/ used to run here too, via check-decisions.sh. The script, its
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
# points here, so raising the cap is one edit rather than four that drift (0006, still standing per 0008).
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

# --- the ratchet over the skill corpus ---------------------------------------
# No number lives here: the baseline holds it, and the checker owns the comparison. Node absent is a
# SKIP rather than a pass — the same guard the .mjs self-tests use, and for the same reason.
echo
echo "Checking the skill corpus against its baseline..."
if command -v node >/dev/null; then
  node "$ROOT/scripts/check-skill-corpus.mjs" --root "$ROOT" || FAILED=1
else
  echo "• skills/: SKIP (node missing — the checker is a .mjs)"
fi

# --- the eval fixture's copy of the shipped checker --------------------------
# land-gotcha-shape carries a real copy rather than a stub, because the case turns on `agents:check`
# actually refusing an un-re-recorded corpus. A copy is a fork the moment the template moves, and a
# fixture running last month's checker measures last month's behaviour while reporting today's. Lives
# here rather than in check-agents-docs.test.sh, whose every case runs against a synthetic mktemp
# scaffold and never against a real path in this repo.
FIXTURE_CHECKER="$ROOT/evals/fixtures/land-gotcha-shape/base/scripts/check-agents-docs.mjs"

echo
echo "Checking the eval fixture's checker against the template..."
if [ ! -f "$FIXTURE_CHECKER" ]; then
  echo "::error::${FIXTURE_CHECKER#"$ROOT"/} is missing — the land-gotcha-shape case needs a runnable checker."
  FAILED=1
elif cmp -s "$ROOT/templates/check-agents-docs.mjs" "$FIXTURE_CHECKER"; then
  echo "• land-gotcha-shape: checker matches templates/check-agents-docs.mjs"
else
  echo "::error::${FIXTURE_CHECKER#"$ROOT"/} has drifted from templates/check-agents-docs.mjs."
  echo "::error::  Re-copy it: cp templates/check-agents-docs.mjs ${FIXTURE_CHECKER#"$ROOT"/}"
  echo "::error::  Then re-seed the fixture's baseline if the corpus moved with it."
  FAILED=1
fi

# --- the declared bullets exist ----------------------------------------------
# Four hooks and worktree.sh resolve their command by grepping AGENTS.md for one of these labels, and
# every one of them falls back rather than failing when the label is absent — the design that keeps an
# undeclared requirement from breaking commits, and the reason a missing bullet is silent. Bootstrap
# went missing exactly that way: the template shipped it, `worktree.sh create` read for it, and this
# repo answered with a lockfile guess for months while the prose above the list said "four".
#
# Repo-only on purpose. The shipped checker grades consumers too, and a repo scaffolded before a label
# existed is entitled to not declare it — `dw-doctor` warns there, which is the right severity away
# from home. Here the list is a contract with our own hooks, so it fails.
echo
echo "Checking AGENTS.md declares every grep-read bullet..."
for label in "Lint command" "Typecheck command" "Commit pattern" "Commit trailer" "Bootstrap command"; do
  if grep -qE "^[[:space:]]*[-*][[:space:]]*\*{0,2}${label}\*{0,2}:" "$ROOT/AGENTS.md"; then
    echo "• declared: $label"
  else
    echo "::error::AGENTS.md declares no **$label** under ## Solo lane."
    echo "::error::  Add it, or the reader silently falls back to its own default."
    FAILED=1
  fi
done

echo
if [ "$FAILED" -eq 0 ]; then
  echo "All artifact checks passed."
else
  echo "Artifact validation FAILED."
fi
exit $FAILED
