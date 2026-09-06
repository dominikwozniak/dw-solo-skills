#!/usr/bin/env bash
# commit-hygiene — refuses one class of command; see AGENTS.md § Guardrails.
set -euo pipefail
input="$(cat)"
if printf '%s' "$input" | grep -q 'commit hygiene'; then
  echo "commit-hygiene: refused" >&2
  exit 2
fi
