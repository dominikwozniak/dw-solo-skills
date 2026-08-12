#!/bin/bash
# PreToolUse hook — blocks reading/editing/writing .env files (secrets).
# Wire with matcher "Read|Edit|Write|MultiEdit|NotebookEdit|Grep|Bash":
# file tools are checked via tool_input.file_path/.notebook_path/.path,
# Bash via tokens of tool_input.command (cat .env, source .env, cp x .env).
# Allowed basenames: .env.example / .env.sample / .env.template (secret-free).
# Exit 2 + stderr message causes Claude to see the block and self-correct.
# Guardrail against accidental secret exposure — NOT a security boundary
# (quoted paths in Bash slip through; permissions.deny is the backstop).

set -uo pipefail

command -v jq >/dev/null || exit 0

INPUT=$(cat)

ALLOWED_BASENAMES=(".env.example" ".env.sample" ".env.template")

# is_env_file <path-or-token> — 0 if basename is .env / .env.* / .envrc
# and not on the allowlist.
is_env_file() {
  local base="${1##*/}"
  [[ "$base" =~ ^\.env(\..+)?$ || "$base" == ".envrc" ]] || return 1
  local allowed
  for allowed in "${ALLOWED_BASENAMES[@]}"; do
    [[ "$base" == "$allowed" ]] && return 1
  done
  return 0
}

# strip_heredocs — drop heredoc bodies from stdin, keeping each opener line.
# A body is prose, not command tokens: `git commit -F - <<'MSG'` carries a
# commit message the quote-stripping below cannot see any quoting in, so its
# .env mentions would read as bare paths. The opener line is kept, because a
# redirect target on it (`cat > .env <<EOF`) is a real path that must block.
# `[^<]` keeps here-strings (`<<<`) out. The delimiter class is alphanumeric
# only, which is what makes interpolating it into the terminator match safe.
# Deliberately unconditional: a literal `<<` in prose starts body mode and
# swallows the lines below it. This is a guardrail, not a security boundary.
HEREDOC_OPEN='(^|[^<])<<-?[[:space:]]*["'"'"'\]?([A-Za-z_][A-Za-z0-9_]*)'
strip_heredocs() {
  local line delim="" body=0
  while IFS= read -r line; do
    if [[ $body -eq 1 ]]; then
      [[ "$line" =~ ^[[:space:]]*$delim[[:space:]]*$ ]] && { body=0; delim=""; }
      continue
    fi
    printf '%s\n' "$line"
    [[ "$line" =~ $HEREDOC_OPEN ]] && { delim="${BASH_REMATCH[2]}"; body=1; }
  done
  # The loop's status is that last test, false for any command not ending in an
  # opener — which would make the pipeline below non-zero under `pipefail`.
  # Harmless while this file has no `set -e`; the day it gets one, the Bash
  # check would be skipped in full and silently. Pin it to 0 instead.
  return 0
}

block() {
  echo "BLOCKED: $1 touches '$2' — .env files hold secrets and must not be read or modified by the agent (.env.example / .env.sample / .env.template are fine). Refused by a dw-* guardrail hook. If this is genuinely needed (e.g. 'cp .env.example .env'), ask the user to run it manually." >&2
  exit 2
}

TOOL_NAME=$(jq -r '.tool_name // "tool"' <<<"$INPUT")

# File tools: a single path field.
FILE_PATH=$(jq -r '.tool_input.file_path // .tool_input.notebook_path // .tool_input.path // empty' <<<"$INPUT")
if [[ -n "$FILE_PATH" ]]; then
  is_env_file "$FILE_PATH" && block "$TOOL_NAME" "$FILE_PATH"
fi

# Bash: drop heredoc bodies, strip quoted spans (so prose like
# `git commit -m "docs: .env"` passes), split on shell separators, check each
# token's basename. Newlines are folded to spaces only after the heredoc pass —
# sed strips quotes per line, so a multi-line `-m "…"` body would otherwise
# leak its inner lines as tokens. That fold is also why heredocs need their own
# line-based pass first: by the time it runs there are no lines left to find a
# terminator on, and a heredoc body carries no quoting to strip in any case.
COMMAND=$(jq -r '.tool_input.command // empty' <<<"$INPUT")
if [[ -n "$COMMAND" ]]; then
  STRIPPED=$(printf '%s\n' "$COMMAND" | strip_heredocs | tr '\n' ' ' | sed -E 's/"[^"]*"//g' | sed -E "s/'[^']*'//g")
  while IFS= read -r token; do
    [[ -z "$token" ]] && continue
    is_env_file "$token" && block "Bash command" "$token"
  done < <(printf '%s\n' "$STRIPPED" | tr -s "[:space:];|&()<>=\`\"'" '\n')
fi

exit 0
