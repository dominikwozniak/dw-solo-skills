#!/usr/bin/env bash
# Self-test for the enforce-commit-hygiene.sh hook template: pins which `git
# commit` and `git add` commands the hook refuses (exit 2) vs lets through
# (exit 0), across all four checks — declared subject pattern, declared trailer,
# a live backtick inside -m, and `git add -A` / `git add .`.
#
# The two policies are read from AGENTS.md, so most cases run against a
# THROWAWAY repo whose AGENTS.md this test writes: the fixture is the input, and
# pinning behaviour against whatever this repo happens to declare today would
# make the test a mirror of the declaration rather than a check on the hook.
# The `none` cases and the no-bullet default are the same fixture with a
# different AGENTS.md.
#
# Run standalone (`bash scripts/tests/enforce-commit-hygiene.test.sh`) or via
# scripts/validate-artifacts.sh. Exit 0 iff every case matches. bash 3.2 safe.
set -uo pipefail
export LC_ALL=C

command -v jq >/dev/null || {
  echo "SKIP: jq missing (hooks no-op without it)"
  exit 0
}

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
HOOK="$ROOT/templates/hooks/enforce-commit-hygiene.sh"

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

# The hook resolves its policies from the repo it is invoked in, so each case
# runs with the CWD inside a scratch repo we control.
TMP="$(mktemp -d 2>/dev/null || mktemp -d -t hygiene)"
cleanup() { rm -rf "$TMP"; }
trap cleanup EXIT

FIXTURE="$TMP/repo"
mkdir -p "$FIXTURE"
git -C "$FIXTURE" init -q 2>/dev/null

# write_policy <pattern-line-value> <trailer-line-value> — both go in verbatim,
# so a case can pass a backticked value, a bare `none`, or the empty string to
# omit the bullet entirely.
write_policy() {
  {
    echo "# fixture"
    echo
    echo "## Solo lane"
    echo
    [ -n "$1" ] && echo "- **Commit pattern**: $1"
    [ -n "$2" ] && echo "- **Commit trailer**: $2"
    echo
  } >"$FIXTURE/AGENTS.md"
}

run_bash() (
  cd "$FIXTURE" || exit 1
  jq -n --arg c "$1" '{tool_name:"Bash",tool_input:{command:$c}}' | bash "$HOOK" >/dev/null 2>&1
)

blocked() {
  run_bash "$2"
  rc=$?
  if [ "$rc" -eq 2 ]; then note_pass "$1"; else note_fail "$1" "want exit 2, got $rc"; fi
}
allowed() {
  run_bash "$2"
  rc=$?
  if [ "$rc" -eq 0 ]; then note_pass "$1"; else note_fail "$1" "want exit 0, got $rc"; fi
}

CONV='`^(build|chore|ci|docs|feat|fix|perf|refactor|revert|style|test)(\([^)]+\))?!?: .+`'
TRAILER='`Co-Authored-By:`'
GOOD_MSG='chore(hook): add the hygiene guard

Co-Authored-By: Someone <noreply@example.com>'

echo "declared pattern + declared trailer — blocked (exit 2):"
write_policy "$CONV" "$TRAILER"
blocked "no-type-prefix" "git commit -m \"added a thing

Co-Authored-By: Someone <noreply@example.com>\""
blocked "uppercase-type" "git commit -m \"Fix: a thing

Co-Authored-By: Someone <noreply@example.com>\""
blocked "unknown-type" "git commit -m \"wip: a thing

Co-Authored-By: Someone <noreply@example.com>\""
blocked "no-space-after-colon" "git commit -m \"fix:athing

Co-Authored-By: Someone <noreply@example.com>\""
blocked "empty-subject" 'git commit -m ""'
blocked "missing-trailer" 'git commit -m "fix(hook): a thing"'
blocked "trailer-in-subject-only" 'git commit -m "Co-Authored-By: Someone <noreply@example.com>"'
blocked "body-but-no-trailer" 'git commit -m "fix(hook): a thing" -m "why it was done"'

echo "declared pattern + declared trailer — allowed (exit 0):"
allowed "single-m-with-trailer" "git commit -m \"$GOOD_MSG\""
allowed "repeated-m-trailer-last" 'git commit -m "feat(dw-git): a thing" -m "why it was done" -m "Co-Authored-By: Someone <noreply@example.com>"'
allowed "scopeless-type" "git commit -m \"docs: a thing

Co-Authored-By: Someone <noreply@example.com>\""
allowed "breaking-bang" "git commit -m \"feat(x)!: a thing

Co-Authored-By: Someone <noreply@example.com>\""
allowed "trailer-case-insensitive" "git commit -m \"fix: a thing

co-authored-by: Someone <noreply@example.com>\""
allowed "glued-m-value" "git commit -m\"fix: a thing

Co-Authored-By: Someone <noreply@example.com>\""
allowed "long-message-flag" "git commit --message=\"fix: a thing

Co-Authored-By: Someone <noreply@example.com>\""
allowed "clustered-am" "git commit -am \"fix: a thing

Co-Authored-By: Someone <noreply@example.com>\""

echo "wrappers and other repos resolve to the same commit (exit 2):"
blocked "rtk-wrapper" 'rtk git commit -m "nope, no type prefix"'
blocked "rtk-proxy-wrapper" 'rtk proxy git commit -m "nope, no type prefix"'
blocked "sudo-wrapper" 'sudo git commit -m "nope, no type prefix"'
blocked "dash-C-other-repo" 'git -C ../other commit -m "nope, no type prefix"'
blocked "after-chain" 'pnpm test && git commit -m "nope, no type prefix"'
blocked "second-of-two-commits" "git commit -m \"$GOOD_MSG\" && git commit -m \"nope\""

echo "the message the hook cannot read is passed through (exit 0):"
allowed "editor-commit" "git commit"
allowed "amend-no-edit" "git commit --amend --no-edit"
allowed "message-from-file" "git commit -F /tmp/msg.txt"
allowed "message-from-file-long" "git commit --file=/tmp/msg.txt"
allowed "message-from-stdin-heredoc" "git commit -F - <<'MSG'
whatever shape this is
MSG"
allowed "shell-assembled-message" 'git commit -m "$MSG"'
allowed "command-substituted-message" 'git commit -m "fix: $(date)"'
allowed "merge-subject" 'git commit -m "Merge branch main into topic"'
allowed "revert-subject" 'git commit -m "Revert \"feat: a thing\""'
allowed "fixup-subject" 'git commit -m "fixup! feat: a thing"'
allowed "squash-subject" 'git commit -m "squash! feat: a thing"'
allowed "not-a-commit-at-all" "git status --short"
allowed "no-git-token" "pnpm test"
allowed "empty-input" ""

echo "a dollar that is not an expansion stays checked (exit 2):"
blocked "dollar-amount-still-checked" 'git commit -m "nope, costs \$5

Co-Authored-By: Someone <noreply@example.com>"'

echo "live backtick inside -m — blocked (exit 2):"
blocked "backtick-in-double-quotes" 'git commit -m "fix(hook): stop reading `CHANGE.md`

Co-Authored-By: Someone <noreply@example.com>"'
blocked "backtick-unquoted" 'git commit -m fix:`pwd`'
blocked "backtick-in-body-m" 'git commit -m "fix(hook): a thing" -m "it touches `AGENTS.md`" -m "Co-Authored-By: Someone <noreply@example.com>"'

echo "inert backtick inside -m — allowed (exit 0):"
allowed "backtick-single-quoted" "git commit -m 'fix(hook): stop reading \`CHANGE.md\`

Co-Authored-By: Someone <noreply@example.com>'"
allowed "backtick-escaped" 'git commit -m "fix(hook): stop reading \`CHANGE.md\`

Co-Authored-By: Someone <noreply@example.com>"'

echo "git add — blocked (exit 2):"
blocked "add-dash-A" "git add -A"
blocked "add-dash-A-clustered" "git add -Av"
blocked "add-dash-A-second-in-cluster" "git add -uA"
blocked "add-all-long" "git add --all"
blocked "add-dot" "git add ."
blocked "add-dot-slash" "git add ./"
blocked "add-dot-after-separator" "git add -- ."
blocked "add-dash-A-wrapped" "rtk git add -A"
blocked "add-dash-A-other-repo" "git add -A --dry-run"
blocked "add-then-commit-chain" "git add -A && git commit -m \"$GOOD_MSG\""

echo "git add — allowed (exit 0):"
allowed "add-by-name" "git add AGENTS.md scripts/lint.sh"
allowed "add-patch" "git add -p AGENTS.md"
allowed "add-dotted-path" "git add .ai/work/slug/CHANGE.md"
allowed "add-update-only" "git add -u AGENTS.md"
allowed "commit-a-flag-is-not-add" "git commit -a -m \"$GOOD_MSG\""

echo "a standalone 'none' disables each check (exit 0):"
write_policy '`none`' "$TRAILER"
allowed "pattern-none-any-subject" "git commit -m \"whatever shape

Co-Authored-By: Someone <noreply@example.com>\""
write_policy "none — this repo's log predates the rule" "$TRAILER"
allowed "pattern-none-with-prose" "git commit -m \"whatever shape

Co-Authored-By: Someone <noreply@example.com>\""
write_policy "$CONV" '`none`'
allowed "trailer-none" 'git commit -m "fix: a thing with no trailer"'
write_policy '`none`' '`none`'
allowed "both-none" 'git commit -m "whatever shape, no trailer"'
blocked "both-none-still-catches-backtick" 'git commit -m "whatever `pwd` shape"'
blocked "both-none-still-catches-add-A" "git add -A"

echo "no bullets at all — Conventional Commits by default, no trailer required:"
write_policy "" ""
allowed "default-pattern-match" 'git commit -m "fix(hook): a thing with no trailer"'
blocked "default-pattern-miss" 'git commit -m "a thing with no type prefix"'

echo "an unrendered placeholder is not a declaration:"
write_policy '{{COMMIT_PATTERN}}' '{{COMMIT_TRAILER}}'
allowed "placeholder-falls-back-to-default" 'git commit -m "fix(hook): a thing"'
blocked "placeholder-still-enforces-default" 'git commit -m "a thing with no type prefix"'

echo "no AGENTS.md at all — defaults still apply:"
rm -f "$FIXTURE/AGENTS.md"
allowed "no-agents-md-match" 'git commit -m "fix(hook): a thing"'
blocked "no-agents-md-miss" 'git commit -m "a thing with no type prefix"'

echo
echo "enforce-commit-hygiene self-test: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
