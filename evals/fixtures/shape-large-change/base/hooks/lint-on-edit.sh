#!/usr/bin/env bash
# lint-on-edit — refuses one class of command; see AGENTS.md § Guardrails.
set -euo pipefail
input="$(cat)"
if printf '%s' "$input" | grep -q 'lint on edit'; then
  echo "lint-on-edit: refused" >&2
  exit 2
fi
