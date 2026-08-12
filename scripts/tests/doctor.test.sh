#!/usr/bin/env bash
# Self-test for dw-doctor's doctor.sh — its first. It is the only script this marketplace ships that
# runs on someone else's machine, and its whole value is that its verdict is true; a diagnostic that
# reports a lint command the hook would never run is worse than no diagnostic.
#
# Every case runs against a SYNTHETIC repo under mktemp, never against this one. A self-test whose
# fixture is the live tree is a content gate wearing a unit test's name — it ends up asserting what
# this repo happens to contain rather than what the script promises.
#
# Scoped to the agent-memory block and the always-exit-0 contract. The tool probes (git, jq, gh,
# codex, node, pnpm) read the real PATH, so asserting on them would make the verdict depend on the
# machine — the one thing this file exists to avoid.
#
# Run standalone (`bash scripts/tests/doctor.test.sh`) or via scripts/validate-artifacts.sh.
# Exit 0 iff every case matches. bash 3.2 safe.
set -uo pipefail
export LC_ALL=C

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
DOCTOR="$ROOT/skills/dw-doctor/scripts/doctor.sh"

PASS=0
FAIL=0
note_pass() { PASS=$((PASS + 1)); echo "  ✓ $1"; }
note_fail() { FAIL=$((FAIL + 1)); echo "  ✗ $1 — $2"; }

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
OUT="$WORK/report"

# scaffold <budget-tail> — a synthetic solo-lane repo: .ai/, docs/decisions/, CONTEXT.md, an AGENTS.md
# with the given budget declaration, a CLAUDE.md symlink and the shipped checker's filename. Echoes
# the repo path. Callers mutate the pieces they are testing.
scaffold() {
  local dir
  dir="$WORK/repo.$RANDOM$RANDOM"
  mkdir -p "$dir/.ai/work" "$dir/docs/decisions" "$dir/scripts"
  git -C "$dir" init --quiet
  printf 'glossary\n' >"$dir/CONTEXT.md"
  printf '// the gate\n' >"$dir/scripts/check-agents-docs.mjs"
  cat >"$dir/AGENTS.md" <<AGENTS
# Fixture — agent rules

> Budget: **${1}**, enforced by the checker.

## Task Router

| task          | read           |
| ------------- | -------------- |
| a domain term | \`CONTEXT.md\` |

## Solo lane

- **Lint command**: \`./lint.sh\`
- **Typecheck command**: none
AGENTS
  ln -s AGENTS.md "$dir/CLAUDE.md"
  printf '%s\n' "$dir"
}

# run <repo> — run the doctor from inside the repo, capture the report, echo the exit code.
run() {
  (cd "$1" && bash "$DOCTOR") >"$OUT" 2>&1
  printf '%s\n' "$?"
}

# says <name> <level> <label-substring> [value-substring] — assert one report line at a given level.
says() {
  local want_level="$2" label="$3" value="${4:-}"
  local line
  line="$(grep -F -- "$label" "$OUT" | head -n1)"
  if [ -z "$line" ]; then
    note_fail "$1" "no line mentioning '$label'"
    return
  fi
  case "$want_level" in
    ok) case "$line" in *"[ OK ]"*) ;; *) note_fail "$1" "not OK: $line"; return ;; esac ;;
    warn) case "$line" in *"[WARN]"*) ;; *) note_fail "$1" "not WARN: $line"; return ;; esac ;;
    fail) case "$line" in *"[FAIL]"*) ;; *) note_fail "$1" "not FAIL: $line"; return ;; esac ;;
    info) case "$line" in *"[ OK ]"* | *"[WARN]"* | *"[FAIL]"*) note_fail "$1" "expected info tier: $line"; return ;; esac ;;
  esac
  if [ -n "$value" ]; then
    case "$line" in *"$value"*) ;; *) note_fail "$1" "line did not carry '$value': $line"; return ;; esac
  fi
  note_pass "$1"
}

echo "read-only and always exit 0, whatever it finds:"
repo="$(scaffold '120 lines / 10 KB')"
rc="$(run "$repo")"
if [ "$rc" = "0" ]; then note_pass "healthy-exit-0"; else note_fail "healthy-exit-0" "exit $rc"; fi
rm -rf "$repo/.ai" "$repo/AGENTS.md" "$repo/CLAUDE.md" "$repo/CONTEXT.md" "$repo/docs"
rc="$(run "$repo")"
if [ "$rc" = "0" ]; then note_pass "broken-repo-still-exit-0"; else note_fail "broken-repo-still-exit-0" "exit $rc"; fi
if grep -q "Read-only: nothing was installed or modified" "$OUT"; then
  note_pass "read-only-line-printed"
else
  note_fail "read-only-line-printed" "missing"
fi

echo "a healthy scaffold reports the whole agent-memory block OK:"
repo="$(scaffold '120 lines / 10 KB')"
run "$repo" >/dev/null
says "healthy-agents-present" ok "AGENTS.md " "present"
says "healthy-budget-ok" ok "AGENTS.md budget" "/120 lines"
says "healthy-router-ok" ok "AGENTS.md Task Router" "1 row"
says "healthy-symlink-ok" ok "CLAUDE.md " "symlink -> AGENTS.md"
says "healthy-checker-present" ok "agents:check" "check-agents-docs.mjs present"

echo "the budget, parsed the way the shipped checker parses it:"
repo="$(scaffold '120 lines / 1 KB')"
run "$repo" >/dev/null
says "kb-unit-multiplied" ok "AGENTS.md budget" "/1024 B"

repo="$(scaffold '120 lines / 1024')"
run "$repo" >/dev/null
says "bare-number-is-bytes" ok "AGENTS.md budget" "/1024 B"

repo="$(scaffold '120 lines / 10_240')"
run "$repo" >/dev/null
says "underscores-stripped" ok "AGENTS.md budget" "/10240 B"

repo="$(scaffold '3 lines / 10 KB')"
run "$repo" >/dev/null
says "over-line-budget-warns" warn "AGENTS.md budget" "over"

repo="$(scaffold '120 lines / 30')"
run "$repo" >/dev/null
says "over-byte-budget-warns" warn "AGENTS.md budget" "over"

repo="$(scaffold '120 lines / 10 MB')"
run "$repo" >/dev/null
says "unknown-unit-warns" warn "AGENTS.md budget" "not understood"

repo="$(scaffold 'as long as it needs to be')"
run "$repo" >/dev/null
says "unparseable-budget-warns" warn "AGENTS.md budget" "not parseable"

repo="$(scaffold '120 lines / 10 KB')"
grep -v "Budget:" "$repo/AGENTS.md" >"$repo/tmp" && mv "$repo/tmp" "$repo/AGENTS.md"
run "$repo" >/dev/null
says "absent-budget-warns" warn "AGENTS.md budget" "no 'Budget:"

echo "the router and the topic layer it indexes:"
repo="$(scaffold '120 lines / 10 KB')"
mkdir -p "$repo/docs/agents"
printf 'ui\n' >"$repo/docs/agents/ui.md"
run "$repo" >/dev/null
says "unrouted-topic-warns" warn "docs/agents/ coverage" "ui.md"

printf '| ui | `docs/agents/ui.md` |\n' >>"$repo/AGENTS.md"
run "$repo" >/dev/null
says "routed-topic-ok" ok "docs/agents/ coverage" "every topic file has a row"

repo="$(scaffold '120 lines / 10 KB')"
grep -v "## Task Router" "$repo/AGENTS.md" >"$repo/tmp" && mv "$repo/tmp" "$repo/AGENTS.md"
run "$repo" >/dev/null
says "absent-router-warns" warn "AGENTS.md Task Router" "no '## Task Router'"

echo "an unrendered placeholder is called out, not read as content:"
repo="$(scaffold '120 lines / 10 KB')"
printf -- '- **Stack**: {{STACK}}\n' >>"$repo/AGENTS.md"
run "$repo" >/dev/null
says "placeholder-warns" warn "AGENTS.md placeholders" "{{STACK}}"

echo "CLAUDE.md must be the symlink, never a second copy:"
repo="$(scaffold '120 lines / 10 KB')"
rm "$repo/CLAUDE.md"
printf 'a forked copy\n' >"$repo/CLAUDE.md"
run "$repo" >/dev/null
says "claude-md-real-file-warns" warn "CLAUDE.md " "a real file beside AGENTS.md"

repo="$(scaffold '120 lines / 10 KB')"
rm "$repo/CLAUDE.md"
ln -s CONTEXT.md "$repo/CLAUDE.md"
run "$repo" >/dev/null
says "claude-md-wrong-target-warns" warn "CLAUDE.md " "not AGENTS.md"

repo="$(scaffold '120 lines / 10 KB')"
rm "$repo/CLAUDE.md"
run "$repo" >/dev/null
says "claude-md-absent-warns" warn "CLAUDE.md " "absent"

echo "the two command bullets, resolved in the hooks' own order:"
repo="$(scaffold '120 lines / 10 KB')"
run "$repo" >/dev/null
says "lint-from-agents" ok "Lint command" "./lint.sh — from AGENTS.md"
# `none` is an answer, not a gap: it is what tells the hook to skip rather than eval nothing.
says "typecheck-none-is-ok" ok "Typecheck command" "none (declared, so the hook skips)"

# A legacy repo: AGENTS.md carries no bullet, CLAUDE.local.md does, and the report names the source.
repo="$(scaffold '120 lines / 10 KB')"
grep -v "command\*\*:" "$repo/AGENTS.md" >"$repo/tmp" && mv "$repo/tmp" "$repo/AGENTS.md"
printf '## Project specifics\n\n- **Lint command**: `./legacy-lint.sh`\n' >"$repo/CLAUDE.local.md"
run "$repo" >/dev/null
says "lint-from-legacy" ok "Lint command" "./legacy-lint.sh — from CLAUDE.local.md (legacy)"
says "typecheck-nowhere-warns" warn "Typecheck command" "declared nowhere"
# Matched on the message, not the label: "CLAUDE.local.md" also appears in the Lint command line
# above it, and grep -F would hand back that one instead.
says "legacy-file-is-info-tier" info "nothing writes it any more" "CLAUDE.local.md"

# The value is extracted the way the hooks extract it — first backticked span, else the rest of the
# line. A bullet whose prose mentions another backticked path must report what the HOOK would run.
repo="$(scaffold '120 lines / 10 KB')"
grep -v "Lint command" "$repo/AGENTS.md" >"$repo/tmp" && mv "$repo/tmp" "$repo/AGENTS.md"
printf -- '- **Lint command**: none — the `src/*.ts` files are checked by CI\n' >>"$repo/AGENTS.md"
run "$repo" >/dev/null
says "value-matches-hook-extraction" ok "Lint command" "src/*.ts"

repo="$(scaffold '120 lines / 10 KB')"
grep -v "Lint command" "$repo/AGENTS.md" >"$repo/tmp" && mv "$repo/tmp" "$repo/AGENTS.md"
printf -- '- **Lint command**: {{LINT_COMMAND}}\n' >>"$repo/AGENTS.md"
run "$repo" >/dev/null
says "placeholder-value-warns" warn "Lint command" "unrendered"

echo "a pre-migration layout is named as one, not reported as an empty repo:"
repo="$(scaffold '120 lines / 10 KB')"
rm "$repo/AGENTS.md" "$repo/CLAUDE.md"
printf '# old root\n' >"$repo/CLAUDE.md"
run "$repo" >/dev/null
says "pre-migration-named" warn "AGENTS.md" "pre-migration layout"

echo "lane detection still fires:"
repo="$(scaffold '120 lines / 10 KB')"
mkdir -p "$repo/.ai/runs"
run "$repo" >/dev/null
says "team-lane-warns" warn "lane" "team lane"

repo="$(scaffold '120 lines / 10 KB')"
rm -rf "$repo/.ai"
run "$repo" >/dev/null
says "unscaffolded-warns" warn ".ai/work/" "not scaffolded"

echo
echo "doctor self-test: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
