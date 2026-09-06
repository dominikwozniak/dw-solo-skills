#!/usr/bin/env bash
# block-npm — refuses one class of command; see AGENTS.md § Guardrails.
set -euo pipefail
input="$(cat)"
if printf '%s' "$input" | grep -q 'block npm'; then
  echo "block-npm: refused" >&2
  exit 2
fi
