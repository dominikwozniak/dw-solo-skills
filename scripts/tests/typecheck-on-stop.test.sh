#!/usr/bin/env bash
# Self-test for the typecheck-on-stop.sh hook template — its first, and the reason it needed one:
# the extractor used `\s` inside `grep -E`/`sed -E`, which BSD (macOS) does not implement, and the
# honest value a Node-without-TS repo writes — `none` — was neither a command nor a placeholder, so
# it was `eval`ed at the end of every turn and failed.
#
# What is pinned here: the resolution chain (tracked AGENTS.md first, legacy CLAUDE.local.md second),
# that `none` STOPS the chain rather than merely missing, that the changed-files gate comes before
# any resolution at all, and the exit-code contract (2 + stderr so the model self-corrects).
#
# Not pinned: the package.json `scripts.typecheck` and `tsc --noEmit` probes at the end of the chain.
# Reaching them requires a working pnpm/npm/npx in the sandbox, which would make this test's verdict
# depend on the machine rather than on the hook.
#
# Run standalone (`bash scripts/tests/typecheck-on-stop.test.sh`) or via scripts/validate-artifacts.sh.
# Exit 0 iff every case matches. bash 3.2 safe.
set -uo pipefail
export LC_ALL=C

command -v jq >/dev/null || { echo "SKIP: jq missing (hooks no-op without it)"; exit 0; }

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
HOOK="$ROOT/templates/hooks/typecheck-on-stop.sh"

PASS=0
FAIL=0
note_pass() { PASS=$((PASS + 1)); echo "  ✓ $1"; }
note_fail() { FAIL=$((FAIL + 1)); echo "  ✗ $1 — $2"; }

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

# fixture <agents-line> <local-line> [no-ts] — a throwaway git repo holding an AGENTS.md and/or a
# CLAUDE.local.md with the given line (the empty string means "no such file at all"), a fake
# typechecker that leaves a sentinel behind when it runs, and — unless a third argument is passed —
# an untracked changed.ts so the hook's changed-files gate opens. Echoes the repo path.
fixture() {
  local dir
  dir="$WORK/repo.$RANDOM$RANDOM"
  mkdir -p "$dir"
  git -C "$dir" init --quiet
  if [ -n "${1:-}" ]; then
    printf '# Fixture — agent rules\n\n## Solo lane\n\n%s\n' "$1" >"$dir/AGENTS.md"
  fi
  if [ -n "${2:-}" ]; then
    printf '## Project specifics\n\n%s\n' "$2" >"$dir/CLAUDE.local.md"
  fi
  printf '#!/bin/sh\nprintf "%%s\\n" "${TC_TAG:-ran}" >>"$(dirname "$0")/tc-ran"\nexit "${FAKE_TC_RC:-0}"\n' \
    >"$dir/fake-tc.sh"
  chmod +x "$dir/fake-tc.sh"
  [ -n "${3:-}" ] || printf 'export const x = 1\n' >"$dir/changed.ts"
  printf '%s\n' "$dir"
}

# run <repo> — fire the Stop hook from inside the repo and echo its exit code.
run() {
  local rc
  (cd "$1" && bash "$HOOK" >/dev/null 2>&1)
  rc=$?
  printf '%s\n' "$rc"
}

# expect_rc <name> <want> <got>
expect_rc() {
  if [ "$2" = "$3" ]; then note_pass "$1"; else note_fail "$1" "want exit $2, got $3"; fi
}

# ran <name> <repo> / never_ran <name> <repo> — did the fake typechecker record a call?
ran() {
  if [ -f "$2/tc-ran" ]; then note_pass "$1"; else note_fail "$1" "fake typechecker was never called"; fi
}
never_ran() {
  if [ -f "$2/tc-ran" ]; then
    note_fail "$1" "fake typechecker ran: $(tr '\n' ' ' <"$2/tc-ran")"
  else
    note_pass "$1"
  fi
}

echo "the changed-files gate comes first:"
repo="$(fixture '- **Typecheck command**: `./fake-tc.sh`' '' "no-ts")"
expect_rc "no-ts-changed-exit-0" 0 "$(run "$repo")"
never_ran "no-ts-changed-nothing-run" "$repo"

echo "AGENTS.md is the tracked source:"
repo="$(fixture '- **Typecheck command**: `./fake-tc.sh`' '')"
expect_rc "agents-exit-0" 0 "$(run "$repo")"
ran "agents-invoked" "$repo"

echo "resolves an un-backticked command (freshly rendered style):"
repo="$(fixture '- **Typecheck command**: ./fake-tc.sh' '')"
expect_rc "bare-exit-0" 0 "$(run "$repo")"
ran "bare-invoked" "$repo"

echo "a failing typecheck becomes exit 2 so the model self-corrects:"
repo="$(fixture '- **Typecheck command**: `env FAKE_TC_RC=1 ./fake-tc.sh`' '')"
expect_rc "failing-exit-2" 2 "$(run "$repo")"

echo "AGENTS.md wins over a legacy CLAUDE.local.md:"
repo="$(fixture '- **Typecheck command**: `env TC_TAG=agents ./fake-tc.sh`' '- **Typecheck command**: `env TC_TAG=local ./fake-tc.sh`')"
expect_rc "precedence-exit-0" 0 "$(run "$repo")"
if grep -qx "agents" "$repo/tc-ran" && ! grep -qx "local" "$repo/tc-ran"; then
  note_pass "precedence-agents-first"
else
  note_fail "precedence-agents-first" "tags: $(tr '\n' ' ' <"$repo/tc-ran")"
fi

echo "legacy fallback — CLAUDE.local.md still read when AGENTS.md cannot answer:"
repo="$(fixture '' '- **Typecheck command**: `./fake-tc.sh`')"
expect_rc "legacy-only-exit-0" 0 "$(run "$repo")"
ran "legacy-only-invoked" "$repo"

repo="$(fixture '- **Stack**: nothing to see here' '- **Typecheck command**: `./fake-tc.sh`')"
expect_rc "legacy-agents-silent-exit-0" 0 "$(run "$repo")"
ran "legacy-agents-silent-invoked" "$repo"

repo="$(fixture '- **Typecheck command**: {{TYPECHECK_COMMAND}}' '- **Typecheck command**: `./fake-tc.sh`')"
expect_rc "legacy-agents-placeholder-exit-0" 0 "$(run "$repo")"
ran "legacy-agents-placeholder-invoked" "$repo"

echo "\`none\` is a declaration, and it STOPS the chain:"
# The legacy line would run if `none` merely "found nothing" — so this proves the stop, not a miss.
repo="$(fixture '- **Typecheck command**: none' '- **Typecheck command**: `./fake-tc.sh`')"
expect_rc "none-exit-0" 0 "$(run "$repo")"
never_ran "none-stops-the-chain" "$repo"

repo="$(fixture '- **Typecheck command**: `none`' '- **Typecheck command**: `./fake-tc.sh`')"
expect_rc "none-backticked-exit-0" 0 "$(run "$repo")"
never_ran "none-backticked-stops-the-chain" "$repo"

repo="$(fixture '- **Typecheck command**: NONE' '- **Typecheck command**: `./fake-tc.sh`')"
expect_rc "none-uppercase-exit-0" 0 "$(run "$repo")"
never_ran "none-uppercase-stops-the-chain" "$repo"

# The sentinel is tested on the RAW remainder, before any backtick extraction. Taking the first
# backticked span first made an honest `none` followed by explanatory prose resolve to whatever path
# that prose happened to quote — and eval it at the end of every turn.
repo="$(fixture '- **Typecheck command**: none — the `./fake-tc.sh` types are stripped by Node' '')"
expect_rc "none-with-explanatory-backticks-exit-0" 0 "$(run "$repo")"
never_ran "none-beats-explanatory-backticks" "$repo"

# ...but only as a standalone word.
repo="$(fixture '- **Typecheck command**: `env TC_TAG=nonstop ./fake-tc.sh`' '')"
expect_rc "none-prefixed-command-still-runs-exit-0" 0 "$(run "$repo")"
ran "none-is-not-a-prefix-match" "$repo"

echo "a blank value falls through instead of \`eval\`ing whitespace:"
repo="$(fixture '- **Typecheck command**:' '- **Typecheck command**: `./fake-tc.sh`')"
expect_rc "empty-value-exit-0" 0 "$(run "$repo")"
ran "empty-value-falls-through" "$repo"

echo "CLAUDE_SKIP_TYPECHECK short-circuits everything:"
repo="$(fixture '- **Typecheck command**: `env FAKE_TC_RC=1 ./fake-tc.sh`' '')"
(cd "$repo" && CLAUDE_SKIP_TYPECHECK=1 bash "$HOOK" >/dev/null 2>&1)
expect_rc "skip-env-exit-0" 0 "$?"
never_ran "skip-env-nothing-run" "$repo"

echo "the failure message names the command, on stderr:"
repo="$(fixture '- **Typecheck command**: `env FAKE_TC_RC=1 ./fake-tc.sh`' '')"
err="$(cd "$repo" && bash "$HOOK" 2>&1 >/dev/null)"
case "$err" in
  *"Typecheck failed"*fake-tc.sh*) note_pass "failure-message-on-stderr" ;;
  *) note_fail "failure-message-on-stderr" "stderr was: $(printf '%s' "$err" | tr '\n' '|')" ;;
esac

echo
echo "typecheck-on-stop self-test: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
