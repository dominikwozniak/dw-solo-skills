#!/bin/bash
# PreToolUse Bash hook — blocks dangerous/destructive commands (git and beyond).
# Reads tool_input.command from stdin (Claude Code hook protocol).
# Exit 2 + stderr message causes Claude to see the block and self-correct.
# Patterns are anchored to a command boundary (line start, or after ; & |) so
# prose inside quotes (commit messages, echo strings) doesn't false-positive.
# Guardrail against agent accidents — NOT a security boundary; permissions.ask
# and permissions.deny in settings.json are the jq-less backstop.
# Adapted from mattpocock/skills/skills/misc/git-guardrails-claude-code.

set -uo pipefail

command -v jq >/dev/null || exit 0

INPUT=$(cat)
COMMAND=$(jq -r '.tool_input.command // empty' <<<"$INPUT")

[[ -z "$COMMAND" ]] && exit 0

# See through wrapper prefixes: a destructive command stays destructive when run
# via sudo or wrapped by RTK — `rtk <cmd>` (the auto-rewrite), `rtk proxy <cmd>`,
# and the subcommands that execute an arbitrary command themselves (`rtk run` is
# a raw `sh -c`; `err`, `summary`, `test` run it and filter the output). One
# optional word after `rtk` covers every form, present and future.
# Consume zero or more wrappers right after a boundary so `rtk git push --force`
# matches the same as `git push --force`.
WRAPPER='(sudo[[:space:]]+|rtk[[:space:]]+([a-z-]+[[:space:]]+)?)*'

# Start-of-command boundary: line start, or right after ; & | (chain/pipe), then
# any wrapper prefixes, then an optional quote (`rtk run "git push --force"`).
BOUNDARY="(^|[;&|][[:space:]]*)${WRAPPER}[\"']?"

# A `.` path argument meaning "the whole working tree", in every spelling: quoted
# or bare, with or without a trailing slash, and ending on the closing quote whose
# opener BOUNDARY absorbed (`rtk run "git restore ."`). The end anchor is the point
# — a bare `\.` also matched the leading dot of a dotted path, so restoring one
# tracked file under `.ai/` or `.claude/` read as wiping the whole tree. It has to
# be one constant rather than inline: the patterns below are single-quoted, which
# cannot carry the `'` this quote class needs.
DOT_ARG="[\"']?\./?[\"']?[[:space:]]*[\"']?[[:space:]]*(\$|[;&|])"

# `git -C <path> <cmd>` runs the command in another repo, so it is the same command
# with the same blast radius. Only the patterns using DOT_ARG carry this so far —
# `git -C sub push --force` and friends are still unmatched (backlogged).
GIT="git( -C [^;&|]*)?"

DANGEROUS_PATTERNS=(
  'git push( [^;&|]*)?( --force| -f\b)'                   # force push, any arg order (incl. --force-with-lease)
  'git push( [^;&|]*)?( --delete\b| :\S)'                 # remote branch deletion (push --delete / push origin :branch)
  'git reset( [^;&|]*)? --hard'                           # discards index + working tree
  'git clean( +-[A-Za-z-]+)* +(-[A-Za-z]*[dfxX]|--force)' # deletes untracked files/dirs — any flag order (-fd, -f -d, -xdf, -d, --force)
  'git branch( [^;&|]*)?( -D\b| -f\b| --force\b)'         # force-deletes or force-repoints a branch
  "$GIT"' checkout (-- +)?'"$DOT_ARG"                     # discards all working-tree changes
  "$GIT"' restore (-- +)?'"$DOT_ARG"                      # discards all working-tree changes
  'git stash clear\b'                                     # wipes every stash, unrecoverable
  'rm( [^;&|]*)? /\*? *($|[;&|])'                         # rm aimed at / or /*
  'rm( [^;&|]*)? (~|\$HOME)/? *($|[;&|])'                 # rm aimed at the home dir
  'rm( [^;&|]*)? \.\.?/? *($|[;&|])'                      # rm aimed at . or .. (cwd wipe)
  'rmdir\b'                                               # directory removal — ask the user instead
  'find( [^;&|]*)? -delete\b'                             # bulk delete via find
  'shred\b'                                               # irrecoverable file destruction
)

for pattern in "${DANGEROUS_PATTERNS[@]}"; do
  if echo "$COMMAND" | grep -qE "${BOUNDARY}${pattern}"; then
    echo "BLOCKED: '$COMMAND' matches dangerous pattern '$pattern'. Refused by a dw-* guardrail hook. If you genuinely need this, the user must run it manually." >&2
    exit 2
  fi
done

exit 0
