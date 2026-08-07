#!/usr/bin/env bash
# Self-test for backlog-audit.sh. The audit's whole value is telling a live citation from a dead
# one and a same-day pair of entries from a day apart — both of which were wrong in the first
# draft (BSD `date -j -f` without a time reads the current clock, so identical created: dates
# printed different ages). Cases run against a fixture directory, never the live backlog, so the
# assertions stay true as .ai/backlog/ churns.
#
# Run standalone (`bash scripts/tests/backlog-audit.test.sh`) or via scripts/validate-artifacts.sh.
# Exit 0 iff every case matches. bash 3.2 / macOS + BSD safe.
set -uo pipefail
export LC_ALL=C

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
AUDIT="$ROOT/scripts/runtime/backlog-audit.sh"

PASS=0
FAIL=0
note_pass() { PASS=$((PASS + 1)); echo "  ✓ $1"; }
note_fail() { FAIL=$((FAIL + 1)); echo "  ✗ $1 — $2"; }

FIX="$(mktemp -d 2>/dev/null || mktemp -d -t backlog-audit-test)"
trap 'rm -rf "$FIX"' EXIT

# 2026-08-08 00:00:00 UTC — fixed so the age assertions never drift with the wall clock.
NOW=1786176000

cat >"$FIX/live-citations.md" <<'EOF'
---
created: 2026-08-01
---

# An entry citing only paths that exist

`scripts/runtime/slugify.sh` and `dw-land/SKILL.md` and `doctor.sh` all resolve, the last two by
suffix. Prose in backticks like `## Gotchas`, `--min-rank1` and `git mv` is not a path.
`pnpm/action-setup` is a GitHub Action, not a repo path.
EOF

cat >"$FIX/dead-citation.md" <<'EOF'
---
created: 2026-08-01
---

# An entry citing a path that no longer exists

`scripts/runtime/definitely-not-here.sh` is gone; `templates/settings.json` is not.
EOF

cat >"$FIX/no-frontmatter.md" <<'EOF'
# An entry with no created: line

Nothing to age against.
EOF

cat >"$FIX/README.md" <<'EOF'
# not an entry — must be skipped
EOF

OUT="$FIX/out.txt"
BACKLOG_AUDIT_NOW="$NOW" bash "$AUDIT" "$FIX" >"$OUT" 2>&1
rc=$?

# has <name> <regex> — the report must contain a line matching <regex>.
has() {
  if grep -qE "$2" "$OUT"; then note_pass "$1"; else
    note_fail "$1" "no line matching /$2/"
  fi
}
# hasnt <name> <regex> — the report must NOT contain one.
hasnt() {
  if grep -qE "$2" "$OUT"; then note_fail "$1" "unexpected line matching /$2/"; else
    note_pass "$1"
  fi
}

echo "backlog-audit self-test"

[ "$rc" -eq 0 ] && note_pass "exits 0 (report, not a gate)" ||
  note_fail "exits 0 (report, not a gate)" "exit $rc"

has "counts the three entries, skips README" '^3 entries'
hasnt "README is not audited as an entry" '── README\.md'

has "live citations report none dead" 'live-citations|^   cites:   [0-9]+ live, none dead'
has "dead citation is named" 'DEAD:.*definitely-not-here\.sh'
has "exactly one entry is stale" '^3 entries · 1 with a dead citation'

# The age race: both fixture entries carry created: 2026-08-01 and NOW is 2026-08-08, so both
# must read 7 — the first draft printed 6 for one and 7 for the other within a single run.
ages="$(grep -cE '^   age:     7 days \(created 2026-08-01\)' "$OUT")"
[ "$ages" -eq 2 ] && note_pass "same created: date yields the same age (no clock race)" ||
  note_fail "same created: date yields the same age (no clock race)" "want 2 lines at 7 days, got $ages"

has "a missing created: is reported, not fatal" 'no created: in frontmatter'

# An empty directory is a normal answer, not an error.
mkdir -p "$FIX/empty"
eout="$(BACKLOG_AUDIT_NOW="$NOW" bash "$AUDIT" "$FIX/empty" 2>&1)"
case "$eout" in
  *"0 entries"*) note_pass "an empty backlog reports 0 entries" ;;
  *) note_fail "an empty backlog reports 0 entries" "got: $eout" ;;
esac

# A missing directory says so and still exits 0.
mout="$(bash "$AUDIT" "$FIX/absent" 2>&1)"
mrc=$?
if [ "$mrc" -eq 0 ] && printf '%s' "$mout" | grep -q "nothing to audit"; then
  note_pass "a missing backlog directory is not an error"
else
  note_fail "a missing backlog directory is not an error" "exit $mrc: $mout"
fi

echo
echo "backlog-audit self-test: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
