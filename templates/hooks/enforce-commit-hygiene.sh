#!/bin/bash
# PreToolUse Bash hook — enforces the commit conventions the project DECLARES, so
# the rules a session is trusted to follow are checked instead. Four refusals:
#
#   1. a `-m` subject that misses the declared "- **Commit pattern**:" ERE
#   2. a message missing the declared "- **Commit trailer**:" line
#   3. a LIVE backtick inside a `-m` string — command substitution that mangles
#      the message and still exits 0, so nobody notices until they read the log
#   4. `git add -A` / `git add .` — stage session work by name
#
# Both policies are declared, never inferred from prose. The bullets resolve the
# way lint-on-edit.sh's does: AGENTS.md first, CLAUDE.local.md as the legacy
# fallback, the first backticked span is the value, and a standalone `none`
# disables the check. The PATTERN falls back to Conventional Commits when no
# bullet exists; the TRAILER falls back to `none`, because a requirement nobody
# declared must not start failing commits in a repo that never asked for it.
#
# Exit 2 + stderr message causes Claude to see the block and self-correct.
# Guardrail against agent sloppiness — NOT a security boundary. Check 4 in
# particular is a habit rule, not a safety one; the user can always run the
# command themselves.
#
# WHY A LEXER AND NOT `xargs -n1`. The obvious way to pull a `-m` value out is to
# let xargs re-tokenize the command, honouring its quoting. It does not survive
# contact with this repo: BSD xargs (macOS) dies with "unterminated quote" the
# moment a quoted argument contains a NEWLINE, and a multi-line `-m` body is the
# normal shape here — so tokenization silently stopped at `-m` and every commit
# read as "no message". The scanner below is ~40 lines, has no such limit, and
# pays for itself twice: check 3 needs to know whether a backtick sat in a
# single-quoted span (inert) or a double-quoted one (live), which is exactly the
# state the scan already carries and no token list can reconstruct.
#
# Wrapper prefixes need no handling of their own, unlike in
# block-dangerous-commands.sh: the walk keys off a `git` token, and every token
# before one — `sudo`, `rtk`, `rtk proxy` — is simply not that token, so
# `rtk git commit -m …` and `sudo git commit -m …` land on the same path as the
# bare form. `git -C <path> commit` does too; the pre-verb options are consumed.

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
# Cheap bail-out before the per-character scan: nothing here can fire without a
# `git` token, and the two verbs it cares about are `commit` and `add`.
[[ "$COMMAND" == *git* ]] || exit 0
case "$COMMAND" in
  *commit* | *add*) ;;
  *) exit 0 ;;
esac

repo_root="$(git rev-parse --show-toplevel 2>/dev/null)" || exit 0

# --- the declared policies ---------------------------------------------------
# Conventional Commits, the default when no bullet is declared. Kept as one
# constant so the block message can quote the same string the check applied.
# CLAUDE_COMMIT_PATTERN_DEFAULT replaces this fallback and nothing else — a
# declared bullet still wins — so a copy wired from outside the repo
# (~/.claude/hooks/) can pass `none` where the log was never Conventional Commits
# and keep checks 3 and 4.
DEFAULT_PATTERN='^(build|chore|ci|docs|feat|fix|perf|refactor|revert|style|test)(\([^)]+\))?!?: .+'
[[ -n "${CLAUDE_COMMIT_PATTERN_DEFAULT:-}" ]] && DEFAULT_PATTERN="$CLAUDE_COMMIT_PATTERN_DEFAULT"

# resolve_declared <label> <default> — echoes the declared value, the literal
# `none`, or <default>. POSIX classes, not `\s`: BSD sed does not implement it in
# ERE, and `:\s*` captures a leading space that reads as "declared" downstream —
# the trap lint-on-edit.sh and the since-retired typecheck-on-stop.sh each sprang once.
resolve_declared() {
  local label="$1" fallback="$2" md line rest value
  for md in "$repo_root/AGENTS.md" "$repo_root/CLAUDE.local.md"; do
    [[ -f "$md" ]] || continue
    line=$(grep -E "^[[:space:]]*[-*]?[[:space:]]*\*{0,2}$label\*{0,2}:" "$md" | head -n1)
    [[ -n "$line" ]] || continue
    rest=$(printf '%s\n' "$line" | sed -e "s/.*$label[*]*://" -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
    # `none` is tested on the RAW remainder, before backtick extraction: a line
    # reading "none — the log predates the rule" must skip, not adopt `the log`
    # as a pattern. The word has to stand alone.
    case "$rest" in
      none | None | NONE | none[!A-Za-z0-9]* | None[!A-Za-z0-9]* | NONE[!A-Za-z0-9]*)
        echo "none"
        return
        ;;
    esac
    value=$(printf '%s\n' "$line" | sed -n "s/.*$label[*]*:[^\`]*\`\([^\`]*\)\`.*/\1/p")
    [[ -z "$value" ]] && value="$rest"
    value=$(printf '%s' "$value" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
    # A freshly rendered AGENTS.md still carries the bare placeholder; that is
    # not a declaration, so fall through to the default.
    case "$value" in
      "" | '{{COMMIT_PATTERN}}' | '{{COMMIT_TRAILER}}') continue ;;
    esac
    echo "$value"
    return
  done
  echo "$fallback"
}

PATTERN=$(resolve_declared "Commit pattern" "$DEFAULT_PATTERN")
TRAILER=$(resolve_declared "Commit trailer" "none")

# --- the lexer ---------------------------------------------------------------
# Splits the command into TOKENS the way a shell would — quotes removed, escapes
# honoured — and records per token whether a LIVE backtick appeared in it
# (TOKEN_LIVE_BT), meaning one outside single quotes and not backslash-escaped.
# `;` `&` `|` become tokens of their own so a chained command can be closed off.
TOKENS=()
TOKEN_LIVE_BT=()
lex() {
  # Two statements, not one `local s="$1" n=${#s}`: every word of a `local` is
  # expanded BEFORE the builtin runs, so `${#s}` would read an `s` that is not
  # set yet — which under `set -u` aborts the hook at exit 1, i.e. it stops
  # guarding and says nothing.
  local s="$1"
  local n=${#s}
  local i=0 ch cur="" have=0 live=0 state=plain
  TOKENS=()
  TOKEN_LIVE_BT=()
  while ((i < n)); do
    ch=${s:i:1}
    case "$state" in
      plain)
        case "$ch" in
          "'")
            state=sq
            have=1
            ;;
          '"')
            state=dq
            have=1
            ;;
          '\')
            i=$((i + 1))
            cur+=${s:i:1}
            have=1
            ;;
          '`')
            live=1
            cur+=$ch
            have=1
            ;;
          ' ' | $'\t' | $'\n')
            if ((have)); then
              TOKENS+=("$cur")
              TOKEN_LIVE_BT+=("$live")
              cur=""
              have=0
              live=0
            fi
            ;;
          ';' | '&' | '|')
            if ((have)); then
              TOKENS+=("$cur")
              TOKEN_LIVE_BT+=("$live")
              cur=""
              have=0
              live=0
            fi
            TOKENS+=("$ch")
            TOKEN_LIVE_BT+=("0")
            ;;
          *)
            cur+=$ch
            have=1
            ;;
        esac
        ;;
      sq)
        # Inside single quotes NOTHING is special — not the backslash, and not
        # the backtick, which is the whole reason this state is tracked apart.
        case "$ch" in
          "'") state=plain ;;
          *) cur+=$ch ;;
        esac
        ;;
      dq)
        case "$ch" in
          '"') state=plain ;;
          '\')
            i=$((i + 1))
            cur+=${s:i:1}
            ;;
          '`')
            live=1
            cur+=$ch
            ;;
          *) cur+=$ch ;;
        esac
        ;;
    esac
    i=$((i + 1))
  done
  if ((have)); then
    TOKENS+=("$cur")
    TOKEN_LIVE_BT+=("$live")
  fi
  return 0
}

block() {
  echo "BLOCKED: $1" >&2
  echo "Refused by a dw-* guardrail hook. If this is genuinely right, the user must run it manually." >&2
  exit 2
}

# --- the checks over one `git commit` ----------------------------------------
# Group state, scalars rather than arrays: bash 3.2 errors on "${arr[@]}" for an
# empty array under `set -u`, and the group only ever needs the first message,
# the concatenation of all of them, and one sticky flag.
MSG_COUNT=0
MSG_FIRST=""
MSG_ALL=""
MSG_LIVE_BT=0
MSG_FROM_FILE=0

reset_group() {
  MSG_COUNT=0
  MSG_FIRST=""
  MSG_ALL=""
  MSG_LIVE_BT=0
  MSG_FROM_FILE=0
}

add_msg() {
  if ((MSG_COUNT == 0)); then
    MSG_FIRST="$1"
    MSG_ALL="$1"
  else
    # Repeated `-m` is how git builds a body: each one becomes its own paragraph.
    MSG_ALL="$MSG_ALL"$'\n\n'"$1"
  fi
  MSG_COUNT=$((MSG_COUNT + 1))
  [[ "$2" == "1" ]] && MSG_LIVE_BT=1
  return 0
}

# has_trailer <key> <message> — a line whose start matches <key>, case-blind.
# The key goes into a `case` glob, so a glob metacharacter in a declared trailer
# would be read as a pattern; trailer keys are words and colons, so that is a
# theoretical hole rather than a live one.
has_trailer() {
  local key line
  key=$(printf '%s' "$1" | tr 'A-Z' 'a-z')
  while IFS= read -r line; do
    line=$(printf '%s' "$line" | sed -e 's/^[[:space:]]*//' | tr 'A-Z' 'a-z')
    case "$line" in
      "$key"*) return 0 ;;
    esac
  done <<<"$2"
  return 1
}

check_group() {
  local subject
  ((MSG_COUNT == 0)) && return 0 # editor commit — the message is not here to read
  ((MSG_FROM_FILE)) && return 0  # -F/--file — likewise

  if ((MSG_LIVE_BT)); then
    block "this commit message carries a live backtick inside a double-quoted -m, so the shell will run the backticked span and splice its output in — the commit succeeds with that phrase GONE. Either drop the backticks, single-quote the message, escape them (\\\`), or write the message to a file and use 'git commit -F <file>'."
  fi

  subject=${MSG_FIRST%%$'\n'*}

  # git's own machine-written subjects, which no project pattern describes.
  case "$subject" in
    "Merge "* | "Revert "* | "fixup! "* | "squash! "* | "amend! "*) return 0 ;;
  esac
  # A message assembled by the shell is not the message: `-m "$MSG"` reaches here
  # as the literal dollars-and-a-name, and checking that would be checking
  # nothing. Pass it through rather than block on a string nobody wrote. The
  # class matters — a message reading "costs $5" holds no expansion and stays
  # checked, where a blanket `*$*` would have waved it through.
  if printf '%s' "$MSG_ALL" | grep -q '\$[({A-Za-z_]'; then
    return 0
  fi

  if [[ "$PATTERN" != "none" ]] && ! printf '%s' "$subject" | grep -qE "$PATTERN"; then
    block "commit subject \"$subject\" does not match this project's declared commit pattern.
  pattern: $PATTERN
  declared in AGENTS.md as '- **Commit pattern**:' (a standalone 'none' disables this check).
Rewrite the subject to match — most often that means a 'type(scope): subject' prefix, lowercase and imperative."
  fi

  if [[ "$TRAILER" != "none" ]] && ! has_trailer "$TRAILER" "$MSG_ALL"; then
    block "commit message is missing this project's declared trailer.
  trailer: $TRAILER
  declared in AGENTS.md as '- **Commit trailer**:' (a standalone 'none' disables this check).
Add it as the last line of the message — with repeated -m, that is a final -m of its own."
  fi
  return 0
}

# --- the walk ----------------------------------------------------------------
lex "$COMMAND"

verb=""
i=0
count=${#TOKENS[@]}
while ((i < count)); do
  t="${TOKENS[i]}"
  case "$t" in
    ';' | '&' | '|')
      check_group
      reset_group
      verb=""
      i=$((i + 1))
      continue
      ;;
    git)
      check_group
      reset_group
      verb=""
      i=$((i + 1))
      # Consume everything before the subcommand: `-C <path>`, `-c k=v`,
      # `--git-dir=…`. A `git -C sub commit` is the same commit in another repo.
      while ((i < count)); do
        case "${TOKENS[i]}" in
          -C | -c | --git-dir | --work-tree | --namespace)
            i=$((i + 2))
            ;;
          -*)
            i=$((i + 1))
            ;;
          *)
            verb="${TOKENS[i]}"
            i=$((i + 1))
            break
            ;;
        esac
      done
      continue
      ;;
  esac

  case "$verb" in
    commit)
      case "$t" in
        -F | --file)
          MSG_FROM_FILE=1
          i=$((i + 2)) # the flag and its filename
          continue
          ;;
        --file=* | -F?*)
          MSG_FROM_FILE=1
          ;;
        --message)
          if ((i + 1 < count)); then
            add_msg "${TOKENS[i + 1]}" "${TOKEN_LIVE_BT[i + 1]}"
            i=$((i + 2))
            continue
          fi
          ;;
        --message=*)
          add_msg "${t#--message=}" "${TOKEN_LIVE_BT[i]}"
          ;;
        --*) ;; # every other long option is none of this hook's business
        -*)
          # A short-option cluster carrying `m`: -m, -am, -sm, and the glued
          # forms -mfix: … / -amfix: …, where the message starts right after the
          # `m`. Anything without an `m` (-a, -s, --amend's sibling -e) is skipped.
          rest="${t#-}"
          case "$rest" in
            *m*)
              tail="${rest#*m}"
              if [[ -z "$tail" ]]; then
                if ((i + 1 < count)); then
                  add_msg "${TOKENS[i + 1]}" "${TOKEN_LIVE_BT[i + 1]}"
                  i=$((i + 2))
                  continue
                fi
              else
                add_msg "$tail" "${TOKEN_LIVE_BT[i]}"
              fi
              ;;
          esac
          ;;
      esac
      ;;
    add)
      case "$t" in
        --all)
          block "'git add' is staging the whole working tree ($t). Stage session work by name — 'git add path1 path2' — so an unrelated or half-finished file cannot ride along into the commit."
          ;;
        # Every other long option, and the `--` separator, are none of this
        # hook's business — and this arm has to precede the short-cluster one
        # below, which would otherwise read the `A` in a long name as the flag.
        --*) ;;
        # `-A` in any cluster: -A, -Av, -uA.
        -*A*)
          block "'git add' is staging the whole working tree ($t). Stage session work by name — 'git add path1 path2' — so an unrelated or half-finished file cannot ride along into the commit."
          ;;
        . | ./)
          block "'git add $t' stages the whole working tree. Stage session work by name — 'git add path1 path2' — so an unrelated or half-finished file cannot ride along into the commit."
          ;;
      esac
      ;;
  esac
  i=$((i + 1))
done

check_group

exit 0
