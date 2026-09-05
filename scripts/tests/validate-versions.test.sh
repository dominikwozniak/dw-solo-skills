#!/usr/bin/env bash
# Self-test for validate-versions.sh: pins the two failures it exists for, plus the four passes that
# must not become false alarms.
#
# This repo tests a CI validator only where looking at it cannot settle the question. validate-docs.sh
# still has no self-test on purpose, being a disk check a reader can verify by looking;
# validate-manifests.sh gained one for its manifest-validation pass alone, for the reason that file's
# header gives. This one is different in the same way: it is git plumbing over two refs, where the interesting case (a version that
# didn't grow) needs a base tip that has moved since the branch forked. Nothing about that shape can
# be checked by looking, and `717f1e5` is the standing proof a validator passes silently while broken.
#
# The fixture is a miniature marketplace in a throwaway repo — two plugins, one skill symlink each,
# one runtime script, one templates symlink — so the surface derivation is exercised for real rather
# than mocked. Every case is a fresh branch off the fixture's main.
#
# Run standalone (`bash scripts/tests/validate-versions.test.sh`) or via scripts/validate-artifacts.sh.
# Exit 0 iff every case passes. bash 3.2 / macOS + BSD safe.
set -uo pipefail
export LC_ALL=C

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
CHECKER="$ROOT/scripts/validate-versions.sh"

PASS=0
FAIL=0
note_pass() { PASS=$((PASS + 1)); echo "  ✓ $1"; }
note_fail() { FAIL=$((FAIL + 1)); echo "  ✗ $1 — $2"; }

if ! command -v jq >/dev/null; then
  echo "validate-versions self-test: SKIP (jq missing — the checker needs it)"
  exit 0
fi

TMP="$(mktemp -d)"
trap 'cd / && rm -rf "$TMP"' EXIT

REPO="$TMP/repo"
mkdir -p "$REPO"
cd "$REPO" || exit 1
# macOS mktemp hands out a /var/folders/... symlink; git and the checker both print physical paths.
REPO="$(pwd -P)"

git init -q -b main
git config user.email "test@test"
git config user.name "test"
git config commit.gpgsign false

# --- the fixture marketplace -------------------------------------------------
# alpha ships one skill and one runtime script; beta ships one skill and the templates payload. The
# split is what proves a change to alpha's skill leaves beta unflagged.
mkdir -p .claude-plugin
mkdir -p plugins/alpha/.claude-plugin plugins/alpha/skills plugins/alpha/scripts
mkdir -p plugins/beta/.claude-plugin plugins/beta/skills
mkdir -p skills/one skills/two scripts/runtime templates/hooks docs

cat >.claude-plugin/marketplace.json <<'JSON'
{
  "name": "fixture",
  "plugins": [
    { "name": "alpha", "version": "1.0.0", "source": "./plugins/alpha" },
    { "name": "beta", "version": "2.3.4", "source": "./plugins/beta" }
  ]
}
JSON
echo '{ "name": "alpha", "version": "1.0.0" }' >plugins/alpha/.claude-plugin/plugin.json
echo '{ "name": "beta", "version": "2.3.4" }' >plugins/beta/.claude-plugin/plugin.json

echo "skill one" >skills/one/SKILL.md
echo "skill two" >skills/two/SKILL.md
echo "#!/bin/sh" >scripts/runtime/tool.sh
chmod +x scripts/runtime/tool.sh
echo "hook" >templates/hooks/a.sh
echo "docs" >docs/notes.md

ln -s ../../../skills/one plugins/alpha/skills/one
ln -s ../../../scripts/runtime/tool.sh plugins/alpha/scripts/tool.sh
ln -s ../../../skills/two plugins/beta/skills/two
ln -s ../../templates plugins/beta/templates

git add .claude-plugin plugins skills scripts templates docs
git commit -qm "fixture"
BASE_MAIN="$(git rev-parse HEAD)"

# bump <plugin> <version> — the real thing: both manifests together, as the error message demands.
bump() {
  jq --arg n "$1" --arg v "$2" '(.plugins[] | select(.name == $n) | .version) |= $v' \
    .claude-plugin/marketplace.json >tmp.json && mv tmp.json .claude-plugin/marketplace.json
  jq --arg v "$2" '.version = $v' "plugins/$1/.claude-plugin/plugin.json" >tmp.json &&
    mv tmp.json "plugins/$1/.claude-plugin/plugin.json"
}

# on <branch> — fresh branch off the fixture's main, so cases never contaminate each other.
on() {
  git switch -q -C "$1" "$BASE_MAIN"
}

# expect <name> <pass|fail> <base-ref> [grep-for] — run the checker, assert the exit code, and
# optionally assert the error names what it should.
expect() {
  name="$1"
  want="$2"
  base="$3"
  needle="${4:-}"
  out="$("$CHECKER" --base "$base" 2>&1)"
  rc=$?
  if [ "$want" = "pass" ] && [ "$rc" -ne 0 ]; then
    note_fail "$name" "expected exit 0, got $rc: $out"
    return
  fi
  if [ "$want" = "fail" ] && [ "$rc" -eq 0 ]; then
    note_fail "$name" "expected non-zero exit, got 0: $out"
    return
  fi
  if [ -n "$needle" ] && ! echo "$out" | grep -q "$needle"; then
    note_fail "$name" "output missing '$needle': $out"
    return
  fi
  note_pass "$name"
}

echo "the two failures this check exists for:"

# Failure 2 — a shipped-payload change with no bump at all. The one validate-manifests.sh cannot see
# because both manifests still agree with each other.
on payload-unbumped
echo "edited" >>skills/one/SKILL.md
git commit -qam "edit alpha's skill"
expect "unbumped-skill-fails" fail main "alpha"
expect "unbumped-skill-names-the-path" fail main "skills/one/SKILL.md"

# Failure 1 — the version DID grow against the fork point, but main has since taken that number.
# This is the case a merge-base comparison passes every time, so it is the load-bearing one: `on`
# branches off BASE_MAIN, main then advances to 1.0.1, and the branch claims 1.0.1 too.
on took-mains-number
echo "edited" >>skills/one/SKILL.md
bump alpha 1.0.1
git commit -qam "edit and bump to 1.0.1"
BRANCH_REF="$(git rev-parse --abbrev-ref HEAD)"
git switch -q main
bump alpha 1.0.1
git commit -qam "main takes 1.0.1 first"
git switch -q "$BRANCH_REF"
expect "number-already-taken-on-main-fails" fail main "needs > 1.0.1"
# Same tree, judged against the fork point instead — proves the failure comes from the base TIP and
# not from anything else about the diff.
expect "same-tree-passes-against-the-fork-point" pass "$BASE_MAIN"
git switch -q main
git reset -q --keep "$BASE_MAIN"

echo "the passes that must not become false alarms:"

on payload-bumped
echo "edited" >>skills/one/SKILL.md
bump alpha 1.0.1
git commit -qam "edit alpha's skill and bump"
expect "bumped-skill-passes" pass main

on runtime-script
echo "# more" >>scripts/runtime/tool.sh
bump alpha 1.0.1
git commit -qam "edit the runtime script and bump"
expect "runtime-script-is-payload" pass main
on runtime-script-unbumped
echo "# more" >>scripts/runtime/tool.sh
git commit -qam "edit the runtime script"
expect "runtime-script-unbumped-fails" fail main "alpha"

on templates-unbumped
echo "more" >>templates/hooks/a.sh
git commit -qam "edit a template"
expect "templates-are-beta-payload" fail main "beta"

on non-payload
echo "more" >>docs/notes.md
git commit -qam "edit docs"
expect "non-payload-change-passes" pass main

# A file surface must match EXACTLY, not by prefix. scripts/runtime/tool.sh is shipped;
# scripts/runtime/tool.sh.bak is not, and prefix matching demanded a bump for it.
on runtime-neighbour
echo "not shipped" >scripts/runtime/tool.sh.bak
git add scripts/runtime/tool.sh.bak
git commit -qm "add a file next to the shipped script"
expect "file-surface-matches-exactly-not-by-prefix" pass main

# Ownership: alpha's skill must not implicate beta. Asserted on the OK line, since the run fails
# overall for alpha and a bare exit code would not distinguish the two.
on alpha-only
echo "edited" >>skills/one/SKILL.md
git commit -qam "edit alpha's skill"
out="$("$CHECKER" --base main 2>&1)"
if echo "$out" | grep -q "^OK  beta (shipped surface untouched)"; then
  note_pass "one-plugin's-change-leaves-the-other-alone"
else
  note_fail "one-plugin's-change-leaves-the-other-alone" "beta not reported untouched: $out"
fi

# A plugin introduced on the branch has no previous number to grow past.
on new-plugin
mkdir -p plugins/gamma/.claude-plugin plugins/gamma/skills
mkdir -p skills/three
echo "skill three" >skills/three/SKILL.md
ln -s ../../../skills/three plugins/gamma/skills/three
echo '{ "name": "gamma", "version": "0.1.0" }' >plugins/gamma/.claude-plugin/plugin.json
jq '.plugins += [{ "name": "gamma", "version": "0.1.0", "source": "./plugins/gamma" }]' \
  .claude-plugin/marketplace.json >tmp.json && mv tmp.json .claude-plugin/marketplace.json
git add plugins/gamma skills/three .claude-plugin/marketplace.json
git commit -qm "add gamma"
expect "new-plugin-needs-no-growth" pass main "new plugin"

echo "the skips:"

on skip-cases
expect "unresolvable-base-skips" pass "no/such/ref" "SKIP"
expect "nothing-changed-passes" pass main "nothing changed"

echo "argument handling:"

# `--base` with nothing after it used to spin forever: shift 2 fails with one argument left, and
# without set -e the loop re-reads the same $1. The watchdog is the assertion — a regression hangs
# the process rather than returning a wrong answer, so a bare exit-code check would hang the suite.
"$CHECKER" --base >/dev/null 2>&1 &
probe=$!
(
  sleep 5
  kill -9 "$probe" 2>/dev/null
) &
watchdog=$!
wait "$probe"
rc=$?
kill -9 "$watchdog" 2>/dev/null
wait "$watchdog" 2>/dev/null
if [ "$rc" -eq 1 ]; then
  note_pass "base-without-argument-errors"
elif [ "$rc" -ge 128 ]; then
  note_fail "base-without-argument-errors" "hung — killed by the watchdog (rc=$rc)"
else
  note_fail "base-without-argument-errors" "expected exit 1, got $rc"
fi

echo
echo "validate-versions self-test: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
