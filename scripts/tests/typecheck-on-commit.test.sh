#!/usr/bin/env bash
# Self-test for the typecheck-on-commit.sh hook template. What is pinned: only
# a real `git … commit` triggers it (wrapper spellings included, prose mentions
# excluded), the staged-TS gate comes before any resolution (`-a` widens it to
# tracked modifications), the resolver chain (tracked AGENTS.md over the legacy
# CLAUDE.local.md, placeholder and blank values fall through, `none` stops the
# chain even trailed by explanatory backticks), the --bash-command fast path,
# and a failing typecheck refusing the commit with exit 2 + stderr.
#
# Run standalone (`bash scripts/tests/typecheck-on-commit.test.sh`) or via
# scripts/validate-artifacts.sh. Exit 0 iff every case matches. bash 3.2 safe.
set -uo pipefail
export LC_ALL=C

command -v jq >/dev/null || {
  echo "SKIP: jq missing (hooks no-op without it)"
  exit 0
}

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
HOOK="$ROOT/templates/hooks/typecheck-on-commit.sh"

PASS=0
FAIL=0
note_pass() { PASS=$((PASS + 1)); echo "  ✓ $1"; }
note_fail() { FAIL=$((FAIL + 1)); echo "  ✗ $1 — $2"; }

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

# fixture [staged-file] [modify-tracked] — a throwaway git repo with a fake
# typechecker behind the declared bullet. Optionally stages a file; optionally
# leaves a tracked .ts modified but unstaged (the -a case). Echoes the path.
fixture() {
  local dir
  dir="$WORK/repo.$RANDOM$RANDOM"
  mkdir -p "$dir"
  git -C "$dir" init --quiet
  printf '# Fixture\n\n## Solo lane\n\n- **Typecheck command**: `./fake-tc.sh`\n' >"$dir/AGENTS.md"
  printf '#!/bin/sh\n: >"$(dirname "$0")/tc-ran"\nexit "${FAKE_TC_RC:-0}"\n' >"$dir/fake-tc.sh"
  chmod +x "$dir/fake-tc.sh"
  if [ -n "${1:-}" ]; then
    printf 'export const x = 1\n' >"$dir/$1"
    git -C "$dir" add "$1"
  fi
  if [ -n "${2:-}" ]; then
    printf 'export const y = 1\n' >"$dir/tracked.ts"
    git -C "$dir" add tracked.ts
    git -C "$dir" -c user.email=t@t.t -c user.name=t commit -qm seed
    printf 'export const y = 2\n' >"$dir/tracked.ts"
  fi
  printf '%s\n' "$dir"
}

# run <repo> <command> — fire the hook with a synthetic PreToolUse payload.
run() {
  (cd "$1" && printf '{"tool_input":{"command":%s}}' "$(printf '%s' "$2" | jq -Rs .)" |
    bash "$HOOK" >/dev/null 2>&1)
  printf '%s\n' $?
}

expect_rc() {
  if [ "$2" = "$3" ]; then note_pass "$1"; else note_fail "$1" "want exit $2, got $3"; fi
}
ran() {
  if [ -f "$2/tc-ran" ]; then note_pass "$1"; else note_fail "$1" "typechecker never called"; fi
}
never_ran() {
  if [ -f "$2/tc-ran" ]; then note_fail "$1" "typechecker ran"; else note_pass "$1"; fi
}

echo "only a real git commit triggers it:"
repo="$(fixture staged.ts)"
expect_rc "plain-ls-exit-0" 0 "$(run "$repo" 'ls -la')"
never_ran "plain-ls-nothing-run" "$repo"

repo="$(fixture staged.ts)"
expect_rc "prose-mention-exit-0" 0 "$(run "$repo" 'echo "git commit is a thing"')"
never_ran "prose-mention-nothing-run" "$repo"

repo="$(fixture staged.ts)"
expect_rc "git-add-exit-0" 0 "$(run "$repo" 'git add file.ts')"
never_ran "git-add-nothing-run" "$repo"

echo "the staged-TS gate comes before any resolution:"
repo="$(fixture staged.md)"
expect_rc "md-only-exit-0" 0 "$(run "$repo" 'git commit -m "docs"')"
never_ran "md-only-nothing-run" "$repo"

repo="$(fixture staged.ts)"
expect_rc "staged-ts-exit-0" 0 "$(run "$repo" 'git commit -m "feat"')"
ran "staged-ts-invoked" "$repo"

echo "-a widens the gate to tracked modifications:"
repo="$(fixture '' modify)"
expect_rc "unstaged-plain-exit-0" 0 "$(run "$repo" 'git commit -m "x"')"
never_ran "unstaged-plain-nothing-run" "$repo"

repo="$(fixture '' modify)"
expect_rc "unstaged-dash-am-exit-0" 0 "$(run "$repo" 'git commit -am "x"')"
ran "unstaged-dash-am-invoked" "$repo"

echo "wrapper spellings still trigger:"
repo="$(fixture staged.ts)"
expect_rc "rtk-wrapper-exit-0" 0 "$(run "$repo" 'rtk git commit -m "y"')"
ran "rtk-wrapper-invoked" "$repo"

repo="$(fixture staged.ts)"
expect_rc "chained-exit-0" 0 "$(run "$repo" 'git add -u && git commit -m "y"')"
ran "chained-invoked" "$repo"

echo "the --bash-command fast path reads the command off stdin:"
repo="$(fixture staged.ts)"
(cd "$repo" && printf '%s' 'git commit -m "z"' | bash "$HOOK" --bash-command >/dev/null 2>&1)
expect_rc "stdin-path-exit-0" 0 "$?"
ran "stdin-path-invoked" "$repo"

echo "the resolver chain — AGENTS.md wins, placeholder and blank fall through:"
repo="$(fixture staged.ts)"
printf '## Project specifics\n\n- **Typecheck command**: `./absent-tc.sh`\n' >"$repo/CLAUDE.local.md"
expect_rc "agents-beats-legacy-exit-0" 0 "$(run "$repo" 'git commit -m "x"')"
ran "agents-beats-legacy-invoked" "$repo"

repo="$(fixture staged.ts)"
printf '# Fixture\n\n- **Stack**: nothing declared here\n' >"$repo/AGENTS.md"
printf '## Project specifics\n\n- **Typecheck command**: `./fake-tc.sh`\n' >"$repo/CLAUDE.local.md"
expect_rc "legacy-fallback-exit-0" 0 "$(run "$repo" 'git commit -m "x"')"
ran "legacy-fallback-invoked" "$repo"

repo="$(fixture staged.ts)"
printf '# Fixture\n\n## Solo lane\n\n- **Typecheck command**: {{TYPECHECK_COMMAND}}\n' >"$repo/AGENTS.md"
printf '## Project specifics\n\n- **Typecheck command**: `./fake-tc.sh`\n' >"$repo/CLAUDE.local.md"
expect_rc "placeholder-falls-through-exit-0" 0 "$(run "$repo" 'git commit -m "x"')"
ran "placeholder-falls-through-invoked" "$repo"

repo="$(fixture staged.ts)"
printf '# Fixture\n\n## Solo lane\n\n- **Typecheck command**:\n' >"$repo/AGENTS.md"
printf '## Project specifics\n\n- **Typecheck command**: `./fake-tc.sh`\n' >"$repo/CLAUDE.local.md"
expect_rc "blank-falls-through-exit-0" 0 "$(run "$repo" 'git commit -m "x"')"
ran "blank-falls-through-invoked" "$repo"

echo "\`none\` stops the chain:"
repo="$(fixture staged.ts)"
printf '# Fixture\n\n## Solo lane\n\n- **Typecheck command**: none\n' >"$repo/AGENTS.md"
printf '## Project specifics\n\n- **Typecheck command**: `./fake-tc.sh`\n' >"$repo/CLAUDE.local.md"
expect_rc "none-exit-0" 0 "$(run "$repo" 'git commit -m "x"')"
never_ran "none-nothing-run" "$repo"

repo="$(fixture staged.ts)"
printf '# Fixture\n\n## Solo lane\n\n- **Typecheck command**: none — the `./fake-tc.sh` types are stripped\n' >"$repo/AGENTS.md"
expect_rc "none-explanatory-backticks-exit-0" 0 "$(run "$repo" 'git commit -m "x"')"
never_ran "none-beats-explanatory-backticks" "$repo"

echo "a failing typecheck refuses the commit:"
repo="$(fixture staged.ts)"
printf '# Fixture\n\n## Solo lane\n\n- **Typecheck command**: `env FAKE_TC_RC=1 ./fake-tc.sh`\n' >"$repo/AGENTS.md"
expect_rc "failing-exit-2" 2 "$(run "$repo" 'git commit -m "x"')"
err="$(cd "$repo" && printf '%s' 'git commit -m "x"' | bash "$HOOK" --bash-command 2>&1 >/dev/null)"
case "$err" in
  *"Typecheck failed"*fake-tc.sh*"commit refused"*) note_pass "failure-message-on-stderr" ;;
  *) note_fail "failure-message-on-stderr" "stderr was: $(printf '%s' "$err" | tr '\n' '|')" ;;
esac

echo "CLAUDE_SKIP_TYPECHECK short-circuits everything:"
repo="$(fixture staged.ts)"
(cd "$repo" && printf '%s' 'git commit -m "x"' | CLAUDE_SKIP_TYPECHECK=1 bash "$HOOK" --bash-command >/dev/null 2>&1)
expect_rc "skip-env-exit-0" 0 "$?"
never_ran "skip-env-nothing-run" "$repo"

echo "last-resort probe — the installed compiler, never a package manager:"
# undeclared_fixture — like fixture(), but with NO declared bullet, so resolution falls all the way
# through to the probe. Stages a .ts so the hook has a reason to run at all.
undeclared_fixture() {
  local dir
  dir="$WORK/probe.$RANDOM$RANDOM"
  mkdir -p "$dir"
  git -C "$dir" init --quiet
  printf 'export const x = 1\n' >"$dir/a.ts"
  git -C "$dir" add a.ts
  printf '%s\n' "$dir"
}

# The branch read `npx tsc` and had no case, so nothing noticed it reached for a package manager to
# run a binary sitting in node_modules. It must use what is installed, and tsconfig.json alone is no
# longer enough — that file says the repo is TypeScript, not that the compiler is present.
repo="$(undeclared_fixture)"
printf '{}\n' >"$repo/tsconfig.json"
mkdir -p "$repo/node_modules/.bin"
printf '#!/bin/sh\n: >"$(dirname "$0")/../../tc-ran"\nexit 0\n' >"$repo/node_modules/.bin/tsc"
chmod +x "$repo/node_modules/.bin/tsc"
expect_rc "probe-local-tsc-exit-0" 0 "$(run "$repo" 'git commit -m "x"')"
ran "probe-local-tsc-invoked" "$repo"

# tsconfig.json but nothing installed: stay quiet rather than fetch a compiler mid-commit.
repo="$(undeclared_fixture)"
printf '{}\n' >"$repo/tsconfig.json"
expect_rc "probe-no-compiler-exit-0" 0 "$(run "$repo" 'git commit -m "x"')"
never_ran "probe-no-compiler-nothing-run" "$repo"

# A failing local compiler still refuses the commit — the whole point of the gate.
repo="$(undeclared_fixture)"
printf '{}\n' >"$repo/tsconfig.json"
mkdir -p "$repo/node_modules/.bin"
printf '#!/bin/sh\n: >"$(dirname "$0")/../../tc-ran"\nexit 1\n' >"$repo/node_modules/.bin/tsc"
chmod +x "$repo/node_modules/.bin/tsc"
expect_rc "probe-local-tsc-failure-blocks" 2 "$(run "$repo" 'git commit -m "x"')"
ran "probe-local-tsc-failure-invoked" "$repo"

echo
echo "typecheck-on-commit self-test: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
