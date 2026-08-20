#!/usr/bin/env bash
# validate-docs.sh — guard the docs ↔ skills contract that AGENTS.md's add-a-skill checklist
# otherwise keeps by hand. CI already validates manifests but never the prose, so a skill added /
# renamed / removed — or an explicit-invoke flag flipped — can ship with the docs silently out of
# sync. Six mechanical, no-judgement checks:
#   1. no dead skill links   — every skills/<x>/SKILL.md linked in README exists on disk
#   2. no undocumented skill — every skills/<x>/ on disk is linked in the README task-router
#   3. explicit-invoke sync  — a skill's `disable-model-invocation: true` <=> it is marked `⭑` in
#                              the task-router AND named in README's explicit-only list
#   4. no stale Next: target — every `**Next:**` pointer names a skill that exists on disk
#   5. the agent-docs contract — AGENTS.md within the budget it declares, every docs/agents/ topic
#      file routed to, every routed path real, every documented `pnpm <script>` a real script, and
#      CLAUDE.md still a symlink
#   6. no dangling references/ pointer — every `references/<file>.md` a SKILL.md cites is on disk
#
# Check 5 is not implemented here. It runs `templates/check-agents-docs.mjs` — the very checker this
# repo SHIPS into repos that dw-init scaffolds — against this repo's own root. Reimplementing two of
# its checks in bash was the obvious version and it was worse in both directions: a second
# implementation to keep in step, and a payload whose only proof it works is that it works somewhere
# else. This is the same bargain scripts/tests/hooks-in-sync.test.sh strikes for the hooks, and it
# means a bug in the shipped checker fails this repo's own gate before a consumer ever sees it.
#
# There used to be two more, and their deletion is the point rather than a regression: one compared
# each README Arguments cell to the skill's own `argument-hint`, the other compared the "Before you
# push" gate across three markdown copies. Both guarded prose that existed only because it was
# written twice — the column is gone (argument-hint is the one copy) and the gate now lives in
# package.json, which is what CI runs. A check whose whole job is to notice that two hand-kept
# copies drifted is cheaper to delete along with the second copy.
#
# Every doc that lists skills is README, so check 3 reads one file. If a second doc ever grows such a
# list, put it in EXPLICIT_LIST_DOCS rather than hardcoding a filename — upstream, docs/WORKFLOWS.md
# drifted to 5 of 7 explicit skills precisely because it was outside that loop.
#
# Run from the repo root (`pnpm validate:docs`) or via CI. Exit 0 iff the docs match the skills.
set -uo pipefail
export LC_ALL=C

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$ROOT" || exit 1

README="README.md"
# Every doc carrying an "Explicit-only skills" list. Add a doc here when it grows one.
EXPLICIT_LIST_DOCS="$README"
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

# explicit_list_text <doc> — the prose that names explicit-only skills in that doc. docs/ keep it as
# an "## Explicit-only skills" section; README keeps it as a bolded paragraph. Read the whole
# paragraph (marker line through the next blank line), not just the marker line — prettier wraps at
# 100 cols, so the names routinely continue onto the following lines.
explicit_list_text() {
  case "$1" in
    "$README") awk '/\*\*Explicit-only skills\*\*/{f=1} f&&/^[[:space:]]*$/{exit} f{print}' "$1" ;;
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
      echo "::error::${d}SKILL.md **Next:** names \`$ref\`, which is not a skill in this repo"
      FAILED=1
    fi
  done
done

# --- check 5: the agent-docs contract ----------------------------------------
echo
echo "Checking the agent-docs contract (budget, Task Router, symlink)..."
# Run the shipped checker against ourselves. It resolves the repo root from its own location, so it
# grades THIS repo whether it is a normal clone or a worktree. Its failures already name the file and
# the fix, so they are passed through rather than re-worded; only the ::error:: prefix CI groups by
# is added.
agents_err="$(mktemp)"
if ! node "$ROOT/templates/check-agents-docs.mjs" 2>"$agents_err"; then
  while IFS= read -r line; do
    [ -n "$line" ] && echo "::error::$line"
  done <"$agents_err"
  FAILED=1
fi
rm -f "$agents_err"

# --- check 6: no dangling references/ pointer --------------------------------
echo
echo "Checking every references/ file a SKILL.md cites exists on disk..."
# A skill body that outgrew one read moves a block to skills/<x>/references/<file>.md and keeps a
# pointer to it. The pointer is prose, so a rename, or a move that was only half made, sends the
# model at a file that isn't there — the one failure the split introduces, and the body it was cut
# from no longer says what the missing file said.
for d in skills/*/; do
  [ -f "$d/SKILL.md" ] || continue
  for ref in $(grep -oE 'references/[A-Za-z0-9._-]+\.md' "$d/SKILL.md" | sort -u); do
    if [ -f "$d$ref" ]; then
      echo "OK  $(basename "$d") -> $ref"
    else
      echo "::error::${d}SKILL.md cites $ref, which does not exist on disk"
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
