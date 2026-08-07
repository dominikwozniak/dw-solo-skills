---
created: 2026-08-02
---

# An "optional companions" section in `dw-doctor`'s `doctor.sh`

One WARN-tier (never FAIL) check for `codex` on PATH plus the `openai-codex` plugin dir, fix:
`/codex:setup`. Cap the depth there — never probe auth. Codex is the only companion the skills route
to (`dw-check/SKILL.md:45-61`, `dw-ship/SKILL.md:52`); local accelerators like `ctx7` and `rtk` stay
out, since no skill names them and `doctor.sh` runs on a consumer's machine.
