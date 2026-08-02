---
created: 2026-08-01
---

# `EnterWorktree` doesn't fire `SessionStart`

No `SessionStart` hook runs when a session enters a worktree mid-flight. `0003` routed
`CLAUDE.local.md` around it; any other such hook is still silently skipped.
