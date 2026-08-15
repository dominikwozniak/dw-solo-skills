#!/usr/bin/env bash
# `pnpm lint [PATHS...]` — agnix over the given paths, or the whole tree when given none.
#
# The paths are load-bearing, not a convenience: AGENTS.md's `- **Lint command**:` bullet is read by
# .claude/hooks/lint-on-edit.sh, which appends the edited file as one literal argument. A version of
# this script that hardcoded `.` swallowed that argument and walked the whole tree on every single
# edit — slow, exposed to the OOM below, and a silent lie about what the root file claims.
#
# This script filters nothing on the way through: an explicitly named path is an explicit request,
# and silently dropping arguments is the bug above. Before assuming a path you hand over is covered
# by .agnix.toml's `exclude` list, read the NOTE there — .husky/pre-commit is where filtering lives.
set -uo pipefail

# Bash 3.2 (macOS system bash) errors on an empty `"$@"` under `set -u`, so pick the argv rather
# than expanding it bare.
if [ "$#" -gt 0 ]; then
  paths=("$@")
else
  paths=(".")
fi

out="$(NODE_OPTIONS=--max-old-space-size=8192 node_modules/.bin/agnix "${paths[@]}" 2>&1)"; code=$?
printf '%s\n' "$out"
if printf '%s' "$out" | grep -qi 'terminated abnormally'; then
  echo "::error::agnix terminated abnormally — lint did not run" >&2
  exit 1
fi
exit "$code"
