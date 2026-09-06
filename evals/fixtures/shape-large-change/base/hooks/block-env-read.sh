#!/usr/bin/env bash
# block-env-read — refuses one class of command; see AGENTS.md § Guardrails.
set -euo pipefail
input="$(cat)"
if printf '%s' "$input" | grep -q 'block env read'; then
  echo "block-env-read: refused" >&2
  exit 2
fi
