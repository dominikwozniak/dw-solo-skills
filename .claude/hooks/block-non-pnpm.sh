#!/bin/bash
# PreToolUse Bash hook — enforces pnpm over npm/yarn/bun in Node projects.
# Reads tool_input.command from stdin (Claude Code hook protocol).
# Exit 2 + stderr message causes Claude to see the block and self-correct.
# Allows: pnpm, pnpm dlx, npx (npx ≠ npm install).
# JS/TS projects only — skip this hook when bootstrapping a non-Node stack.

set -uo pipefail

# Fast path: --bash-command says the dispatcher already parsed the payload and
# put the command on stdin. Gated on argv, never on an environment variable — a
# stray one must not be able to skip a check below.
if [[ "${1:-}" == "--bash-command" ]]; then
  COMMAND=$(cat)
else
  command -v jq >/dev/null || exit 0
  INPUT=$(cat)
  COMMAND=$(jq -r '.tool_input.command // empty' <<<"$INPUT")
fi

[[ -z "$COMMAND" ]] && exit 0

# Wrapper prefixes, the same shape block-dangerous-commands.sh uses and for the
# same reason: `npm install` is still `npm install` when something else types it.
# This hook used to strip exactly one leading `sudo ` by parameter expansion and
# know nothing else, so `rtk npm install`, `sudo sudo npm install` and
# `NODE_ENV=production npm ci` all sailed past — and the rtk form matters most
# here, because a repo running an rtk rewrite over its own commands would have had
# the guardrail bypassed on every single one.
#
# The three alternatives are `sudo`, `rtk` with its optional subcommand (`rtk run`
# is a raw `sh -c`; `proxy`, `err`, `summary`, `test` also execute the rest), and a
# leading `VAR=value` assignment. The trailing `*` composes them, so
# `sudo rtk run npm install` matches too.
WRAPPER='(sudo[[:space:]]+|rtk[[:space:]]+([a-z-]+[[:space:]]+)?|[A-Za-z_][A-Za-z0-9_]*=[^[:space:]]*[[:space:]]+)*'

# Start-of-command boundary: line start, or right after ; & | — so `npm` inside a
# path (`node_modules/.bin/npm-run-all`), inside a longer word (`npmsinstall`) or
# inside a commit message never matches. Then the wrappers, then an optional quote
# for the `rtk run "npm install"` form.
BOUNDARY="(^|[;&|][[:space:]]*)${WRAPPER}[\"']?"

# POSIX classes rather than `\s`: it is a GNU extension that the BSD grep macOS
# ships happens to honour, which is exactly the kind of accident to stop relying
# on once it is noticed.
BLOCKED_PATTERNS=(
  'npm[[:space:]]+(install|i|add|ci|update|upgrade|exec|run)\b'
  'yarn([[:space:]]|$)'
  'bun[[:space:]]+(install|i|add|remove|update|run|x)\b'
)

for pattern in "${BLOCKED_PATTERNS[@]}"; do
  if echo "$COMMAND" | grep -qE "${BOUNDARY}${pattern}"; then
    echo "BLOCKED: '$COMMAND' uses npm/yarn/bun. This repo enforces pnpm. Use 'pnpm install', 'pnpm add <pkg>', 'pnpm dlx <cmd>', or 'npx <cmd>' (npx is fine — it's not npm install)." >&2
    exit 2
  fi
done

exit 0
