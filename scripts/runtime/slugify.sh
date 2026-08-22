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
#   slugify.sh dated <text>            <YYYY-MM-DD>-<slug> entry name for the .ai/ lanes
#   slugify.sh undate <name>           <name> with a leading <YYYY-MM-DD>- removed
#
# Empty parts are dropped: run-id with an empty ticket is <YYYYMMDD>-<desc>.
# Date is `date +%Y%m%d`, overridable via $SLUG_DATE (deterministic tests/fixtures).
#
# `dated` names entries in .ai/work/, .ai/backlog/ and .ai/archive/, where each
# lane stamps its own date — so the same change is 2026-08-20-<slug> in work and
# 2026-08-22-<slug> in archive. It uses `date +%F` (not run-id's %Y%m%d) and the
# same $SLUG_DATE override, honoured verbatim.
#
# `undate` is the other half, and the reason both live here: every comparison of
# one lane's entry against another's runs on the bare slug, so the two prefixes
# never have to agree. It STRIPS, never slugifies — the input is an existing name
# off disk, and re-slugifying it would silently rewrite one that broke the rule.
# Only the %F form is stripped; a bare 8-digit run-id prefix is a different lane
# and passes through, because eating 8 leading digits could truncate a real slug.
set -euo pipefail
export LC_ALL=C

# lowercase; every run of non-[a-z0-9] -> single '-'; trim leading/trailing '-'.
# Non-ASCII is not transliterated: under LC_ALL=C each byte becomes '-'
# (e.g. "café" -> "caf"). Tickets and git branches are ASCII, so this is fine.
slug() {
  printf '%s' "${1:-}" | tr 'A-Z' 'a-z' | sed -E 's/[^a-z0-9]+/-/g; s/^-+//; s/-+$//'
}

usage="usage: slugify.sh {slug|branch-slug|run-id|dated|undate} ..."

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
  dated)
    [ "$#" -ge 2 ] || { echo "usage: slugify.sh dated <text>" >&2; exit 1; }
    date_part="${SLUG_DATE:-$(date +%F)}"
    parts=("$date_part")
    d=$(slug "$2"); [ -n "$d" ] && parts+=("$d")
    (IFS=-; printf '%s\n' "${parts[*]}")
    ;;
  undate)
    [ "$#" -ge 2 ] || { echo "usage: slugify.sh undate <name>" >&2; exit 1; }
    printf '%s' "$2" | sed -E 's/^[0-9]{4}-[0-9]{2}-[0-9]{2}-//'
    printf '\n'
    ;;
  "" | -h | --help | help)
    echo "$usage" >&2
    [ "$cmd" = "" ] && exit 1 || exit 0
    ;;
  *)
    echo "slugify.sh: unknown subcommand '$cmd'" >&2
    echo "$usage" >&2
    exit 1
    ;;
esac
