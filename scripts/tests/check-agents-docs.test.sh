#!/usr/bin/env bash
# Self-test for the check-agents-docs.mjs payload — the checker dw-init drops into a scaffolded repo
# to guard its AGENTS.md contract. Every case runs against a SYNTHETIC scaffold under mktemp, never
# against this repo: a self-test whose fixture is the live tree is a content gate wearing a unit
# test's name, and it ends up stricter than the contract it claims to test.
#
# What is pinned: the budget parser (the part with real logic — bare number = bytes, KB = ×1024,
# malformed is REJECTED rather than guessed), placeholder detection, router coverage and path sync,
# command sync, and the CLAUDE.md symlink. Plus one negative that matters as much as the positives:
# docs/decisions/ is NOT validated, by decision.
#
# Run standalone (`bash scripts/tests/check-agents-docs.test.sh`) or via scripts/validate-artifacts.sh.
# Exit 0 iff every case matches. bash 3.2 safe.
set -uo pipefail
export LC_ALL=C

command -v node >/dev/null || { echo "SKIP: node missing (the checker is a .mjs)"; exit 0; }

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
CHECKER="$ROOT/templates/check-agents-docs.mjs"

PASS=0
FAIL=0
note_pass() { PASS=$((PASS + 1)); echo "  ✓ $1"; }
note_fail() { FAIL=$((FAIL + 1)); echo "  ✗ $1 — $2"; }

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

# scaffold <budget-line-tail> [extra-router-row] — a minimal valid scaffolded repo: AGENTS.md carrying
# the given budget declaration, a CLAUDE.md symlink, the routed files its Task Router names, and the
# checker at scripts/check-agents-docs.mjs (the placement dw-init uses, and what its root-finding walk
# expects). Echoes the repo path.
#
# The extra row goes INSIDE the router table on purpose. Coverage and path sync are scoped to the
# `## Task Router` section — naming a topic file in some other section is not routing to it — so a row
# appended at the end of the file would be scanned by neither, and a case built that way passes
# without testing anything.
scaffold() {
  local dir
  dir="$WORK/repo.$RANDOM$RANDOM"
  mkdir -p "$dir/scripts" "$dir/.ai"
  cp "$CHECKER" "$dir/scripts/check-agents-docs.mjs"
  printf 'glossary\n' >"$dir/CONTEXT.md"
  printf 'what .ai/ is\n' >"$dir/.ai/README.md"
  cat >"$dir/AGENTS.md" <<AGENTS
# Fixture — agent rules

> \`CLAUDE.md\` is a symlink to this file. Budget: **${1}**, enforced by the checker.

## Task Router

| task            | read              |
| --------------- | ----------------- |
| the loop        | \`.ai/README.md\` |
| a domain term   | \`CONTEXT.md\`    |
${2:-}

## Solo lane

- **Lint command**: none
AGENTS
  ln -s AGENTS.md "$dir/CLAUDE.md"
  printf '%s\n' "$dir"
}

# check <repo> — run the checker and echo its exit code; stdout+stderr land in $OUT.
OUT="$WORK/out"
check() {
  (cd "$1" && node scripts/check-agents-docs.mjs) >"$OUT" 2>&1
  printf '%s\n' "$?"
}

# expect_rc <name> <want> <got>
expect_rc() {
  if [ "$2" = "$3" ]; then note_pass "$1"; else note_fail "$1" "want exit $2, got $3: $(tr '\n' '|' <"$OUT")"; fi
}

# expect_says <name> <substring>
expect_says() {
  if grep -qF -- "$2" "$OUT"; then
    note_pass "$1"
  else
    note_fail "$1" "output did not mention '$2': $(tr '\n' '|' <"$OUT")"
  fi
}

echo "a valid scaffold passes, and says what it measured:"
repo="$(scaffold '120 lines / 10 KB')"
expect_rc "valid-exit-0" 0 "$(check "$repo")"
expect_says "valid-reports-the-budget" "/120 lines"

echo "the budget parser:"
# KB is ×1024, so 1 KB is roomy for a ~15-line fixture and 1 bare byte is not.
repo="$(scaffold '120 lines / 1 KB')"
expect_rc "kb-unit-multiplies-exit-0" 0 "$(check "$repo")"
expect_says "kb-unit-multiplies-to-1024" "/1024 B"

repo="$(scaffold '120 lines / 1024')"
expect_rc "bare-number-is-bytes-exit-0" 0 "$(check "$repo")"
expect_says "bare-number-is-bytes" "/1024 B"

repo="$(scaffold '120 lines / 10_240')"
expect_rc "underscored-number-exit-0" 0 "$(check "$repo")"
expect_says "underscored-number-parsed" "/10240 B"

repo="$(scaffold '3 lines / 10 KB')"
expect_rc "over-line-budget-exit-1" 1 "$(check "$repo")"
expect_says "over-line-budget-named" "over its declared 3-line"

repo="$(scaffold '120 lines / 40')"
expect_rc "over-byte-budget-exit-1" 1 "$(check "$repo")"
expect_says "over-byte-budget-named" "40-B budget"

# An unrecognised unit must be REJECTED, not read as bare bytes — `10 MB` silently meaning 10 bytes
# is the failure mode this parser is strict to avoid.
repo="$(scaffold '120 lines / 10 MB')"
expect_rc "unknown-unit-exit-1" 1 "$(check "$repo")"
expect_says "unknown-unit-called-malformed" "malformed"

repo="$(scaffold 'a few lines, not too many')"
expect_rc "unparseable-exit-1" 1 "$(check "$repo")"
expect_says "unparseable-called-malformed" "malformed"

repo="$(scaffold '120 lines / 10 KB')"
grep -v "Budget:" "$repo/AGENTS.md" >"$repo/AGENTS.tmp" && mv "$repo/AGENTS.tmp" "$repo/AGENTS.md"
expect_rc "no-budget-exit-1" 1 "$(check "$repo")"
expect_says "no-budget-named" "declares no budget"

echo "an unrendered placeholder is a failure, not content:"
repo="$(scaffold '120 lines / 10 KB')"
printf -- '- **Typecheck command**: {{TYPECHECK_COMMAND}}\n' >>"$repo/AGENTS.md"
expect_rc "placeholder-exit-1" 1 "$(check "$repo")"
expect_says "placeholder-named" "{{TYPECHECK_COMMAND}}"

echo "the Task Router:"
repo="$(scaffold '120 lines / 10 KB')"
mkdir -p "$repo/docs/agents"
printf 'ui rules\n' >"$repo/docs/agents/ui.md"
expect_rc "unrouted-topic-exit-1" 1 "$(check "$repo")"
expect_says "unrouted-topic-named" "docs/agents/ui.md has no row"

# The same topic file, now with a row: coverage is satisfied and the path resolves.
repo="$(scaffold '120 lines / 10 KB' '| ui, styling | `docs/agents/ui.md` |')"
mkdir -p "$repo/docs/agents"
printf 'ui rules\n' >"$repo/docs/agents/ui.md"
expect_rc "routed-topic-exit-0" 0 "$(check "$repo")"

# Coverage is scoped to the router: a topic file named in another section is not routed to.
repo="$(scaffold '120 lines / 10 KB')"
mkdir -p "$repo/docs/agents"
printf 'ui rules\n' >"$repo/docs/agents/ui.md"
printf -- '- see `docs/agents/ui.md` for the boundary\n' >>"$repo/AGENTS.md"
expect_rc "mention-outside-router-is-not-a-row-exit-1" 1 "$(check "$repo")"
expect_says "mention-outside-router-named" "docs/agents/ui.md has no row"

repo="$(scaffold '120 lines / 10 KB')"
rm "$repo/CONTEXT.md"
expect_rc "missing-routed-path-exit-1" 1 "$(check "$repo")"
expect_says "missing-routed-path-named" "points at CONTEXT.md"

# A `read` cell names more than paths — a skill, a command, a section heading. None is checkable.
repo="$(scaffold '120 lines / 10 KB' '| animations | the `react-native-best-practices` skill, via `pnpm exec eslint` |')"
expect_rc "non-path-cells-ignored-exit-0" 0 "$(check "$repo")"

repo="$(scaffold '120 lines / 10 KB' '| a glob | `src/**/*.ts` and `docs/agents/<topic>.md` and `https://example.com/x.md` |')"
expect_rc "globs-placeholders-urls-ignored-exit-0" 0 "$(check "$repo")"

# Only the `read` column is a routed target. The task column describes the task, so its backticks name
# concepts — "what a `CHANGE.md` is" points at no CHANGE.md in the repo root, and the shipped template
# says exactly that.
repo="$(scaffold '120 lines / 10 KB' '| the loop, `.ai/work/`, what a `CHANGE.md` is | `CONTEXT.md` |')"
expect_rc "task-column-is-not-a-target-exit-0" 0 "$(check "$repo")"

repo="$(scaffold '120 lines / 10 KB')"
grep -v "## Task Router" "$repo/AGENTS.md" >"$repo/AGENTS.tmp" && mv "$repo/AGENTS.tmp" "$repo/AGENTS.md"
expect_rc "no-router-section-exit-1" 1 "$(check "$repo")"
expect_says "no-router-section-named" "no \"## Task Router\" section"

echo "command sync:"
repo="$(scaffold '120 lines / 10 KB')"
printf '{ "scripts": { "test": "vitest" } }\n' >"$repo/package.json"
printf -- '- **Test**: `pnpm test`\n' >>"$repo/AGENTS.md"
expect_rc "real-script-exit-0" 0 "$(check "$repo")"

printf -- '- **Gate**: `pnpm check`\n' >>"$repo/AGENTS.md"
expect_rc "missing-script-exit-1" 1 "$(check "$repo")"
expect_says "missing-script-named" "pnpm check"

# pnpm's own subcommands are not scripts, and must not be reported as missing ones.
repo="$(scaffold '120 lines / 10 KB')"
printf '{ "scripts": {} }\n' >"$repo/package.json"
printf -- '- **Lint**: `pnpm exec eslint --fix`, installed via `pnpm add -D eslint`\n' >>"$repo/AGENTS.md"
expect_rc "pnpm-builtins-ignored-exit-0" 0 "$(check "$repo")"

# No package.json is no claim to check — this ships into non-Node repos too.
repo="$(scaffold '120 lines / 10 KB')"
printf -- '- **Gate**: `pnpm check`\n' >>"$repo/AGENTS.md"
expect_rc "no-package-json-skips-command-sync-exit-0" 0 "$(check "$repo")"

echo "CLAUDE.md is a symlink, never a second copy:"
repo="$(scaffold '120 lines / 10 KB')"
rm "$repo/CLAUDE.md"
expect_rc "claude-md-missing-exit-1" 1 "$(check "$repo")"
expect_says "claude-md-missing-named" "is missing"

repo="$(scaffold '120 lines / 10 KB')"
rm "$repo/CLAUDE.md"
printf 'a forked copy\n' >"$repo/CLAUDE.md"
expect_rc "claude-md-real-file-exit-1" 1 "$(check "$repo")"
expect_says "claude-md-real-file-named" "is a real file"

repo="$(scaffold '120 lines / 10 KB')"
rm "$repo/CLAUDE.md"
ln -s CONTEXT.md "$repo/CLAUDE.md"
expect_rc "claude-md-wrong-target-exit-1" 1 "$(check "$repo")"
expect_says "claude-md-wrong-target-named" "must point at AGENTS.md"

echo "docs/decisions/ is NOT validated — by decision, not by omission:"
# A record breaking every rule the team-lane checker enforced: no frontmatter, a number out of
# sequence, a name that is not <NNNN>-<slug>.md. The checker must not care.
repo="$(scaffold '120 lines / 10 KB')"
mkdir -p "$repo/docs/decisions"
printf 'no frontmatter, no number, no status\n' >"$repo/docs/decisions/whatever.md"
printf -- '---\ndecision: 0099\n---\n\n# 0099 — out of sequence\n' >"$repo/docs/decisions/0099-orphan.md"
expect_rc "decisions-unchecked-exit-0" 0 "$(check "$repo")"

echo "the shipped AGENTS.md template, rendered the way dw-init renders it, passes the shipped checker:"
# The one case that tests the two payload halves against each other rather than against a fixture.
# Every case above builds its own minimal AGENTS.md, so none of them would notice the template
# growing past its own declared budget, gaining a router row for a path the scaffold does not create,
# or naming a `pnpm <script>` dw-init never writes.
repo="$WORK/rendered"
mkdir -p "$repo/scripts" "$repo/.ai/backlog" "$repo/.ai/archive" "$repo/docs/decisions" "$repo/.claude/hooks"
cp "$CHECKER" "$repo/scripts/check-agents-docs.mjs"
for seeded in .ai/README.md .ai/backlog/README.md .ai/archive/README.md docs/decisions/README.md CONTEXT.md; do
  printf 'seeded by dw-init\n' >"$repo/$seeded"
done
printf '{ "scripts": { "test": "vitest", "agents:check": "node scripts/check-agents-docs.mjs" } }\n' \
  >"$repo/package.json"
sed \
  -e 's|{{PROJECT_NAME}}|Scratch|' \
  -e 's|{{AGENTS_CHECK_COMMAND}}|pnpm agents:check|' \
  -e 's|{{STACK}}|TypeScript + Node|' \
  -e 's|{{DEFAULT_BRANCH}}|main|g' \
  -e 's|{{TEST_COMMAND}}|`pnpm test`|' \
  -e 's|{{LINT_COMMAND}}|`pnpm exec eslint --fix`|' \
  -e 's|{{TYPECHECK_COMMAND}}|none|' \
  -e 's|{{HOOKS_INSTALLED}}|- `block-dangerous-commands` — blocks destructive shell.|' \
  "$ROOT/templates/AGENTS.md" >"$repo/AGENTS.md"
ln -s AGENTS.md "$repo/CLAUDE.md"
expect_rc "shipped-template-passes-exit-0" 0 "$(check "$repo")"
if grep -q '{{' "$repo/AGENTS.md"; then
  note_fail "shipped-template-placeholders-known" "the template holds a {{…}} token this test does not substitute"
else
  note_pass "shipped-template-placeholders-known"
fi

echo
echo "check-agents-docs self-test: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
