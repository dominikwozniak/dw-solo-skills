#!/usr/bin/env bash
# Self-test for check-decisions.sh: one synthetic docs/decisions/ per case, each holding the
# single defect it names. The script is the only thing standing between a consumer repo and a
# broken supersede pointer, and dw-land calls it before it writes a record — so a regression here
# is silent everywhere it matters. Fixtures are built under a temp root and thrown away.
#
# Run standalone (`bash scripts/tests/check-decisions.test.sh`) or via scripts/validate-artifacts.sh.
# Exit 0 iff every case matches. bash 3.2 / macOS + BSD safe.
set -uo pipefail
export LC_ALL=C

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
CHECK="$ROOT/scripts/runtime/check-decisions.sh"

TMP="$(mktemp -d "${TMPDIR:-/tmp}/check-decisions.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

PASS=0
FAIL=0
note_pass() { PASS=$((PASS + 1)); echo "  ✓ $1"; }
note_fail() { FAIL=$((FAIL + 1)); echo "  ✗ $1 — $2"; }

# fixture <case-name> — make an empty docs/decisions/ under a fresh root, echo the root.
fixture() {
  mkdir -p "$TMP/$1/docs/decisions"
  printf '%s\n' "$TMP/$1"
}

# record <root> <filename> <decision> <date> <status> [superseded-by]
record() {
  path="$1/docs/decisions/$2"
  {
    echo "---"
    echo "decision: $3"
    echo "date: $4"
    echo "status: $5"
    [ "$#" -ge 6 ] && echo "superseded-by: $6"
    echo "---"
    echo
    echo "# A record"
  } >"$path"
}

# expect <name> <want-exit> <want-grep|-> <root> — run the check, assert exit code and, when a
# pattern is given, that stdout matches it. `-` asserts stdout is empty instead.
expect() {
  name="$1"; want_rc="$2"; want="$3"; root="$4"
  out=$(bash "$CHECK" "$root" 2>&1); rc=$?
  if [ "$rc" -ne "$want_rc" ]; then
    note_fail "$name" "want exit $want_rc got $rc (output: ${out:-<empty>})"
    return
  fi
  if [ "$want" = "-" ]; then
    if [ -n "$out" ]; then
      note_fail "$name" "expected no output, got: $out"
    else
      note_pass "$name"
    fi
  elif printf '%s\n' "$out" | grep -qE "$want"; then
    note_pass "$name"
  else
    note_fail "$name" "output did not match /$want/: ${out:-<empty>}"
  fi
}

echo "silence (exit 0, nothing on stdout):"

r=$(fixture no-folder); rm -rf "$r/docs"
expect "missing-folder" 0 - "$r"

r=$(fixture empty)
expect "empty-folder" 0 - "$r"

r=$(fixture readme-only); echo "# Decisions" >"$r/docs/decisions/README.md"
expect "readme-skipped" 0 - "$r"

r=$(fixture clean)
record "$r" "0001-first-thing.md" 0001 2026-01-01 active
record "$r" "0002-second-thing.md" 0002 2026-02-02 superseded 0003
record "$r" "0003-third-thing.md" 0003 2026-03-03 active
echo "# Decisions" >"$r/docs/decisions/README.md"
expect "clean-folder" 0 - "$r"

# The template writes `status: active # active | superseded`; the value is what precedes the #.
r=$(fixture trailing-comment)
record "$r" "0001-with-comment.md" "0001 # the number" "2026-01-01" "active # active | superseded"
expect "trailing-comment-stripped" 0 - "$r"

echo "errors (exit 1, named by file):"

r=$(fixture bad-name); record "$r" "1-loose.md" 0001 2026-01-01 active
expect "filename-not-four-digits" 1 "1-loose\.md is not named" "$r"

r=$(fixture bad-name-case); record "$r" "0001-Not-Kebab.md" 0001 2026-01-01 active
expect "filename-not-kebab" 1 "0001-Not-Kebab\.md is not named" "$r"

r=$(fixture duplicate)
record "$r" "0001-first.md" 0001 2026-01-01 active
record "$r" "0001-again.md" 0001 2026-01-02 active
expect "duplicate-number" 1 "reuses number 0001" "$r"

r=$(fixture no-frontmatter); echo "# Just a heading" >"$r/docs/decisions/0001-bare.md"
expect "missing-frontmatter" 1 "has no frontmatter" "$r"

r=$(fixture mismatch); record "$r" "0001-off-by-one.md" 0002 2026-01-01 active
expect "decision-mismatch" 1 "declares decision: 0002" "$r"

r=$(fixture no-decision-field)
printf -- '---\ndate: 2026-01-01\nstatus: active\n---\n' >"$r/docs/decisions/0001-nodecision.md"
expect "decision-missing" 1 "declares decision: \(missing\)" "$r"

r=$(fixture bad-date); record "$r" "0001-when.md" 0001 "01/01/2026" active
expect "date-malformed" 1 "needs a date: YYYY-MM-DD" "$r"

r=$(fixture bad-status); record "$r" "0001-mood.md" 0001 2026-01-01 draft
expect "status-not-in-set" 1 'status "draft"' "$r"

r=$(fixture superseded-no-pointer); record "$r" "0001-old.md" 0001 2026-01-01 superseded
expect "superseded-without-pointer" 1 "names no superseded-by" "$r"

r=$(fixture dangling)
record "$r" "0001-old.md" 0001 2026-01-01 superseded 0007
record "$r" "0002-new.md" 0002 2026-01-02 active
expect "superseded-by-dangling" 1 "superseded-by: 0007, which does not exist" "$r"

echo "warnings (exit 0 — a gap is past tense and blocks nothing):"

r=$(fixture gap)
record "$r" "0001-first.md" 0001 2026-01-01 active
record "$r" "0003-third.md" 0003 2026-03-03 active
expect "gap-warns-not-fails" 0 "^warn: .*has 0003 where 0002 was expected" "$r"

r=$(fixture starts-late); record "$r" "0010-inherited.md" 0010 2026-01-01 active
expect "sequence-starts-late" 0 "^warn: .*has 0010 where 0001 was expected" "$r"

# Only the first gap: every later number would fail against a shifted expectation.
r=$(fixture two-gaps)
record "$r" "0001-a.md" 0001 2026-01-01 active
record "$r" "0003-c.md" 0003 2026-01-03 active
record "$r" "0005-e.md" 0005 2026-01-05 active
out=$(bash "$CHECK" "$r" 2>&1)
if [ "$(printf '%s\n' "$out" | grep -c '^warn:')" = "1" ]; then
  note_pass "only-first-gap-reported"
else
  note_fail "only-first-gap-reported" "expected exactly one warn line, got: $out"
fi

# An error and a warning together still exit non-zero — the error decides.
r=$(fixture error-plus-warning)
record "$r" "0002-late-start.md" 0002 2026-01-01 draft
expect "error-outranks-warning" 1 'status "draft"' "$r"

echo "arguments:"

# No argument at all: falls back to the repo root, whose own docs/decisions/ must be clean.
out=$(bash "$CHECK" 2>&1); rc=$?
if [ "$rc" -eq 0 ] && [ -z "$out" ]; then
  note_pass "no-arg-checks-this-repo"
else
  note_fail "no-arg-checks-this-repo" "this repo's own docs/decisions/ is not clean (exit $rc): $out"
fi

echo
echo "check-decisions self-test: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
