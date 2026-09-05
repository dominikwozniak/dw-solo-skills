#!/usr/bin/env bash
# Self-test for the manifest-validation pass of validate-manifests.sh: pins that a plugin.json is
# validated through a dereferenced copy, and that a warning is a failure.
#
# Why this one needs a test when the rest of validate-manifests.sh does not. The rest is a disk
# check a reader can verify by looking — is this entry a symlink, does it resolve, is the canon
# executable. This pass is not: `claude plugin validate` reads components without following
# symlinks, so run in place against this repo it validated zero of twelve skills and still printed
# a tick. Looking at the script could not show that, and looking at CI could not either. The gate
# reported green for as long as it existed. Only a fixture with a deliberately broken skill behind
# a symlink says whether the gate can see it.
#
# The checker is repo-specific past this pass — it hardcodes the runtime script names and the
# template plugin — so a fixture can never satisfy all of it. Every case therefore asserts on the
# validator's own output rather than on the exit code, which fixture-irrelevant checks always trip.
#
# Run standalone (`bash scripts/tests/validate-manifests.test.sh`) or via scripts/validate-artifacts.sh.
# Exit 0 iff every case passes. bash 3.2 / macOS + BSD safe.
set -uo pipefail
export LC_ALL=C

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
CHECKER="$ROOT/scripts/validate-manifests.sh"

PASS=0
FAIL=0
note_pass() { PASS=$((PASS + 1)); echo "  ✓ $1"; }
note_fail() { FAIL=$((FAIL + 1)); echo "  ✗ $1 — $2"; }

if ! command -v jq >/dev/null; then
  echo "validate-manifests self-test: SKIP (jq missing — the checker needs it)"
  exit 0
fi
if ! command -v claude >/dev/null; then
  echo "validate-manifests self-test: SKIP (claude CLI missing — the pass under test needs it)"
  exit 0
fi

TMP="$(mktemp -d)"
trap 'cd / && rm -rf "$TMP"' EXIT

REPO="$TMP/repo"
mkdir -p "$REPO"
cd "$REPO" || exit 1

# --- the fixture marketplace -------------------------------------------------
# One plugin, one skill, reached the way this repo reaches every skill: a relative symlink from the
# plugin into a canon directory at the root. That symlink is the whole point of the fixture.
#
# It has to be warning-free in its own right — owner, description and author all present. Every case
# below asserts on one message across the whole run, so a fixture that warns about itself would make
# each of them pass for the wrong reason.
mkdir -p .claude-plugin plugins/alpha/.claude-plugin plugins/alpha/skills skills/one

cat >.claude-plugin/marketplace.json <<'JSON'
{
  "name": "fixture",
  "owner": { "name": "test" },
  "description": "A fixture marketplace.",
  "plugins": [{ "name": "alpha", "version": "1.0.0", "source": "./plugins/alpha" }]
}
JSON
cat >plugins/alpha/.claude-plugin/plugin.json <<'JSON'
{
  "name": "alpha",
  "version": "1.0.0",
  "description": "A fixture plugin.",
  "author": { "name": "test" },
  "skills": "./skills"
}
JSON

write_skill() {
  cat >skills/one/SKILL.md
}
write_skill <<'MD'
---
name: one
description: A fixture skill that exists only so the validator has something real to read.
---

# one
MD

ln -s ../../../skills/one plugins/alpha/skills/one

# expect <name> <present|absent> <needle> — run the checker in the fixture and assert on its output.
expect() {
  name="$1"
  want="$2"
  needle="$3"
  out="$("$CHECKER" 2>&1)"
  if echo "$out" | grep -q "$needle"; then
    found=present
  else
    found=absent
  fi
  if [ "$found" = "$want" ]; then
    note_pass "$name"
  else
    note_fail "$name" "expected '$needle' $want, was $found: $out"
  fi
}

echo "the failure this pass exists for:"
# A skill is only ever reached through the symlink. In place the validator never opens it; through
# the dereferenced copy it must, and must say so.
write_skill <<'MD'
---
name: one
---

# one — no description in frontmatter
MD
expect "broken-skill-behind-a-symlink-is-seen" present "validation warnings are failures here"

echo
echo "and the shapes that must not become false alarms:"
write_skill <<'MD'
---
name: one
description: A fixture skill that exists only so the validator has something real to read.
---

# one
MD
expect "clean-tree-raises-nothing" absent "validation warnings are failures here"
# The symlink warning is the one the in-place run always produced. Dereferencing removes its cause,
# so seeing it again means the copy stopped being made.
expect "dereferenced-run-never-warns-about-symlinks" absent "were not read"
# A misspelled manifest field warns rather than errors, so it rode through the old exit-code gate.
jq '. + { "authr": "typo" }' plugins/alpha/.claude-plugin/plugin.json >tmp.json && mv tmp.json plugins/alpha/.claude-plugin/plugin.json
expect "misspelled-manifest-field-is-seen" present "validation warnings are failures here"

echo
if [ "$FAIL" -eq 0 ]; then
  echo "validate-manifests self-test: $PASS passed"
  exit 0
fi
echo "validate-manifests self-test: $FAIL failed, $PASS passed"
exit 1
