#!/usr/bin/env bash
# slugify.sh — canonical, deterministic derivation of .ai/ paths and slugs.
#
# The run-folder name, the ticket slug, and the .ai/verify/<branch-slug>/ folder
# are DERIVED state — pure functions of (date, ticket, branch). Leaving that
# derivation to prose let each skill munge strings its own way: the bug that
# motivated this script was .ai/runs/<…-ABC-123-…> (uppercase) drifting from
# .ai/verify/<abc-123-…> (lowercase). One rule, one function, no drift.
#
# Subcommands:
#   slugify.sh slug <text>             lowercase kebab slug (a-z0-9, single '-')
#   slugify.sh branch-slug <branch>    slug of a git branch (matches .ai/verify/<slug>)
#   slugify.sh run-id <ticket> <desc>  <YYYYMMDD>[-<ticket>]-<desc> run-folder name
#
# Empty parts are dropped: run-id with an empty ticket is <YYYYMMDD>-<desc>.
# Date is `date +%Y%m%d`, overridable via $SLUG_DATE (deterministic tests/fixtures).
set -euo pipefail
export LC_ALL=C

# lowercase; every run of non-[a-z0-9] -> single '-'; trim leading/trailing '-'.
# Non-ASCII is not transliterated: under LC_ALL=C each byte becomes '-'
# (e.g. "café" -> "caf"). Tickets and git branches are ASCII, so this is fine.
slug() {
  printf '%s' "${1:-}" | tr 'A-Z' 'a-z' | sed -E 's/[^a-z0-9]+/-/g; s/^-+//; s/-+$//'
}

cmd="${1:-}"
case "$cmd" in
  slug | branch-slug)
    [ "$#" -ge 2 ] || { echo "usage: slugify.sh $cmd <text>" >&2; exit 1; }
    out=$(slug "$2")
    printf '%s\n' "$out"
    ;;
  run-id)
    [ "$#" -ge 3 ] || { echo "usage: slugify.sh run-id <ticket> <desc>" >&2; exit 1; }
    date_part="${SLUG_DATE:-$(date +%Y%m%d)}"
    parts=("$date_part")
    t=$(slug "$2"); [ -n "$t" ] && parts+=("$t")
    d=$(slug "$3"); [ -n "$d" ] && parts+=("$d")
    (IFS=-; printf '%s\n' "${parts[*]}")
    ;;
  "" | -h | --help | help)
    echo "usage: slugify.sh {slug|branch-slug|run-id} ..." >&2
    [ "$cmd" = "" ] && exit 1 || exit 0
    ;;
  *)
    echo "slugify.sh: unknown subcommand '$cmd'" >&2
    echo "usage: slugify.sh {slug|branch-slug|run-id} ..." >&2
    exit 1
    ;;
esac
