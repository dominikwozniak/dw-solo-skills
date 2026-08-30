#!/usr/bin/env bash
# Self-test for the block-env-access.sh hook template: pins which file paths
# (Read/Edit/Write) and Bash commands the .env guardrail blocks (exit 2) vs
# allows (exit 0) — including the .env.example/.env.sample/.env.template
# allowlist and the quoted-prose pass-through.
#
# Run standalone (`bash scripts/tests/block-env-access.test.sh`) or via
# scripts/validate-artifacts.sh. Exit 0 iff every case matches. bash 3.2 safe.
set -uo pipefail
export LC_ALL=C

command -v jq >/dev/null || { echo "SKIP: jq missing (hooks no-op without it)"; exit 0; }

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
HOOK="$ROOT/templates/hooks/block-env-access.sh"

PASS=0
FAIL=0
note_pass() { PASS=$((PASS + 1)); echo "  ✓ $1"; }
note_fail() { FAIL=$((FAIL + 1)); echo "  ✗ $1 — $2"; }

run_file() { jq -n --arg t "$1" --arg p "$2" '{tool_name:$t,tool_input:{file_path:$p}}' | bash "$HOOK" >/dev/null 2>&1; }
run_bash() { jq -n --arg c "$1" '{tool_name:"Bash",tool_input:{command:$c}}' | bash "$HOOK" >/dev/null 2>&1; }

# blocked_file <name> <tool> <path> / blocked_bash <name> <command> — must exit 2.
blocked_file() {
  run_file "$2" "$3"; rc=$?
  if [ "$rc" -eq 2 ]; then note_pass "$1"; else note_fail "$1" "want exit 2, got $rc"; fi
}
blocked_bash() {
  run_bash "$2"; rc=$?
  if [ "$rc" -eq 2 ]; then note_pass "$1"; else note_fail "$1" "want exit 2, got $rc"; fi
}

# allowed_file <name> <tool> <path> / allowed_bash <name> <command> — must exit 0.
allowed_file() {
  run_file "$2" "$3"; rc=$?
  if [ "$rc" -eq 0 ]; then note_pass "$1"; else note_fail "$1" "want exit 0, got $rc"; fi
}
allowed_bash() {
  run_bash "$2"; rc=$?
  if [ "$rc" -eq 0 ]; then note_pass "$1"; else note_fail "$1" "want exit 0, got $rc"; fi
}

echo "file tools — blocked (exit 2):"
blocked_file "read-abs-env"      Read  "/app/.env"
blocked_file "read-env-local"    Read  ".env.local"
blocked_file "edit-env-prod"     Edit  "config/.env.production"
blocked_file "write-env"         Write ".env"
blocked_file "read-env-test"     Read  ".env.test"
blocked_file "read-envrc"        Read  ".envrc"

echo "file tools — allowed (exit 0):"
allowed_file "read-env-example"  Read  ".env.example"
allowed_file "read-env-sample"   Read  ".env.sample"
allowed_file "edit-env-template" Edit  ".env.template"
allowed_file "read-env-ts"       Read  "src/env.ts"
allowed_file "read-nested-ex"    Read  "config/.env.example"

echo "bash commands — blocked (exit 2):"
blocked_bash "cat-env"           "cat .env"
blocked_bash "source-env"        "source ./.env"
blocked_bash "cp-to-env"         "cp .env.example .env"
blocked_bash "append-env"        "echo FOO=1 >> .env"
blocked_bash "env-file-flag"     "docker run --env-file=.env img"
blocked_bash "cat-env-local"     "cat .env.local"

echo "bash commands — allowed (exit 0):"
allowed_bash "cat-env-example"   "cat .env.example"
allowed_bash "cat-environment"   "cat .environment"
allowed_bash "cat-foo-env"       "cat foo.env"
allowed_bash "prose-in-quotes"   'git commit -m "load .env in prod"'
allowed_bash "prose-multiline"   'git commit -m "subject
- mentions .envrc and ./.env in the body
- more prose"'
allowed_bash "plain-ls"          "ls -la"
allowed_bash "empty-input"       ""

echo "bash commands — multiline still blocked (exit 2):"
blocked_bash "multiline-cat-env" 'echo start
cat .env'

# Heredoc bodies are prose, not command tokens — a commit message piped through
# `git commit -F -` carries no quoting for the quote-strip to find. The body is
# dropped; the opener line is not, so a redirect target on it still blocks.
echo "bash commands — heredoc body dropped, opener line still checked:"
allowed_bash "heredoc-commit-quoted" "git commit -F - <<'MSG'
fix(hook): stop blocking messages that name a dotenv file

The body mentions .env and .envrc as prose.
MSG"
allowed_bash "heredoc-commit-bare" "git commit -F - <<MSG
mentions .env in the body
MSG"
blocked_bash "heredoc-redirect-target" "cat > .env <<EOF
SECRET=1
EOF"
blocked_bash "after-heredoc-cat-env" "cat <<EOF
prose mentioning .env
EOF
cat .env"

echo "the DW_GUARD_COMMAND fast path skips stdin:"
DW_GUARD_COMMAND='cat .env' bash "$HOOK" </dev/null >/dev/null 2>&1
rc=$?
if [ "$rc" -eq 2 ]; then note_pass "fast-path-blocks"; else note_fail "fast-path-blocks" "want exit 2, got $rc"; fi
DW_GUARD_COMMAND='cat .env.example' bash "$HOOK" </dev/null >/dev/null 2>&1
rc=$?
if [ "$rc" -eq 0 ]; then note_pass "fast-path-allows"; else note_fail "fast-path-allows" "want exit 0, got $rc"; fi

echo
echo "block-env-access self-test: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
