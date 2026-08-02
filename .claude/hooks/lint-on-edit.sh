#!/usr/bin/env bash
# PostToolUse hook — runs the project's lint command on the edited file.
# Reads tool_input.file_path from stdin (Claude Code hook protocol).
# Lint command resolved in order:
#   1. CLAUDE.local.md "Lint command:" value (if present)
#   2. package.json scripts.lint (with --fix if eslint/biome detected)
#   3. pnpm exec eslint --fix / npx eslint --fix
# Exits 0 on success, 2 + stderr on lint failure so Claude self-corrects.

set -uo pipefail

command -v jq >/dev/null || exit 0

input=$(cat)
tool_name=$(jq -r '.tool_name // empty' <<<"$input")
file_path=$(jq -r '.tool_input.file_path // empty' <<<"$input")

case "$tool_name" in
  Edit|Write|MultiEdit) ;;
  *) exit 0 ;;
esac

[[ -z "$file_path" ]] && exit 0
[[ -f "$file_path" ]] || exit 0
[[ "$file_path" =~ \.(ts|tsx|js|jsx|mjs|cjs)$ ]] || exit 0

repo_root="$(git -C "$(dirname "$file_path")" rev-parse --show-toplevel 2>/dev/null)" || exit 0
cd "$repo_root" || exit 0

# Pull the command out of the "- **Lint command**: `pnpm lint`" line. Deliberately free of `\s`:
# BSD sed (macOS) does not implement it in ERE, and the previous version's `:\s*` matched the
# literal colon and then nothing, capturing a single space. A space is not empty, so it sailed
# through the -n guard below and `eval " \"$file_path\""` EXECUTED the edited file instead of
# linting it — harmless on a non-executable .ts, not harmless in general.
resolve_lint_cmd() {
  if [[ -f "CLAUDE.local.md" ]]; then
    local line from_md
    line=$(grep -E '^[[:space:]]*[-*]?[[:space:]]*\*{0,2}Lint command\*{0,2}:' CLAUDE.local.md | head -n1)
    # The first backticked span is the command — that is how the line is written. A freshly
    # scaffolded CLAUDE.local.md has the bare `{{LINT_COMMAND}}` placeholder and no backticks,
    # so fall back to the rest of the line and let the placeholder check reject it.
    from_md=$(printf '%s\n' "$line" | sed -n 's/.*Lint command[*]*:[^`]*`\([^`]*\)`.*/\1/p')
    [[ -z "$from_md" ]] && from_md=$(printf '%s\n' "$line" | sed 's/.*Lint command[*]*://')
    from_md=$(printf '%s' "$from_md" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
    if [[ -n "$from_md" && "$from_md" != "{{LINT_COMMAND}}" ]]; then
      echo "$from_md"
      return
    fi
  fi
  if command -v pnpm >/dev/null && [[ -f "package.json" ]] && jq -e '.devDependencies.eslint // .dependencies.eslint' package.json >/dev/null 2>&1; then
    echo "pnpm exec eslint --fix --max-warnings 0"
    return
  fi
  if command -v npx >/dev/null && [[ -f "package.json" ]] && jq -e '.devDependencies.eslint // .dependencies.eslint' package.json >/dev/null 2>&1; then
    echo "npx eslint --fix --max-warnings 0"
    return
  fi
  echo ""
}

cmd=$(resolve_lint_cmd)
# Blank-safe, not just empty-safe: a whitespace-only command would `eval` into running the file.
[[ "$cmd" =~ [^[:space:]] ]] || exit 0

if ! output=$(eval "$cmd \"$file_path\"" 2>&1); then
  {
    echo "Lint failed for $file_path ($cmd):"
    echo "$output"
  } >&2
  exit 2
fi

exit 0
