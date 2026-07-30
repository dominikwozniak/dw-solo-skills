#!/usr/bin/env bash
set -uo pipefail
out="$(NODE_OPTIONS=--max-old-space-size=8192 node_modules/.bin/agnix . 2>&1)"; code=$?
printf '%s\n' "$out"
if printf '%s' "$out" | grep -qi 'terminated abnormally'; then
  echo "::error::agnix terminated abnormally — lint did not run" >&2
  exit 1
fi
exit "$code"
