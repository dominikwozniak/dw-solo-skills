#!/usr/bin/env bash
# Self-test for slugify.sh: pins the exact slug / branch-slug / run-id output. slugify is the
# canonical path-deriver, and the artifact validator derives expected slugs *through* slugify —
# so a slugify regression is self-masking there (both sides shift together). Only a direct
# assertion on the output catches it, which is what this file does.
#
# Run standalone (`bash scripts/tests/slugify.test.sh`) or via scripts/validate-artifacts.sh.
# Exit 0 iff every case matches. bash 3.2 / macOS + BSD safe.
set -uo pipefail
export LC_ALL=C

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
SLUGIFY="$ROOT/scripts/runtime/slugify.sh"

PASS=0
FAIL=0
note_pass() { PASS=$((PASS + 1)); echo "  ✓ $1"; }
note_fail() { FAIL=$((FAIL + 1)); echo "  ✗ $1 — $2"; }

# eq <name> <expected> <slugify args...> — stdout must equal <expected> AND exit 0.
eq() {
  name="$1"; want="$2"; shift 2
  got=$("$SLUGIFY" "$@" 2>/dev/null); rc=$?
  if [ "$rc" -eq 0 ] && [ "$got" = "$want" ]; then
    note_pass "$name"
  else
    note_fail "$name" "want '$want' got '$got' (exit $rc)"
  fi
}

# rid <name> <expected> <ticket> <desc> — run-id with a pinned $SLUG_DATE for determinism.
rid() {
  name="$1"; want="$2"; shift 2
  got=$(SLUG_DATE=20260620 "$SLUGIFY" run-id "$@" 2>/dev/null); rc=$?
  if [ "$rc" -eq 0 ] && [ "$got" = "$want" ]; then
    note_pass "$name"
  else
    note_fail "$name" "want '$want' got '$got' (exit $rc)"
  fi
}

# fails <name> <slugify args...> — must exit non-zero.
fails() {
  name="$1"; shift
  if "$SLUGIFY" "$@" >/dev/null 2>&1; then
    note_fail "$name" "expected non-zero exit"
  else
    note_pass "$name"
  fi
}

echo "slug / branch-slug:"
eq "slug-spaces"      "hello-world"          slug "Hello World"
eq "slug-ticket"      "abc-123"              slug "ABC-123"
eq "slug-collapse"    "multiple-spaces"      slug "  multiple   spaces  "
eq "slug-punct"       "foo-bar-baz-qux"      slug "Foo/Bar_Baz.qux"
eq "slug-trim-dashes" "leading-and-trailing" slug "--leading-and-trailing--"
eq "slug-nonascii"    "caf"                  slug "café"
eq "slug-digits"      "123"                  slug "123"
eq "slug-empty"       ""                     slug ""
eq "branch-slug"      "feature-abc-123-foo"  branch-slug "feature/ABC-123-foo"

echo "run-id (SLUG_DATE=20260620):"
rid "run-id-full"      "20260620-abc-123-add-foo" "ABC-123" "add foo"
rid "run-id-no-ticket" "20260620-add-foo"         ""        "add foo"
rid "run-id-no-desc"   "20260620-abc-123"         "ABC-123" ""
rid "run-id-date-only" "20260620"                 ""        ""

echo "errors (expect non-zero exit):"
fails "slug-no-arg"    slug
fails "run-id-too-few" run-id "ABC-123"
fails "unknown-subcmd" bogus
fails "no-subcmd"

echo
echo "slugify self-test: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
