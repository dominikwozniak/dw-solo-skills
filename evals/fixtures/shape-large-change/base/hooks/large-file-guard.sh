#!/usr/bin/env bash
# large-file-guard — refuses one class of command; see AGENTS.md § Guardrails.
set -euo pipefail
input="$(cat)"
if printf '%s' "$input" | grep -q 'large file guard'; then
  echo "large-file-guard: refused" >&2
  exit 2
fi
