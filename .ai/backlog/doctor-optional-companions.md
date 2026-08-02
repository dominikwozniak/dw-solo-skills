---
created: 2026-08-02
---

# An "optional companions" section in `dw-doctor`'s `doctor.sh`

WARN-tier (never FAIL) checks for `codex` on PATH + the `openai-codex` plugin dir (fix:
`/codex:setup`), `ctx7` (fix: `pnpm add -g ctx7`), and `rtk` (fix: https://github.com/rtk-ai/rtk)
— accelerators the loop now names, not guardrails. Cap codex depth at pointing to `/codex:setup`;
never probe auth.
