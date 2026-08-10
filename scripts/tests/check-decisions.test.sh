#!/usr/bin/env bash
# Self-test for check-decisions.sh: one synthetic docs/decisions/ per case, each holding the
# single defect it names. The script is the only thing standing between a consumer repo and a
# broken supersede pointer, and dw-land calls it before it writes a record — so a regression here
# is silent everywhere it matters. Fixtures are built under a temp root and thrown away.
#
# Every case pins the EXACT number of finding lines, not just that an expected one appears, and
# asserts stderr stayed empty. That strictness is the point: an earlier substring-matching version
# of this file passed 20 green cases while the script emitted two fabricated findings alongside
# each real one — extra output is precisely the failure mode a "did the expected line show up?"
# assertion cannot see.
#
# Run standalone (`bash scripts/tests/check-decisions.test.sh`) or via scripts/validate-artifacts.sh.
# Exit 0 iff every case matches. bash 3.2 / macOS + BSD safe.
set -uo pipefail
export LC_ALL=C

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
CHECK="$ROOT/scripts/runtime/check-decisions.sh"

TMP="$(mktemp -d "${TMPDIR:-/tmp}/check-decisions.XXXXXX")"
cleanup() {
  chmod -R u+rwx "$TMP" 2>/dev/null
  rm -rf "$TMP"
}
trap cleanup EXIT

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

# expect <name> <want-exit> <want-line-count> <want-grep|-> <root>
# Asserts all four at once: the exit code, that findings go to STDOUT and nothing to stderr, the
# exact number of finding lines, and — unless '-' — that one of them matches the pattern.
expect() {
  name="$1"; want_rc="$2"; want_lines="$3"; want="$4"; root="$5"

  errfile="$TMP/stderr.out"
  out=$(bash "$CHECK" "$root" 2>"$errfile"); rc=$?
  errout=$(cat "$errfile" 2>/dev/null)
  rm -f "$errfile"

  if [ -z "$out" ]; then lines=0; else lines=$(printf '%s\n' "$out" | grep -c ''); fi

  if [ -n "$errout" ]; then
    note_fail "$name" "findings must go to stdout; stderr had: $errout"
  elif [ "$rc" -ne "$want_rc" ]; then
    note_fail "$name" "want exit $want_rc got $rc (output: ${out:-<empty>})"
  elif [ "$lines" -ne "$want_lines" ]; then
    note_fail "$name" "want $want_lines finding line(s), got $lines: ${out:-<empty>}"
  elif [ "$want" != "-" ] && ! printf '%s\n' "$out" | grep -qE "$want"; then
    note_fail "$name" "output did not match /$want/: ${out:-<empty>}"
  else
    note_pass "$name"
  fi
}

echo "silence (exit 0, nothing on stdout):"

r=$(fixture no-folder); rm -rf "$r/docs"
expect "missing-folder" 0 0 - "$r"

r=$(fixture empty)
expect "empty-folder" 0 0 - "$r"

r=$(fixture readme-only); echo "# Decisions" >"$r/docs/decisions/README.md"
expect "readme-skipped" 0 0 - "$r"

r=$(fixture clean)
record "$r" "0001-first-thing.md" 0001 2026-01-01 active
record "$r" "0002-second-thing.md" 0002 2026-02-02 superseded 0003
record "$r" "0003-third-thing.md" 0003 2026-03-03 active
echo "# Decisions" >"$r/docs/decisions/README.md"
expect "clean-folder" 0 0 - "$r"

# The template writes `status: active # active | superseded`; the value is what precedes the #.
r=$(fixture trailing-comment)
record "$r" "0001-with-comment.md" "0001 # the number" "2026-01-01" "active # active | superseded"
expect "trailing-comment-stripped" 0 0 - "$r"

# A CRLF record is well-formed; only the line endings differ. Matching `---\r` against `---`
# would call it frontmatter-less and blame the wrong thing.
r=$(fixture crlf)
printf -- '---\r\ndecision: 0001\r\ndate: 2026-01-01\r\nstatus: active\r\n---\r\n\r\n# A\r\n' \
  >"$r/docs/decisions/0001-crlf.md"
expect "crlf-record-accepted" 0 0 - "$r"

echo "errors (exit 1, named by file):"

r=$(fixture bad-name); record "$r" "1-loose.md" 0001 2026-01-01 active
expect "filename-not-four-digits" 1 1 "1-loose\.md is not named" "$r"

r=$(fixture bad-name-case); record "$r" "0001-Not-Kebab.md" 0001 2026-01-01 active
expect "filename-not-kebab" 1 1 "0001-Not-Kebab\.md is not named" "$r"

r=$(fixture duplicate)
record "$r" "0001-first.md" 0001 2026-01-01 active
record "$r" "0001-again.md" 0001 2026-01-02 active
expect "duplicate-number" 1 1 "reuses number 0001" "$r"

r=$(fixture no-frontmatter); echo "# Just a heading" >"$r/docs/decisions/0001-bare.md"
expect "missing-frontmatter" 1 1 "has no frontmatter" "$r"

r=$(fixture mismatch); record "$r" "0001-off-by-one.md" 0002 2026-01-01 active
expect "decision-mismatch" 1 1 "declares decision: 0002" "$r"

r=$(fixture no-decision-field)
printf -- '---\ndate: 2026-01-01\nstatus: active\n---\n' >"$r/docs/decisions/0001-nodecision.md"
expect "decision-missing" 1 1 "declares decision: \(missing\)" "$r"

r=$(fixture bad-date); record "$r" "0001-when.md" 0001 "01/01/2026" active
expect "date-malformed" 1 1 "needs a date: YYYY-MM-DD" "$r"

r=$(fixture bad-status); record "$r" "0001-mood.md" 0001 2026-01-01 draft
expect "status-not-in-set" 1 1 'status "draft"' "$r"

r=$(fixture superseded-no-pointer); record "$r" "0001-old.md" 0001 2026-01-01 superseded
expect "superseded-without-pointer" 1 1 "names no superseded-by" "$r"

r=$(fixture dangling)
record "$r" "0001-old.md" 0001 2026-01-01 superseded 0007
record "$r" "0002-new.md" 0002 2026-01-02 active
expect "superseded-by-dangling" 1 1 "superseded-by: 0007, which does not exist" "$r"

echo "one defect yields one finding (no cascades):"

# A record whose CONTENTS are unreadable still occupies its number — the file is right there.
# Registering it late made this fixture report a phantom missing 0002 and a phantom dangling
# pointer on top of the one real error.
r=$(fixture cascade-frontmatter)
record "$r" "0001-a.md" 0001 2026-01-01 active
echo "# no frontmatter" >"$r/docs/decisions/0002-b.md"
record "$r" "0003-c.md" 0003 2026-01-03 superseded 0002
expect "malformed-body-still-holds-its-number" 1 1 "0002-b\.md has no frontmatter" "$r"

# Same for a record whose NAME is wrong past the number: 0002-Bad-Slug.md is a badly named 0002,
# not a missing one.
r=$(fixture cascade-filename)
record "$r" "0001-a.md" 0001 2026-01-01 active
record "$r" "0002-Bad-Slug.md" 0002 2026-01-02 active
record "$r" "0003-c.md" 0003 2026-01-03 superseded 0002
expect "bad-slug-still-holds-its-number" 1 1 "0002-Bad-Slug\.md is not named" "$r"

echo "warnings (exit 0 — a gap is past tense and blocks nothing):"

r=$(fixture gap)
record "$r" "0001-first.md" 0001 2026-01-01 active
record "$r" "0003-third.md" 0003 2026-03-03 active
expect "gap-warns-not-fails" 0 1 "^warn: .*has 0003 where 0002 was expected" "$r"

r=$(fixture starts-late); record "$r" "0010-inherited.md" 0010 2026-01-01 active
expect "sequence-starts-late" 0 1 "^warn: .*has 0010 where 0001 was expected" "$r"

# Only the first gap: every later number would fail against a shifted expectation. The line count
# is the assertion, and exit 0 is asserted with it — a warning that blocked dw-land would defeat
# the whole reason contiguity is a warning.
r=$(fixture two-gaps)
record "$r" "0001-a.md" 0001 2026-01-01 active
record "$r" "0003-c.md" 0003 2026-01-03 active
record "$r" "0005-e.md" 0005 2026-01-05 active
expect "only-first-gap-reported" 0 1 "^warn: .*has 0003 where 0002 was expected" "$r"

# An error and a warning together still exit non-zero — the error decides.
r=$(fixture error-plus-warning)
record "$r" "0002-late-start.md" 0002 2026-01-01 draft
expect "error-outranks-warning" 1 2 'status "draft"' "$r"

echo "the folder itself:"

# An unlistable directory is not an empty one. Skip as root, where the permission does not bite.
if [ "$(id -u)" = "0" ]; then
  echo "  – unreadable-folder (skipped: running as root)"
else
  r=$(fixture unreadable)
  chmod 000 "$r/docs/decisions"
  expect "unreadable-folder-is-an-error" 1 1 "cannot be listed" "$r"
  chmod 755 "$r/docs/decisions"

  r=$(fixture unreadable-record)
  record "$r" "0001-locked.md" 0001 2026-01-01 active
  chmod 000 "$r/docs/decisions/0001-locked.md"
  expect "unreadable-record-is-an-error" 1 1 "cannot be read" "$r"
  chmod 644 "$r/docs/decisions/0001-locked.md"
fi

echo "arguments:"

# No argument at all: falls back to `git rev-parse --show-toplevel`, so a call from a SUBDIRECTORY
# still reads the root's docs/decisions/ and not the cwd's. A synthetic repo, deliberately: an
# earlier version ran this against the repo the test itself lives in, which quietly made a unit
# test the gate on live content — and a strictly-silent one, so a `warn:` gap would have failed it
# even though the script exits 0 for exactly that reason. scripts/validate-artifacts.sh owns the
# dogfood pass over this repo's own records, with the warn/error split intact.
r="$(fixture noarg)"
git init -q -b main "$r"
record "$r" "0001-first.md" "0001" "2026-01-01" "active"
record "$r" "0001-second.md" "0001" "2026-01-02" "active"
mkdir -p "$r/nested/deeper"
errfile="$TMP/stderr.noarg"
out=$(cd "$r/nested/deeper" && bash "$CHECK" 2>"$errfile"); rc=$?
errout=$(cat "$errfile" 2>/dev/null)
rm -f "$errfile"
lines=0
[ -n "$out" ] && lines=$(printf '%s\n' "$out" | wc -l | tr -d ' ')
if [ "$rc" -eq 1 ] && [ "$lines" -eq 1 ] && [ -z "$errout" ] && printf '%s' "$out" | grep -q "reuses number 0001"; then
  note_pass "no-arg-resolves-the-repo-root-from-a-subdirectory"
else
  note_fail "no-arg-resolves-the-repo-root-from-a-subdirectory" "exit $rc, $lines line(s): $out$errout"
fi

echo
echo "check-decisions self-test: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
