#!/usr/bin/env bash
# Self-test for the block-non-pnpm.sh hook template: pins which package-manager
# commands the pnpm guardrail refuses (exit 2) vs allows (exit 0).
#
# Writing this test is what found the hole it now pins: the hook stripped one
# leading `sudo ` and knew nothing about rtk, so every wrapped form went through.
# The wrapper group below is that fix, and it is the reason a guardrail without a
# self-test is a guardrail nobody has checked.
#
# `npx` must stay allowed — it is not `npm install`, and blocking it would break
# every one-off tool invocation. The near-miss group is what keeps the wrapper
# prefix from reaching into a commit message.
#
# Run standalone (`bash scripts/tests/block-non-pnpm.test.sh`) or via
# scripts/validate-artifacts.sh. Exit 0 iff every case matches. bash 3.2 safe.
set -uo pipefail
export LC_ALL=C

command -v jq >/dev/null || {
  echo "SKIP: jq missing (hooks no-op without it)"
  exit 0
}

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
HOOK="$ROOT/templates/hooks/block-non-pnpm.sh"

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

run_bash() { jq -n --arg c "$1" '{tool_name:"Bash",tool_input:{command:$c}}' | bash "$HOOK" >/dev/null 2>&1; }

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

echo "npm — blocked (exit 2):"
blocked "npm-install" "npm install"
blocked "npm-install-pkg" "npm install lodash"
blocked "npm-i" "npm i"
blocked "npm-i-pkg" "npm i lodash"
blocked "npm-add" "npm add lodash"
blocked "npm-ci" "npm ci"
blocked "npm-update" "npm update"
blocked "npm-upgrade" "npm upgrade"
blocked "npm-exec" "npm exec tsc"
blocked "npm-run" "npm run build"
blocked "npm-install-save-dev" "npm install --save-dev prettier"
blocked "sudo-npm-install" "sudo npm install -g typescript"
blocked "npm-after-and" "pnpm build && npm install"
blocked "npm-after-semicolon" "cd app; npm ci"
blocked "npm-after-pipe" "echo x | npm run seed"

echo "yarn and bun — blocked (exit 2):"
blocked "yarn-bare" "yarn"
blocked "yarn-add" "yarn add lodash"
blocked "yarn-install" "yarn install"
blocked "bun-install" "bun install"
blocked "bun-i" "bun i"
blocked "bun-add" "bun add lodash"
blocked "bun-remove" "bun remove lodash"
blocked "bun-run" "bun run build"
blocked "bun-x" "bun x tsc"
blocked "sudo-yarn" "sudo yarn add lodash"

echo "pnpm, npx and the near-misses — allowed (exit 0):"
allowed "pnpm-install" "pnpm install"
allowed "pnpm-add" "pnpm add -D prettier"
allowed "pnpm-dlx" "pnpm dlx ctx7 library React"
allowed "pnpm-run-script" "pnpm validate:artifacts"
# npx is not npm install, and blocking it would break every one-off tool run.
allowed "npx-tsc" "npx tsc --noEmit"
allowed "npx-scoped" "npx @scope/tool"
# `npm` inside a longer word or a path is not the command.
allowed "npm-substring" "npmsinstall"
allowed "npm-in-a-path" "cat node_modules/.bin/npm-run-all"
allowed "npm-in-prose" 'git commit -m "docs: why npm install is banned"'
allowed "npm-bare-no-subcommand" "npm --version"
allowed "npm-unknown-subcommand" "npm whoami"
# `bun`/`yarn` as a substring of something else.
allowed "bundle-not-bun" "bundle exec rspec"
allowed "bunx-not-bun-space" "bunx tsc"
allowed "empty-input" ""
allowed "plain-ls" "ls -la"

echo "wrappers — the same forms block-dangerous-commands.sh sees through (exit 2):"
# These all passed while the hook stripped one leading `sudo ` and knew nothing
# else. The rtk forms are the ones that mattered: a repo running an rtk rewrite
# over its own commands had the guardrail bypassed on every one of them.
blocked "rtk-npm-install" "rtk npm install"
blocked "rtk-proxy-npm" "rtk proxy npm ci"
blocked "rtk-run-npm" "rtk run npm install"
blocked "rtk-run-quoted-npm" 'rtk run "npm install"'
blocked "rtk-yarn" "rtk yarn add lodash"
blocked "rtk-bun" "rtk bun install"
blocked "sudo-twice" "sudo sudo npm install"
blocked "sudo-rtk-run-npm" "sudo rtk run npm install"
blocked "env-prefix" "NODE_ENV=production npm ci"
blocked "two-env-prefixes" "CI=1 NODE_ENV=production npm ci"
blocked "env-prefix-after-chain" "cd app; NODE_ENV=test npm run seed"
blocked "sudo-after-chain" "cd app && sudo npm install"

echo "the wrapper prefix must not reach into prose or a longer word (exit 0):"
# A wrapper chain only counts at a command boundary. Without that, an `=` anywhere
# in a commit message would turn the rest of the line into a command.
allowed "env-like-text-in-prose" 'git commit -m "fix: NODE_ENV=1 npm ci was wrong"'
allowed "npm-after-a-word" "echo why npm install is banned"
allowed "rtk-without-npm" "rtk gain"
allowed "rtk-git-status" "rtk git status"
allowed "pnpm-after-wrapper" "rtk pnpm install"

echo
echo "block-non-pnpm self-test: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
