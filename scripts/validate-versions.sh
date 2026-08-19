#!/usr/bin/env bash
# validate-versions.sh — the check validate-manifests.sh structurally cannot be. That one compares
# marketplace.json[].version against the owning plugin.json.version inside ONE tree, so it sees a
# mismatch and nothing else. Two failures merge green under it, both hit for real:
#
#   1. a version that didn't grow — two parallel changes take the same number and auto-merge
#      (twice on 2026-08-02, caught by hand);
#   2. a shipped-payload change with no bump at all — templates/, scripts/runtime/ or a
#      skills/<name>/ moves, CI is green, and every installed consumer keeps the old copy.
#
# Seeing either needs history, so this reads TWO refs and uses each for a different job:
#
#   - WHICH PATHS CHANGED comes from the merge base (`git diff --name-only $(merge-base) HEAD`) —
#     what this branch did, never what main did meanwhile.
#   - WHETHER THE VERSION GREW is measured against the BASE TIP, not the merge base. That asymmetry
#     is the whole point: a branch that went 0.4.5 -> 0.4.6 really did grow relative to where it
#     forked, so a merge-base comparison passes failure 1 every time. Against main's tip, a number
#     main has already taken is not greater, and it fails.
#
# A plugin's shipped surface is derived from the symlink graph on disk, never hardcoded — the same
# rule validate-manifests.sh follows, so adding a plugin stays a manifest entry plus symlinks.
#
# Run standalone, as `pnpm validate:versions`, or from CI with an explicit --base. Exit 0 iff every
# plugin that changed also grew. bash 3.2 / macOS + BSD safe.
set -uo pipefail
export LC_ALL=C

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$ROOT" || exit 1

BASE="origin/main"
while [ $# -gt 0 ]; do
  case "$1" in
    --base)
      BASE="${2:-}"
      shift 2
      ;;
    --base=*)
      BASE="${1#--base=}"
      shift
      ;;
    -h | --help)
      echo "usage: validate-versions.sh [--base <ref>]   (default: origin/main)"
      exit 0
      ;;
    *)
      echo "::error::unknown argument: $1"
      exit 1
      ;;
  esac
done

FAILED=0

# A base ref we cannot resolve is a SKIP, not a failure — same bargain as validate-artifacts.sh
# skipping pass 3 when node is absent. This validator never touches the network: CI fetches the base
# before calling it, and a local run uses whatever origin/main the last fetch left behind. Failing
# here instead would make a fresh clone, a shallow checkout or an offline gate run look like a
# missing bump, which is the one answer that must stay meaningful.
if [ -z "$BASE" ] || ! git rev-parse --verify --quiet "$BASE^{commit}" >/dev/null; then
  echo "• version bumps: SKIP (base ref '$BASE' does not resolve — nothing to diff against)"
  exit 0
fi

MERGE_BASE="$(git merge-base "$BASE" HEAD 2>/dev/null)"
if [ -z "$MERGE_BASE" ]; then
  echo "• version bumps: SKIP (no merge base between '$BASE' and HEAD)"
  exit 0
fi

CHANGED="$(git diff --name-only "$MERGE_BASE" HEAD)"
if [ -z "$CHANGED" ]; then
  echo "• version bumps: nothing changed against $BASE — no bump required."
  exit 0
fi

# version_gt <a> <b> — true iff a > b, comparing dot-separated numeric components left to right.
# Not `sort -V`: BSD sort has no -V, and this repo's scripts claim macOS safety. Non-numeric
# components compare as 0, which is deliberate — a prerelease suffix is not something this repo's
# versions use, and treating one as "not greater" fails loudly rather than passing quietly.
version_gt() {
  a="$1"
  b="$2"
  i=1
  while [ "$i" -le 3 ]; do
    ai="$(echo "$a" | cut -d. -f"$i")"
    bi="$(echo "$b" | cut -d. -f"$i")"
    case "$ai" in '' | *[!0-9]*) ai=0 ;; esac
    case "$bi" in '' | *[!0-9]*) bi=0 ;; esac
    if [ "$ai" -gt "$bi" ]; then return 0; fi
    if [ "$ai" -lt "$bi" ]; then return 1; fi
    i=$((i + 1))
  done
  return 1
}

PLUGIN_DIRS="$(jq -r '.plugins[].source' .claude-plugin/marketplace.json | sed 's|^\./||' | sort)"

echo "Checking plugin versions grew where the shipped surface changed (base: $BASE)..."

for p in $PLUGIN_DIRS; do
  name="$(basename "$p")"

  # The shipped surface: everything `claude plugin install` would dereference into the cache.
  # plugins/<p>/** covers the manifest and the symlinks themselves; the canon each symlink points at
  # has to be listed separately, because editing skills/<n>/SKILL.md leaves the link's target string
  # untouched and so never shows up as a plugins/** path. (validate-artifacts.yaml's own paths filter
  # carries the same warning for the same reason.)
  #
  # .claude-plugin/marketplace.json is deliberately NOT in any surface: that file is where half the
  # bump lands, so counting it would make every bump its own justification.
  SURFACE="$p/"
  for entry in "$p"/skills/*; do
    { [ -e "$entry" ] || [ -L "$entry" ]; } || continue
    SURFACE="$SURFACE skills/$(basename "$entry")/"
  done
  for link in "$p"/scripts/*.sh; do
    { [ -e "$link" ] || [ -L "$link" ]; } || continue
    SURFACE="$SURFACE scripts/runtime/$(basename "$link")"
  done
  [ -L "$p/templates" ] && SURFACE="$SURFACE templates/"

  # First changed path under the surface, kept as the evidence line an error prints.
  hit=""
  for path in $CHANGED; do
    for pre in $SURFACE; do
      case "$path" in
        "$pre"*)
          hit="$path"
          break
          ;;
      esac
    done
    [ -n "$hit" ] && break
  done

  if [ -z "$hit" ]; then
    echo "OK  $name (shipped surface untouched)"
    continue
  fi

  manifest="$p/.claude-plugin/plugin.json"
  head_v="$(jq -r '.version' "$manifest" 2>/dev/null)"

  # Absent at base = a plugin this branch introduces. There is no previous number to grow past.
  base_v="$(git show "$BASE:$manifest" 2>/dev/null | jq -r '.version' 2>/dev/null)"
  if [ -z "$base_v" ] || [ "$base_v" = "null" ]; then
    echo "OK  $name=$head_v (new plugin — no version at $BASE)"
    continue
  fi

  if version_gt "$head_v" "$base_v"; then
    echo "OK  $name=$head_v (was $base_v at $BASE)"
  else
    echo "::error::$name: shipped surface changed but the version did not grow —"
    echo "::error::  $BASE has $base_v, this branch has $head_v (needs > $base_v)"
    echo "::error::  e.g. $hit"
    echo "::error::  bump it in BOTH .claude-plugin/marketplace.json and $manifest"
    FAILED=1
  fi
done

echo
if [ "$FAILED" -eq 0 ]; then
  echo "All plugin versions grew where they had to."
else
  echo "Version validation FAILED."
fi
exit $FAILED
