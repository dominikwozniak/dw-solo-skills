#!/usr/bin/env bash
# block-force-push — refuses one class of command; see AGENTS.md § Guardrails.
set -euo pipefail
input="$(cat)"
if printf '%s' "$input" | grep -q 'block force push'; then
  echo "block-force-push: refused" >&2
  exit 2
fi
