#!/usr/bin/env bash
# backlog-audit.sh — read-only staleness report over .ai/backlog/. Mutates nothing.
#
# Why it exists: an entry is easy to verify against the working tree and wrong to verify only
# there. A finished-but-unmerged branch can already have resolved one, and nothing in the
# working tree says so. The 2026-08-07 prune reported "no entry is implemented" twice while
# routing-eval-explain-flag had already deleted an entry and removed the skill lines another
# one described. That cross-branch check is pure mechanism, so it lives here instead of in a
# reader's discipline; the drop / merge / bundle judgement stays with whoever reads the report.
#
# Usage:  backlog-audit.sh [<backlog-dir>]      default: <repo-root>/.ai/backlog
# Env:    BACKLOG_AUDIT_BASE  base ref for the branch diff (default: origin's HEAD, else main)
#         BACKLOG_AUDIT_NOW   epoch seconds for the age column (default: now) — for fixtures
#
# Exit 0 always: this is a report, never a gate. bash 3.2 / macOS + BSD safe.
set -uo pipefail
export LC_ALL=C

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
DIR="${1:-$ROOT/.ai/backlog}"

if [ ! -d "$DIR" ]; then
  echo "no backlog directory at ${DIR#"$ROOT"/} — nothing to audit"
  exit 0
fi

# --- base ref: what "already on the default branch" means for the branch diff ----------------
BASE="${BACKLOG_AUDIT_BASE:-}"
if [ -z "$BASE" ]; then
  BASE="$(git -C "$ROOT" symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null || true)"
  BASE="${BASE#origin/}"
  [ -n "$BASE" ] || BASE=main
fi
git -C "$ROOT" rev-parse --verify --quiet "$BASE" >/dev/null || BASE=""

NOW="${BACKLOG_AUDIT_NOW:-$(date +%s)}"
CUR="$(git -C "$ROOT" rev-parse --abbrev-ref HEAD 2>/dev/null || echo '')"

# to_epoch <YYYY-MM-DD> — UTC midnight, BSD date first then GNU. Empty when unparseable.
# Two deliberate choices, both bugs in the first draft: the time is pinned to 00:00:00 because
# BSD `date -j -f "%Y-%m-%d"` fills H:M:S from the *current* clock, so identical created: dates
# read a day apart depending on which second of the run parsed them; and everything is UTC
# because local midnights are not a whole number of 86400s apart from a UTC day grid, which
# lands the age off by one at any non-zero offset.
to_epoch() {
  date -j -u -f "%Y-%m-%d %H:%M:%S" "$1 00:00:00" +%s 2>/dev/null && return 0
  date -u -d "$1" +%s 2>/dev/null
}

# NOW_DAY — UTC midnight of the audit date, the same convention created: is parsed in, so the
# age is an exact whole-day count.
now_date="$(date -u -r "$NOW" +%Y-%m-%d 2>/dev/null || date -u -d "@$NOW" +%Y-%m-%d 2>/dev/null)"
NOW_DAY="$(to_epoch "$now_date")"
[ -n "$NOW_DAY" ] || NOW_DAY="$NOW"

# TOP — top-level entries, so a token like `pnpm/action-setup` (a GitHub Action, not a path) is
# never mistaken for a repo path and reported dead.
TOP="$(git -C "$ROOT" ls-files | sed -E 's|/.*||' | sort -u)"

# exists_path <token> — does this path still resolve? Literal first, then a suffix match against
# the index, so the shorthand entries actually use — `dw-land/SKILL.md`, `doctor.sh` — resolves to
# skills/dw-land/SKILL.md and skills/dw-doctor/scripts/doctor.sh.
exists_path() {
  [ -e "$ROOT/$1" ] && return 0
  esc="$(printf '%s' "$1" | sed 's/[].[^$*\\/]/\\&/g')"
  git -C "$ROOT" ls-files | grep -qE "(^|/)${esc}\$"
}

# cited_paths <file> — backticked tokens shaped like repo paths, with any :line[-line] suffix
# stripped. Prose in backticks (`## Gotchas`, `--min-rank1`, `git mv`) carries a space or no path
# shape and drops out. A slashed token survives only if its first segment is a real top-level
# entry, or it carries a known extension.
cited_paths() {
  grep -oE '`[^`]+`' "$1" 2>/dev/null |
    tr -d '`' |
    sed -E 's/:[0-9]+(-[0-9]+)?$//' |
    grep -E '^[A-Za-z0-9._/-]+$' |
    while IFS= read -r tok; do
      case "$tok" in
        *.sh | *.md | *.ts | *.json | *.yaml | *.yml | *.txt) echo "$tok" ;;
        */*)
          case " $(echo $TOP) " in
            *" ${tok%%/*} "*) echo "$tok" ;;
          esac
          ;;
      esac
    done |
    sort -u
}

# --- per-branch changed-file lists, computed once -------------------------------------------
# Entry x branch would otherwise be O(n*m) git invocations. Branches checked out in a linked
# worktree are labelled, since that is where unmerged finished work tends to sit.
BRANCHES=""
if [ -n "$BASE" ]; then
  BRANCHES="$(git -C "$ROOT" for-each-ref --format='%(refname:short)' refs/heads |
    grep -v -x -e "$BASE" -e "$CUR" || true)"
fi

# Bracket form, not --porcelain: a command proxy on PATH (rtk) rewrites `git worktree list` and
# drops the flag, silently returning the human format. `[branch]` is present in both.
# Flattened to one space-delimited line so the `case " $WT_BRANCHES "` membership test below
# matches the last name too — with newlines intact it never does.
WT_BRANCHES="$(git -C "$ROOT" worktree list 2>/dev/null |
  sed -n 's/.*\[\(.*\)\].*/\1/p' | tr '\n' ' ' || true)"

TMP="$(mktemp -d 2>/dev/null || mktemp -d -t backlog-audit)"
trap 'rm -rf "$TMP"' EXIT

for b in $BRANCHES; do
  git -C "$ROOT" diff --name-only "$BASE...$b" >"$TMP/$(printf '%s' "$b" | tr '/' '_')" 2>/dev/null || : >"$TMP/$(printf '%s' "$b" | tr '/' '_')"
done

branch_label() {
  case " $WT_BRANCHES " in
    *" $1 "*) printf '%s (worktree)' "$1" ;;
    *) printf '%s' "$1" ;;
  esac
}

# --- the report ------------------------------------------------------------------------------
echo "Backlog audit — ${DIR#"$ROOT"/}"
[ -n "$BASE" ] && echo "Branch diffs against: $BASE" || echo "Branch diffs: skipped (no base ref)"
echo

ENTRIES=0
STALE=0
ELSEWHERE=0

for f in "$DIR"/*.md; do
  [ -e "$f" ] || continue
  base="$(basename "$f")"
  [ "$base" = "README.md" ] && continue
  ENTRIES=$((ENTRIES + 1))
  rel="${f#"$ROOT"/}"

  echo "── $base"

  added="$(git -C "$ROOT" log --diff-filter=A --follow --format='%ad %h %s' --date=short -1 -- "$rel" 2>/dev/null)"
  echo "   added:   ${added:-not committed yet}"

  created="$(sed -n 's/^created:[[:space:]]*//p' "$f" | head -n1)"
  if [ -n "$created" ]; then
    ce="$(to_epoch "$created")"
    if [ -n "$ce" ]; then
      echo "   age:     $(((NOW_DAY - ce) / 86400)) days (created $created)"
    else
      echo "   age:     unparseable created: '$created'"
    fi
  else
    echo "   age:     no created: in frontmatter"
  fi

  dead=""
  live=0
  for p in $(cited_paths "$f"); do
    if exists_path "$p"; then
      live=$((live + 1))
    else
      dead="$dead $p"
    fi
  done
  if [ -n "$dead" ]; then
    echo "   cites:   $live live, DEAD:$dead"
    STALE=$((STALE + 1))
  else
    echo "   cites:   $live live, none dead"
  fi

  hits=""
  for b in $BRANCHES; do
    list="$TMP/$(printf '%s' "$b" | tr '/' '_')"
    [ -f "$list" ] || continue
    why=""
    grep -q -x "$rel" "$list" && why="the entry file"
    for p in $(cited_paths "$f"); do
      if grep -q -x "$p" "$list"; then
        [ -n "$why" ] && why="$why + $p" || why="$p"
        break
      fi
    done
    [ -n "$why" ] && hits="$hits
     - $(branch_label "$b"): $why"
  done
  if [ -n "$hits" ]; then
    echo "   ELSEWHERE — another branch already touches this:$hits"
    ELSEWHERE=$((ELSEWHERE + 1))
  fi
  echo
done

echo "$ENTRIES entries · $STALE with a dead citation · $ELSEWHERE touched on another branch"
[ "$ELSEWHERE" -gt 0 ] && echo "Read the ELSEWHERE ones before judging them: finished unmerged work may already cover them."
exit 0
