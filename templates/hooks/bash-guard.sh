#!/bin/bash
# PreToolUse Bash dispatcher — one stdin read, one jq parse, and each guard
# spawned only when the command could trip it. Wire THIS script alone for
# matcher "Bash"; wiring a guard directly still works — each one parses stdin
# itself when DW_GUARD_COMMAND is absent.
# Guardrail against agent accidents — NOT a security boundary; permissions.ask
# and permissions.deny in settings.json are the jq-less backstop.

set -uo pipefail

command -v jq >/dev/null || exit 0

INPUT=$(cat)
COMMAND=$(jq -r '.tool_input.command // empty' <<<"$INPUT")

[[ -z "$COMMAND" ]] && exit 0

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export DW_GUARD_COMMAND="$COMMAND"

# A guard pruned from .claude/hooks/ is skipped, not an error.
run() {
  [[ -f "$DIR/$1" ]] || return 0
  bash "$DIR/$1" </dev/null
}

# Always-on guards.
run block-dangerous-commands.sh || exit $?
run credential-leak-guard.sh || exit $?

# Trigger-scoped guards — the substring tests over-approximate on purpose; the
# guard itself does the exact matching, this only skips spawns that cannot fire.
case "$COMMAND" in
  *npm* | *yarn* | *bun*) run block-non-pnpm.sh || exit $? ;;
esac
case "$COMMAND" in
  *git*commit* | *git*add*) run enforce-commit-hygiene.sh || exit $? ;;
esac
case "$COMMAND" in
  *git*commit*) run typecheck-on-commit.sh || exit $? ;;
esac

exit 0
