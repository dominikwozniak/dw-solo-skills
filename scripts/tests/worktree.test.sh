#!/usr/bin/env bash
# Self-test for worktree.sh: pins the create/remove contract in a throwaway repo — worktree at
# .claude/worktrees/<slug> on branch <slug>, stdout carrying only the path, the never-nest and
# dirty-worktree refusals, and remove resolving the branch from porcelain (so a `claude
# --worktree` worktree named worktree-<slug> tears down just as cleanly).
#
# Run standalone (`bash scripts/tests/worktree.test.sh`) or via scripts/validate-artifacts.sh.
# Exit 0 iff every case passes. bash 3.2 / macOS + BSD safe.
set -uo pipefail
export LC_ALL=C

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
WORKTREE="$ROOT/scripts/runtime/worktree.sh"

PASS=0
FAIL=0
note_pass() { PASS=$((PASS + 1)); echo "  ✓ $1"; }
note_fail() { FAIL=$((FAIL + 1)); echo "  ✗ $1 — $2"; }

TMP="$(mktemp -d)"
trap 'cd / && rm -rf "$TMP"' EXIT

# Throwaway repo with one commit — worktree add checks out committed state only.
REPO="$TMP/repo"
mkdir -p "$REPO"
cd "$REPO"
# macOS mktemp hands out a /var/folders/... symlink; the script prints physical paths.
REPO="$(pwd -P)"
git init -q -b main
git config user.email "test@test"
git config user.name "test"
echo one >file.txt
git add file.txt
git commit -qm "init"
BASE_SHA="$(git rev-parse HEAD)"
echo two >>file.txt
git add file.txt
git commit -qm "second"

echo "create:"
out=$("$WORKTREE" create alpha 2>/dev/null)
rc=$?
if [ "$rc" -eq 0 ] && [ "$out" = "$REPO/.claude/worktrees/alpha" ] && [ -d "$out" ]; then
  note_pass "create-ok (path on stdout, dir exists)"
else
  note_fail "create-ok" "rc=$rc out='$out'"
fi

got_branch="$(cd "$REPO/.claude/worktrees/alpha" && git rev-parse --abbrev-ref HEAD)"
if [ "$got_branch" = "alpha" ]; then
  note_pass "create-branch-checked-out"
else
  note_fail "create-branch-checked-out" "got '$got_branch'"
fi

if "$WORKTREE" create alpha >/dev/null 2>&1; then
  note_fail "create-duplicate-refused" "expected non-zero exit"
else
  note_pass "create-duplicate-refused"
fi

if (cd "$REPO/.claude/worktrees/alpha" && "$WORKTREE" create nested >/dev/null 2>&1); then
  note_fail "create-nested-refused" "expected non-zero exit"
else
  note_pass "create-nested-refused"
fi

"$WORKTREE" create beta "$BASE_SHA" >/dev/null 2>&1
beta_sha="$(cd "$REPO/.claude/worktrees/beta" && git rev-parse HEAD)"
if [ "$beta_sha" = "$BASE_SHA" ]; then
  note_pass "create-custom-base"
else
  note_fail "create-custom-base" "want $BASE_SHA got $beta_sha"
fi

echo "remove:"
if (cd "$REPO/.claude/worktrees/alpha" && "$WORKTREE" remove alpha >/dev/null 2>&1); then
  note_fail "remove-from-inside-refused" "expected non-zero exit"
else
  note_pass "remove-from-inside-refused"
fi

echo dirty >>"$REPO/.claude/worktrees/alpha/file.txt"
if "$WORKTREE" remove alpha >/dev/null 2>&1; then
  note_fail "remove-dirty-refused" "expected non-zero exit"
elif [ -d "$REPO/.claude/worktrees/alpha" ]; then
  note_pass "remove-dirty-refused (worktree kept)"
else
  note_fail "remove-dirty-refused" "worktree is gone despite refusal"
fi

git -C "$REPO/.claude/worktrees/alpha" checkout -q -- file.txt
if "$WORKTREE" remove alpha >/dev/null 2>&1 &&
  ! git -C "$REPO" worktree list | grep -q "worktrees/alpha" &&
  ! git -C "$REPO" show-ref --verify --quiet refs/heads/alpha; then
  note_pass "remove-ok (worktree and branch gone)"
else
  note_fail "remove-ok" "worktree or branch survived"
fi

if "$WORKTREE" remove alpha >/dev/null 2>&1; then
  note_fail "remove-missing-refused" "expected non-zero exit"
else
  note_pass "remove-missing-refused"
fi

# The `claude --worktree` spelling: dir gamma, branch worktree-gamma — remove must resolve the
# branch from porcelain rather than assume it equals the slug.
git -C "$REPO" worktree add -b worktree-gamma "$REPO/.claude/worktrees/gamma" >/dev/null 2>&1
if "$WORKTREE" remove gamma >/dev/null 2>&1 &&
  ! git -C "$REPO" show-ref --verify --quiet refs/heads/worktree-gamma; then
  note_pass "remove-claude-w-spelling (branch worktree-gamma gone)"
else
  note_fail "remove-claude-w-spelling" "branch worktree-gamma survived"
fi

echo "errors (expect non-zero exit):"
if "$WORKTREE" bogus >/dev/null 2>&1; then note_fail "unknown-subcmd" "expected non-zero"; else note_pass "unknown-subcmd"; fi
if "$WORKTREE" >/dev/null 2>&1; then note_fail "no-subcmd" "expected non-zero"; else note_pass "no-subcmd"; fi
if "$WORKTREE" create >/dev/null 2>&1; then note_fail "create-no-slug" "expected non-zero"; else note_pass "create-no-slug"; fi

echo
echo "worktree self-test: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
