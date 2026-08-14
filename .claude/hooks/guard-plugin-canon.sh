#!/bin/bash
# PreToolUse hook — refuses an Edit/Write/MultiEdit aimed into `plugins/`, and
# names the canonical file behind the symlink instead. Wire with matcher
# "Edit|Write|MultiEdit".
#
# A plugin directory is almost entirely symlinks pointing back at the canon it
# ships — `plugins/dw-solo/skills/dw-next` → `skills/dw-next`, and the same for
# `scripts/` and `templates/`. Editing through one is at best a confusing way to
# reach the real file, and at worst destroys the link: a Write that replaces the
# symlink with a regular file silently forks the copy the plugin ships from the
# copy the repo maintains, and nothing fails until someone installs the plugin.
#
# THE RULE IS NOT "every path under plugins/". It is "every path under plugins/
# that is not a real, already-existing file" — which is the invariant itself
# rather than a restatement of it, and it needs no allowlist to maintain. The
# three `plugins/*/.claude-plugin/plugin.json` files are genuinely owned by their
# plugin, so they are real files and stay editable; a version bump must not have
# to argue with a guardrail. Anything that resolves through a symlink is refused,
# and so is a path that does not exist yet, because creating a new regular file
# under `plugins/` is exactly the mistake this hook exists to catch.
#
# Exit 2 + stderr message causes Claude to see the block and self-correct.
# Guardrail against agent accidents — NOT a security boundary.

set -uo pipefail

command -v jq >/dev/null || exit 0

INPUT=$(cat)
TOOL_NAME=$(jq -r '.tool_name // empty' <<<"$INPUT")

case "$TOOL_NAME" in
  Edit | Write | MultiEdit | NotebookEdit) ;;
  *) exit 0 ;;
esac

FILE_PATH=$(jq -r '.tool_input.file_path // .tool_input.notebook_path // .tool_input.path // empty' <<<"$INPUT")
[[ -z "$FILE_PATH" ]] && exit 0

# The tool usually hands over an absolute path; a relative one is against the
# project dir, which is this hook's cwd.
case "$FILE_PATH" in
  /*) abs="$FILE_PATH" ;;
  *) abs="$PWD/$FILE_PATH" ;;
esac

repo_root="$(git rev-parse --show-toplevel 2>/dev/null)" || exit 0

# relativize <abs-path> — echoes the path relative to the repo root, or nothing
# when it is outside the repo.
#
# NOT `${abs#"$repo_root"/}`. That is a string prefix test, and the two strings
# routinely name the same directory in different spellings: git reports the
# physical path while the tool hands over one that still contains a symlinked
# ancestor — `/private/var/…` against `/var/…` on macOS is the everyday case, and
# a repo reached through a symlinked home dir is another. The test failed
# CLOSED-then-open: the path read as "outside the repo" and the hook exited 0,
# i.e. it stopped guarding and said nothing. `-ef` compares device and inode, so
# it answers the question actually being asked.
#
# The walk itself is textual — `dirname` never resolves anything — so it cannot
# hop through the plugin symlink it is here to detect. Only the parent being
# tested is ever stat'ed.
relativize() {
  local probe="$1" out="" parent
  while [[ -n "$probe" && "$probe" != "/" ]]; do
    parent="$(dirname "$probe")"
    out="$(basename "$probe")${out:+/$out}"
    if [[ -d "$parent" && "$parent" -ef "$repo_root" ]]; then
      printf '%s\n' "$out"
      return 0
    fi
    probe="$parent"
  done
  return 1
}

rel="$(relativize "$abs" || true)"
[[ -z "$rel" ]] && exit 0
case "$rel" in
  plugins/*) ;;
  *) exit 0 ;;
esac

# canon_of <abs-path> — echoes the repo-relative path the deepest symlinked
# ancestor points at, with the remaining components appended, or nothing when no
# ancestor is a symlink. `readlink -f` is not available on BSD (macOS), hence the
# walk; one relative hop is all the plugin layout uses, but the loop handles a
# chain without caring.
canon_of() {
  local probe="$1" suffix="" link resolved dir parent
  while [[ -n "$probe" && "$probe" != "/" ]]; do
    if [[ -L "$probe" ]]; then
      link="$(readlink "$probe")"
      case "$link" in
        /*) resolved="$link" ;;
        *)
          dir="$(cd "$(dirname "$probe")" 2>/dev/null && cd "$(dirname "$link")" 2>/dev/null && pwd)" || return 1
          resolved="$dir/$(basename "$link")"
          ;;
      esac
      # Prefer the repo-relative spelling; fall back to the absolute one for a
      # link that genuinely points outside the repo.
      printf '%s\n' "$(relativize "$resolved$suffix" || printf '%s' "$resolved$suffix")"
      return 0
    fi
    parent="$(dirname "$probe")"
    [[ -d "$parent" && "$parent" -ef "$repo_root" ]] && return 1
    suffix="/$(basename "$probe")$suffix"
    probe="$parent"
  done
  return 1
}

canon="$(canon_of "$abs" || true)"

if [[ -z "$canon" ]]; then
  # No symlinked ancestor. A real file that is already there is plugin-owned and
  # fine to edit; anything else would be a NEW regular file under plugins/.
  [[ -f "$abs" ]] && exit 0
  {
    echo "BLOCKED: '$rel' would create a new file under plugins/, which owns nothing but its plugin.json."
    echo "Everything else a plugin ships is a symlink to the canon — add the file under skills/,"
    echo "scripts/runtime/ or templates/ and symlink it in from the plugin."
    echo "Refused by a dw-* guardrail hook. See the layout rule in AGENTS.md."
  } >&2
  exit 2
fi

{
  echo "BLOCKED: '$rel' is a symlink into the plugin, not the file it points at. Edit the canon:"
  echo "  $canon"
  echo "Editing through the link at best reaches that file the long way round, and a Write that"
  echo "replaces the symlink with a regular file forks what the plugin ships from what the repo"
  echo "maintains — with nothing failing until someone installs it."
  echo "Refused by a dw-* guardrail hook. See the layout rule in AGENTS.md."
} >&2
exit 2
