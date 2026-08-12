#!/usr/bin/env bash
# Self-test for the lint-on-edit.sh hook template: pins how the project's lint command is read out
# of the tracked AGENTS.md (with a legacy CLAUDE.local.md fallback), that a declared `none` stops
# the chain instead of being run, and — the case that actually bit — that the hook NEVER executes
# the file it was asked to lint.
#
# The bug this locks down: the original extractor used `\s` inside `sed -E`, which BSD sed (macOS)
# does not implement. `:\s*` matched the colon and nothing else, so the captured "command" was a
# single space. A space is not empty, so the `[[ -z ]]` guard passed it through and
# `eval " \"$file_path\""` ran the edited file as a program. On a non-executable .ts that surfaced
# as a confusing "Permission denied"; on anything with the executable bit it would have run.
#
# The second bug: `none` — the honest value a repo without a linter writes — was neither a command
# nor a placeholder, so it was `eval`ed and failed on every single edit.
#
# Run standalone (`bash scripts/tests/lint-on-edit.test.sh`) or via scripts/validate-artifacts.sh.
# Exit 0 iff every case matches. bash 3.2 safe.
set -uo pipefail
export LC_ALL=C

command -v jq >/dev/null || { echo "SKIP: jq missing (hooks no-op without it)"; exit 0; }

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
HOOK="$ROOT/templates/hooks/lint-on-edit.sh"

PASS=0
FAIL=0
note_pass() { PASS=$((PASS + 1)); echo "  ✓ $1"; }
note_fail() { FAIL=$((FAIL + 1)); echo "  ✗ $1 — $2"; }

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

# fixture <agents-line> <local-line> — a throwaway git repo holding an AGENTS.md and/or a
# CLAUDE.local.md with the given line (pass the empty string for "no such file at all"), an
# EXECUTABLE target.ts that leaves a sentinel behind if it is ever run, and a fake linter that
# records the arguments it was handed. Echoes the repo path.
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
  # Executable on purpose: if the hook ever execs the target, the sentinel proves it.
  printf '#!/bin/sh\ntouch "$(dirname "$0")/EXECUTED"\n' >"$dir/target.ts"
  chmod +x "$dir/target.ts"
  printf '#!/bin/sh\nprintf "%%s\\n" "$@" >>"$(dirname "$0")/lint-args"\nexit "${FAKE_LINT_RC:-0}"\n' \
    >"$dir/fake-lint.sh"
  chmod +x "$dir/fake-lint.sh"
  printf '%s\n' "$dir"
}

# run <repo> [file] — feed the hook a Write event for the target and echo its exit code.
run() {
  local dir="$1" target="${2:-target.ts}" rc
  jq -n --arg t "Write" --arg p "$dir/$target" '{tool_name:$t,tool_input:{file_path:$p}}' \
    | bash "$HOOK" >/dev/null 2>&1
  rc=$?
  printf '%s\n' "$rc"
}

# expect_rc <name> <want> <got>
expect_rc() {
  if [ "$2" = "$3" ]; then note_pass "$1"; else note_fail "$1" "want exit $2, got $3"; fi
}

# never_executed <name> <repo> — the sentinel must be absent.
never_executed() {
  if [ -e "$2/EXECUTED" ]; then
    note_fail "$1" "the hook EXECUTED the edited file"
  else
    note_pass "$1"
  fi
}

# ran_linter <name> <repo> — the fake linter recorded a call.
ran_linter() {
  if [ -f "$2/lint-args" ]; then note_pass "$1"; else note_fail "$1" "fake linter was never called"; fi
}

# never_ran_linter <name> <repo> — the fake linter recorded nothing.
never_ran_linter() {
  if [ -f "$2/lint-args" ]; then
    note_fail "$1" "fake linter ran: $(tr '\n' ' ' <"$2/lint-args")"
  else
    note_pass "$1"
  fi
}

echo "AGENTS.md is the tracked source, and it gets the file path:"
repo="$(fixture '- **Lint command**: `./fake-lint.sh` (notes after it are ignored)' '')"
expect_rc "agents-backticked-exit-0" 0 "$(run "$repo")"
if [ -f "$repo/lint-args" ] && grep -q "target.ts" "$repo/lint-args"; then
  note_pass "agents-received-path"
else
  note_fail "agents-received-path" "fake linter was not called with the file path"
fi
never_executed "agents-no-exec" "$repo"

echo "resolves an un-backticked command (freshly rendered style):"
repo="$(fixture '- **Lint command**: ./fake-lint.sh' '')"
expect_rc "bare-exit-0" 0 "$(run "$repo")"
ran_linter "bare-invoked" "$repo"

echo "a failing linter becomes exit 2 so the model self-corrects:"
repo="$(fixture '- **Lint command**: `env FAKE_LINT_RC=1 ./fake-lint.sh`' '')"
expect_rc "failing-lint-exit-2" 2 "$(run "$repo")"

echo "AGENTS.md wins over a legacy CLAUDE.local.md:"
repo="$(fixture '- **Lint command**: `./fake-lint.sh --from-agents`' '- **Lint command**: `./fake-lint.sh --from-local`')"
expect_rc "precedence-exit-0" 0 "$(run "$repo")"
if grep -q -- "--from-agents" "$repo/lint-args" && ! grep -q -- "--from-local" "$repo/lint-args"; then
  note_pass "precedence-agents-first"
else
  note_fail "precedence-agents-first" "args: $(tr '\n' ' ' <"$repo/lint-args")"
fi

echo "legacy fallback — CLAUDE.local.md still read when AGENTS.md cannot answer:"
repo="$(fixture '' '- **Lint command**: `./fake-lint.sh`')"
expect_rc "legacy-only-exit-0" 0 "$(run "$repo")"
ran_linter "legacy-only-invoked" "$repo"

repo="$(fixture '- **Stack**: nothing to see here' '- **Lint command**: `./fake-lint.sh`')"
expect_rc "legacy-agents-silent-exit-0" 0 "$(run "$repo")"
ran_linter "legacy-agents-silent-invoked" "$repo"

repo="$(fixture '- **Lint command**: {{LINT_COMMAND}}' '- **Lint command**: `./fake-lint.sh`')"
expect_rc "legacy-agents-placeholder-exit-0" 0 "$(run "$repo")"
ran_linter "legacy-agents-placeholder-invoked" "$repo"

echo "\`none\` is a declaration, and it STOPS the chain:"
# The legacy line would run if `none` merely "found nothing" — so this proves the stop, not a miss.
repo="$(fixture '- **Lint command**: none' '- **Lint command**: `./fake-lint.sh`')"
expect_rc "none-exit-0" 0 "$(run "$repo")"
never_ran_linter "none-stops-the-chain" "$repo"
never_executed "none-no-exec" "$repo"

repo="$(fixture '- **Lint command**: `none`' '- **Lint command**: `./fake-lint.sh`')"
expect_rc "none-backticked-exit-0" 0 "$(run "$repo")"
never_ran_linter "none-backticked-stops-the-chain" "$repo"

repo="$(fixture '- **Lint command**: None' '- **Lint command**: `./fake-lint.sh`')"
expect_rc "none-capitalised-exit-0" 0 "$(run "$repo")"
never_ran_linter "none-capitalised-stops-the-chain" "$repo"

# The sentinel is tested on the RAW remainder, before any backtick extraction. Taking the first
# backticked span first made `none — see `./fake-lint.sh`` RUN ./fake-lint.sh on every edit, which is
# the exact opposite of what the line says.
repo="$(fixture '- **Lint command**: none — see `./fake-lint.sh` if you must' '')"
expect_rc "none-with-explanatory-backticks-exit-0" 0 "$(run "$repo")"
never_ran_linter "none-beats-explanatory-backticks" "$repo"

repo="$(fixture '- **Lint command**: none (this project has no linter)' '')"
expect_rc "none-with-parenthetical-exit-0" 0 "$(run "$repo")"
never_ran_linter "none-beats-a-parenthetical" "$repo"

# ...but the word has to stand alone. A command that merely starts with those letters is a command.
repo="$(fixture '- **Lint command**: `./fake-lint.sh --none-of-it`' '')"
expect_rc "none-prefixed-command-still-runs-exit-0" 0 "$(run "$repo")"
ran_linter "none-is-not-a-prefix-match" "$repo"

echo "no-ops instead of executing the file (the regression):"
repo="$(fixture '- **Lint command**:' '')"
expect_rc "empty-value-exit-0" 0 "$(run "$repo")"
never_executed "empty-value-no-exec" "$repo"

repo="$(fixture '- **Lint command**: {{LINT_COMMAND}}' '')"
expect_rc "placeholder-exit-0" 0 "$(run "$repo")"
never_executed "placeholder-no-exec" "$repo"

repo="$(fixture '' '')"
expect_rc "no-memory-file-exit-0" 0 "$(run "$repo")"
never_executed "no-memory-file-no-exec" "$repo"

echo "ignores files it does not lint:"
repo="$(fixture '- **Lint command**: `./fake-lint.sh`' '')"
printf 'text\n' >"$repo/notes.md"
expect_rc "md-ignored" 0 "$(run "$repo" "notes.md")"
never_ran_linter "md-not-linted" "$repo"

echo "a filename cannot inject a command (the path is never re-parsed):"
# The hole: the path used to be spliced into the string `eval` parsed, and double quotes do not stop
# command substitution once eval reparses. A file named `$(touch PWNED).js` cleared the existence and
# extension checks and then executed on the next Write. The command is still eval'ed — it is authored
# by the repo owner — but the path goes in as one literal argument.
repo="$(fixture '- **Lint command**: `./fake-lint.sh`' '')"
inject='$(touch PWNED).js'
printf 'export const x = 1\n' >"$repo/$inject"
expect_rc "injected-filename-exit-0" 0 "$(run "$repo" "$inject")"
if [ -e "$repo/PWNED" ]; then
  note_fail "injected-filename-not-executed" "the substitution in the filename RAN"
else
  note_pass "injected-filename-not-executed"
fi
if [ -f "$repo/lint-args" ] && grep -qF 'touch PWNED' "$repo/lint-args"; then
  note_pass "injected-filename-passed-through-literally"
else
  note_fail "injected-filename-passed-through-literally" "args: $(tr '\n' ' ' <"$repo/lint-args" 2>/dev/null)"
fi

# Quoting inside the authored command still works — that is why it is eval'ed at all.
repo="$(fixture '- **Lint command**: `env TAG="two words" ./fake-lint.sh --flag`' '')"
expect_rc "quoted-args-in-command-exit-0" 0 "$(run "$repo")"
if [ -f "$repo/lint-args" ] && grep -qx -- "--flag" "$repo/lint-args"; then
  note_pass "quoted-args-in-command-preserved"
else
  note_fail "quoted-args-in-command-preserved" "args: $(tr '\n' ' ' <"$repo/lint-args" 2>/dev/null)"
fi

echo "a pipeline in the declared command refuses, instead of executing the file:"
# `eval "set -- foo | bar"` runs `set --` in a subshell, so no positional parameters land in the
# parent and `"$@" "$file_path"` collapses to just the path. That re-entered the execute-the-file bug
# through a different door, silently and at exit 0. Refuse loudly instead.
repo="$(fixture '- **Lint command**: `./fake-lint.sh | cat`' '')"
expect_rc "pipeline-command-exit-2" 2 "$(run "$repo")"
never_executed "pipeline-command-no-exec" "$repo"

# The shapes that DO survive word-splitting keep working — only a pipeline is refused.
for shape in './fake-lint.sh && true' './fake-lint.sh;' './fake-lint.sh 2>/dev/null'; do
  repo="$(fixture "- **Lint command**: \`$shape\`" '')"
  rc="$(run "$repo")"
  if [ "$rc" = "0" ] && [ -f "$repo/lint-args" ]; then
    note_pass "shell-shape-still-runs: $shape"
  else
    note_fail "shell-shape-still-runs: $shape" "rc=$rc, linted=$([ -f "$repo/lint-args" ] && echo yes || echo no)"
  fi
  never_executed "shell-shape-no-exec: $shape" "$repo"
done

echo
echo "lint-on-edit self-test: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
