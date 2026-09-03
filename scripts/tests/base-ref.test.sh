#!/usr/bin/env bash
# Self-test for base-ref.sh: pins which ref of the default branch a diff is taken against —
# local by default, `origin/` only when it strictly contains local or local does not exist,
# the fetch never blocking, and a refusal when neither ref is there to print.
#
# Run standalone (`bash scripts/tests/base-ref.test.sh`) or via scripts/validate-artifacts.sh.
# Exit 0 iff every case passes. bash 3.2 / macOS + BSD safe.
set -uo pipefail
export LC_ALL=C

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
BASEREF="$ROOT/scripts/runtime/base-ref.sh"

PASS=0
FAIL=0
note_pass() { PASS=$((PASS + 1)); echo "  ✓ $1"; }
note_fail() { FAIL=$((FAIL + 1)); echo "  ✗ $1 — $2"; }

TMP="$(mktemp -d)"
trap 'cd / && rm -rf "$TMP"' EXIT

# expect <name> <want> <dir> [args...] — run base-ref.sh in <dir>, compare stdout to <want>.
expect() {
  local name="$1" want="$2" dir="$3"
  shift 3
  local got rc
  got="$(cd "$dir" && "$BASEREF" "$@" 2>/dev/null)"
  rc=$?
  if [ "$rc" -eq 0 ] && [ "$got" = "$want" ]; then
    note_pass "$name"
  else
    note_fail "$name" "rc=$rc got='$got' want='$want'"
  fi
}

# commit_in <dir> <file> <msg> — one commit, quiet. The message goes in by file rather than -m so
# this test's own text never reads as a commit this repo's hygiene hook should judge.
commit_in() {
  (cd "$1" && echo "$3" >>"$2" && git add "$2" && printf '%s\n' "$3" | git commit -q -F -)
}

# A bare origin and a clone of it, one commit on main, pushed. `git clone` sets origin/HEAD, which
# is what the no-argument form reads.
ORIGIN="$TMP/origin.git"
git init -q --bare -b main "$ORIGIN"
SEED="$TMP/seed"
git init -q -b main "$SEED"
git -C "$SEED" config user.email "test@test"
git -C "$SEED" config user.name "test"
commit_in "$SEED" file.txt "init"
git -C "$SEED" remote add origin "$ORIGIN"
git -C "$SEED" push -q -u origin main
REPO="$TMP/repo"
git clone -q "$ORIGIN" "$REPO"
git -C "$REPO" config user.email "test@test"
git -C "$REPO" config user.name "test"

echo "with an origin:"
expect "in-sync-prefers-origin" "origin/main" "$REPO"
expect "explicit-branch-arg-honoured" "origin/main" "$REPO" main

# origin moves on: someone else pushed — origin now strictly contains local.
commit_in "$SEED" file.txt "upstream-two"
git -C "$SEED" push -q origin main
expect "origin-ahead-prefers-origin" "origin/main" "$REPO"

# local moves on without pushing — origin no longer contains local, so local wins.
git -C "$REPO" pull -q --rebase origin main
commit_in "$REPO" file.txt "local-three"
expect "local-ahead-prefers-local" "main" "$REPO"

# diverged: both moved. Local is the default.
commit_in "$SEED" other.txt "upstream-four"
git -C "$SEED" push -q origin main
expect "diverged-prefers-local" "main" "$REPO"

# stdout is one line and nothing else — callers splice it into a diff command.
lines="$(cd "$REPO" && "$BASEREF" 2>/dev/null | wc -l | tr -d ' ')"
if [ "$lines" = "1" ]; then
  note_pass "stdout-is-one-line"
else
  note_fail "stdout-is-one-line" "got $lines lines"
fi

echo "without a local copy:"
# A clone that checked out a feature branch only: no refs/heads/main, origin/main present.
FEATURE="$TMP/feature"
git clone -q --branch main --single-branch "$ORIGIN" "$FEATURE"
git -C "$FEATURE" switch -q -c topic
git -C "$FEATURE" branch -q -D main
expect "no-local-falls-to-origin" "origin/main" "$FEATURE"

echo "without an origin:"
LOCAL="$TMP/local"
git init -q -b main "$LOCAL"
git -C "$LOCAL" config user.email "test@test"
git -C "$LOCAL" config user.name "test"
commit_in "$LOCAL" file.txt "init"
expect "no-origin-prints-local" "main" "$LOCAL"

TRUNK="$TMP/trunk"
git init -q -b trunk "$TRUNK"
git -C "$TRUNK" config user.email "test@test"
git -C "$TRUNK" config user.name "test"
commit_in "$TRUNK" file.txt "init"
expect "no-origin-explicit-branch" "trunk" "$TRUNK" trunk

echo "refusals and degraded origins:"
if (cd "$LOCAL" && "$BASEREF" nope >/dev/null 2>&1); then
  note_fail "neither-ref-refused" "expected non-zero exit"
else
  note_pass "neither-ref-refused"
fi
err="$(cd "$LOCAL" && "$BASEREF" nope 2>&1 >/dev/null)"
case "$err" in
  *"neither 'nope' nor 'origin/nope'"*) note_pass "neither-ref-names-both" ;;
  *) note_fail "neither-ref-names-both" "stderr='$err'" ;;
esac

# An origin that cannot be reached must not block: the fetch fails silently and the last fetched
# state decides. `file://` to a path that does not exist fails fast without any prompt.
git -C "$REPO" remote set-url origin "file://$TMP/does-not-exist.git"
expect "unreachable-origin-still-prints" "main" "$REPO"

echo
echo "base-ref.test.sh: $PASS passed / $FAIL failed"
[ "$FAIL" -eq 0 ]
