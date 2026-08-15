#!/usr/bin/env bash
# Self-test for scripts/lint.sh: pins that the paths it is handed are the paths agnix is asked to
# check, and that the "terminated abnormally" guard still turns a silent OOM into a hard failure.
#
# The bug this locks down: the script hardcoded `agnix .`. .claude/hooks/lint-on-edit.sh resolves the
# root's `- **Lint command**:` bullet and appends the edited file as one literal argument, so every
# edit paid for a full-tree walk over the one file it named — slow, exposed to the OOM, and a silent
# lie about what AGENTS.md claims. Nothing failed; the argument was simply swallowed.
#
# agnix is stubbed rather than run: the real binary's findings are not what is under test here, the
# argv it receives is. The stub also proves the memory bump still reaches it, since dropping
# NODE_OPTIONS is exactly the kind of edit that looks harmless and re-opens the OOM.
#
# Run standalone (`bash scripts/tests/lint.test.sh`) or via scripts/validate-artifacts.sh.
# Exit 0 iff every case matches. bash 3.2 safe.
set -uo pipefail
export LC_ALL=C

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
SCRIPT="$ROOT/scripts/lint.sh"

PASS=0
FAIL=0
note_pass() { PASS=$((PASS + 1)); echo "  ✓ $1"; }
note_fail() { FAIL=$((FAIL + 1)); echo "  ✗ $1 — $2"; }

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

# fixture [stub-body] — a throwaway directory holding node_modules/.bin/agnix, the relative path
# lint.sh invokes. The stub writes one line per argument to agnix-args (so a path containing spaces
# is visibly one argument, not two), records NODE_OPTIONS, and exits FAKE_AGNIX_RC. Echoes the dir.
fixture() {
  local dir
  dir="$WORK/repo.$RANDOM$RANDOM"
  mkdir -p "$dir/node_modules/.bin"
  {
    printf '#!/bin/sh\n'
    printf 'base="$(cd "$(dirname "$0")/../.." && pwd)"\n'
    printf 'printf "%%s\\n" "$@" >"$base/agnix-args"\n'
    printf 'printf "%%s\\n" "${NODE_OPTIONS:-UNSET}" >"$base/agnix-env"\n'
    printf '%s\n' "${1:-}"
    printf 'exit "${FAKE_AGNIX_RC:-0}"\n'
  } >"$dir/node_modules/.bin/agnix"
  chmod +x "$dir/node_modules/.bin/agnix"
  printf '%s\n' "$dir"
}

# run <repo> [paths...] — invoke lint.sh from inside the fixture (it resolves agnix relatively) and
# echo its exit code. Output is captured so a case can assert on it.
OUT=""
run() {
  local dir="$1" rc
  shift
  OUT="$(cd "$dir" && bash "$SCRIPT" "$@" 2>&1)"
  rc=$?
  printf '%s\n' "$rc"
}

# expect_rc <name> <want> <got>
expect_rc() {
  if [ "$2" = "$3" ]; then note_pass "$1"; else note_fail "$1" "want exit $2, got $3"; fi
}

# expect_args <name> <repo> <want-newline-separated> — the exact argv, order included.
expect_args() {
  local got
  got="$(cat "$2/agnix-args" 2>/dev/null)"
  if [ "$got" = "$3" ]; then
    note_pass "$1"
  else
    note_fail "$1" "want [$(printf '%s' "$3" | tr '\n' '|')], got [$(printf '%s' "$got" | tr '\n' '|')]"
  fi
}

echo "no arguments still walks the whole tree:"
repo="$(fixture)"
expect_rc "bare-exit-0" 0 "$(run "$repo")"
expect_args "bare-walks-the-dot" "$repo" "."

echo "a path is forwarded instead of being swallowed (the regression):"
repo="$(fixture)"
expect_rc "one-path-exit-0" 0 "$(run "$repo" "skills/dw-next/SKILL.md")"
expect_args "one-path-forwarded" "$repo" "skills/dw-next/SKILL.md"

echo "several paths are all forwarded, and the default dot is NOT appended:"
# A `.` sneaking in alongside would restore the full walk while looking scoped.
repo="$(fixture)"
expect_rc "two-paths-exit-0" 0 "$(run "$repo" "AGENTS.md" "skills/dw-shape/SKILL.md")"
expect_args "two-paths-forwarded" "$repo" "AGENTS.md
skills/dw-shape/SKILL.md"

echo "a path containing spaces stays one argument:"
repo="$(fixture)"
expect_rc "spaced-path-exit-0" 0 "$(run "$repo" "skills/two words/SKILL.md")"
expect_args "spaced-path-not-split" "$repo" "skills/two words/SKILL.md"

echo "the memory bump still reaches agnix:"
repo="$(fixture)"
run "$repo" >/dev/null
if grep -q -- "--max-old-space-size=8192" "$repo/agnix-env" 2>/dev/null; then
  note_pass "node-options-passed-through"
else
  note_fail "node-options-passed-through" "NODE_OPTIONS was $(cat "$repo/agnix-env" 2>/dev/null)"
fi

echo "agnix's exit code is the script's exit code:"
repo="$(fixture)"
expect_rc "failing-agnix-propagates" 1 "$(FAKE_AGNIX_RC=1 run "$repo" "AGENTS.md")"

echo "a scoped run still hard-errors on an abnormal termination:"
# The OOM prints this and exits 0, so without the guard a lint that never ran reads as a clean pass.
# It has to hold for a pathed call too, not just the bare one.
repo="$(fixture 'echo "agnix terminated abnormally"')"
expect_rc "abnormal-bare-exit-1" 1 "$(run "$repo")"
repo="$(fixture 'echo "agnix terminated abnormally"')"
expect_rc "abnormal-with-path-exit-1" 1 "$(run "$repo" "AGENTS.md")"

echo "agnix's own output still reaches the caller:"
repo="$(fixture 'echo "Found 0 errors, 3 warnings"')"
run "$repo" "AGENTS.md" >/dev/null
case "$OUT" in
  *"Found 0 errors, 3 warnings"*) note_pass "output-passed-through" ;;
  *) note_fail "output-passed-through" "output was [$OUT]" ;;
esac

echo
echo "lint self-test: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
