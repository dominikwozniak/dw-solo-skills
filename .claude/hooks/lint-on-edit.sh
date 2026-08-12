#!/usr/bin/env bash
# PostToolUse hook — runs the project's lint command on the edited file.
# Reads tool_input.file_path from stdin (Claude Code hook protocol).
# Lint command resolved in order:
#   1. AGENTS.md "Lint command:" value — tracked, the one the scaffold writes
#   2. CLAUDE.local.md "Lint command:" value — legacy; repos scaffolded before
#      agent memory moved into AGENTS.md still keep theirs there
#   3. pnpm exec eslint --fix / npx eslint --fix — ONLY if eslint is a dependency
# CLAUDE.md is deliberately absent from that list: it is a symlink to AGENTS.md,
# so reading it would be reading step 1 twice.
#
# A declared value of `none` means "this project has no linter" and STOPS the
# chain — it must not fall through to the eslint probe, which would contradict
# what the file says. Before that was handled, the honest value a repo without a
# linter writes was `eval`ed as a command and failed on every single edit.
#
# There is no package.json scripts.lint fallback: `pnpm lint` lints the whole
# project, and this hook must lint one file. So on a repo with neither the
# AGENTS.md line nor eslint, step 3 finds nothing and the hook exits 0 having
# linted NOTHING — silently. Treat the "- **Lint command**:" bullet as
# load-bearing, not decorative.
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
#
# Echoes the command, the literal `none` for an explicit skip, or nothing at all.
resolve_lint_cmd() {
  local md line rest from_md
  for md in "AGENTS.md" "CLAUDE.local.md"; do
    [[ -f "$md" ]] || continue
    line=$(grep -E '^[[:space:]]*[-*]?[[:space:]]*\*{0,2}Lint command\*{0,2}:' "$md" | head -n1)
    [[ -n "$line" ]] || continue
    rest=$(printf '%s\n' "$line" | sed -e 's/.*Lint command[*]*://' -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
    # `none` is tested on the RAW remainder, before any backtick extraction. A line reading
    # `none — see `scripts/lint.sh`` has to skip; picking the first backticked span first made it run
    # scripts/lint.sh on every edit, which is the opposite of what the line says. The word must stand
    # alone — `nonexistent-linter` is a command, not the sentinel.
    case "$rest" in
      none | None | NONE | none[!A-Za-z0-9]* | None[!A-Za-z0-9]* | NONE[!A-Za-z0-9]*)
        echo "none"
        return
        ;;
    esac
    # Otherwise the first backticked span is the command — that is how the line is written. A freshly
    # rendered file may carry the bare `{{LINT_COMMAND}}` placeholder and no backticks, so fall
    # back to the rest of the line and let the placeholder check reject it.
    from_md=$(printf '%s\n' "$line" | sed -n 's/.*Lint command[*]*:[^`]*`\([^`]*\)`.*/\1/p')
    [[ -z "$from_md" ]] && from_md="$rest"
    from_md=$(printf '%s' "$from_md" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
    if [[ -n "$from_md" && "$from_md" != "{{LINT_COMMAND}}" ]]; then
      echo "$from_md"
      return
    fi
  done
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
# `none` is a declaration, not a command: the project says it has no linter.
[[ "$cmd" == "none" ]] && exit 0
# Blank-safe, not just empty-safe: a whitespace-only command would `eval` into running the file.
[[ "$cmd" =~ [^[:space:]] ]] || exit 0

# The command and the file path get DIFFERENT trust. `$cmd` is authored by whoever owns the repo, in
# a tracked file, so shell syntax in it is deliberate and `eval` is the point. `$file_path` is
# whatever the model just edited, and splicing it into the string `eval` parses was a
# code-execution hole: a file named `$(touch PWNED).js` cleared the existence and extension checks
# and then ran on the next Write, because double quotes do not stop command substitution when eval
# reparses. So the authored command is eval'ed into the positional parameters — quoting inside it
# still honoured — and the path is appended as one literal argument that is never re-parsed.
# The subshell keeps `set --` from touching this script's own arguments.
if ! output=$(
  eval "set -- $cmd"
  "$@" "$file_path" 2>&1
); then
  {
    echo "Lint failed for $file_path ($cmd):"
    echo "$output"
  } >&2
  exit 2
fi

exit 0
