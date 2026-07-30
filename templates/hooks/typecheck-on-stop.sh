#!/usr/bin/env bash
# Stop hook — runs typecheck when TS/TSX files changed in working tree.
# Skip via CLAUDE_SKIP_TYPECHECK=1.
# Typecheck command resolved in order:
#   1. CLAUDE.local.md "Typecheck command:" value
#   2. package.json scripts.typecheck (pnpm run typecheck)
#   3. pnpm exec tsc --noEmit / npx tsc --noEmit
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

resolve_typecheck_cmd() {
  if [[ -f "CLAUDE.local.md" ]]; then
    local from_md
    from_md=$(grep -E "^\s*[-*]?\s*\*\*?Typecheck command\*\*?:" CLAUDE.local.md | sed -E 's/.*Typecheck command\*?\*?:\s*`?([^`]+)`?.*/\1/' | head -n1)
    if [[ -n "$from_md" && "$from_md" != "{{TYPECHECK_COMMAND}}" ]]; then
      echo "$from_md"
      return
    fi
  fi
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
[[ -z "$cmd" ]] && exit 0

if ! output=$(eval "$cmd" 2>&1); then
  {
    echo "Typecheck failed ($cmd):"
    echo "$output"
  } >&2
  exit 2
fi

exit 0
