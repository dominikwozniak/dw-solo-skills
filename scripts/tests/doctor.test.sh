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

# scaffold <budget-tail> [extra-router-row] — a synthetic solo-lane repo: .ai/, docs/decisions/,
# CONTEXT.md, an AGENTS.md with the given budget declaration, a CLAUDE.md symlink and the shipped
# checker's filename. Echoes the repo path. Callers mutate the pieces they are testing.
#
# The extra row goes INSIDE the router table on purpose. Coverage is grepped against the sliced-out
# `## Task Router` section, so a row appended at the end of the file is scanned by nothing — and a case
# built that way passes without testing anything, which is how the whole-file grep stayed hidden.
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
${2:-}

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

echo "survives a hostile environment — it runs on someone else's machine:"
# `set -u` plus a bare $HOME took the whole diagnostic down before the summary, so every check below
# the codex probe was lost. A missing HOME must cost one line, not the report.
repo="$(scaffold '120 lines / 10 KB')"
(cd "$repo" && env -u HOME bash "$DOCTOR") >"$OUT" 2>&1
rc=$?
if [ "$rc" = "0" ] && grep -q "Summary" "$OUT"; then
  note_pass "home-unset-still-reports"
else
  note_fail "home-unset-still-reports" "exit $rc; last line: $(tail -1 "$OUT")"
fi
if grep -q "unbound variable" "$OUT"; then
  note_fail "home-unset-no-unbound-error" "$(grep 'unbound variable' "$OUT" | head -n1)"
else
  note_pass "home-unset-no-unbound-error"
fi

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

# Strict on the tail, exactly as the shipped checker is. An open `.*` accepted this here and the gate
# rejected it — the same divergence class as the line count.
repo="$(scaffold '120 lines / 10 KB trailing garbage')"
run "$repo" >/dev/null
says "trailing-garbage-is-not-parseable" warn "AGENTS.md budget" "not parseable"

# ...but the comma the shipped template actually writes must still parse.
repo="$(scaffold '120 lines / 10 KB, enforced by the checker')"
run "$repo" >/dev/null
says "comma-tail-still-parses" ok "AGENTS.md budget" "/10240 B"

# A leading zero is base 10, not octal. Bash arithmetic bailed on `08` and the budget line vanished
# from the report altogether, while Node reads Number("08") as 8.
repo="$(scaffold '120 lines / 08 KB')"
run "$repo" >/dev/null
says "leading-zero-is-base-10" ok "AGENTS.md budget" "/8192 B"
if grep -q "value too great for base" "$OUT"; then
  note_fail "leading-zero-no-bash-arithmetic-error" "$(grep 'value too great' "$OUT" | head -n1)"
else
  note_pass "leading-zero-no-bash-arithmetic-error"
fi

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

# The same topic file with a row INSIDE the table.
repo="$(scaffold '120 lines / 10 KB' '| ui | `docs/agents/ui.md` |')"
mkdir -p "$repo/docs/agents"
printf 'ui\n' >"$repo/docs/agents/ui.md"
run "$repo" >/dev/null
says "routed-topic-ok" ok "docs/agents/ coverage" "every topic file has a row"

# Coverage is scoped to the router section: a mention anywhere else is not a row. The earlier version
# of the case above appended its row after `## Solo lane` and still passed, because the grep scanned
# the whole file — a case that passed for the wrong reason and hid the bug.
repo="$(scaffold '120 lines / 10 KB')"
mkdir -p "$repo/docs/agents"
printf 'ui\n' >"$repo/docs/agents/ui.md"
printf -- '- see `docs/agents/ui.md` for the boundary\n' >>"$repo/AGENTS.md"
run "$repo" >/dev/null
says "mention-outside-the-router-is-not-a-row" warn "docs/agents/ coverage" "ui.md"

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

# Judged by destination, like the checker: these spellings are the same link, and warning about them
# would flag a correct repo.
repo="$(scaffold '120 lines / 10 KB')"
rm "$repo/CLAUDE.md"
ln -s ./AGENTS.md "$repo/CLAUDE.md"
run "$repo" >/dev/null
says "claude-md-dot-slash-is-ok" ok "CLAUDE.md " "symlink -> AGENTS.md"

repo="$(scaffold '120 lines / 10 KB')"
rm "$repo/CLAUDE.md"
ln -s "$repo/AGENTS.md" "$repo/CLAUDE.md"
run "$repo" >/dev/null
says "claude-md-absolute-is-ok" ok "CLAUDE.md " "symlink -> AGENTS.md"

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

# The value is extracted in the hooks' own ORDER: the `none` sentinel on the raw remainder first, then
# the first backticked span, then the rest of the line. An earlier version of this case asserted the
# opposite — that `none — the `src/*.ts` files…` reports `src/*.ts` — and so pinned the bug instead of
# the contract: the hook was running that path on every edit.
repo="$(scaffold '120 lines / 10 KB')"
grep -v "Lint command" "$repo/AGENTS.md" >"$repo/tmp" && mv "$repo/tmp" "$repo/AGENTS.md"
printf -- '- **Lint command**: none — the `src/*.ts` files are checked by CI\n' >>"$repo/AGENTS.md"
run "$repo" >/dev/null
says "none-beats-explanatory-backticks" ok "Lint command" "none (declared, so the hook skips)"

# A backticked command still wins over surrounding prose — that half was always right.
repo="$(scaffold '120 lines / 10 KB')"
grep -v "Lint command" "$repo/AGENTS.md" >"$repo/tmp" && mv "$repo/tmp" "$repo/AGENTS.md"
printf -- '- **Lint command**: `./lint.sh` (notes after it are ignored)\n' >>"$repo/AGENTS.md"
run "$repo" >/dev/null
says "backticked-command-wins-over-prose" ok "Lint command" "./lint.sh — from AGENTS.md"

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

echo "the line count agrees with the gate, not merely with wc:"
# The checker counts split("\n").length; `wc -l` counts newlines and is one lower. A file exactly on
# its budget therefore passed here and failed the gate — the doctor's whole claim is that it agrees
# with what enforces. Asserted against the real checker rather than a remembered number.
repo="$(scaffold '120 lines / 10 KB')"
mkdir -p "$repo/.ai"
printf 'seeded\n' >"$repo/.ai/README.md"
run "$repo" >/dev/null
doctor_lines="$(grep -F "AGENTS.md budget" "$OUT" | sed -nE 's|.*[^0-9]([0-9]+)/120 lines.*|\1|p')"
checker_lines="$(node -e 'console.log(require("node:fs").readFileSync(process.argv[1],"utf8").split("\n").length)' "$repo/AGENTS.md")"
if [ -n "$doctor_lines" ] && [ "$doctor_lines" = "$checker_lines" ]; then
  note_pass "line-count-matches-the-checker ($doctor_lines)"
else
  note_fail "line-count-matches-the-checker" "doctor said '$doctor_lines', checker says '$checker_lines'"
fi

# The boundary case the mismatch hid: a file whose checker count is exactly the budget must be OK
# here, and one line over must be over — both judged on the same number the gate uses.
lines_now="$checker_lines"
repo="$(scaffold "$lines_now lines / 10 KB")"
run "$repo" >/dev/null
says "exactly-at-budget-is-ok" ok "AGENTS.md budget" "$lines_now/$lines_now lines"

repo="$(scaffold "$((lines_now - 1)) lines / 10 KB")"
run "$repo" >/dev/null
says "one-over-budget-warns" warn "AGENTS.md budget" "over"

echo "a team-lane repo is not half-checked against the solo layout:"
# The lane warning already says the solo plugin is the wrong one here. Repeating "fix: dw-init" for
# AGENTS.md and both command bullets would be advice for a lane this script just disclaimed — the
# same reason the promotion-target checks sit behind $SOLO.
repo="$(scaffold '120 lines / 10 KB')"
rm -rf "$repo/.ai"
mkdir -p "$repo/.ai/runs"
rm "$repo/AGENTS.md" "$repo/CLAUDE.md"
run "$repo" >/dev/null
says "team-lane-memory-skipped" info "agent-memory checks skipped" "team-lane repo"
for label in "AGENTS.md" "Lint command" "Typecheck command"; do
  if grep -F -- "$label" "$OUT" | grep -q "dw-init"; then
    note_fail "team-lane-no-dw-init-advice: $label" "$(grep -F -- "$label" "$OUT" | head -n1)"
  else
    note_pass "team-lane-no-dw-init-advice: $label"
  fi
done

echo "the two silent pnpm-11 traps (inherited from pnpm-pin-in-one-field, which left them untested):"
# That change added both checks and recorded in this change's CHANGE.md that they ship with no
# self-test "because this change owns the harness". This is the harness, so here they are.
#
# The v11 gate is satisfied through the DECLARED pin, never through the pnpm on PATH: `cur_pnpm` also
# flips it, so a case resting on that would pass or fail by machine. For the same reason the v10
# negative — where a `pnpm` block is legitimate — is not testable here at all, and is left out rather
# than faked.
pin_v11() {
  printf '{ "devEngines": { "packageManager": { "name": "pnpm", "version": "11.18.0" } } }\n' >"$1/package.json"
}

repo="$(scaffold '120 lines / 10 KB')"
pin_v11 "$repo"
printf '{ "devEngines": { "packageManager": { "name": "pnpm", "version": "11.18.0" } }, "pnpm": { "onlyBuiltDependencies": ["esbuild"] } }\n' >"$repo/package.json"
run "$repo" >/dev/null
says "orphaned-pnpm-block-warns" warn "pnpm settings" "pnpm 11 reads none of it"

repo="$(scaffold '120 lines / 10 KB')"
pin_v11 "$repo"
run "$repo" >/dev/null
if grep -qF "pnpm settings" "$OUT"; then
  note_fail "no-pnpm-block-is-silent" "$(grep -F 'pnpm settings' "$OUT" | head -n1)"
else
  note_pass "no-pnpm-block-is-silent"
fi

# The pre-v11 LOCKFILE check was untestable until doctor.sh stopped probing with `pnpm -v` inside the
# repo: in a repo declaring `devEngines.packageManager` that probe made pnpm download itself and
# REWRITE pnpm-lock.yaml, adding the very `packageManagerDependencies` key this check looks for — so
# the fixture was v11 by the time the check read it. The probe now runs from `/`, and these three
# cases are what that bought. The last one is the guard: it asserts the fixture's lockfile is
# byte-identical across a run, so a future repo-local probe fails here instead of shipping.
lock_pre_v11() {
  # No leading `---`, and neither of the two per-importer keys v11 writes. `lockfileVersion: '9.0'`
  # is deliberately present and deliberately not the tell — v11 still writes exactly that.
  printf "lockfileVersion: '9.0'\n\nimporters:\n  .: {}\n" >"$1/pnpm-lock.yaml"
}

repo="$(scaffold '120 lines / 10 KB')"
pin_v11 "$repo"
lock_pre_v11 "$repo"
run "$repo" >/dev/null
says "pre-v11-lockfile-warns" warn "pnpm-lock.yaml" "written before pnpm 11"

repo="$(scaffold '120 lines / 10 KB')"
pin_v11 "$repo"
printf -- "---\nlockfileVersion: '9.0'\n\nimporters:\n  .:\n    packageManagerDependencies: {}\n" >"$repo/pnpm-lock.yaml"
run "$repo" >/dev/null
if grep -qF "written before pnpm 11" "$OUT"; then
  note_fail "v11-lockfile-is-silent" "$(grep -F 'written before pnpm 11' "$OUT" | head -n1)"
else
  note_pass "v11-lockfile-is-silent"
fi

repo="$(scaffold '120 lines / 10 KB')"
pin_v11 "$repo"
lock_pre_v11 "$repo"
before="$(cksum <"$repo/pnpm-lock.yaml")"
run "$repo" >/dev/null
if [ "$(cksum <"$repo/pnpm-lock.yaml")" = "$before" ]; then
  note_pass "run-does-not-touch-the-lockfile"
else
  note_fail "run-does-not-touch-the-lockfile" "pnpm-lock.yaml changed across one doctor run"
fi

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
