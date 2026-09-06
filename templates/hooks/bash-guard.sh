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

# A heredoc BODY is the text of a file being written, not commands being run, and
# every guard below matches line by line — so `npm install` inside one sits at a
# start-of-line anchor and reads exactly like an invocation. That false refusal is
# the single biggest source of friction these guardrails cause: it stops the agent
# from writing its own test fixtures. Dropped once, here, so the trigger cases
# below stop spawning on it too; a guard wired directly rather than through this
# dispatcher keeps the old behaviour, which `bash-guard.sh` has always allowed.
#
# The opener line is KEPT, because a redirect target on it (`cat > .env <<EOF`) is
# a real path that must still block — but its `<<` is collapsed to `<` on the way
# out. Two guards downstream run a heredoc strip of their own, and handed a kept
# opener with no terminator left to find they would enter body mode and swallow
# every real command after it. The `(^|[^<])` guard is what keeps a here-string
# (`<<<`) from being rewritten into an opener.
#
# Copy of the pass in block-env-access.sh — the third of this shape, and the same
# bargain the other guards strike: each has to work alone when the dispatcher
# prunes or skips it. Its known weakness travels too: a literal `<<` anywhere
# starts body mode. Guardrail, not a security boundary.
HEREDOC_OPEN='(^|[^<])<<-?[[:space:]]*["'"'"'\]?([A-Za-z_][A-Za-z0-9_]*)'
strip_heredocs() {
  local line delim="" body=0
  while IFS= read -r line; do
    if [[ $body -eq 1 ]]; then
      [[ "$line" =~ ^[[:space:]]*$delim[[:space:]]*$ ]] && { body=0; delim=""; }
      continue
    fi
    if [[ "$line" =~ $HEREDOC_OPEN ]]; then
      delim="${BASH_REMATCH[2]}"
      body=1
      printf '%s\n' "$line" | sed -E 's/(^|[^<])<<-?/\1</'
      continue
    fi
    printf '%s\n' "$line"
  done
  return 0
}

# What the guards actually scan. Identical to COMMAND for anything without a
# heredoc, which is nearly everything, so their refusal messages are unchanged.
SCAN=$(printf '%s\n' "$COMMAND" | strip_heredocs)

# The command goes on stdin, not in the environment: environ shares the exec
# size limit, so a long enough one made every spawn die with 126 — no guard ran
# and the call went through. A guard pruned from the dir is still a skip.
run() {
  [[ -f "$DIR/$1" ]] || return 0
  printf '%s' "$SCAN" | bash "$DIR/$1" --bash-command
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
# `npx` needs its own arm: it shares no substring with `npm`, so a trigger list
# without it means the guard is never spawned and the refusal never happens, no
# matter what the guard's own patterns say. A guard's self-test calls it directly
# and cannot see that — this list is the only thing that decides it runs at all.
case "$SCAN" in
  *npm* | *npx* | *yarn* | *bun*) guard block-non-pnpm.sh ;;
esac
case "$SCAN" in
  *git*commit* | *git*add*) guard enforce-commit-hygiene.sh ;;
esac
case "$SCAN" in
  *git*commit*) guard typecheck-on-commit.sh ;;
esac

exit 0
