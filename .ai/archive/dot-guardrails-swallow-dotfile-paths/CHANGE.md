---
change: dot-guardrails-swallow-dotfile-paths
branch: main
created: 2026-08-13
status: landed # shaping | building | landed
landed: 2026-08-13
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

- [x] 1. Anchor both dot patterns in `templates/hooks/block-dangerous-commands.sh`, mirror the file
      byte-for-byte into `.claude/hooks/block-dangerous-commands.sh` (`validate-artifacts.sh` enforces
      that), and add cases to `scripts/tests/block-dangerous-commands.test.sh`: `allowed` for
      `git restore .ai/work/x`, `git checkout .claude/settings.json`; `blocked` for `git restore ./`,
      `git checkout -- .` and the quoted `rtk run "git restore ."`. Keep the existing `restore-dot` /
      `checkout-dot` / `checkout-dashes-dot` / `restore-staged` cases passing.
- [x] 2. Bump `dw-solo-setup` 0.1.15 → 0.1.16 in `plugins/dw-solo-setup/.claude-plugin/plugin.json`
      **and** `.claude-plugin/marketplace.json` — the two must stay identical.
- [x] 3. `git rm .ai/backlog/apply-the-heredoc-fix-to-the-vendored-hook-in-dw-skills.md`.
- [x] 4. Added at land time, from the verdict: close the two pre-existing holes the anchor work
      exposed — a quoted `"."` / `'.'` argument, and the `git -C <path>` form — by folding the quote
      class into a `DOT_ARG` constant and prefixing both patterns with a `GIT` one. Eight more cases.
      The remaining `-C` gap on the other git patterns is parked, not fixed.

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

The end anchor became a named `DOT_END` constant beside `BOUNDARY` rather than being inlined twice.
That was forced, not stylistic: array elements are single-quoted, so the `["']?` the closing-quote
tolerance needs cannot appear inline — a double-quoted constant with `[\"']` is the only spelling that
carries both quote characters. The two patterns concatenate it (`'…\.'"$DOT_END"`), which also means
the block message prints the expanded regex.

Nothing in the tree referenced the deleted backlog entry (grepped before removing it), so no pointer
was left dangling. The backlog is 7/8 against the cap again, which buys the next change one slot.

`DOT_END` became `DOT_ARG` in task 4 — once the leading quote class had to move inside, the constant
was no longer a tail. The land-time verdict is what found the two holes, and it found them by running
the same probe against the `origin/main` hook and the new one and diffing the exit codes; that
old-vs-new comparison is worth more than reading a regex, and it is the reason the anchor could be
called a one-row delta with any confidence.
