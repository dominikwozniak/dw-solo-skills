#!/usr/bin/env bash
# check-decisions.sh — hold docs/decisions/ to the contract templates/decisions-README.md states.
#
# The folder has no index by design: the filename number is the identity, and `superseded-by:` is
# a pointer made of that number. Nothing else in the loop reads the folder as a whole, so a
# misnumbered record, a duplicate, or a supersede link into thin air stays silent until someone
# follows it. This is the read that catches those.
#
#   check-decisions.sh [repo-root]     default: git rev-parse --show-toplevel, else $PWD
#
# Read-only, always: it NEVER renumbers or rewrites a record. A number is what the pointers are
# made of, so auto-repair would break the very links it is protecting — the caller reports and
# stops instead (skills/dw-land/references/decision-record.md).
#
# Findings go to stdout, one per line, prefixed `error: ` or `warn: ` for a caller to route:
#   error  — filename shape, duplicate number, missing frontmatter, decision: ≠ filename number,
#            a malformed date:, a status: outside {active, superseded}, a superseded record whose
#            superseded-by: is missing or names a record that does not exist.
#   warn   — the first gap in the sequence from 0001, and only the first. A gap is past tense: a
#            record was deleted or the folder started mid-sequence. It breaks nothing being
#            written now, so it complains once rather than blocking every close.
#
# Exit 0 when clean or warnings-only, 1 when any error was found. A missing docs/decisions/ is
# legal — a repo with no records yet — and exits 0 silently.
#
# bash 3.2 / macOS + BSD safe. Adapted from grateful-me-app-v2's check-agents-docs.mjs, whose
# other checks are that repo's own contract and stay there.
set -uo pipefail
export LC_ALL=C

ROOT="${1:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
DIR="$ROOT/docs/decisions"

[ -d "$DIR" ] || exit 0

ERRORS=0
err() { ERRORS=$((ERRORS + 1)); printf 'error: %s\n' "$1"; }
warn() { printf 'warn: %s\n' "$1"; }

# A directory that cannot be listed leaves the glob below unexpanded, which is indistinguishable
# from an empty folder — and "no records" is legal here, so it would exit 0 as if clean. Say so
# instead: an unread folder is not a checked folder.
if [ ! -r "$DIR" ] || [ ! -x "$DIR" ]; then
  err "docs/decisions/ exists but cannot be listed — its records went unchecked (fix the directory permissions)."
  exit 1
fi

# frontmatter <path> — the block between the leading `---` and the next one, on stdout.
# Non-zero when the file does not open with one, or never closes it. CR is dropped first: a
# CRLF record is well-formed, and matching `---\r` against `---` would call it frontmatter-less.
# Stripping here covers field() too, which only ever sees this function's output.
frontmatter() {
  tr -d '\r' <"$1" | awk '
    NR == 1 && $0 != "---" { exit 1 }
    NR == 1 { next }
    /^---[[:space:]]*$/ { closed = 1; exit }
    { print }
    END { if (!closed) exit 1 }
  '
}

# field <frontmatter> <name> — the value of `name:`, empty when absent. Values may carry a
# trailing `# active | superseded` comment, as the template writes them; strip from the first #.
field() {
  printf '%s\n' "$1" |
    sed -n -E "s/^$2:[[:space:]]*(.+)\$/\1/p" |
    head -n 1 |
    sed -E 's/#.*$//; s/[[:space:]]+$//'
}

# Parallel arrays, not an associative one — bash 3.2 has no `declare -A`. SEEN is a
# space-delimited membership set, matched with `case`, which is enough for four-digit numbers.
SEEN=" "
NUMBERS=""
ENTRIES=()
STATUSES=()
SUPBYS=()

for path in "$DIR"/*.md; do
  [ -f "$path" ] || continue
  entry=$(basename "$path")
  [ "$entry" = "README.md" ] && continue

  # A leading four-digit number is enough to claim a slot, even when the rest of the name is
  # wrong: 0002-Bad-Slug.md is a badly named record, not a missing 0002.
  case "$entry" in
    [0-9][0-9][0-9][0-9]-*.md) number="${entry%%-*}" ;;
    *) number="" ;;
  esac

  if [ -n "$number" ]; then
    case "$SEEN" in
      *" $number "*)
        err "docs/decisions/$entry reuses number $number, already taken by another record — numbers are never reused."
        continue
        ;;
    esac
    # Register the moment the filename yields a number — BEFORE anything below can skip this
    # record. Contiguity and superseded-by both ask "does a record with this number exist", and a
    # file sitting right there answers yes however broken it is. Registering later let one
    # malformed record fabricate a missing-number gap and a dangling pointer on top of the real
    # finding, sending you after two problems that were never there.
    SEEN="$SEEN$number "
    NUMBERS="$NUMBERS$number
"
  fi

  if [ -z "$number" ] || ! printf '%s' "$entry" | grep -qE '^[0-9]{4}-[a-z0-9]+(-[a-z0-9]+)*\.md$'; then
    err "docs/decisions/$entry is not named <NNNN>-<kebab-slug>.md — the number is what orders these and what superseded-by points at."
    continue
  fi

  if ! fm=$(frontmatter "$path"); then
    err "docs/decisions/$entry has no frontmatter — decision, status and date are required."
    continue
  fi

  declared=$(field "$fm" "decision")
  status=$(field "$fm" "status")
  date_value=$(field "$fm" "date")

  [ "$declared" = "$number" ] ||
    err "docs/decisions/$entry declares decision: ${declared:-(missing)}, which does not match its filename number $number."
  printf '%s' "$date_value" | grep -qE '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' ||
    err "docs/decisions/$entry needs a date: YYYY-MM-DD in its frontmatter (found: ${date_value:-(missing)})."
  [ "$status" = "active" ] || [ "$status" = "superseded" ] ||
    err "docs/decisions/$entry has status \"${status:-(missing)}\" — it must be active or superseded."

  ENTRIES[${#ENTRIES[@]}]="$entry"
  STATUSES[${#STATUSES[@]}]="$status"
  SUPBYS[${#SUPBYS[@]}]="$(field "$fm" "superseded-by")"
done

# Contiguity: records are append-only and never deleted, so a gap means one went missing or the
# folder started mid-sequence. Only the first gap is reported — every later number would fail
# against a shifted expectation and bury the one finding that matters.
if [ -n "$NUMBERS" ]; then
  index=0
  while IFS= read -r number; do
    [ -n "$number" ] || continue
    index=$((index + 1))
    expected=$(printf '%04d' "$index")
    if [ "$number" != "$expected" ]; then
      warn "docs/decisions/ has $number where $expected was expected — records are numbered contiguously from 0001 and never deleted."
      break
    fi
  done <<EOF
$(printf '%s' "$NUMBERS" | sort)
EOF
fi

# A superseded record has to name a replacement, and that replacement has to exist — the pointer
# is the only thing connecting the two, and dw-land writes it by hand.
i=0
while [ "$i" -lt "${#ENTRIES[@]}" ]; do
  entry="${ENTRIES[$i]}"
  status="${STATUSES[$i]}"
  supby="${SUPBYS[$i]}"
  i=$((i + 1))
  [ "$status" = "superseded" ] || continue
  if [ -z "$supby" ]; then
    err "docs/decisions/$entry is marked superseded but names no superseded-by."
    continue
  fi
  case "$SEEN" in
    *" $supby "*) ;;
    *) err "docs/decisions/$entry points at superseded-by: $supby, which does not exist." ;;
  esac
done

[ "$ERRORS" -eq 0 ]
