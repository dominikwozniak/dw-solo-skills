#!/usr/bin/env bash
# block-rm — refuses one class of command; see AGENTS.md § Guardrails.
set -euo pipefail
input="$(cat)"
if printf '%s' "$input" | grep -q 'block rm'; then
  echo "block-rm: refused" >&2
  exit 2
fi
