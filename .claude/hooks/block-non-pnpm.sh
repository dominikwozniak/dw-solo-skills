#!/bin/bash
# PreToolUse Bash hook — enforces pnpm over npm/yarn/bun in Node projects.
# Reads tool_input.command from stdin (Claude Code hook protocol).
# Exit 2 + stderr message causes Claude to see the block and self-correct.
# Allows: pnpm, pnpm dlx, npx (npx ≠ npm install).
# JS/TS projects only — skip this hook when bootstrapping a non-Node stack.

set -uo pipefail

command -v jq >/dev/null || exit 0

INPUT=$(cat)
COMMAND=$(jq -r '.tool_input.command // empty' <<<"$INPUT")

[[ -z "$COMMAND" ]] && exit 0

# Strip optional leading `sudo ` for matching. Anchor to start-of-command
# (or `&&`/`;`/`|` boundary) so we never match `npm` inside paths or strings.
BLOCKED_PATTERNS=(
  '(^|[;&|]\s*)npm\s+(install|i|add|ci|update|upgrade|exec|run)\b'
  '(^|[;&|]\s*)yarn(\s|$)'
  '(^|[;&|]\s*)bun\s+(install|i|add|remove|update|run|x)\b'
)

# Normalize: drop a leading `sudo ` for matching only.
NORMALIZED="${COMMAND#sudo }"

for pattern in "${BLOCKED_PATTERNS[@]}"; do
  if echo "$NORMALIZED" | grep -qE "$pattern"; then
    echo "BLOCKED: '$COMMAND' uses npm/yarn/bun. This repo enforces pnpm. Use 'pnpm install', 'pnpm add <pkg>', 'pnpm dlx <cmd>', or 'npx <cmd>' (npx is fine — it's not npm install)." >&2
    exit 2
  fi
done

exit 0
