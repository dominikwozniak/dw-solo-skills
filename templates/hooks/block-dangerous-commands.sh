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

# See through wrapper prefixes: a destructive command stays destructive when run
# via sudo or wrapped by RTK — `rtk <cmd>` (the auto-rewrite), `rtk proxy <cmd>`,
# and the subcommands that execute an arbitrary command themselves (`rtk run` is
# a raw `sh -c`; `err`, `summary`, `test` run it and filter the output). One
# optional word after `rtk` covers every form, present and future.
# A leading `VAR=value` assignment is a wrapper too: the shell strips it and runs
# what follows, so the blast radius is unchanged. It was missing here while
# `block-non-pnpm.sh` had it, which let an assignment prefix carry any destructive
# command past the boundary below.
# Consume zero or more wrappers right after a boundary so `rtk git push --force`
# matches the same as `git push --force`.
WRAPPER='(sudo[[:space:]]+|rtk[[:space:]]+([a-z-]+[[:space:]]+)?|[A-Za-z_][A-Za-z0-9_]*=[^[:space:]]*[[:space:]]+)*'

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
# with the same blast radius — and in a repo with worktrees, `sub` is very often a
# sibling checkout of the very tree the guardrail is protecting. EVERY git pattern
# below carries it; for a while only the DOT_ARG pair did, which meant
# `git -C sub push --force` sailed through while `git push --force` was refused.
#
# The path is ONE argument — a quoted span, or a run of non-space characters — and
# not the `[^;&|]*` it started as. What protects `git commit -m "never reset
# --hard"` from matching the reset pattern is that `git` and `reset` have to be
# ADJACENT; a prefix that swallows spaces destroys exactly that, and the loosest
# form quietly refused every `-C` command whose message quoted a dangerous phrase.
# Keeping the quoted alternatives means a path containing a space still blocks.
GIT="git( -C (\"[^\"]*\"|'[^']*'|[^[:space:];&|]+))?"

DANGEROUS_PATTERNS=(
  "$GIT"' push( [^;&|]*)?( --force| -f\b)'                    # force push, any arg order (incl. --force-with-lease)
  "$GIT"' push( [^;&|]*)?( --delete\b| :\S)'                  # remote branch deletion (push --delete / push origin :branch)
  "$GIT"' reset( [^;&|]*)? --hard'                            # discards index + working tree
  "$GIT"' clean( +-[A-Za-z-]+)* +(-[A-Za-z]*[dfxX]|--force)'  # deletes untracked files/dirs — any flag order (-fd, -f -d, -xdf, -d, --force)
  "$GIT"' branch( [^;&|]*)?( -f\b| --force\b)'                # force-repoints a branch; -D stays ask-level — dw-ship deletes merged branches
  "$GIT"' checkout (-- +)?'"$DOT_ARG"                         # discards all working-tree changes
  "$GIT"' restore (-- +)?'"$DOT_ARG"                          # discards all working-tree changes
  "$GIT"' stash clear\b'                                      # wipes every stash, unrecoverable
  'rm( [^;&|]*)? /\*? *($|[;&|])'                         # rm aimed at / or /*
  'rm( [^;&|]*)? (~|\$HOME)/? *($|[;&|])'                 # rm aimed at the home dir
  'rm( [^;&|]*)? \.\.?/? *($|[;&|])'                      # rm aimed at . or .. (cwd wipe)
  'find( [^;&|]*)? -delete\b'                             # bulk delete via find
  'shred\b'                                               # irrecoverable file destruction
)

# Inside a quoted span, `;` `&` and `|` are text rather than separators, so they
# must not open a command boundary. Without this, `git commit -m "docs: never |
# git push --force"` was refused for naming the thing it forbids, and a heredoc or
# a grep pattern carrying one was unwritable.
#
# It cuts the other way too, which is the part worth knowing: the patterns bound an
# argument run with `[^;&|]*`, and a quoted separator used to END that run — so
# `git push origin "feat|x" --force` never reached its own `--force` and went
# through. Masking makes the run span the quoted text, which is what a shell does.
#
# Twin of the function in block-non-pnpm.sh. Each guard has to work alone when the
# dispatcher prunes or skips it, so this is a copy, and nothing measures the drift
# between them — `grep -rln mask_quoted_separators templates/hooks/` finds both.
mask_quoted_separators() {
  local s="$1"
  local n=${#s}
  local i=0 ch out="" state=plain
  while ((i < n)); do
    ch=${s:i:1}
    # An escaped character is a literal, never a separator, in any state.
    if [[ "$ch" == '\' ]]; then
      out+=$ch
      i=$((i + 1))
      if ((i < n)); then
        ch=${s:i:1}
        case "$ch" in ';' | '&' | '|') ch=$'\002' ;; esac
        out+=$ch
      fi
      i=$((i + 1))
      continue
    fi
    case "$state" in
      plain)
        case "$ch" in
          "'") state=sq ;;
          '"') state=dq ;;
        esac
        ;;
      sq) [[ "$ch" == "'" ]] && state=plain ;;
      dq) [[ "$ch" == '"' ]] && state=plain ;;
    esac
    if [[ "$state" != plain ]]; then
      case "$ch" in ';' | '&' | '|') ch=$'\002' ;; esac
    fi
    out+=$ch
    i=$((i + 1))
  done
  # Unterminated quote: everything after the opener was read as quoted, so a real
  # separator may have been masked. Fail closed — judge the original instead.
  if [[ "$state" != plain ]]; then
    printf '%s' "$s"
  else
    printf '%s' "$out"
  fi
}

SCAN=$(mask_quoted_separators "$COMMAND")

for pattern in "${DANGEROUS_PATTERNS[@]}"; do
  # Matched against SCAN, reported as COMMAND: the user has to see what they typed.
  if printf '%s\n' "$SCAN" | grep -qE "${BOUNDARY}${pattern}"; then
    echo "BLOCKED: '$COMMAND' matches dangerous pattern '$pattern'. Refused by a dw-* guardrail hook. If you genuinely need this, the user must run it manually." >&2
    exit 2
  fi
done

exit 0
