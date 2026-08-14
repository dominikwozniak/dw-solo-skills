#!/usr/bin/env bash
# Self-test for worktree.sh: pins the create/remove contract in a throwaway repo — worktree at
# .claude/worktrees/<slug> on branch <slug>, stdout carrying only the path, the never-nest and
# dirty-worktree refusals, and remove resolving the branch from porcelain (so a `claude
# --worktree` worktree named worktree-<slug> tears down just as cleanly).
#
# Run standalone (`bash scripts/tests/worktree.test.sh`) or via scripts/validate-artifacts.sh.
# Exit 0 iff every case passes. bash 3.2 / macOS + BSD safe.
set -uo pipefail
export LC_ALL=C

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
WORKTREE="$ROOT/scripts/runtime/worktree.sh"

PASS=0
FAIL=0
note_pass() { PASS=$((PASS + 1)); echo "  ✓ $1"; }
note_fail() { FAIL=$((FAIL + 1)); echo "  ✗ $1 — $2"; }

TMP="$(mktemp -d)"
trap 'cd / && rm -rf "$TMP"' EXIT

# Throwaway repo with one commit — worktree add checks out committed state only.
REPO="$TMP/repo"
mkdir -p "$REPO"
cd "$REPO"
# macOS mktemp hands out a /var/folders/... symlink; the script prints physical paths.
REPO="$(pwd -P)"
git init -q -b main
git config user.email "test@test"
git config user.name "test"
echo one >file.txt
git add file.txt
git commit -qm "init"
BASE_SHA="$(git rev-parse HEAD)"
echo two >>file.txt
git add file.txt
git commit -qm "second"

echo "create:"
out=$("$WORKTREE" create alpha 2>/dev/null)
rc=$?
if [ "$rc" -eq 0 ] && [ "$out" = "$REPO/.claude/worktrees/alpha" ] && [ -d "$out" ]; then
  note_pass "create-ok (path on stdout, dir exists)"
else
  note_fail "create-ok" "rc=$rc out='$out'"
fi

got_branch="$(cd "$REPO/.claude/worktrees/alpha" && git rev-parse --abbrev-ref HEAD)"
if [ "$got_branch" = "alpha" ]; then
  note_pass "create-branch-checked-out"
else
  note_fail "create-branch-checked-out" "got '$got_branch'"
fi

if "$WORKTREE" create alpha >/dev/null 2>&1; then
  note_fail "create-duplicate-refused" "expected non-zero exit"
else
  note_pass "create-duplicate-refused"
fi

if (cd "$REPO/.claude/worktrees/alpha" && "$WORKTREE" create nested >/dev/null 2>&1); then
  note_fail "create-nested-refused" "expected non-zero exit"
else
  note_pass "create-nested-refused"
fi

"$WORKTREE" create beta "$BASE_SHA" >/dev/null 2>&1
beta_sha="$(cd "$REPO/.claude/worktrees/beta" && git rev-parse HEAD)"
if [ "$beta_sha" = "$BASE_SHA" ]; then
  note_pass "create-custom-base"
else
  note_fail "create-custom-base" "want $BASE_SHA got $beta_sha"
fi

echo "remove:"
if (cd "$REPO/.claude/worktrees/alpha" && "$WORKTREE" remove alpha >/dev/null 2>&1); then
  note_fail "remove-from-inside-refused" "expected non-zero exit"
else
  note_pass "remove-from-inside-refused"
fi

echo dirty >>"$REPO/.claude/worktrees/alpha/file.txt"
if "$WORKTREE" remove alpha >/dev/null 2>&1; then
  note_fail "remove-dirty-refused" "expected non-zero exit"
elif [ -d "$REPO/.claude/worktrees/alpha" ]; then
  note_pass "remove-dirty-refused (worktree kept)"
else
  note_fail "remove-dirty-refused" "worktree is gone despite refusal"
fi

git -C "$REPO/.claude/worktrees/alpha" checkout -q -- file.txt
if "$WORKTREE" remove alpha >/dev/null 2>&1 &&
  ! git -C "$REPO" worktree list | grep -q "worktrees/alpha" &&
  ! git -C "$REPO" show-ref --verify --quiet refs/heads/alpha; then
  note_pass "remove-ok (worktree and branch gone)"
else
  note_fail "remove-ok" "worktree or branch survived"
fi

if "$WORKTREE" remove alpha >/dev/null 2>&1; then
  note_fail "remove-missing-refused" "expected non-zero exit"
else
  note_pass "remove-missing-refused"
fi

# The `claude --worktree` spelling: dir gamma, branch worktree-gamma — remove must resolve the
# branch from porcelain rather than assume it equals the slug.
git -C "$REPO" worktree add -b worktree-gamma "$REPO/.claude/worktrees/gamma" >/dev/null 2>&1
if "$WORKTREE" remove gamma >/dev/null 2>&1 &&
  ! git -C "$REPO" show-ref --verify --quiet refs/heads/worktree-gamma; then
  note_pass "remove-claude-w-spelling (branch worktree-gamma gone)"
else
  note_fail "remove-claude-w-spelling" "branch worktree-gamma survived"
fi

echo ".worktreeinclude:"
# A file is copied only when it matches a pattern AND is gitignored — the documented rule. Each
# case below is one half of that conjunction, plus the refusals, plus the stdout contract.
printf 'local-probe.txt\nnested/\ntracked-probe.txt\nunlisted.txt\nnode_modules/\n' >"$REPO/.gitignore"
git -C "$REPO" add .gitignore
git -C "$REPO" commit -qm "gitignore"

# Gitignored and listed -> copied. Mode 600 must survive.
echo secret >"$REPO/local-probe.txt"
chmod 600 "$REPO/local-probe.txt"
# Gitignored, not listed -> skipped.
echo nope >"$REPO/unlisted.txt"
# Listed but TRACKED -> skipped (the checkout already has it).
echo tracked >"$REPO/tracked-probe.txt"
git -C "$REPO" add -f tracked-probe.txt
git -C "$REPO" commit -qm "tracked probe"
# Nested pattern -> parent dirs created at the destination.
mkdir -p "$REPO/nested"
echo deep >"$REPO/nested/deep.txt"
# Refused regardless of the pattern.
mkdir -p "$REPO/node_modules/pkg"
echo dep >"$REPO/node_modules/pkg/index.js"

printf 'local-probe.txt\nnested/**\ntracked-probe.txt\nnode_modules/**\n' >"$REPO/.worktreeinclude"

ERRLOG="$TMP/delta.stderr"
out=$("$WORKTREE" create delta 2>"$ERRLOG")
WT="$REPO/.claude/worktrees/delta"

if [ "$out" = "$WT" ]; then
  note_pass "include-stdout-still-path-only"
else
  note_fail "include-stdout-still-path-only" "stdout was '$out'"
fi

if [ -f "$WT/local-probe.txt" ] && [ "$(cat "$WT/local-probe.txt")" = "secret" ]; then
  note_pass "include-ignored-and-listed-copied"
else
  note_fail "include-ignored-and-listed-copied" "missing or wrong content"
fi

got_mode="$(ls -l "$WT/local-probe.txt" 2>/dev/null | cut -c1-10)"
if [ "$got_mode" = "-rw-------" ]; then
  note_pass "include-mode-preserved (600)"
else
  note_fail "include-mode-preserved" "got '$got_mode'"
fi

if [ -f "$WT/nested/deep.txt" ]; then
  note_pass "include-nested-pattern-copied"
else
  note_fail "include-nested-pattern-copied" "parent dir or file missing"
fi

if [ ! -e "$WT/unlisted.txt" ]; then
  note_pass "include-ignored-not-listed-skipped"
else
  note_fail "include-ignored-not-listed-skipped" "copied a file no pattern named"
fi

# Tracked files arrive via the checkout, never the copy — proven by content, since a copy would
# have overwritten the committed "tracked" with the working-tree value.
if [ -f "$WT/tracked-probe.txt" ] && [ "$(cat "$WT/tracked-probe.txt")" = "tracked" ]; then
  note_pass "include-tracked-not-duplicated"
else
  note_fail "include-tracked-not-duplicated" "tracked file missing or overwritten"
fi

if [ ! -e "$WT/node_modules" ]; then
  note_pass "include-node-modules-refused"
else
  note_fail "include-node-modules-refused" "copied node_modules despite the hard refusal"
fi

# The refusal is silent-by-default's opposite: it has to say so, on stderr, from the same run that
# did the copying.
if grep -q "refused 1 path(s) matched by .worktreeinclude" "$ERRLOG"; then
  note_pass "include-refusal-reported-on-stderr"
else
  note_fail "include-refusal-reported-on-stderr" "no refusal line in stderr: $(tr '\n' '|' <"$ERRLOG")"
fi

# The volume warning counts post-refusal, so a pattern whose bulk is refused must not trip it —
# otherwise it cries wolf on every repo with node_modules and stops being read.
if grep -q "files to copy" "$ERRLOG"; then
  note_fail "include-volume-warning-counts-after-refusals" "warned about files it was going to refuse"
else
  note_pass "include-volume-warning-counts-after-refusals"
fi

# Two, not three: tracked-probe.txt is listed but tracked, so the intersection drops it.
if grep -q "copied 2 file(s) named by .worktreeinclude" "$ERRLOG"; then
  note_pass "include-copy-count-reported-on-stderr"
else
  note_fail "include-copy-count-reported-on-stderr" "stderr: $(tr '\n' '|' <"$ERRLOG")"
fi

"$WORKTREE" remove delta >/dev/null 2>&1

# No .worktreeinclude at all -> create behaves exactly as before.
rm -f "$REPO/.worktreeinclude"
out=$("$WORKTREE" create epsilon 2>/dev/null)
if [ "$out" = "$REPO/.claude/worktrees/epsilon" ] && [ ! -e "$REPO/.claude/worktrees/epsilon/local-probe.txt" ]; then
  note_pass "include-absent-is-a-no-op"
else
  note_fail "include-absent-is-a-no-op" "rc/out='$out' or a file was copied anyway"
fi
"$WORKTREE" remove epsilon >/dev/null 2>&1

echo "tracked AGENTS.md needs no carry at all (the link class lost its member):"
# Decision 0007: agent memory is tracked now, so `git worktree add` delivers it unaided. This is the
# ordinary case, and the point of asserting it is that nothing in worktree.sh has to be involved.
printf '# Fixture — agent rules\n' >"$REPO/AGENTS.md"
git -C "$REPO" add AGENTS.md
git -C "$REPO" commit -qm "tracked agent memory"
"$WORKTREE" create upsilon >/dev/null 2>&1
UPSILON="$REPO/.claude/worktrees/upsilon"
if [ -f "$UPSILON/AGENTS.md" ] && [ ! -L "$UPSILON/AGENTS.md" ]; then
  note_pass "tracked-memory-arrives-as-a-real-file"
else
  note_fail "tracked-memory-arrives-as-a-real-file" "missing, or carried in as a link"
fi
"$WORKTREE" remove upsilon >/dev/null 2>&1

echo "legacy CLAUDE.local.md is NOT carried in — the link class is retired:"
# Decision 0007 moved agent memory into tracked AGENTS.md, which git checks out unaided, and that left
# the link class with no member. The link step and its SessionStart hook are both gone. What this
# group pins is the retirement itself, in the one case that used to trigger it: a legacy file sitting
# in the main tree.
#
# A legacy repo still READS its own file — lint-on-edit and typecheck-on-stop resolve AGENTS.md first
# and CLAUDE.local.md second, and that is untouched. Nothing carries it across a worktree boundary any
# more, and `create` must not mention it in either direction: a message about a file the scaffold
# stopped writing is noise on every worktree of every repo made from here on.
echo "conventions" >"$REPO/CLAUDE.local.md"
ZLOG="$TMP/zeta.stderr"
out=$("$WORKTREE" create zeta 2>"$ZLOG")
ZETA="$REPO/.claude/worktrees/zeta"
if [ ! -e "$ZETA/CLAUDE.local.md" ]; then
  note_pass "legacy-local-memory-not-carried-in"
else
  note_fail "legacy-local-memory-not-carried-in" "something appeared: $(ls -ld "$ZETA/CLAUDE.local.md")"
fi
if [ "$out" = "$ZETA" ]; then
  note_pass "legacy-local-memory-create-still-succeeds"
else
  note_fail "legacy-local-memory-create-still-succeeds" "out='$out'"
fi
if grep -qi "CLAUDE.local.md" "$ZLOG"; then
  note_fail "legacy-local-memory-unmentioned" "stderr mentioned it: $(tr '\n' '|' <"$ZLOG")"
else
  note_pass "legacy-local-memory-unmentioned"
fi
"$WORKTREE" remove zeta >/dev/null 2>&1
rm -f "$REPO/CLAUDE.local.md"

echo "readiness report (the regenerate class):"
# The report exists because this class fails silently: no node_modules is a loud build error, but
# no .husky/_ means git finds no hooks and commits skip every gate without a word.
echo '{"name":"probe"}' >"$REPO/package.json"
touch "$REPO/pnpm-lock.yaml"
mkdir -p "$REPO/.husky"
echo "pnpm exec lint-staged" >"$REPO/.husky/pre-commit"
git -C "$REPO" add package.json pnpm-lock.yaml .husky/pre-commit
git -C "$REPO" commit -qm "node project with husky"

RLOG="$TMP/iota.stderr"
out=$("$WORKTREE" create iota 2>"$RLOG")
if [ "$out" = "$REPO/.claude/worktrees/iota" ]; then
  note_pass "readiness-stdout-still-path-only"
else
  note_fail "readiness-stdout-still-path-only" "stdout was '$out'"
fi
if grep -q "run: pnpm install" "$RLOG"; then
  note_pass "readiness-names-the-install-command"
else
  note_fail "readiness-names-the-install-command" "stderr: $(tr '\n' '|' <"$RLOG")"
fi
if grep -q "COMMIT HOOKS ARE INACTIVE" "$RLOG"; then
  note_pass "readiness-warns-hooks-inactive"
else
  note_fail "readiness-warns-hooks-inactive" "stderr: $(tr '\n' '|' <"$RLOG")"
fi
"$WORKTREE" remove iota >/dev/null 2>&1

# With .husky/_ present the hook warning must not fire — the report has to stay believable.
# Committed so the fresh checkout actually has it — in a real repo the install regenerates it.
mkdir -p "$REPO/.husky/_"
echo "husky" >"$REPO/.husky/_/h"
git -C "$REPO" add -f .husky/_/h
git -C "$REPO" commit -qm "husky internals"
RLOG2="$TMP/kappa.stderr"
"$WORKTREE" create kappa 2>"$RLOG2" >/dev/null
if grep -q "COMMIT HOOKS ARE INACTIVE" "$RLOG2"; then
  note_fail "readiness-no-false-hook-warning" "warned despite .husky/_ being present"
else
  note_pass "readiness-no-false-hook-warning"
fi
# $REPO has no .gitmodules — most repos don't, and a line about submodules there would teach the
# reader to skim the whole report.
if grep -q "submodule" "$RLOG2"; then
  note_fail "readiness-no-false-submodule-warning" "warned in a repo with no submodules"
else
  note_pass "readiness-no-false-submodule-warning"
fi
"$WORKTREE" remove kappa >/dev/null 2>&1
rm -rf "$REPO/.husky/_"

echo "remove, superproject with populated submodules:"
# `git worktree remove` refuses outright once a submodule is **checked out** in the worktree —
# cleanliness never enters into it, so the plain call can never tear that worktree down. A gitlink
# sitting in the index is not enough: `worktree add` leaves submodules empty, and the refusal only
# starts once someone runs `submodule update --init` there, which is exactly what a repo keeping
# reference checkouts under submodules needs. Hence the init below — without it this whole section
# would pass through the plain path and pin nothing.
#
# --force lifts that refusal, but it lifts the dirty-worktree one too, so the dirty case below is
# the one that matters: it pins that remove reaches for the flag only on a clean worktree.
#
# A separate repo on purpose. Adding a submodule to $REPO would route every remove above through
# the --force branch too, and the plain path would stop being tested at all.
SUB="$TMP/sub"
SUPER="$TMP/super"
for r in "$SUB" "$SUPER"; do
  mkdir -p "$r"
  git init -q -b main "$r"
  git -C "$r" config user.email "test@test"
  git -C "$r" config user.name "test"
  echo seed >"$r/file.txt"
  git -C "$r" add file.txt
  git -C "$r" commit -qm "init"
done
SUPER="$(cd "$SUPER" && pwd -P)"
# file:// submodules are refused by default since git 2.38 (CVE-2022-39253).
git -C "$SUPER" -c protocol.file.allow=always submodule add -q "$SUB" vendor/sub >/dev/null 2>&1
git -C "$SUPER" commit -qm "add submodule" >/dev/null 2>&1
cd "$SUPER"

RLOG3="$TMP/delta.stderr"
if [ -n "$("$WORKTREE" create delta 2>"$RLOG3")" ]; then
  note_pass "submodule-create-ok"
else
  note_fail "submodule-create-ok" "create failed in a superproject"
fi

# The empty submodule is the state `create` leaves behind, so the readiness report has to name it
# before the init below hides the evidence.
if grep -q "run: git submodule update --init" "$RLOG3"; then
  note_pass "readiness-names-submodule-init"
else
  note_fail "readiness-names-submodule-init" "stderr: $(tr '\n' '|' <"$RLOG3")"
fi

git -C "$SUPER/.claude/worktrees/delta" -c protocol.file.allow=always \
  submodule update --init >/dev/null 2>&1
if [ -n "$(ls -A "$SUPER/.claude/worktrees/delta/vendor/sub" 2>/dev/null)" ]; then
  note_pass "submodule-populated-in-worktree (the refusal's precondition)"
else
  note_fail "submodule-populated-in-worktree" "submodule empty — the cases below prove nothing"
fi

# Untracked counts as dirty for git's own check, so it must count for ours.
echo scratch >"$SUPER/.claude/worktrees/delta/untracked.txt"
if "$WORKTREE" remove delta >/dev/null 2>&1; then
  note_fail "submodule-remove-dirty-refused" "expected non-zero exit — --force went too wide"
elif [ -d "$SUPER/.claude/worktrees/delta" ]; then
  note_pass "submodule-remove-dirty-refused (worktree kept)"
else
  note_fail "submodule-remove-dirty-refused" "worktree is gone despite refusal"
fi

rm -f "$SUPER/.claude/worktrees/delta/untracked.txt"
if "$WORKTREE" remove delta >/dev/null 2>&1 &&
  ! git -C "$SUPER" worktree list | grep -q "worktrees/delta" &&
  ! git -C "$SUPER" show-ref --verify --quiet refs/heads/delta; then
  note_pass "submodule-remove-ok (worktree and branch gone)"
else
  note_fail "submodule-remove-ok" "worktree or branch survived"
fi

cd "$REPO"

echo "errors (expect non-zero exit):"
if "$WORKTREE" bogus >/dev/null 2>&1; then note_fail "unknown-subcmd" "expected non-zero"; else note_pass "unknown-subcmd"; fi
if "$WORKTREE" >/dev/null 2>&1; then note_fail "no-subcmd" "expected non-zero"; else note_pass "no-subcmd"; fi
if "$WORKTREE" create >/dev/null 2>&1; then note_fail "create-no-slug" "expected non-zero"; else note_pass "create-no-slug"; fi

echo
echo "worktree self-test: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
