#!/usr/bin/env bash
# Self-test for the bash-guard.sh dispatcher — one stdin parse, guards spawned
# only when the command could trip them. What is pinned: a blocking guard's
# exit 2 and stderr propagate through the dispatcher, a passing command exits 0,
# a guard file pruned from the hooks dir is skipped rather than an error, and
# the trigger-scoping never lets a blockable command through (the dispatcher
# runs against the real sibling guards, not stubs).
#
# Run standalone (`bash scripts/tests/bash-guard.test.sh`) or via
# scripts/validate-artifacts.sh. Exit 0 iff every case matches. bash 3.2 safe.
set -uo pipefail
export LC_ALL=C

command -v jq >/dev/null || {
  echo "SKIP: jq missing (hooks no-op without it)"
  exit 0
}

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
HOOKS="$ROOT/templates/hooks"

PASS=0
FAIL=0
note_pass() { PASS=$((PASS + 1)); echo "  ✓ $1"; }
note_fail() { FAIL=$((FAIL + 1)); echo "  ✗ $1 — $2"; }

# run <command> — fire the dispatcher from the templates dir with a synthetic
# payload; echoes the exit code.
run() {
  printf '{"tool_input":{"command":%s}}' "$(printf '%s' "$1" | jq -Rs .)" |
    bash "$HOOKS/bash-guard.sh" >/dev/null 2>&1
  printf '%s\n' $?
}

expect_rc() {
  if [ "$2" = "$3" ]; then note_pass "$1"; else note_fail "$1" "want exit $2, got $3"; fi
}

echo "passing commands pass:"
expect_rc "safe-ls" 0 "$(run 'ls -la')"
expect_rc "safe-pnpm" 0 "$(run 'pnpm install')"
expect_rc "safe-git-status" 0 "$(run 'git status --short')"
expect_rc "safe-env-example" 0 "$(run 'cat .env.example')"

echo "each guard still blocks through the dispatcher:"
expect_rc "dangerous-force-push" 2 "$(run 'git push --force origin main')"
expect_rc "dangerous-rtk-wrapped" 2 "$(run 'rtk git push --force origin main')"
expect_rc "non-pnpm-npm-install" 2 "$(run 'npm install lodash')"
expect_rc "hygiene-add-A" 2 "$(run 'git add -A')"
expect_rc "credential-ssh-read" 2 "$(run 'cat ~/.ssh/id_rsa')"
expect_rc "env-cat-env" 2 "$(run 'cat .env')"

echo "the blocking stderr propagates to the caller:"
err="$(printf '{"tool_input":{"command":"npm install x"}}' | bash "$HOOKS/bash-guard.sh" 2>&1 >/dev/null)"
case "$err" in
  *BLOCKED*pnpm*) note_pass "stderr-propagates" ;;
  *) note_fail "stderr-propagates" "stderr was: $(printf '%s' "$err" | tr '\n' '|')" ;;
esac

echo "a pruned guard is a skip, not an error:"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
cp "$HOOKS/bash-guard.sh" "$WORK/"
cp "$HOOKS/block-dangerous-commands.sh" "$WORK/"
# No non-pnpm, hygiene, credential or typecheck guards in this dir.
rc="$(printf '{"tool_input":{"command":"npm install x"}}' | bash "$WORK/bash-guard.sh" >/dev/null 2>&1
  printf '%s' $?)"
expect_rc "pruned-npm-guard-skipped" 0 "$rc"
rc="$(printf '{"tool_input":{"command":"git push --force"}}' | bash "$WORK/bash-guard.sh" >/dev/null 2>&1
  printf '%s' $?)"
expect_rc "kept-guard-still-blocks" 2 "$rc"

# The command used to travel in the environment, which shares the exec size
# limit: past it every spawn died with 126 and the dispatcher allowed the call.
echo "a command too large for an argv/environ transport is still guarded:"
big="$(awk 'BEGIN { s = ""; while (length(s) < 200000) s = s "x"; print s }')"
expect_rc "huge-destructive-blocked" 2 "$(run "git push --force origin main # $big")"
expect_rc "huge-safe-passes" 0 "$(run "echo ok # $big")"

# A guard exiting non-2 is broken, not a verdict: it must not take the guards
# below it down with it.
echo "a broken guard does not disable the ones after it:"
BROKEN="$(mktemp -d)"
cp "$HOOKS/bash-guard.sh" "$HOOKS/block-dangerous-commands.sh" "$BROKEN/"
printf '#!/bin/bash\nexit 126\n' >"$BROKEN/credential-leak-guard.sh"
rc="$(printf '{"tool_input":{"command":"git push --force"}}' | bash "$BROKEN/bash-guard.sh" >/dev/null 2>&1
  printf '%s' $?)"
expect_rc "broken-guard-later-guard-still-blocks" 2 "$rc"
printf '#!/bin/bash\nexit 126\n' >"$BROKEN/block-dangerous-commands.sh"
err="$(printf '{"tool_input":{"command":"ls"}}' | bash "$BROKEN/bash-guard.sh" 2>&1 >/dev/null)"
case "$err" in
  *"exited 126"*) note_pass "broken-guard-reported-on-stderr" ;;
  *) note_fail "broken-guard-reported-on-stderr" "stderr was: $(printf '%s' "$err" | tr '\n' '|')" ;;
esac
rm -rf "$BROKEN"

echo
echo "bash-guard self-test: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
