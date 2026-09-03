#!/usr/bin/env bash
# Self-test for the guard-plugin-canon.sh hook template: pins which Edit/Write
# targets under plugins/ are refused (exit 2) vs allowed (exit 0), and that the
# refusal names the canon the symlink points at rather than just saying no.
#
# Most cases run against a THROWAWAY repo built to the same shape as this one —
# a plugin whose skills/scripts/templates entries are symlinks back to the canon,
# plus one real plugin.json it genuinely owns. The last group runs against THIS
# repo, because the layout the hook encodes is this repo's and a fixture that
# drifted from it would pass while the real thing broke.
#
# Run standalone (`bash scripts/tests/guard-plugin-canon.test.sh`) or via
# scripts/validate-artifacts.sh. Exit 0 iff every case matches. bash 3.2 safe.
set -uo pipefail
export LC_ALL=C

command -v jq >/dev/null || {
  echo "SKIP: jq missing (hooks no-op without it)"
  exit 0
}

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
HOOK="$ROOT/templates/hooks/guard-plugin-canon.sh"

PASS=0
FAIL=0
note_pass() {
  PASS=$((PASS + 1))
  echo "  ✓ $1"
}
note_fail() {
  FAIL=$((FAIL + 1))
  echo "  ✗ $1 — $2"
}

TMP="$(mktemp -d 2>/dev/null || mktemp -d -t canon)"
cleanup() { rm -rf "$TMP"; }
trap cleanup EXIT

# --- the fixture: this repo's layout in miniature -----------------------------
FIX="$TMP/repo"
mkdir -p "$FIX/skills/dw-thing" "$FIX/scripts/runtime" "$FIX/templates/hooks" \
  "$FIX/plugins/dw-p/skills" "$FIX/plugins/dw-p/scripts" "$FIX/plugins/dw-p/.claude-plugin"
git -C "$FIX" init -q 2>/dev/null
printf 'canon\n' >"$FIX/skills/dw-thing/SKILL.md"
printf 'canon\n' >"$FIX/scripts/runtime/worktree.sh"
printf 'canon\n' >"$FIX/templates/hooks/a-hook.sh"
printf '{}\n' >"$FIX/plugins/dw-p/.claude-plugin/plugin.json"
ln -s ../../../skills/dw-thing "$FIX/plugins/dw-p/skills/dw-thing"
ln -s ../../../scripts/runtime/worktree.sh "$FIX/plugins/dw-p/scripts/worktree.sh"
ln -s ../../templates "$FIX/plugins/dw-p/templates"

# run <repo> <tool> <path> — invoke the hook with cwd inside <repo>, since it
# resolves the repo root and relative paths from there.
run() (
  cd "$1" || exit 1
  jq -n --arg t "$2" --arg p "$3" '{tool_name:$t,tool_input:{file_path:$p}}' | bash "$HOOK" >/dev/null 2>&1
)
stderr_of() (
  cd "$1" || exit 1
  jq -n --arg t "$2" --arg p "$3" '{tool_name:$t,tool_input:{file_path:$p}}' | bash "$HOOK" 2>&1 >/dev/null
)

blocked() {
  run "$FIX" "$2" "$3"
  rc=$?
  if [ "$rc" -eq 2 ]; then note_pass "$1"; else note_fail "$1" "want exit 2, got $rc"; fi
}
allowed() {
  run "$FIX" "$2" "$3"
  rc=$?
  if [ "$rc" -eq 0 ]; then note_pass "$1"; else note_fail "$1" "want exit 0, got $rc"; fi
}
names_canon() {
  out="$(stderr_of "$FIX" Edit "$2")"
  case "$out" in
    *"$3"*) note_pass "$1" ;;
    *) note_fail "$1" "stderr did not name '$3': $out" ;;
  esac
}

echo "editing through a plugin symlink — blocked (exit 2):"
blocked "skill-through-symlink" Edit "$FIX/plugins/dw-p/skills/dw-thing/SKILL.md"
blocked "skill-symlink-itself" Write "$FIX/plugins/dw-p/skills/dw-thing"
blocked "script-through-symlink" Edit "$FIX/plugins/dw-p/scripts/worktree.sh"
blocked "templates-dir-symlink" Write "$FIX/plugins/dw-p/templates/hooks/a-hook.sh"
blocked "multiedit-through-symlink" MultiEdit "$FIX/plugins/dw-p/skills/dw-thing/SKILL.md"
blocked "relative-path-through-symlink" Edit "plugins/dw-p/skills/dw-thing/SKILL.md"
blocked "new-file-under-plugin" Write "$FIX/plugins/dw-p/skills/dw-new/SKILL.md"
blocked "new-file-beside-plugin-json" Write "$FIX/plugins/dw-p/.claude-plugin/other.json"
blocked "new-file-at-plugin-root" Write "$FIX/plugins/dw-p/README.md"

echo "a NEW plugin's manifest is the one creatable path (exit 0):"
# Adding a plugin means writing a plugin.json that does not exist yet, so the
# existing-file test cannot cover it — and the refusal used to tell you to put it
# under skills/, which is advice no plugin.json can follow.
allowed "new-plugin-manifest" Write "$FIX/plugins/dw-new/.claude-plugin/plugin.json"
allowed "new-plugin-manifest-relative" Write "plugins/dw-new/.claude-plugin/plugin.json"
# …but only that exact path, and still never through a symlink.
blocked "new-plugin-other-manifest" Write "$FIX/plugins/dw-new/.claude-plugin/marketplace.json"
blocked "new-plugin-stray-file" Write "$FIX/plugins/dw-new/README.md"

echo "the refusal names the canon behind the link:"
names_canon "names-skill-canon" "$FIX/plugins/dw-p/skills/dw-thing/SKILL.md" "skills/dw-thing/SKILL.md"
names_canon "names-script-canon" "$FIX/plugins/dw-p/scripts/worktree.sh" "scripts/runtime/worktree.sh"
names_canon "names-template-canon" "$FIX/plugins/dw-p/templates/hooks/a-hook.sh" "templates/hooks/a-hook.sh"

echo "what a plugin genuinely owns, and everything outside plugins/ — allowed (exit 0):"
allowed "plugin-json-is-real" Edit "$FIX/plugins/dw-p/.claude-plugin/plugin.json"
allowed "canon-skill-direct" Edit "$FIX/skills/dw-thing/SKILL.md"
allowed "canon-script-direct" Edit "$FIX/scripts/runtime/worktree.sh"
allowed "canon-template-direct" Write "$FIX/templates/hooks/a-hook.sh"
allowed "new-file-outside-plugins" Write "$FIX/skills/dw-other/SKILL.md"
allowed "path-outside-the-repo" Edit "/tmp/somewhere-else.md"
allowed "read-is-not-guarded" Read "$FIX/plugins/dw-p/skills/dw-thing/SKILL.md"
allowed "bash-is-not-guarded" Bash "$FIX/plugins/dw-p/skills/dw-thing/SKILL.md"
allowed "empty-path" Edit ""

echo "against this repo's real layout:"
real_case() {
  run "$ROOT" "$2" "$3"
  rc=$?
  if [ "$rc" -eq "$4" ]; then note_pass "$1"; else note_fail "$1" "want exit $4, got $rc"; fi
}
real_case "real-skill-symlink-blocked" Edit "$ROOT/plugins/dw-solo/skills/dw-next/SKILL.md" 2
real_case "real-script-symlink-blocked" Edit "$ROOT/plugins/dw-solo/scripts/worktree.sh" 2
real_case "real-plugin-json-allowed" Edit "$ROOT/plugins/dw-solo/.claude-plugin/plugin.json" 0
real_case "real-canon-allowed" Edit "$ROOT/skills/dw-next/SKILL.md" 0
real_case "real-marketplace-allowed" Edit "$ROOT/.claude-plugin/marketplace.json" 0
out="$(stderr_of "$ROOT" Edit "$ROOT/plugins/dw-solo/skills/dw-next/SKILL.md")"
case "$out" in
  *"skills/dw-next/SKILL.md"*) note_pass "real-refusal-names-canon" ;;
  *) note_fail "real-refusal-names-canon" "stderr did not name the canon: $out" ;;
esac

# Every plugin entry is either a symlink or one of the three owned plugin.json
# files. That is the invariant the hook's rule IS, so if it ever stops holding
# the hook silently starts allowing edits it should refuse.
echo "the invariant the hook's rule rests on:"
strays=""
for f in $(find "$ROOT/plugins" -type f 2>/dev/null); do
  case "$f" in
    */.claude-plugin/plugin.json) ;;
    *) strays="$strays $f" ;;
  esac
done
if [ -z "$strays" ]; then
  note_pass "no-real-files-under-plugins-but-plugin-json"
else
  note_fail "no-real-files-under-plugins-but-plugin-json" "real file(s) the hook would now allow:$strays"
fi

echo
echo "guard-plugin-canon self-test: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
