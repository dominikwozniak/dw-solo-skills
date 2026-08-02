#!/usr/bin/env bash
# validate-evals.sh — guard the skills ↔ eval-cases contract, the same way validate-docs.sh guards
# the skills ↔ README contract. `node evals/routing.ts` only scores the case files that exist; it
# cannot notice the one nobody wrote. Four mechanical, no-judgement checks:
#   1. no unevaluated skill  — every model-invocable skills/<x>/ has evals/cases/<x>.json
#   2. no orphan case file   — every evals/cases/<x>.json has a skills/<x>/ that is model-invocable
#   3. case files are shaped — declared skill matches the filename, and the prompt/owner minimums hold
#   4. owners are real       — every negative's `owner` names a skill on disk
#
# Check 1 skips `disable-model-invocation: true` skills on purpose: routing is never the model's
# decision there, so there is no routing to assert. Check 2 is the other half of that — a case file
# FOR an explicit-invoke skill is a mistake, not a bonus, and would quietly measure nothing.
#
# The minimums are the floor the change that introduced this settled on: enough positives to see a
# pattern rather than a coincidence, and enough negatives that the gate which actually catches
# description drift (see evals/README.md) has something to work with.
#
# Run from the repo root (`pnpm validate:evals`) or via CI. Exit 0 iff the cases match the skills.
set -uo pipefail
export LC_ALL=C

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$ROOT" || exit 1

CASES_DIR="evals/cases"
MIN_POSITIVES=3
MIN_NEGATIVES=2
FAILED=0

# Unlike the guardrail hooks, which no-op without jq, a validator that silently passes is worse
# than one that fails loudly.
if ! command -v jq >/dev/null; then
  echo "::error::jq is required by validate-evals.sh but is not on PATH"
  exit 1
fi

# in_list <needle> <space-separated-haystack> — exit 0 if present.
in_list() {
  for w in $2; do [ "$w" = "$1" ] && return 0; done
  return 1
}

# --- skill sets --------------------------------------------------------------
disk_skills=""
invocable="" # everything WITHOUT disable-model-invocation: true
for d in skills/*/; do
  [ -f "$d/SKILL.md" ] || continue
  name="$(basename "$d")"
  disk_skills="$disk_skills $name"
  if ! grep -qE '^disable-model-invocation:[[:space:]]*true' "$d/SKILL.md"; then
    invocable="$invocable $name"
  fi
done

if [ -z "$invocable" ]; then
  echo "::error::found no model-invocable skills under skills/ — nothing to evaluate"
  exit 1
fi

# --- check 1: no unevaluated skill -------------------------------------------
echo "Checking every model-invocable skill has an eval case file..."
for name in $invocable; do
  if [ -f "$CASES_DIR/$name.json" ]; then
    echo "OK  $name has $CASES_DIR/$name.json"
  else
    echo "::error::skills/$name/ is model-invocable but has no $CASES_DIR/$name.json"
    FAILED=1
  fi
done

# --- check 2: no orphan case file --------------------------------------------
echo
echo "Checking every case file belongs to a model-invocable skill on disk..."
for f in "$CASES_DIR"/*.json; do
  [ -f "$f" ] || continue
  name="$(basename "$f" .json)"
  if ! in_list "$name" "$disk_skills"; then
    echo "::error::$f has no matching skills/$name/SKILL.md"
    FAILED=1
  elif ! in_list "$name" "$invocable"; then
    echo "::error::$f exists but skills/$name/ is disable-model-invocation — it measures nothing"
    FAILED=1
  else
    echo "OK  $(basename "$f") -> skills/$name/"
  fi
done

# --- checks 3 and 4: shape, minimums, real owners ----------------------------
echo
echo "Checking case files are shaped and their owners exist..."
for f in "$CASES_DIR"/*.json; do
  [ -f "$f" ] || continue
  name="$(basename "$f" .json)"

  if ! jq -e . "$f" >/dev/null 2>&1; then
    echo "::error::$f is not valid JSON"
    FAILED=1
    continue
  fi

  declared="$(jq -r '.skill // empty' "$f")"
  if [ "$declared" != "$name" ]; then
    echo "::error::$f declares skill \"$declared\" but the filename says \"$name\""
    FAILED=1
  fi

  n_pos="$(jq -r '(.positives // []) | length' "$f")"
  n_neg="$(jq -r '(.negatives // []) | length' "$f")"
  if [ "$n_pos" -lt "$MIN_POSITIVES" ]; then
    echo "::error::$f has $n_pos positives, needs at least $MIN_POSITIVES"
    FAILED=1
  fi
  if [ "$n_neg" -lt "$MIN_NEGATIVES" ]; then
    echo "::error::$f has $n_neg negatives, needs at least $MIN_NEGATIVES"
    FAILED=1
  fi

  # An empty or missing prompt scores zero against everything and reads as a passing case.
  if [ "$(jq -r '[(.positives // [])[] | select((.prompt // "") == "")] | length' "$f")" != "0" ]; then
    echo "::error::$f has a positive with no prompt"
    FAILED=1
  fi
  if [ "$(jq -r '[(.negatives // [])[] | select((.prompt // "") == "")] | length' "$f")" != "0" ]; then
    echo "::error::$f has a negative with no prompt"
    FAILED=1
  fi

  missing_owner="$(jq -r '[(.negatives // [])[] | select((.owner // "") == "")] | length' "$f")"
  if [ "$missing_owner" != "0" ]; then
    echo "::error::$f has $missing_owner negative(s) with no owner"
    FAILED=1
  fi

  for owner in $(jq -r '(.negatives // [])[] | .owner // empty' "$f" | sort -u); do
    if ! in_list "$owner" "$disk_skills"; then
      echo "::error::$f names owner \"$owner\", which is not a skill in this repo"
      FAILED=1
    elif [ "$owner" = "$name" ]; then
      echo "::error::$f names itself as the owner of one of its negatives"
      FAILED=1
    fi
  done

  [ "$FAILED" -eq 0 ] && echo "OK  $(basename "$f") ($n_pos positives, $n_neg negatives)"
done

echo
if [ "$FAILED" -eq 0 ]; then
  echo "All eval case checks passed."
else
  echo "Eval case validation FAILED."
fi
exit $FAILED
