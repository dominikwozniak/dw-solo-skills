#!/usr/bin/env bash
# validate-docs.sh — guard the docs ↔ skills contract that AGENTS.md's add-a-skill checklist
# otherwise keeps by hand. CI already validates manifests but never the prose, so a skill added /
# renamed / removed — or an explicit-invoke flag flipped — can ship with the docs silently out of
# sync. Four mechanical, no-judgement checks:
#   1. no dead skill links   — every skills/<x>/SKILL.md linked in README exists on disk
#   2. no undocumented skill — every skills/<x>/ on disk is linked in the README task-router
#   3. explicit-invoke sync  — a skill's `disable-model-invocation: true` <=> it is marked `⭑` in
#                              the task-router AND named in EVERY doc that carries an explicit list
#   4. no stale Next: target — every `**Next:**` pointer names a skill that exists on disk
#
# Check 3 iterates EXPLICIT_LIST_DOCS rather than hardcoding two files: in the upstream repo this
# check covered README + DESIGN only, and docs/WORKFLOWS.md drifted (it listed 5 of 7 explicit
# skills) precisely because it wasn't in the loop. Adding a doc that lists skills is one edit here.
#
# Run from the repo root (`pnpm validate:docs`) or via CI. Exit 0 iff the docs match the skills.
set -uo pipefail
export LC_ALL=C

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$ROOT" || exit 1

README="README.md"
DESIGN="docs/DESIGN.md"
# Every doc carrying an "Explicit-only skills" list. Add a doc here when it grows one.
EXPLICIT_LIST_DOCS="$README $DESIGN"
FAILED=0

# in_list <needle> <space-separated-haystack> — exit 0 if present.
in_list() {
  for w in $2; do [ "$w" = "$1" ] && return 0; done
  return 1
}

# --- skill sets --------------------------------------------------------------
disk_skills=""
explicit_disk="" # frontmatter disable-model-invocation: true
for d in skills/*/; do
  [ -f "$d/SKILL.md" ] || continue
  name="$(basename "$d")"
  disk_skills="$disk_skills $name"
  if grep -qE '^disable-model-invocation:[[:space:]]*true' "$d/SKILL.md"; then
    explicit_disk="$explicit_disk $name"
  fi
done

# --- check 1: no dead skill links --------------------------------------------
echo "Checking README skill links resolve to skills on disk..."
linked="$(grep -oE 'skills/dw-[a-z-]+/SKILL\.md' "$README" | sort -u)"
for path in $linked; do
  if [ -f "$path" ]; then
    echo "OK  $path"
  else
    echo "::error::$README links $path but no such skill exists on disk"
    FAILED=1
  fi
done

# --- check 2: no undocumented skill ------------------------------------------
echo
echo "Checking every skill on disk is linked in the README task-router..."
for name in $disk_skills; do
  if printf '%s\n' "$linked" | grep -qx "skills/$name/SKILL.md"; then
    echo "OK  $name documented"
  else
    echo "::error::skills/$name/ exists but is not linked in $README task-router"
    FAILED=1
  fi
done

# --- check 3: explicit-invoke consistency ------------------------------------
echo
echo "Checking explicit-invoke (⭑ / disable-model-invocation) consistency..."
# A task-router row "carries ⭑" iff the line linking the skill also contains the ⭑ marker.
star_rows=""
for name in $disk_skills; do
  if grep "skills/$name/SKILL.md" "$README" | grep -q '⭑'; then
    star_rows="$star_rows $name"
  fi
done

# explicit_list_text <doc> — the prose that names explicit-only skills in that doc.
# README keeps it on one bolded line; docs/ keep it as an "## Explicit-only skills" section.
explicit_list_text() {
  case "$1" in
    "$README") grep -F '**Explicit-only skills**' "$1" || true ;;
    *) awk '/^## Explicit-only skills/{f=1;next} f&&/^## /{exit} f{print}' "$1" ;;
  esac
}

# contains_name <text> <skill> — text mentions `<skill>` (backtick-wrapped).
contains_name() { case "$1" in *"\`$2\`"*) return 0 ;; *) return 1 ;; esac; }

# forward: each explicit-on-disk skill must carry ⭑ and appear in every listing doc.
for name in $explicit_disk; do
  in_list "$name" "$star_rows" \
    || { echo "::error::$name is explicit (disable-model-invocation) but has no \`⭑\` in the $README task-router"; FAILED=1; }
  for doc in $EXPLICIT_LIST_DOCS; do
    text="$(explicit_list_text "$doc")"
    if [ -z "$text" ]; then
      echo "::error::$doc has no explicit-only list for this check to read"
      FAILED=1
    elif ! contains_name "$text" "$name"; then
      echo "::error::$name is explicit but is not named in $doc's explicit-only list"
      FAILED=1
    fi
  done
done

# reverse: nothing may claim explicit status it doesn't actually have on disk.
for name in $star_rows; do
  in_list "$name" "$explicit_disk" \
    || { echo "::error::$name carries \`⭑\` in $README but its SKILL.md is not disable-model-invocation: true"; FAILED=1; }
done
for doc in $EXPLICIT_LIST_DOCS; do
  for name in $(explicit_list_text "$doc" | grep -oE 'dw-[a-z-]+' | sort -u); do
    in_list "$name" "$explicit_disk" \
      || { echo "::error::$name is listed in $doc's explicit-only list but is not explicit on disk"; FAILED=1; }
  done
done
[ "$FAILED" -eq 0 ] && echo "OK  explicit-invoke lists agree across:$EXPLICIT_LIST_DOCS"

# --- check 4: no stale Next: target ------------------------------------------
echo
echo "Checking every **Next:** pointer names a skill that exists..."
# Each SKILL.md ends with a `**Next:**` line naming the skill a user would reach for next. After a
# skill is renamed or moved to another repo, a stale pointer sends the model at something absent.
for d in skills/*/; do
  [ -f "$d/SKILL.md" ] || continue
  nextline="$(grep -F '**Next:**' "$d/SKILL.md" || true)"
  [ -n "$nextline" ] || continue
  for ref in $(printf '%s\n' "$nextline" | grep -oE 'dw-[a-z-]+' | sort -u); do
    if in_list "$ref" "$disk_skills"; then
      echo "OK  $(basename "$d") -> $ref"
    else
      echo "::error::$d/SKILL.md **Next:** names \`$ref\`, which is not a skill in this repo"
      FAILED=1
    fi
  done
done

echo
if [ "$FAILED" -eq 0 ]; then
  echo "All doc checks passed."
else
  echo "Doc validation FAILED."
fi
exit $FAILED
