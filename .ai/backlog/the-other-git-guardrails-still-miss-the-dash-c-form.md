---
created: 2026-08-13
source: dot-guardrails-swallow-dotfile-paths
---

# The `GIT` prefix reaches only the dot patterns, so `git -C sub push --force` is still unmatched

`git -C <path>` runs the command in another repo with the same blast radius. The `GIT` constant that
closes this exists in `block-dangerous-commands.sh` already — applying it to `push`, `reset --hard`,
`clean`, `branch -D` and `stash clear` is a prefix swap plus a case each. Held back only because it
changes patterns this change had no reason to touch. Hunk and reasoning:
`.ai/archive/dot-guardrails-swallow-dotfile-paths/`.
