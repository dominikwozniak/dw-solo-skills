#!/usr/bin/env bash
# Self-test for the check-agents-docs.mjs payload — the checker dw-init drops into a scaffolded repo
# to guard its AGENTS.md contract. Every case runs against a SYNTHETIC scaffold under mktemp, never
# against this repo: a self-test whose fixture is the live tree is a content gate wearing a unit
# test's name, and it ends up stricter than the contract it claims to test.
#
# What is pinned: the budget parser (the part with real logic — bare number = bytes, KB = ×1024,
# malformed is REJECTED rather than guessed), placeholder detection, router coverage and path sync,
# command sync, the CLAUDE.md symlink, and the record ceiling's parser. Plus two negatives that matter
# as much as the positives: a record's SHAPE is never validated, and where no ceiling is declared the
# records are neither checked nor mentioned.
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
  # A real .git, because that is what the checker resolves the repo root by. Without it the fixtures
  # would exercise only the tarball fallback and the primary path would go untested.
  git -C "$dir" init --quiet
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

# expect_silent_about <name> <substring> — the other half of an opt-in check: not failing is not
# enough, it must also not be mentioned, or every repo that declined it still pays a line of report.
expect_silent_about() {
  if grep -qF -- "$2" "$OUT"; then
    note_fail "$1" "output mentioned '$2' when it should not: $(tr '\n' '|' <"$OUT")"
  else
    note_pass "$1"
  fi
}

echo "a valid scaffold passes, and says what it measured:"
repo="$(scaffold '120 lines / 10 KB')"
expect_rc "valid-exit-0" 0 "$(check "$repo")"
expect_says "valid-reports-the-budget" "/120 lines"
# The resolved root is in the report because every check depends on it, and a wrong one produces
# confident wrong output.
expect_says "valid-names-the-resolved-root" "$repo"

echo "the repo root comes from .git, not from the first AGENTS.md above the script:"
# AGENTS.md is a per-directory convention, so scripts/AGENTS.md is legal. Resolving by the nearest
# AGENTS.md made the checker treat scripts/ as the root and report three failures about a healthy repo.
repo="$(scaffold '120 lines / 10 KB')"
printf '# Rules for scripts/\n\nKeep them POSIX.\n' >"$repo/scripts/AGENTS.md"
expect_rc "nested-agents-md-does-not-hijack-the-root" 0 "$(check "$repo")"
expect_says "nested-agents-md-root-is-still-the-repo" "$repo:"

# A git root with no AGENTS.md fails by naming the path, so the message is actionable.
repo="$(scaffold '120 lines / 10 KB')"
rm "$repo/AGENTS.md" "$repo/CLAUDE.md"
printf '# Rules for scripts/\n' >"$repo/scripts/AGENTS.md"
expect_rc "no-root-agents-md-exit-1" 1 "$(check "$repo")"
expect_says "no-root-agents-md-names-the-path" "no AGENTS.md at the repo root"

# No .git anywhere: the AGENTS.md walk is the only guess left, and it still works.
repo="$(scaffold '120 lines / 10 KB')"
rm -rf "$repo/.git"
expect_rc "no-git-falls-back-to-the-agents-walk" 0 "$(check "$repo")"

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

# Tighter: coverage is scoped to the READ column, not merely to the section. A topic file named in a
# task description is being talked about, not routed to — and accepting that made the check hollow.
repo="$(scaffold '120 lines / 10 KB' '| editing `docs/agents/ui.md` | `CONTEXT.md` |')"
mkdir -p "$repo/docs/agents"
printf 'ui rules\n' >"$repo/docs/agents/ui.md"
expect_rc "task-column-mention-is-not-coverage-exit-1" 1 "$(check "$repo")"
expect_says "task-column-mention-is-not-coverage-named" "docs/agents/ui.md has no row"

# A `./`-prefixed target is the same path, and must satisfy coverage rather than read as a second one.
repo="$(scaffold '120 lines / 10 KB' '| ui | `./docs/agents/ui.md` |')"
mkdir -p "$repo/docs/agents"
printf 'ui rules\n' >"$repo/docs/agents/ui.md"
expect_rc "dot-slash-target-counts-as-coverage" 0 "$(check "$repo")"

# An escaped pipe is cell CONTENT, not a column break. Splitting on every pipe picked the wrong "last
# cell", which could let a nonexistent routed path through unchecked.
repo="$(scaffold '120 lines / 10 KB' '| a \| b | `nope/missing.md` |')"
expect_rc "escaped-pipe-still-finds-the-read-column" 1 "$(check "$repo")"
expect_says "escaped-pipe-named-the-missing-path" "points at nope/missing.md"

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
expect_says "claude-md-wrong-target-named" "must resolve to AGENTS.md"

# Compared by destination, not spelling: these are the same link, and rejecting them would fail a repo
# that is correctly set up.
repo="$(scaffold '120 lines / 10 KB')"
rm "$repo/CLAUDE.md"
ln -s ./AGENTS.md "$repo/CLAUDE.md"
expect_rc "claude-md-dot-slash-target-accepted" 0 "$(check "$repo")"

repo="$(scaffold '120 lines / 10 KB')"
rm "$repo/CLAUDE.md"
ln -s "$repo/AGENTS.md" "$repo/CLAUDE.md"
expect_rc "claude-md-absolute-target-accepted" 0 "$(check "$repo")"

echo "a record's SHAPE is NOT validated — by decision, not by omission:"
# A record breaking every rule the team-lane checker enforced: no frontmatter, a number out of
# sequence, a name that is not <NNNN>-<slug>.md. The checker must not care.
repo="$(scaffold '120 lines / 10 KB')"
mkdir -p "$repo/docs/decisions"
printf 'no frontmatter, no number, no status\n' >"$repo/docs/decisions/whatever.md"
printf -- '---\ndecision: 0099\n---\n\n# 0099 — out of sequence\n' >"$repo/docs/decisions/0099-orphan.md"
expect_rc "decisions-unchecked-exit-0" 0 "$(check "$repo")"
# And with no README declaring a ceiling, SIZE is not checked either — nor mentioned.
expect_silent_about "no-ceiling-declared-says-nothing" "record(s)"

echo "the record ceiling, where the folder's README declares one:"
# long_record <path> <lines> — a record of exactly <lines> lines, named the way a real one is.
long_record() {
  : >"$1"
  i=0
  while [ "$i" -lt "$2" ]; do printf 'a line of a decision record\n' >>"$1"; i=$((i + 1)); done
}
# declare_ceiling <repo> <tail> — the one-line declaration, in the place the payload seeds it.
declare_ceiling() {
  mkdir -p "$1/docs/decisions"
  printf '# decisions\n\nCeiling: **%s** per record.\n' "$2" >"$1/docs/decisions/README.md"
}

repo="$(scaffold '120 lines / 10 KB')"
declare_ceiling "$repo" "40 lines"
long_record "$repo/docs/decisions/0001-a-short-one.md" 20
expect_rc "under-ceiling-exit-0" 0 "$(check "$repo")"
expect_says "under-ceiling-reports-the-longest" "longest 21/40 lines"

repo="$(scaffold '120 lines / 10 KB')"
declare_ceiling "$repo" "40 lines"
long_record "$repo/docs/decisions/0002-a-long-one.md" 41
expect_rc "over-ceiling-exit-1" 1 "$(check "$repo")"
expect_says "over-ceiling-names-the-record" "0002-a-long-one.md is 42 lines"
expect_says "over-ceiling-names-the-number" "declared 40-line ceiling"

# Only <NNNN>-<slug>.md is a record. The README states the contract and a stray note is not a record,
# so neither is measured — otherwise declaring the ceiling in a long README would fail on itself.
repo="$(scaffold '120 lines / 10 KB')"
declare_ceiling "$repo" "40 lines"
long_record "$repo/docs/decisions/notes.md" 400
i=0
while [ "$i" -lt 400 ]; do printf 'padding for the README\n' >>"$repo/docs/decisions/README.md"; i=$((i + 1)); done
expect_rc "non-records-are-not-measured" 0 "$(check "$repo")"
expect_says "non-records-leave-zero-records" "0 record(s)"

# Malformed is REJECTED, never guessed at — the same bargain the budget parser makes.
repo="$(scaffold '120 lines / 10 KB')"
declare_ceiling "$repo" "as short as it needs to be"
expect_rc "malformed-ceiling-exit-1" 1 "$(check "$repo")"
expect_says "malformed-ceiling-called-malformed" "ceiling declaration is malformed"

echo "the topic-file ratchet:"
# topic_repo <words-in-topic.md> — a scaffold with one routed topic file of the given word count.
topic_repo() {
  local dir
  dir="$(scaffold '120 lines / 10 KB' '| a topic       | `docs/agents/topic.md` |')"
  mkdir -p "$dir/docs/agents"
  : >"$dir/docs/agents/topic.md"
  local i=0
  while [ "$i" -lt "$1" ]; do printf 'word\n' >>"$dir/docs/agents/topic.md"; i=$((i + 1)); done
  printf '%s\n' "$dir"
}
# update <repo> — re-record the baseline; echoes the exit code, output in $OUT.
update() {
  (cd "$1" && node scripts/check-agents-docs.mjs --update-baseline) >"$OUT" 2>&1
  printf '%s\n' "$?"
}

repo="$(topic_repo 10)"
expect_rc "no-baseline-exit-0" 0 "$(check "$repo")"
expect_silent_about "no-baseline-says-nothing" "topic words"

expect_rc "update-baseline-exit-0" 0 "$(update "$repo")"
expect_says "update-baseline-says-so" "baseline re-recorded at 10 words"
expect_rc "seeded-baseline-exit-0" 0 "$(check "$repo")"
expect_says "seeded-baseline-reported" "10/10 topic words"

# Growth fails, and the message has to carry the total, the baseline, the delta and WHICH file grew —
# a ratchet that only says "too big" leaves you diffing the corpus by hand.
printf 'word\nword\n' >>"$repo/docs/agents/topic.md"
expect_rc "growth-exit-1" 1 "$(check "$repo")"
expect_says "growth-names-the-delta" "12 words, baseline 10, +2"
expect_says "growth-names-the-file" "topic.md 10→12"

# Shrinking is free and needs no ceremony: that is the whole bargain.
repo="$(topic_repo 10)"
update "$repo" >/dev/null
: >"$repo/docs/agents/topic.md"
printf 'word\n' >"$repo/docs/agents/topic.md"
expect_rc "shrink-exit-0" 0 "$(check "$repo")"

# README.md is the shipped contract, not this repo's prose. A payload refresh that lengthens it must
# not read as the corpus growing.
repo="$(topic_repo 10)"
mkdir -p "$repo/docs/agents"
printf 'the contract\n' >"$repo/docs/agents/README.md"
sed -i.bak 's@| a domain term   | `CONTEXT.md`    |@| a domain term   | `CONTEXT.md`    |\n| what goes where | `docs/agents/README.md` |@' "$repo/AGENTS.md"
rm -f "$repo/AGENTS.md.bak"
update "$repo" >/dev/null
i=0
while [ "$i" -lt 500 ]; do printf 'contract prose\n' >>"$repo/docs/agents/README.md"; i=$((i + 1)); done
expect_rc "readme-excluded-from-the-corpus" 0 "$(check "$repo")"

# A baseline that cannot be read is a failure that names its own fix, never a silent skip.
repo="$(topic_repo 10)"
update "$repo" >/dev/null
printf 'not json\n' >"$repo/docs/agents/corpus.baseline.json"
expect_rc "corrupt-baseline-exit-1" 1 "$(check "$repo")"
expect_says "corrupt-baseline-names-the-fix" "Re-record it with"

# A typo'd flag must not run a plain check and look like success.
repo="$(topic_repo 10)"
(cd "$repo" && node scripts/check-agents-docs.mjs --update-baselines) >"$OUT" 2>&1
expect_rc "unknown-flag-exit-2" 2 "$?"
expect_says "unknown-flag-named" "unexpected argument"

echo "the shipped AGENTS.md template, rendered the way dw-init renders it, passes the shipped checker:"
# The one case that tests the two payload halves against each other rather than against a fixture.
# Every case above builds its own minimal AGENTS.md, so none of them would notice the template
# growing past its own declared budget, gaining a router row for a path the scaffold does not create,
# or naming a `pnpm <script>` dw-init never writes.
repo="$WORK/rendered"
mkdir -p "$repo/scripts" "$repo/.ai/backlog" "$repo/.ai/archive" "$repo/docs/decisions" "$repo/.claude/hooks"
git -C "$repo" init --quiet
cp "$CHECKER" "$repo/scripts/check-agents-docs.mjs"
mkdir -p "$repo/docs/agents"
for seeded in .ai/README.md .ai/backlog/README.md .ai/archive/README.md CONTEXT.md VERIFY.md; do
  printf 'seeded by dw-init\n' >"$repo/$seeded"
done
# These two are copied rather than stubbed, because they are payload too: the router row dw-init ships
# points at the first, and the second carries the ceiling declaration this checker parses. Stubbing
# them would leave both halves of that pair untested against each other.
cp "$ROOT/templates/agents-docs-README.md" "$repo/docs/agents/README.md"
cp "$ROOT/templates/decisions-README.md" "$repo/docs/decisions/README.md"
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
  -e 's|{{COMMIT_PATTERN}}|`^(feat\|fix): .+`|' \
  -e 's|{{COMMIT_TRAILER}}|none|' \
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
