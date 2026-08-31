#!/bin/bash
# PreToolUse Bash dispatcher — one stdin read, one jq parse, and each guard
# spawned only when the command could trip it. Wire THIS script alone for
# matcher "Bash"; wiring a guard directly still works — without the
# --bash-command flag each guard parses the JSON payload from stdin itself.
# Guardrail against agent accidents — NOT a security boundary; permissions.ask
# and permissions.deny in settings.json are the jq-less backstop.

set -uo pipefail

command -v jq >/dev/null || exit 0

INPUT=$(cat)
COMMAND=$(jq -r '.tool_input.command // empty' <<<"$INPUT")

[[ -z "$COMMAND" ]] && exit 0

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# The command goes on stdin, not in the environment: environ shares the exec
# size limit, so a long enough one made every spawn die with 126 — no guard ran
# and the call went through. A guard pruned from the dir is still a skip.
run() {
  [[ -f "$DIR/$1" ]] || return 0
  printf '%s' "$COMMAND" | bash "$DIR/$1" --bash-command
}

# Only a refusal stops the chain. Any other non-zero is a broken guard rather
# than a verdict — say so, and let the guards below it still run.
guard() {
  local rc
  run "$1"
  rc=$?
  [[ $rc -eq 2 ]] && exit 2
  [[ $rc -ne 0 ]] && echo "bash-guard.sh: $1 exited $rc, which is not a refusal — the remaining guards still ran, but this one needs fixing." >&2
  return 0
}

# Always-on guards. block-env-access stays wired separately for the file
# tools (Read/Edit/…); its Bash leg runs from here.
guard block-dangerous-commands.sh
guard credential-leak-guard.sh
guard block-env-access.sh

# Trigger-scoped guards — the substring tests over-approximate on purpose; the
# guard itself does the exact matching, this only skips spawns that cannot fire.
case "$COMMAND" in
  *npm* | *yarn* | *bun*) guard block-non-pnpm.sh ;;
esac
case "$COMMAND" in
  *git*commit* | *git*add*) guard enforce-commit-hygiene.sh ;;
esac
case "$COMMAND" in
  *git*commit*) guard typecheck-on-commit.sh ;;
esac

exit 0
