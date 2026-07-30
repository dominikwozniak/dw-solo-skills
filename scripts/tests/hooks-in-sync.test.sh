#!/usr/bin/env bash
# Self-test pinning the "templates ≡ installed copies" invariant: this repo is
# itself an instance of what dw-init scaffolds, so every hook in .claude/hooks/
# must be a byte-identical, executable copy of its template under
# templates/hooks/ — the hooks you run are the hooks you ship. Every template
# must also be executable (install does `chmod +x`, but a template committed
# without the executable bit would ship broken via `git archive`/checkout).
#
# NOTE: templates/hooks/ here is a vendored copy of the same canon in the
# `dw-skills` repo (team lane). They are byte-identical today and a fix to one
# must be applied to both — nothing across the repo boundary can detect drift.
#
# Run standalone (`bash scripts/tests/hooks-in-sync.test.sh`) or via
# scripts/validate-artifacts.sh. Exit 0 iff every check passes. bash 3.2 safe.
set -uo pipefail
export LC_ALL=C

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
TEMPLATES="$ROOT/templates/hooks"
INSTALLED="$ROOT/.claude/hooks"

PASS=0
FAIL=0
note_pass() { PASS=$((PASS + 1)); echo "  ✓ $1"; }
note_fail() { FAIL=$((FAIL + 1)); echo "  ✗ $1 — $2"; }

echo "templates executable + installed copies byte-identical:"
for tmpl in "$TEMPLATES"/*.sh; do
  name="$(basename "$tmpl")"
  if [ -x "$tmpl" ]; then
    note_pass "template-executable: $name"
  else
    note_fail "template-executable: $name" "fix: chmod +x"
  fi
  installed="$INSTALLED/$name"
  # Not every template is installed here (stack-specific hooks are pruned),
  # but where a copy exists it must match the template byte for byte.
  if [ -f "$installed" ]; then
    if cmp -s "$tmpl" "$installed"; then
      note_pass "in-sync: $name"
    else
      note_fail "in-sync: $name" "differs from template — re-copy from templates/hooks/"
    fi
    if [ -x "$installed" ]; then
      note_pass "installed-executable: $name"
    else
      note_fail "installed-executable: $name" "fix: chmod +x"
    fi
  fi
done

echo "every installed hook has a template counterpart:"
for installed in "$INSTALLED"/*.sh; do
  name="$(basename "$installed")"
  if [ -f "$TEMPLATES/$name" ]; then
    note_pass "has-template: $name"
  else
    note_fail "has-template: $name" "no template under templates/hooks/ — add it or remove the copy"
  fi
done

echo
echo "hooks-in-sync self-test: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
