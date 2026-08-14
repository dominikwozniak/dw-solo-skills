#!/usr/bin/env bash
# Self-test for scripts/check-skill-corpus.mjs — the ratchet that lets skills/*/SKILL.md shrink and
# refuses to let it grow without a re-recorded baseline. Every case runs against a SYNTHETIC corpus
# under mktemp, driven through --root, and never against this repo: a case asserting the real 13 243
# would make this file a second content gate rather than a test of the checker's logic
# (check-agents-docs.test.sh:2-5 states the same reason at length).
#
# What is pinned: the three exit codes and the report each one owes a reader. Over baseline must name
# the skill, not just the total — a number you cannot act on is why the corpus grew unnoticed in the
# first place. A malformed baseline must exit 2 rather than pass, because a checker that cannot read
# its baseline knows nothing about the corpus.
#
# Run standalone (`bash scripts/tests/check-skill-corpus.test.sh`) or via scripts/validate-artifacts.sh,
# which picks it up from scripts/tests/*.test.sh with no wiring. Exit 0 iff every case matches.
# bash 3.2 safe.
set -uo pipefail
export LC_ALL=C

command -v node >/dev/null || {
  echo "SKIP: node missing (the checker is a .mjs)"
  exit 0
}

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
CHECKER="$ROOT/scripts/check-skill-corpus.mjs"

PASS=0
FAIL=0
note_pass() {
  PASS=$((PASS + 1))
  echo "  ✓ $1"
}
note_fail() {
  FAIL=$((FAIL + 1))
  echo "  ✗ $1 — $2"
}

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

# corpus <baseline-json> — a fixture holding two skills of 3 and 2 words, plus the given baseline
# verbatim so a malformed one can be spelled out. Echoes the fixture root.
corpus() {
  local dir
  dir="$WORK/fx.$RANDOM$RANDOM"
  mkdir -p "$dir/scripts" "$dir/skills/dw-alpha" "$dir/skills/dw-beta"
  printf 'one two three\n' >"$dir/skills/dw-alpha/SKILL.md"
  printf 'four five\n' >"$dir/skills/dw-beta/SKILL.md"
  printf '%s\n' "$1" >"$dir/scripts/skill-corpus.baseline.json"
  printf '%s\n' "$dir"
}

# at_baseline — the fixture recorded exactly as it is: 5 words across the two skills.
AT_BASELINE='{"words":5,"perSkill":{"dw-alpha":3,"dw-beta":2}}'

OUT="$WORK/out"
check() {
  node "$CHECKER" --root "$1" >"$OUT" 2>&1
  printf '%s\n' "$?"
}

expect_rc() {
  if [ "$2" = "$3" ]; then note_pass "$1"; else note_fail "$1" "want exit $2, got $3: $(tr '\n' '|' <"$OUT")"; fi
}

expect_says() {
  if grep -qF -- "$2" "$OUT"; then
    note_pass "$1"
  else
    note_fail "$1" "output did not mention '$2': $(tr '\n' '|' <"$OUT")"
  fi
}

echo "a corpus at its baseline passes, and says what it measured:"
fx="$(corpus "$AT_BASELINE")"
expect_rc "at-baseline-exit-0" 0 "$(check "$fx")"
expect_says "at-baseline-reports-both-numbers" "5 words, baseline 5"

echo "one word added fails, and names the skill that grew:"
# The whole point of perSkill: the total says the corpus grew, and only this line says where to look.
fx="$(corpus "$AT_BASELINE")"
printf 'one two three four\n' >"$fx/skills/dw-alpha/SKILL.md"
expect_rc "grown-exit-1" 1 "$(check "$fx")"
expect_says "grown-reports-the-delta" "6 words, baseline 5, +1"
expect_says "grown-names-the-skill" "dw-alpha: 4 (was 3, +1)"
expect_says "grown-names-the-resolution" "--update-baseline"
# The skill that did NOT move must stay out of the report, or every failure lists the whole corpus.
if grep -qF -- "dw-beta" "$OUT"; then
  note_fail "grown-omits-the-unchanged-skill" "dw-beta was named despite not growing"
else
  note_pass "grown-omits-the-unchanged-skill"
fi

echo "a wholly new skill is growth too, and reads as new:"
fx="$(corpus "$AT_BASELINE")"
mkdir -p "$fx/skills/dw-gamma"
printf 'six\n' >"$fx/skills/dw-gamma/SKILL.md"
expect_rc "new-skill-exit-1" 1 "$(check "$fx")"
expect_says "new-skill-named-as-new" "dw-gamma: 1 (new, +1)"

echo "one word removed passes, with the nudge to re-record:"
fx="$(corpus "$AT_BASELINE")"
printf 'one two\n' >"$fx/skills/dw-alpha/SKILL.md"
expect_rc "shrunk-exit-0" 0 "$(check "$fx")"
expect_says "shrunk-nudges-a-re-record" "now smaller by 1"

echo "--update-baseline rewrites the file and passes:"
fx="$(corpus "$AT_BASELINE")"
printf 'one two three four\n' >"$fx/skills/dw-alpha/SKILL.md"
node "$CHECKER" --root "$fx" --update-baseline >"$OUT" 2>&1
expect_rc "update-exit-0" 0 "$?"
expect_says "update-reports-the-new-total" "re-recorded at 6 words"
# Re-recorded means the same tree now passes a plain run — the check that the write actually landed,
# rather than that the process said it did.
expect_rc "update-makes-the-next-run-pass" 0 "$(check "$fx")"
if grep -qF -- '"dw-alpha": 4' "$fx/scripts/skill-corpus.baseline.json"; then
  note_pass "update-rewrote-the-per-skill-entry"
else
  note_fail "update-rewrote-the-per-skill-entry" "baseline: $(tr '\n' ' ' <"$fx/scripts/skill-corpus.baseline.json")"
fi
# The $comment carries the whole rationale — a re-record that dropped it would leave the next reader a
# bare number with no way back to why it exists.
fx="$(corpus '{"$comment":"why this exists","words":5,"perSkill":{"dw-alpha":3,"dw-beta":2}}')"
node "$CHECKER" --root "$fx" --update-baseline >"$OUT" 2>&1
if grep -qF -- "why this exists" "$fx/scripts/skill-corpus.baseline.json"; then
  note_pass "update-preserves-the-comment"
else
  note_fail "update-preserves-the-comment" "the \$comment did not survive the rewrite"
fi

echo "a baseline that cannot be read is exit 2, never a silent pass:"
fx="$(corpus 'not json at all')"
expect_rc "malformed-json-exit-2" 2 "$(check "$fx")"
expect_says "malformed-json-named" "not valid JSON"

# Valid JSON, wrong shape — the failure mode a JSON.parse guard alone would wave through.
fx="$(corpus '{"words":"5"}')"
expect_rc "wrong-shape-exit-2" 2 "$(check "$fx")"
expect_says "wrong-shape-named" "malformed"

fx="$(corpus "$AT_BASELINE")"
rm "$fx/scripts/skill-corpus.baseline.json"
expect_rc "missing-baseline-exit-2" 2 "$(check "$fx")"
expect_says "missing-baseline-named" "no baseline at"

echo "the count is the one a reader can reproduce:"
# `cat skills/*/SKILL.md | wc -w` over the fixture, frontmatter and all — if these ever disagree, the
# baseline's "reproduce it with" line is a lie and the number stops being checkable by hand.
fx="$(corpus "$AT_BASELINE")"
printf -- '---\nname: dw-alpha\n---\n\none two three\n' >"$fx/skills/dw-alpha/SKILL.md"
want="$(cat "$fx"/skills/*/SKILL.md | wc -w | tr -d ' ')"
node "$CHECKER" --root "$fx" --update-baseline >"$OUT" 2>&1
if grep -qF -- "re-recorded at $want words" "$OUT"; then
  note_pass "count-matches-wc-w"
else
  note_fail "count-matches-wc-w" "wc -w says $want: $(tr '\n' '|' <"$OUT")"
fi

echo
echo "check-skill-corpus self-test: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
