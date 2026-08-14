#!/usr/bin/env bash
# Self-test for the large-file-guard.sh hook template: pins the threshold
# behaviour of the PostToolUse Write check — which sizes flag (exit 2), which
# pass (exit 0), that only Write is judged, and that CLAUDE_MAX_WRITE_BYTES
# overrides and 0 disables.
#
# Run standalone (`bash scripts/tests/large-file-guard.test.sh`) or via
# scripts/validate-artifacts.sh. Exit 0 iff every case matches. bash 3.2 safe.
set -uo pipefail
export LC_ALL=C

command -v jq >/dev/null || {
  echo "SKIP: jq missing (hooks no-op without it)"
  exit 0
}

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
HOOK="$ROOT/templates/hooks/large-file-guard.sh"

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

TMP="$(mktemp -d 2>/dev/null || mktemp -d -t largefile)"
cleanup() { rm -rf "$TMP"; }
trap cleanup EXIT

# make_file <name> <bytes>
make_file() {
  # `head -c` from /dev/zero, translated to a printable byte so the fixture is
  # not a binary blob in anything that reads it.
  head -c "$2" /dev/zero | tr '\0' 'x' >"$TMP/$1"
  printf '%s' "$TMP/$1"
}

SMALL="$(make_file small.md 1024)"                    # 1 KiB
UNDER="$(make_file under.md 262144)"                  # exactly the threshold
OVER="$(make_file over.md 300000)"                    # over it
HUGE="$(make_file huge.js 2000000)"                   # 2 MB, the real case

run() { jq -n --arg t "$1" --arg p "$2" '{tool_name:$t,tool_input:{file_path:$p}}' | bash "$HOOK" >/dev/null 2>&1; }

flagged() {
  run "$2" "$3"
  rc=$?
  if [ "$rc" -eq 2 ]; then note_pass "$1"; else note_fail "$1" "want exit 2, got $rc"; fi
}
quiet() {
  run "$2" "$3"
  rc=$?
  if [ "$rc" -eq 0 ]; then note_pass "$1"; else note_fail "$1" "want exit 0, got $rc"; fi
}

echo "the default threshold (exit 2 = flagged):"
flagged "over-threshold" Write "$OVER"
flagged "far-over-threshold" Write "$HUGE"

echo "at or under the threshold, and non-Write tools (exit 0):"
quiet "small-file" Write "$SMALL"
quiet "exactly-at-threshold" Write "$UNDER"
quiet "edit-is-not-judged" Edit "$HUGE"
quiet "multiedit-is-not-judged" MultiEdit "$HUGE"
quiet "read-is-not-judged" Read "$HUGE"
quiet "bash-is-not-judged" Bash "$HUGE"
quiet "missing-file" Write "$TMP/does-not-exist.md"
quiet "empty-path" Write ""

echo "CLAUDE_MAX_WRITE_BYTES overrides:"
(
  export CLAUDE_MAX_WRITE_BYTES=512
  run Write "$SMALL"
  rc=$?
  if [ "$rc" -eq 2 ]; then note_pass "lower-threshold-flags-small"; else note_fail "lower-threshold-flags-small" "want exit 2, got $rc"; fi
  export CLAUDE_MAX_WRITE_BYTES=5000000
  run Write "$HUGE"
  rc=$?
  if [ "$rc" -eq 0 ]; then note_pass "raised-threshold-passes-huge"; else note_fail "raised-threshold-passes-huge" "want exit 0, got $rc"; fi
  export CLAUDE_MAX_WRITE_BYTES=0
  run Write "$HUGE"
  rc=$?
  if [ "$rc" -eq 0 ]; then note_pass "zero-disables"; else note_fail "zero-disables" "want exit 0, got $rc"; fi
  # Garbage must fall back to the default, not compare against a non-number.
  export CLAUDE_MAX_WRITE_BYTES=lots
  run Write "$HUGE"
  rc=$?
  if [ "$rc" -eq 2 ]; then note_pass "non-numeric-falls-back-to-default"; else note_fail "non-numeric-falls-back-to-default" "want exit 2, got $rc"; fi
  export CLAUDE_MAX_WRITE_BYTES=""
  run Write "$SMALL"
  rc=$?
  if [ "$rc" -eq 0 ]; then note_pass "empty-falls-back-to-default"; else note_fail "empty-falls-back-to-default" "want exit 0, got $rc"; fi
  echo "$PASS $FAIL" >"$TMP/subshell-counts"
) || true
# The override cases ran in a subshell so the exports could not leak; carry their
# tally back out, or the counts printed below would silently omit five checks.
if [ -f "$TMP/subshell-counts" ]; then
  read -r PASS FAIL <"$TMP/subshell-counts"
fi

echo "the message names the file, the size and the escape hatch:"
out="$(jq -n --arg t Write --arg p "$HUGE" '{tool_name:$t,tool_input:{file_path:$p}}' | bash "$HOOK" 2>&1 >/dev/null)"
for want in "$HUGE" "2000000" "CLAUDE_MAX_WRITE_BYTES"; do
  case "$out" in
    *"$want"*) note_pass "message-names: $want" ;;
    *) note_fail "message-names: $want" "stderr was: $out" ;;
  esac
done

echo
echo "large-file-guard self-test: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
