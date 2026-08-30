#!/usr/bin/env bash
# PreToolUse Bash hook — runs the declared typecheck before a `git commit` that
# carries TS/TSX changes, so the commit is what proves the tree green and no
# full-project pass runs at every turn end (its predecessor, typecheck-on-stop,
# did — measured at 4-5 s of dead wall-clock per turn on a mid-size app).
# Skip via CLAUDE_SKIP_TYPECHECK=1. Resolution order and the `none` sentinel
# match typecheck-on-stop.sh:
#   1. AGENTS.md "Typecheck command:" → 2. CLAUDE.local.md → 3. package.json
#   scripts.typecheck → 4. tsc --noEmit. A declared `none` stops the chain.
# Exit 2 + stderr on failure refuses the commit and Claude self-corrects.

set -uo pipefail

[[ -n "${CLAUDE_SKIP_TYPECHECK:-}" ]] && exit 0

if [[ -n "${DW_GUARD_COMMAND:-}" ]]; then
  COMMAND="$DW_GUARD_COMMAND"
else
  command -v jq >/dev/null || exit 0
  INPUT=$(cat)
  COMMAND=$(jq -r '.tool_input.command // empty' <<<"$INPUT")
fi

[[ -z "$COMMAND" ]] && exit 0

# Only a real `git … commit`, in any wrapper spelling (sudo, rtk, VAR=… prefix),
# `git -C <path>` included — the same boundary shape the sibling guards use.
printf '%s' "$COMMAND" | grep -qE '(^|[;&|][[:space:]]*)([A-Za-z_][A-Za-z0-9_]*=[^[:space:]]*[[:space:]]+|sudo[[:space:]]+|rtk[[:space:]]+([a-z-]+[[:space:]]+)?)*git([[:space:]]+-C[[:space:]]+("[^"]*"|'"'"'[^'"'"']*'"'"'|[^[:space:];&|]+))?[[:space:]]+commit\b' || exit 0

repo_root="$(git rev-parse --show-toplevel 2>/dev/null)" || exit 0
cd "$repo_root" || exit 0

# TS in what this commit will carry: the index — plus tracked modifications when
# the command stages as it commits (-a/--all; --amend carries no such flag).
staged=$(git diff --name-only --cached --diff-filter=ACMR | grep -E '\.(ts|tsx)$' || true)
if [[ -z "$staged" ]] && printf '%s' "$COMMAND" | grep -qE '[[:space:]](-[a-zA-Z]*a[a-zA-Z]*|--all)([[:space:]]|$)'; then
  staged=$(git diff --name-only --diff-filter=ACMR | grep -E '\.(ts|tsx)$' || true)
fi

[[ -z "$staged" ]] && exit 0

# Same resolver as typecheck-on-stop.sh — POSIX classes, `none` tested on the
# raw remainder before backtick extraction, blank-safe.
resolve_typecheck_cmd() {
  local md line rest from_md
  for md in "AGENTS.md" "CLAUDE.local.md"; do
    [[ -f "$md" ]] || continue
    line=$(grep -E '^[[:space:]]*[-*]?[[:space:]]*\*{0,2}Typecheck command\*{0,2}:' "$md" | head -n1)
    [[ -n "$line" ]] || continue
    rest=$(printf '%s\n' "$line" | sed -e 's/.*Typecheck command[*]*://' -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
    case "$rest" in
      none | None | NONE | none[!A-Za-z0-9]* | None[!A-Za-z0-9]* | NONE[!A-Za-z0-9]*)
        echo "none"
        return
        ;;
    esac
    from_md=$(printf '%s\n' "$line" | sed -n 's/.*Typecheck command[*]*:[^`]*`\([^`]*\)`.*/\1/p')
    [[ -z "$from_md" ]] && from_md="$rest"
    from_md=$(printf '%s' "$from_md" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
    if [[ -n "$from_md" && "$from_md" != "{{TYPECHECK_COMMAND}}" ]]; then
      echo "$from_md"
      return
    fi
  done
  if [[ -f "package.json" ]] && jq -e '.scripts.typecheck' package.json >/dev/null 2>&1; then
    if command -v pnpm >/dev/null && [[ -f "pnpm-lock.yaml" ]]; then
      echo "pnpm run typecheck"
      return
    fi
    echo "npm run typecheck"
    return
  fi
  if command -v pnpm >/dev/null && [[ -f "tsconfig.json" ]]; then
    echo "pnpm exec tsc --noEmit"
    return
  fi
  if command -v npx >/dev/null && [[ -f "tsconfig.json" ]]; then
    echo "npx tsc --noEmit"
    return
  fi
  echo ""
}

cmd=$(resolve_typecheck_cmd)
[[ "$cmd" == "none" ]] && exit 0
[[ "$cmd" =~ [^[:space:]] ]] || exit 0

if ! output=$(eval "$cmd" 2>&1); then
  {
    echo "Typecheck failed ($cmd) — commit refused:"
    echo "$output"
  } >&2
  exit 2
fi

exit 0
