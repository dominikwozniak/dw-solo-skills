---
change: dot-guardrails-swallow-dotfile-paths
branch: main
created: 2026-08-13
status: shaping # shaping | building | landed
---

# Change — the `.`-path guardrails stop swallowing every dotfile path

## Goal

`git restore .ai/work/foo` and `git checkout .claude/settings.json` stop being blocked, while
`git restore .`, `git restore -- .` and `git restore ./` stay blocked. Measured by
`pnpm validate:artifacts` with new cases on both sides of the line in
`scripts/tests/block-dangerous-commands.test.sh`.

The defect is a missing end anchor: `'git restore (-- +)?\.'` matches the leading dot of any dotted
path, so restoring a single file under `.ai/` reads as wiping the working tree. Verified at the shell
that `(^|[;&|][[:space:]]*)git restore (-- +)?\./? *($|[;&|])` splits the seven cases correctly.

## Decisions

- **Fix `git checkout (-- +)?\.` in the same pass** — the line above it in the same array carries the
  identical defect, and leaving it means `git checkout .ai/…` still gets refused. One character each,
  one commit.
- **Tolerate a closing quote in the anchor** (`\./? *["']? *($|[;&|])`) — the shared `BOUNDARY`
  already absorbs an opening quote for `rtk run "git restore ."`; a bare `($|[;&|])` end would newly
  let that quoted form through. Anchoring must not trade a false positive for a false negative.
- **The backlog deletion rides along** rather than becoming its own change — a `git rm` with no code
  behind it isn't worth its own gate run, and it was asked for as one change.
- **`dw-skills` is no longer maintained**, so
  `.ai/backlog/apply-the-heredoc-fix-to-the-vendored-hook-in-dw-skills.md` fails the month bar and is
  deleted rather than kept as a record. The findings it points at stay in
  `.ai/archive/block-env-heredoc-escape/` and `.ai/archive/setup-lives-in-tracked-agents-md/`.

## Tasks

- [ ] 1. Anchor both dot patterns in `templates/hooks/block-dangerous-commands.sh`, mirror the file
      byte-for-byte into `.claude/hooks/block-dangerous-commands.sh` (`validate-artifacts.sh` enforces
      that), and add cases to `scripts/tests/block-dangerous-commands.test.sh`: `allowed` for
      `git restore .ai/work/x`, `git checkout .claude/settings.json`; `blocked` for `git restore ./`,
      `git checkout -- .` and the quoted `rtk run "git restore ."`. Keep the existing `restore-dot` /
      `checkout-dot` / `checkout-dashes-dot` / `restore-staged` cases passing.
- [ ] 2. Bump `dw-solo-setup` 0.1.15 → 0.1.16 in `plugins/dw-solo-setup/.claude-plugin/plugin.json`
      **and** `.claude-plugin/marketplace.json` — the two must stay identical.
- [ ] 3. `git rm .ai/backlog/apply-the-heredoc-fix-to-the-vendored-hook-in-dw-skills.md`.

## Anchors

- `templates/hooks/block-dangerous-commands.sh:39-40` — the two defective patterns, adjacent lines in
  `DANGEROUS_PATTERNS`.
- `templates/hooks/block-dangerous-commands.sh:31` — `BOUNDARY`, which ends in `[\"']?` and is why the
  closing-quote tolerance is needed at the other end.
- `templates/hooks/block-dangerous-commands.sh:44` — the `rm` pattern, the in-file precedent for an
  end anchor: `\.\.?/? *($|[;&|])`.
- `scripts/tests/block-dangerous-commands.test.sh:52,85` — `restore-dot` and `restore-staged`, the
  cases the fix must not break.
- `scripts/validate-artifacts.sh:6` — the check that keeps `.claude/hooks/` byte-identical to
  `templates/hooks/`.
- `.ai/backlog/README.md` — the two bars an entry clears; the month bar is the one being invoked.

## Notes

`docs/agents/git-history.md:28` lists `git checkout .` / `git restore .` as blocked — still true after
the fix, no edit needed.
