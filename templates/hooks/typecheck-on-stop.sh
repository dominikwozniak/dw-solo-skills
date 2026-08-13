#!/usr/bin/env bash
# Stop hook — runs typecheck when TS/TSX files changed in working tree.
# Skip via CLAUDE_SKIP_TYPECHECK=1.
# Typecheck command resolved in order:
#   1. AGENTS.md "Typecheck command:" value — tracked, the one the scaffold writes
#   2. CLAUDE.local.md "Typecheck command:" value — legacy; repos scaffolded
#      before agent memory moved into AGENTS.md still keep theirs there
#   3. package.json scripts.typecheck (pnpm run typecheck)
#   4. pnpm exec tsc --noEmit / npx tsc --noEmit
# CLAUDE.md is deliberately absent from that list: it is a symlink to AGENTS.md,
# so reading it would be reading step 1 twice.
#
# A declared value of `none` means "this project has no typechecker" and STOPS
# the chain — it must not fall through to the tsc probe, which would contradict
# what the file says. Before that was handled, the honest value a Node-without-TS
# repo writes was `eval`ed as a command at the end of every turn.
# Exits 0 on success, 2 + stderr on failure so Claude self-corrects.

set -uo pipefail

[[ -n "${CLAUDE_SKIP_TYPECHECK:-}" ]] && exit 0
command -v jq >/dev/null || exit 0

repo_root="$(git rev-parse --show-toplevel 2>/dev/null)" || exit 0
cd "$repo_root" || exit 0

changed=$(
  {
    git diff --name-only --diff-filter=ACMR
    git diff --name-only --cached --diff-filter=ACMR
    git ls-files --others --exclude-standard
  } | grep -E '\.(ts|tsx)$' || true
)

[[ -z "$changed" ]] && exit 0

# POSIX classes, not `\s` — BSD grep/sed (macOS) do not implement it in ERE, so `:\s*` matches the
# colon followed by zero literal `s` and the capture keeps its leading whitespace. Same extraction
# shape as lint-on-edit.sh, deliberately: one bug fixed twice is one bug fixed once.
#
# Echoes the command, the literal `none` for an explicit skip, or nothing at all.
resolve_typecheck_cmd() {
  local md line rest from_md
  for md in "AGENTS.md" "CLAUDE.local.md"; do
    [[ -f "$md" ]] || continue
    line=$(grep -E '^[[:space:]]*[-*]?[[:space:]]*\*{0,2}Typecheck command\*{0,2}:' "$md" | head -n1)
    [[ -n "$line" ]] || continue
    rest=$(printf '%s\n' "$line" | sed -e 's/.*Typecheck command[*]*://' -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
    # `none` is tested on the RAW remainder, before any backtick extraction — the same order fix
    # lint-on-edit.sh needed. `none — the `evals/*.ts` types are stripped` resolved to `evals/*.ts`
    # and got eval'ed at the end of every turn; the sentinel has to win over explanatory prose.
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
# `none` is a declaration, not a command: the project says it has no typechecker.
[[ "$cmd" == "none" ]] && exit 0
# Blank-safe, not just empty-safe — the same trap lint-on-edit.sh sprang.
[[ "$cmd" =~ [^[:space:]] ]] || exit 0

if ! output=$(eval "$cmd" 2>&1); then
  {
    echo "Typecheck failed ($cmd):"
    echo "$output"
  } >&2
  exit 2
fi

exit 0
