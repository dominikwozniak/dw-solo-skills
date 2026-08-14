---
change: commit-pattern-hook
branch: unclaimed
created: 2026-08-14
status: shaping # shaping | building | landed
---

# Change — a PreToolUse hook validates the commit subject, and dw-git stops defending the format in prose

## Goal

`templates/hooks/enforce-commit-pattern.sh` intercepts `git commit -m …` before it runs and exits 2
when the subject does not match the pattern — default Conventional Commits baked into the script,
overridden by a `- **Commit pattern**: <regex>` bullet in `AGENTS.md`, disabled by `none` (the
`lint-on-edit.sh` resolution shape). You know it worked when
`echo '{"tool_name":"Bash","tool_input":{"command":"git commit -m \"bad message\""}}' | bash .claude/hooks/enforce-commit-pattern.sh`
exits 2, `feat(dw-git): …` and the `rtk git commit …` form exit 0, the self-test is green, and
`skills/dw-git/SKILL.md`'s commit Defaults point at the pattern instead of restating it.

## Decisions

- Subject format only — no trailer, backtick-in-`-m`, or staging checks. Keeps the hook one regex
  match, deterministic and testable; the rest stays prose in `dw-git`.
- Pattern source is a hybrid: script default → `AGENTS.md` bullet override → `none` disables.
  One source serves both the writer (model reads `AGENTS.md`) and the enforcer (hook greps the
  same line); a pattern in `settings.json` the model never sees would force a second prose copy.
- Hook and `dw-git` trim land as one change — the trim removes prose enforcement, so it can only
  ship once the hook replaces it. Not a split: the trim is not independently shippable.
- Pass through `-F`/`--file`, editor commits (no `-m`), and `Merge `/`Revert `/`fixup! `/`squash! `/
  `amend! ` subjects — same allowances as the buildwithclaude original; `dw-git` uses `-m`.
- One task, not three — the user's call; the pieces only land together, so slicing them was
  ceremony.
- The `- **Commit pattern**:` bullet for this repo and the `templates/AGENTS.md` placeholder are in
  scope (user promoted them from the left-out list).

## Tasks

One task by the user's call — the pieces only make sense landing together.

- [ ] 1. The whole change in one slice:
  - `templates/hooks/enforce-commit-pattern.sh` + byte-identical executable copy in
    `.claude/hooks/`, wired as the third `PreToolUse`/`Bash` command in both `.claude/settings.json`
    and `templates/settings.json`. Shape after `block-dangerous-commands.sh` (jq guard,
    wrapper-aware `git … commit` detection), `-m` extraction after the buildwithclaude script
    (`xargs -n1` tokenization; `-m`/`--message`/`--message=`/`-mfix:`/clustered `-am`).
  - `scripts/tests/enforce-commit-pattern.test.sh` after `block-env-access.test.sh`: default
    allowed/blocked cases, `rtk` wrapper form, `-F`/editor/`Merge` pass-throughs, bullet override
    (ticket-style regex) and `none` via a temp `AGENTS.md`.
  - `- **Commit pattern**:` bullet in this repo's `AGENTS.md` (`## Solo lane`, beside the lint and
    typecheck bullets) and a placeholder in `templates/AGENTS.md` so `dw-init` users see the
    override exists.
  - Trim `skills/dw-git/SKILL.md` commit Defaults to point at the pattern (subject per
    `- **Commit pattern**:`, hook enforces; body what+why; trailer per `## Git conventions`; one
    logical change), document the hook in `docs/agents/tooling.md`, bump the owning plugin versions
    - `marketplace.json`.

## Anchors

- `templates/hooks/block-dangerous-commands.sh:27-45` — the `WRAPPER`/`BOUNDARY`/`GIT` constants;
  the new hook must see through `sudo`/`rtk` the same way.
- `templates/hooks/lint-on-edit.sh` — the `- **Lint command**:` bullet resolution this hook copies
  for `- **Commit pattern**:` (including `none` as a standalone declaration).
- `scripts/tests/block-env-access.test.sh` — the self-test shape: `jq -n --arg` payloads,
  blocked/allowed helpers, SKIP without jq, target = template.
- `scripts/tests/hooks-in-sync.test.sh` — enforces template↔installed byte identity and +x; add the
  template first.
- `skills/dw-git/SKILL.md:58-68` — the commit Defaults block being trimmed.
- buildwithclaude.com/hook/conventional-commits — the `-m` extraction and pass-through list
  (tokenize via `xargs -n1`; allow `-F`, editor commits, `Merge`/`Revert`/`fixup!`).

## Notes

Full grill/plan record: `/Users/dominik.wozniak/.claude/plans/zastanawiam-sie-nad-nowym-shimmying-gosling.md`.
