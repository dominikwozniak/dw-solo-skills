---
change: commit-hygiene-default-pattern-from-env
branch: commit-hygiene-default-pattern-from-env
created: 2026-09-03
status: landed
landed: 2026-09-03
---

# Change — the commit-hygiene hook's default pattern can be set by the caller

## Tasks

<!-- Convention: `- [ ]` pending, `- [x]` done — `dw-next` flips the box in the task's own commit.
A task that stopped being necessary keeps its box and gains `**skip:** <reason>`; every later
invocation reads that as not remaining. Never rename a task title. -->

- [x] 1. The hook reads `CLAUDE_COMMIT_PATTERN_DEFAULT` as its fallback pattern, with test cases: unset = today's default; `none` skips the subject while `git add -A` and the backtick still refuse; a declared bullet wins over the variable.
- [x] 2. The hook header and `docs/agents/tooling.md`'s resolver chain name the env step between `CLAUDE.local.md` and the script's own default.

## Notes

- Versions: `dw-solo-setup` 0.2.2 → 0.2.3 (one shipped hook grew a knob; the shipped default is unchanged).
- The first use is `~/.claude/settings.json` wiring `CLAUDE_COMMIT_PATTERN_DEFAULT=none bash "$HOME/.claude/hooks/bash-guard.sh"` — outside this repo, done by hand after the merge.
