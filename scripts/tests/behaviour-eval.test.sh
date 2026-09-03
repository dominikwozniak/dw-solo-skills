#!/usr/bin/env bash
# Self-test for evals/behaviour.ts — the free half of it.
#
# The behaviour eval spends real money the moment it calls `claude`, so everything it does BEFORE
# that call is what a test can hold: reading and rejecting case files, building the throwaway git
# fixture, and deciding whether a grader's answer may be believed. This covers exactly those, makes
# zero model calls, and is why a bare `node evals/behaviour.ts` is safe to type.
#
# The case that motivates the arithmetic tests: a grader can return well-formed JSON whose summary
# disagrees with its own per-expectation booleans — three passed, summary says four — and a run that
# trusts the summary reports a green case that was never green. The schema cannot catch that; only
# recounting can.
#
# Run standalone (`bash scripts/tests/behaviour-eval.test.sh`) or via scripts/validate-artifacts.sh.
# Exit 0 iff every case matches. bash 3.2 safe.
set -uo pipefail
export LC_ALL=C

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
RUNNER="$ROOT/evals/behaviour.ts"
[ -f "$RUNNER" ] || { echo "SKIP: no evals/behaviour.ts"; exit 0; }

PASS=0
FAIL=0
note_pass() { PASS=$((PASS + 1)); echo "  ✓ $1"; }
note_fail() { FAIL=$((FAIL + 1)); echo "  ✗ $1 — $2"; }

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

# --- the grading validator ----------------------------------------------------
# grading <json> <expected-count> — echoes "ok" when the answer may be believed, "reject" otherwise.
grading() {
  G_JSON="$1" G_COUNT="$2"
  export G_JSON G_COUNT
  node --input-type=module -e '
    const { validateGrading } = await import(process.env.RUNNER)
    const out = validateGrading(process.env.G_JSON, Number(process.env.G_COUNT))
    console.log(out === null ? "reject" : "ok")
  ' 2>/dev/null
}
export RUNNER

echo "Checking the grading validator..."

two_ok='{"expectations":[{"text":"a","passed":true,"evidence":"e"},{"text":"b","passed":false,"evidence":"e"}],"summary":{"passed":1,"failed":1,"total":2}}'
[ "$(grading "$two_ok" 2)" = "ok" ] &&
  note_pass "a consistent grading is accepted" ||
  note_fail "a consistent grading is accepted" "it was rejected"

# The summary claims both passed; the booleans say one did. This is the case the JSON schema cannot
# express and the only reason this validator exists at all.
lying='{"expectations":[{"text":"a","passed":true,"evidence":"e"},{"text":"b","passed":false,"evidence":"e"}],"summary":{"passed":2,"failed":0,"total":2}}'
[ "$(grading "$lying" 2)" = "reject" ] &&
  note_pass "a summary that disagrees with its own booleans is rejected" ||
  note_fail "a summary that disagrees with its own booleans is rejected" "it was accepted"

short='{"expectations":[{"text":"a","passed":true,"evidence":"e"}],"summary":{"passed":1,"failed":0,"total":1}}'
[ "$(grading "$short" 2)" = "reject" ] &&
  note_pass "a grading covering fewer expectations than were asked is rejected" ||
  note_fail "a grading covering fewer expectations than were asked is rejected" "it was accepted"

no_evidence='{"expectations":[{"text":"a","passed":true},{"text":"b","passed":false,"evidence":"e"}],"summary":{"passed":1,"failed":1,"total":2}}'
[ "$(grading "$no_evidence" 2)" = "reject" ] &&
  note_pass "a verdict with no evidence field is rejected" ||
  note_fail "a verdict with no evidence field is rejected" "it was accepted"

[ "$(grading 'I could not grade this.' 2)" = "reject" ] &&
  note_pass "prose instead of JSON is rejected" ||
  note_fail "prose instead of JSON is rejected" "it was accepted"

# A model that wraps its JSON in a fence or a sentence is still answering.
fenced='here you go: ```json
{"expectations":[{"text":"a","passed":true,"evidence":"e"}],"summary":{"passed":1,"failed":0,"total":1}}
``` hope that helps'
[ "$(grading "$fenced" 1)" = "ok" ] &&
  note_pass "JSON wrapped in prose or a fence is still read" ||
  note_fail "JSON wrapped in prose or a fence is still read" "it was rejected"

# --- fixture materialisation --------------------------------------------------
echo "Checking fixture materialisation..."

FIX="$WORK/fixtures"
mkdir -p "$FIX/demo/base" "$FIX/demo/branch" "$FIX/demo/dirty" "$FIX/demo/.eval"
printf 'baseline\n' >"$FIX/demo/base/kept.txt"
printf 'on the branch\n' >"$FIX/demo/branch/added.txt"
printf 'uncommitted\n' >"$FIX/demo/dirty/scratch.txt"
printf 'some-change\n' >"$FIX/demo/.eval/branch"

FIX_DIR="$FIX"
export FIX_DIR
WS="$(node --input-type=module -e '
  const { materialiseFixture } = await import(process.env.RUNNER)
  console.log(materialiseFixture("demo", process.env.FIX_DIR))
' 2>"$WORK/mat.err")"

if [ -n "$WS" ] && [ -d "$WS" ]; then
  note_pass "a fixture materialises into a workspace"

  [ "$(git -C "$WS" rev-parse --abbrev-ref HEAD)" = "some-change" ] &&
    note_pass ".eval/branch decides the branch" ||
    note_fail ".eval/branch decides the branch" "on $(git -C "$WS" rev-parse --abbrev-ref HEAD)"

  # Two commits: the baseline, then the branch's own. The second is what gives `main...HEAD` a diff
  # for the skills that grade one — a fixture with only a dirty tree cannot test those.
  [ "$(git -C "$WS" rev-list --count HEAD)" = "2" ] &&
    note_pass "base/ and branch/ land as two commits" ||
    note_fail "base/ and branch/ land as two commits" "count $(git -C "$WS" rev-list --count HEAD)"

  [ -z "$(git -C "$WS" ls-files .eval)" ] && [ ! -d "$WS/.eval" ] &&
    note_pass ".eval/ is stripped and never committed" ||
    note_fail ".eval/ is stripped and never committed" "it survived into the workspace"

  git -C "$WS" status --porcelain | grep -q '?? scratch.txt' &&
    note_pass "dirty/ is left uncommitted" ||
    note_fail "dirty/ is left uncommitted" "scratch.txt is not an untracked change"

  git -C "$WS" show --quiet --format=%D main 2>/dev/null | grep -q main &&
    note_pass "the default branch is main, not the host's init.defaultBranch" ||
    note_fail "the default branch is main" "no main branch in the workspace"

  rm -rf "$WS"
else
  note_fail "a fixture materialises into a workspace" "$(head -2 "$WORK/mat.err" | tr '\n' ' ')"
fi

# A name that climbs out of evals/fixtures/ is refused before anything is copied.
escaped="$(node --input-type=module -e '
  const { materialiseFixture } = await import(process.env.RUNNER)
  try { materialiseFixture("../../skills", process.env.FIX_DIR); console.log("allowed") }
  catch { console.log("refused") }
' 2>/dev/null)"
[ "$escaped" = "refused" ] &&
  note_pass "a fixture name climbing out of its directory is refused" ||
  note_fail "a fixture name climbing out of its directory is refused" "got '$escaped'"

# --- the cost gate ------------------------------------------------------------
echo "Checking the cost gate..."

# The point of the whole file: typing the runner's name spends nothing. A fake `claude` on PATH
# leaves a sentinel if it is ever called, so this fails loudly rather than silently costing money.
mkdir -p "$WORK/bin"
cat >"$WORK/bin/claude" <<'FAKE'
#!/usr/bin/env bash
touch "$SENTINEL"
echo '{}'
FAKE
chmod +x "$WORK/bin/claude"
SENTINEL="$WORK/claude-was-called"
export SENTINEL

PATH="$WORK/bin:$PATH" node "$RUNNER" >"$WORK/plan.txt" 2>&1
plan_status=$?

[ "$plan_status" -eq 0 ] &&
  note_pass "a bare run exits 0" ||
  note_fail "a bare run exits 0" "exit $plan_status"

[ ! -f "$SENTINEL" ] &&
  note_pass "a bare run never calls claude" ||
  note_fail "a bare run never calls claude" "the sentinel exists"

grep -q -- "--go" "$WORK/plan.txt" &&
  note_pass "the plan says how to actually run it" ||
  note_fail "the plan says how to actually run it" "no --go in the output"

grep -qi "estimated" "$WORK/plan.txt" &&
  note_pass "the plan prints an estimated cost" ||
  note_fail "the plan prints an estimated cost" "no estimate in the output"

# --- case-file validation -----------------------------------------------------
echo "Checking case-file validation..."

PATH="$WORK/bin:$PATH" node "$RUNNER" no-such-skill >"$WORK/missing.txt" 2>&1
[ "$?" -ne 0 ] && grep -q "no behaviour case file for" "$WORK/missing.txt" &&
  note_pass "a filter naming a skill with no case file fails" ||
  note_fail "a filter naming a skill with no case file fails" "$(head -1 "$WORK/missing.txt")"

echo ""
echo "behaviour-eval self-test: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
