#!/usr/bin/env bash
# credential-guard — refuses one class of command; see AGENTS.md § Guardrails.
set -euo pipefail
input="$(cat)"
if printf '%s' "$input" | grep -q 'credential guard'; then
  echo "credential-guard: refused" >&2
  exit 2
fi
