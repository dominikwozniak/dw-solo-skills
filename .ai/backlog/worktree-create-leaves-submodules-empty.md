---
created: 2026-08-09
source: worktree-remove-with-submodules
---

# Decide whether `worktree.sh create` should populate submodules

`git worktree add` checks out tracked state only, so in a superproject a `/dw-start` worktree gets
empty submodule directories and cannot build until someone runs `submodule update --init` by hand —
the same line the new test has to run before it can reproduce anything.

Either `create` inits them (slow, and `protocol.file.allow` bites on local submodules), or the
readiness report on stderr names the missing command the way it already names the missing install.
Findings: `.ai/archive/worktree-remove-with-submodules`.
