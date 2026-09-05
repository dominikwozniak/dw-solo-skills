#!/usr/bin/env bash
# Self-test for the block-dangerous-commands.sh hook template: pins which Bash
# commands the guardrail blocks (exit 2) vs allows (exit 0). The patterns are
# easy to regress silently — an over-eager regex blocks legit work, a loose one
# lets a destructive command through — and nothing else in CI executes them.
#
# Run standalone (`bash scripts/tests/block-dangerous-commands.test.sh`) or via
# scripts/validate-artifacts.sh. Exit 0 iff every case matches. bash 3.2 safe.
set -uo pipefail
export LC_ALL=C

command -v jq >/dev/null || { echo "SKIP: jq missing (hooks no-op without it)"; exit 0; }

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
HOOK="$ROOT/templates/hooks/block-dangerous-commands.sh"

PASS=0
FAIL=0
note_pass() { PASS=$((PASS + 1)); echo "  ✓ $1"; }
note_fail() { FAIL=$((FAIL + 1)); echo "  ✗ $1 — $2"; }

run_hook() { jq -n --arg c "$1" '{tool_name:"Bash",tool_input:{command:$c}}' | bash "$HOOK" >/dev/null 2>&1; }

# blocked <name> <command> — hook must exit 2.
blocked() {
  run_hook "$2"; rc=$?
  if [ "$rc" -eq 2 ]; then note_pass "$1"; else note_fail "$1" "want exit 2, got $rc"; fi
}

# allowed <name> <command> — hook must exit 0.
allowed() {
  run_hook "$2"; rc=$?
  if [ "$rc" -eq 0 ]; then note_pass "$1"; else note_fail "$1" "want exit 0, got $rc"; fi
}

echo "blocked (exit 2):"
blocked "push-force"          "git push --force"
blocked "push-f"              "git push -f"
blocked "push-f-reordered"    "git push origin main -f"
blocked "push-force-w-lease"  "git push --force-with-lease"
blocked "push-delete"         "git push origin --delete old-branch"
blocked "push-colon-delete"   "git push origin :old-branch"
blocked "reset-hard"          "git reset --hard"
blocked "reset-hard-ref"      "git reset --hard HEAD~1"
blocked "clean-fd"            "git clean -fd"
blocked "clean-f-d"           "git clean -f -d"
blocked "clean-xdf"           "git clean -xdf"
blocked "clean-d"             "git clean -d"
blocked "branch-f-repoint"    "git branch -f main HEAD~3"
allowed "branch-D-ask-level"  "git branch -D feature"
blocked "checkout-dot"        "git checkout ."
blocked "checkout-dashes-dot" "git checkout -- ."
blocked "restore-dot"         "git restore ."
blocked "restore-dashes-dot"  "git restore -- ."
blocked "restore-dot-slash"   "git restore ./"
blocked "checkout-dot-slash"  "git checkout ./"
blocked "restore-dot-chained" "git restore . && echo done"
# The dot patterns end-anchor on a closing quote too, because BOUNDARY already
# consumed the opening one — dropping it would trade a false positive for a hole.
blocked "rtk-run-restore-dot" 'rtk run "git restore ."'
# A quoted `.` argument is the same command. BOUNDARY's quote is at the start of
# the line, so the dot's own quotes have to be part of DOT_ARG.
blocked "restore-quoted-dot"  'git restore "."'
blocked "restore-sq-dot"      "git restore '.'"
blocked "checkout-quoted-dot" 'git checkout "."'
blocked "restore-quoted-slash" 'git restore "./"'
# `git -C <path>` is the same command aimed at another repo — and in a repo with
# worktrees that other repo is often a sibling checkout of this one. One case per
# git pattern, because the prefix used to be on the DOT_ARG pair alone and the
# rest were silently exempt.
blocked "restore-dash-C-dot"  "git -C sub restore ."
blocked "checkout-dash-C-dot" "git -C ../other checkout -- ."
blocked "push-force-dash-C"   "git -C sub push --force"
blocked "push-f-dash-C"       "git -C ../other push -f origin main"
blocked "push-delete-dash-C"  "git -C sub push origin --delete old-branch"
blocked "push-colon-dash-C"   "git -C sub push origin :old-branch"
blocked "reset-hard-dash-C"   "git -C sub reset --hard HEAD~1"
blocked "clean-fd-dash-C"     "git -C sub clean -fd"
allowed "branch-D-dash-C"     "git -C ../other branch -D feature"
blocked "stash-clear-dash-C"  "git -C sub stash clear"
# The wrappers compose with it: BOUNDARY eats `rtk`, then GIT eats the `-C`.
blocked "rtk-dash-C-push"     "rtk git -C sub push --force"
blocked "dash-C-abs-path"     "git -C /Users/someone/repo push --force"
blocked "dash-C-worktree"     "git -C .claude/worktrees/other push --force"
blocked "dash-C-chained"      "pnpm test && git -C sub reset --hard"
# A `-C` path containing a space is still one argument, so it still blocks.
blocked "dash-C-quoted-path"  "git -C 'my repo' push --force"
blocked "dash-C-dq-path"      'git -C "my repo" reset --hard'
blocked "stash-clear"         "git stash clear"
blocked "rm-root"             "rm -rf /"
blocked "rm-home-tilde"       "rm -rf ~"
blocked "rm-home-var"         'rm -rf $HOME'
blocked "rm-cwd"              "rm -rf ."
allowed "rmdir-ask-level"     "rmdir build"
blocked "find-delete"         "find . -name '*.pyc' -delete"
blocked "shred"               "shred secrets.txt"
blocked "chained"             "cd subdir && git push --force"
blocked "sudo-rm-root"        "sudo rm -rf /"
blocked "rtk-push-force"      "rtk git push --force"
blocked "rtk-push-f"          "rtk git push -f origin main"
allowed "rtk-branch-D"        "rtk git branch -D feature"
blocked "rtk-stash-clear"     "rtk git stash clear"
blocked "rtk-proxy-push"      "rtk proxy git push --force"
blocked "rtk-chained"         "cd subdir && rtk git push --force"
# `rtk run` is a raw `sh -c`; err/summary/test run the command and filter output —
# every one of them is a live exec path, not just the `proxy` the regex once knew.
blocked "rtk-run-push"        "rtk run git push --force"
blocked "rtk-run-quoted"      'rtk run "git push --force"'
blocked "rtk-err-push"        "rtk err git push --force"
blocked "rtk-summary-push"    "rtk summary git push --force"
blocked "sudo-rtk-run-push"   "sudo rtk run git push --force"
blocked "rtk-run-rm-home"     "rtk run rm -rf ~"
# A leading `VAR=value` assignment is stripped by the shell, so it wrapped any
# destructive command past the boundary. `block-non-pnpm.sh` carried the
# alternative and this hook did not — the loosest of the three, and invisible
# until a case existed for it. WRAPPER repeats, so a run of assignments composes,
# and it composes with sudo/rtk too.
blocked "assign-push-force"   "FOO=1 git push --force"
blocked "assign-reset-hard"   "GIT_DIR=x git reset --hard"
blocked "assign-empty-value"  "FOO= git push --force"
blocked "assign-multi"        "A=1 B=2 git clean -fd"
blocked "assign-rtk-push"     "NODE_ENV=x rtk git push --force"
blocked "assign-sudo-rm-root" "FOO=1 sudo rm -rf /"
blocked "assign-chained"      "cd sub && FOO=1 git clean -fd"

echo "allowed (exit 0):"
allowed "plain-push"          "git push"
allowed "push-branch"         "git push origin main"
allowed "prose-in-quotes"     'git commit -m "docs: never git push --force"'
# The assignment alternative must not turn a mention into a refusal: it fires
# only at a real start-of-command boundary, and a safe verb after it stays safe.
allowed "assign-plain-push"   "A=1 git push"
allowed "assign-status"       "FOO=bar git status --short"
allowed "assign-pnpm"         "NODE_ENV=test pnpm test"
allowed "clean-dry-run"       "git clean -n"
allowed "clean-dry-run-long"  "git clean --dry-run"
allowed "branch-d-merged"     "git branch -d merged"
allowed "restore-staged"      "git restore --staged ."
# A dotted path is a path, not the working tree: the bare-dot patterns used to
# match its leading dot and refuse to restore a single tracked file.
allowed "restore-dotfile-dir" "git restore .ai/work/x/CHANGE.md"
allowed "restore-dotfile-rel" "git restore .claude/settings.json"
allowed "checkout-dotfile"    "git checkout .claude/settings.json"
allowed "restore-dotted-file" "git restore .gitignore"
allowed "restore-C-dotfile"   "git -C sub restore .ai/work/x"
# The `-C` prefix widens what matches, so the safe forms of each pattern have to
# stay safe with it — otherwise every read of a sibling worktree starts bouncing.
allowed "dash-C-plain-push"   "git -C sub push"
allowed "dash-C-status"       "git -C sub status --short"
allowed "dash-C-clean-dry"    "git -C sub clean -n"
allowed "dash-C-branch-d"     "git -C sub branch -d merged"
allowed "dash-C-reset-soft"   "git -C sub reset --soft HEAD~1"
allowed "dash-C-stash-list"   "git -C sub stash list"
allowed "dash-C-rev-parse"    "git -C .claude/worktrees/other rev-parse HEAD"
# What keeps `git commit -m "never reset --hard"` from matching the reset pattern
# is that `git` and the verb are ADJACENT. A `-C` group swallowing spaces destroys
# that, and the first spelling of it refused every -C command whose message quoted
# a dangerous phrase. These three are the regression, not decoration.
allowed "dash-C-prose-reset"  "git -C sub commit -m 'docs: never reset --hard'"
allowed "dash-C-prose-push"   'git -C sub commit -m "docs: never push --force"'
allowed "dash-C-prose-branch" "git -C sub commit -m 'docs: branch -D is rude'"
allowed "restore-quoted-path" 'git restore "./src/app.ts"'
allowed "checkout-branch"     "git checkout main"
allowed "checkout-feature"    "git checkout feature/x"
allowed "rm-node-modules"     "rm -rf node_modules"
allowed "rm-relative-dir"     "rm -rf ./dist"
allowed "rm-home-subdir"      "rm -rf ~/old-dir"
allowed "find-no-delete"      "find . -name '*.pyc'"
allowed "rtk-status"          "rtk git status"
allowed "rtk-plain-push"      "rtk git push"
allowed "rtk-gain"            "rtk gain"
allowed "rtk-run-tests"       "rtk run pnpm test"
allowed "rtk-summary-status"  "rtk summary git status"
allowed "empty-input"         ""

echo
echo "block-dangerous-commands self-test: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
