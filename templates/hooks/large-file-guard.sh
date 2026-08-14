#!/bin/bash
# PostToolUse Write hook — flags a file the agent just wrote that is far larger
# than anything a human maintains by hand. Wire with matcher "Write".
#
# PostToolUse, so the write ALREADY HAPPENED and this cannot prevent it. That is
# not an oversight: the tool payload carries the content, but measuring it inside
# a PreToolUse hook means the hook decides on a string the model may still be
# streaming, and a size limit that fires before the write is a limit that has to
# be right the first time. After the fact, the file is on disk with a real size,
# the check is exact, and exit 2 puts the number in front of the model while the
# decision to keep or delete it is still live.
#
# The threshold is bytes, deliberately, and generous: this is a "you did not mean
# to do that" check — a pasted bundle, a base64 blob, a dumped log, a generated
# file that should have been gitignored — not a style rule about file length. Any
# hand-written source file is orders of magnitude under it.
#
# Override with CLAUDE_MAX_WRITE_BYTES; set it to 0 to disable the hook without
# unwiring it.
#
# Exits 0 normally, 2 + stderr when the file is over the threshold so Claude sees
# it and can reconsider. Guardrail against agent accidents — NOT a security
# boundary, and not a limit either, since the bytes are already on disk.

set -uo pipefail

command -v jq >/dev/null || exit 0

# DRAIN STDIN BEFORE ANY EARLY EXIT. This read used to sit below the threshold
# resolution, so `CLAUDE_MAX_WRITE_BYTES=0` returned without ever consuming the
# payload — and the writer on the other end of the pipe took SIGPIPE for it. The
# self-test caught it as `zero-disables` exiting 141 instead of 0, but only once,
# under the load of the full suite: the payload is small enough to fit the pipe
# buffer, so the writer normally finishes before the hook can exit, and the race
# only opens when the hook wins. A guardrail that kills its caller some of the
# time is worse than one that no-ops, so the cheap checks come after the read.
input=$(cat)

DEFAULT_MAX_BYTES=262144 # 256 KiB
MAX_BYTES="${CLAUDE_MAX_WRITE_BYTES:-$DEFAULT_MAX_BYTES}"
# A non-numeric or absent override must not become `[[ 0 -gt "" ]]`, which under
# `set -u` is merely wrong rather than loud.
case "$MAX_BYTES" in
  '' | *[!0-9]*) MAX_BYTES="$DEFAULT_MAX_BYTES" ;;
esac
[[ "$MAX_BYTES" -eq 0 ]] && exit 0

tool_name=$(jq -r '.tool_name // empty' <<<"$input")
file_path=$(jq -r '.tool_input.file_path // empty' <<<"$input")

# Write only. An Edit or MultiEdit changes part of a file that already exists at
# whatever size it already was, so charging its whole size to this write would
# fire on every edit to a file that was always big.
case "$tool_name" in
  Write) ;;
  *) exit 0 ;;
esac

[[ -z "$file_path" ]] && exit 0
[[ -f "$file_path" ]] || exit 0

# `wc -c` rather than `stat`: the flag for size is -c on GNU and -f%z on BSD, and
# there is no spelling that works on both.
size=$(wc -c <"$file_path" 2>/dev/null | tr -d '[:space:]')
case "$size" in
  '' | *[!0-9]*) exit 0 ;;
esac

if [[ "$size" -gt "$MAX_BYTES" ]]; then
  {
    echo "LARGE WRITE: $file_path is $size bytes, over the ${MAX_BYTES}-byte threshold."
    echo "Nothing maintained by hand reaches that size, so this is usually a pasted bundle, a"
    echo "base64 blob, a dumped log, or generated output that belongs in .gitignore rather than"
    echo "in the tree. The file is already written — check it is what you meant, and delete it if"
    echo "it is not."
    echo "If a file this size is genuinely right here, raise or disable the threshold with"
    echo "CLAUDE_MAX_WRITE_BYTES (0 disables). Flagged by a dw-* guardrail hook."
  } >&2
  exit 2
fi

exit 0
