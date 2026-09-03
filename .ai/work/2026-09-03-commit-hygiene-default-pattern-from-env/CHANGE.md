---
change: commit-hygiene-default-pattern-from-env
branch: commit-hygiene-default-pattern-from-env
created: 2026-09-03
status: building
---

# Change — the commit-hygiene hook's default pattern can be set by the caller

## Goal

`CLAUDE_COMMIT_PATTERN_DEFAULT=none bash bash-guard.sh` in a repo with no `Commit pattern` bullet
passes any `-m` subject and still refuses `git add -A` and a live backtick; a repo that declares the
bullet is unaffected by the variable; with the variable unset the hook behaves exactly as today. That
lets a global `~/.claude/hooks/` copy run in repos whose log is not Conventional Commits.

## Decisions

- One env var overrides only the **fallback**, never a declared bullet — a repo's own rule cannot be weakened from outside.
- `none` reuses the existing `[[ "$PATTERN" != "none" ]]` guard — no second way to switch the check off.
- Named `CLAUDE_COMMIT_PATTERN_DEFAULT`, after `CLAUDE_MAX_WRITE_BYTES` and `CLAUDE_SKIP_TYPECHECK` — the hooks' one env vocabulary.
- The shipped default stays Conventional Commits — the loosening lives in the caller's wiring, so consumers see no change.

## Tasks

<!-- Convention: `- [ ]` pending, `- [x]` done — `dw-next` flips the box in the task's own commit.
A task that stopped being necessary keeps its box and gains `**skip:** <reason>`; every later
invocation reads that as not remaining. Never rename a task title. -->

- [x] 1. The hook reads `CLAUDE_COMMIT_PATTERN_DEFAULT` as its fallback pattern, with test cases: unset = today's default; `none` skips the subject while `git add -A` and the backtick still refuse; a declared bullet wins over the variable.
- [x] 2. The hook header and `docs/agents/tooling.md`'s resolver chain name the env step between `CLAUDE.local.md` and the script's own default.

## Anchors

- `templates/hooks/enforce-commit-hygiene.sh:66` — `DEFAULT_PATTERN=` constant, the only place the fallback lives; the block message quotes it.
- `templates/hooks/enforce-commit-hygiene.sh:102` — `resolve_declared "Commit pattern" "$DEFAULT_PATTERN"`: declared bullet first, fallback last.
- `templates/hooks/enforce-commit-hygiene.sh:280` — `[[ "$PATTERN" != "none" ]]`: the guard a `none` fallback reuses.
- `templates/hooks/large-file-guard.sh` — `CLAUDE_MAX_WRITE_BYTES`, the env-override precedent and naming.
- `scripts/tests/enforce-commit-hygiene.test.sh:51` — `write_policy` fixture; `:207-215` the no-bullet default cases the new ones sit beside; `:204-205` the "none still catches backtick / add -A" shape to copy.
- `docs/agents/tooling.md:76` — step 3 of the resolver chain ("The script's own default"); the env step goes before it.
- `.claude/hooks/` — byte-identical to `templates/hooks/`, pinned by `scripts/tests/hooks-in-sync.test.sh`; the edit lands in `templates/` and is copied.

## References

- `~/.claude/plans/agents-md-micha-owns-snuggly-leaf.md` — the global-hooks plan this unblocks; decision 7 explains why the hook was left out of `~/.claude/hooks/`.
- `~/.claude/settings.json` — the wiring that will set the variable (`CLAUDE_COMMIT_PATTERN_DEFAULT=none bash "$HOME/.claude/hooks/bash-guard.sh"`); out of scope here, done by hand after landing.

## Notes

- Writing this file through a Bash heredoc tripped check 4: the hook reads the whole command string, so a _mention_ of the staging flag inside a heredoc refuses like an invocation. Write the doc with the Write tool.
