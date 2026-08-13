#!/usr/bin/env bash
# Validate every marketplace.json + plugin.json via Claude CLI, verify version sync between
# marketplace.json[].version and each <source>/.claude-plugin/plugin.json.version, and check the
# shipped scripts (canon in scripts/runtime/, symlinked into the plugin's scripts/ dir).
set -uo pipefail

FOUND=0
FAILED=0

while IFS= read -r file; do
  FOUND=1
  echo "Validating $file..."
  if ! claude plugin validate "$file"; then
    FAILED=1
  fi
done < <(find . -type f \( -name 'marketplace.json' -o -name 'plugin.json' \) -not -path './node_modules/*' -not -path './.inspirations/*' | sort)

if [ "$FOUND" -eq 0 ]; then
  echo "No manifest files found."
  exit 0
fi

echo
echo "Checking version sync between marketplace.json and plugin.json..."
while IFS=$'\t' read -r name source mp_v; do
  pj_v=$(jq -r '.version' "${source#./}/.claude-plugin/plugin.json")
  if [ "$mp_v" = "$pj_v" ]; then
    echo "OK  $name=$mp_v"
  else
    echo "::error::$name: marketplace.json=$mp_v vs plugin.json=$pj_v"
    FAILED=1
  fi
done < <(jq -r '.plugins[] | [.name, .source, .version] | @tsv' .claude-plugin/marketplace.json)

# Plugin roots come from the marketplace manifest — the validator never hardcodes a plugin
# name, so adding a plugin is a manifest entry plus symlinks, not a validator edit.
PLUGIN_DIRS="$(jq -r '.plugins[].source' .claude-plugin/marketplace.json | sed 's|^\./||' | sort)"

echo
echo "Checking shipped scripts (canon in scripts/runtime/, symlinked into the plugin)..."
# Shipped scripts live once under scripts/runtime/ and are exposed to a plugin via a
# git-tracked symlink plugins/<p>/scripts/<s>.sh -> ../../../scripts/runtime/<s>.sh. `claude
# plugin install` dereferences the symlink into a real file in the plugin cache, so the runtime
# path ${CLAUDE_PLUGIN_ROOT}/scripts/<s>.sh resolves. We assert (1) each canon exists and is
# executable, and (2) each plugin entry is a symlink that resolves to it — never a real file
# (a real file would reintroduce the duplication this layout removes).
RUNTIME_SCRIPTS="slugify.sh worktree.sh"
for s in $RUNTIME_SCRIPTS; do
  c="scripts/runtime/$s"
  if [ ! -f "$c" ]; then
    echo "::error::missing canonical script: $c"
    FAILED=1
  elif [ ! -x "$c" ]; then
    echo "::error::$c is not executable (chmod +x)"
    FAILED=1
  else
    echo "OK  $c (canon, executable)"
  fi
done

# check_symlink <plugin-script-path> — must be a symlink that resolves (and runs) via the canon.
# Runs in the current shell (no subshell), so FAILED assignments here persist.
check_symlink() {
  link="$1"
  if [ ! -L "$link" ]; then
    echo "::error::$link must be a symlink into scripts/runtime/ (real file or missing)"
    FAILED=1
  elif [ ! -e "$link" ]; then
    echo "::error::$link is a dangling symlink (target '$(readlink "$link")' missing)"
    FAILED=1
  elif [ ! -x "$link" ]; then
    echo "::error::$link resolves to a non-executable target"
    FAILED=1
  else
    echo "OK  $link -> $(readlink "$link")"
  fi
}

echo
echo "Checking plugin script symlinks resolve to the canon..."
for p in $PLUGIN_DIRS; do
  [ -d "$p/scripts" ] || continue
  for link in "$p"/scripts/*.sh; do
    # An empty scripts/ leaves the glob unexpanded; a dangling symlink still passes -L.
    { [ -e "$link" ] || [ -L "$link" ]; } || continue
    check_symlink "$link"
    case "$(readlink "$link")" in
      ../../../scripts/runtime/*) ;;
      *)
        echo "::error::$link must point into scripts/runtime/ (points at '$(readlink "$link")')"
        FAILED=1
        ;;
    esac
  done
done

# Reverse: a canon script no plugin ships is dead weight — name it rather than let it rot.
for s in $RUNTIME_SCRIPTS; do
  shipped=0
  for p in $PLUGIN_DIRS; do
    [ -L "$p/scripts/$s" ] && shipped=1
  done
  if [ "$shipped" -eq 0 ]; then
    echo "::error::scripts/runtime/$s is shipped by no plugin (add a plugins/<p>/scripts/$s symlink)"
    FAILED=1
  fi
done

echo
echo "Checking every plugin skill entry is a symlink into the canon..."
# Same rule as the scripts: skills/<name>/ is the canon and plugins/<p>/skills/<name> is a
# git-tracked symlink back to it. Forward: every plugin entry is a symlink resolving to the
# canon — a real directory means the canon was bypassed, and edits would silently land in the
# plugin copy instead. Reverse: every canon skill is shipped by exactly one plugin — zero means
# it's dead on disk, two means installs of the two plugins would drift apart.
for p in $PLUGIN_DIRS; do
  for entry in "$p"/skills/*; do
    # An empty skills/ (bar .gitkeep, which the glob skips) leaves the glob unexpanded.
    { [ -e "$entry" ] || [ -L "$entry" ]; } || continue
    name="$(basename "$entry")"
    if [ ! -L "$entry" ]; then
      echo "::error::$entry must be a symlink to ../../../skills/$name (real entry or missing)"
      FAILED=1
    elif [ ! -d "$entry" ]; then
      echo "::error::$entry is a dangling symlink (target '$(readlink "$entry")' missing)"
      FAILED=1
    elif [ "$(cd "$entry" && pwd -P)" != "$(cd "skills/$name" 2>/dev/null && pwd -P)" ]; then
      echo "::error::$entry must resolve to skills/$name (resolves to '$(readlink "$entry")')"
      FAILED=1
    else
      echo "OK  $entry -> $(readlink "$entry")"
    fi
  done
done

for d in skills/*/; do
  # An empty skills/ leaves the glob unexpanded, and basename would yield a literal `*`.
  [ -d "$d" ] || continue
  name="$(basename "$d")"
  owners=0
  for p in $PLUGIN_DIRS; do
    [ -L "$p/skills/$name" ] && owners=$((owners + 1))
  done
  if [ "$owners" -eq 0 ]; then
    echo "::error::skills/$name/ is shipped by no plugin (add a plugins/<p>/skills/$name symlink)"
    FAILED=1
  elif [ "$owners" -gt 1 ]; then
    echo "::error::skills/$name/ is shipped by $owners plugins — a canon skill has exactly one owner"
    FAILED=1
  fi
done

# The template payloads (settings.json, hooks/, AGENTS.md, work-README.md, …) live once at
# the repo root in templates/ and are exposed by a git-tracked symlink
# plugins/dw-solo-setup/templates -> ../../templates, so ${CLAUDE_PLUGIN_ROOT}/templates/ resolves
# after install dereferences it. Only the setup plugin consumes templates/ — the loop plugin ships
# scripts, never payload. templates/hooks/ is a vendored copy of the same canon in the `dw-skills`
# repo; a fix must be applied to both, since nothing across the repo boundary can detect drift.
echo
echo "Checking plugin templates symlink resolves to the canon..."
if [ ! -d templates/hooks ]; then
  echo "::error::missing canonical templates dir: templates/hooks"
  FAILED=1
else
  echo "OK  templates/ (canon)"
fi
TEMPLATE_PLUGINS="plugins/dw-solo-setup"
for p in $TEMPLATE_PLUGINS; do
  link="$p/templates"
  if [ ! -L "$link" ]; then
    echo "::error::$link must be a symlink to ../../templates (real dir or missing)"
    FAILED=1
  elif [ ! -d "$link" ]; then
    echo "::error::$link is a dangling symlink (target '$(readlink "$link")' missing)"
    FAILED=1
  else
    echo "OK  $link -> $(readlink "$link")"
  fi
done

exit $FAILED
