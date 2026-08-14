---
change: commit-pattern-hook
branch: unclaimed
created: 2026-08-14
status: shaping # shaping | building | landed
---

# Change — a PreToolUse hook enforces commit hygiene, and dw-git stops defending in prose what a script can check

## Goal

`templates/hooks/enforce-commit-hygiene.sh` intercepts a `git commit`/`git add` Bash call before it
runs and exits 2 on four things prose alone guards today: a subject that misses the commit pattern,
a missing or forbidden trailer, a backtick inside a `-m` string, and `git add -A` / `git add .`.
Both policies are declared, not inferred — `- **Commit pattern**: <regex>` and
`- **Commit trailer**: required|forbidden|<regex>` in `AGENTS.md`, each disabled by `none`, the
`lint-on-edit.sh` resolution shape. You know it worked when a bad subject, a missing trailer, a
backticked `-m` and `git add -A` each exit 2 with a message naming the fix; when `feat(dw-git): …`
with the repo's trailer, the `rtk git commit …` form, `-F`, editor commits and `Merge …` exit 0;
when the self-test is green; and when `skills/dw-git/SKILL.md` points at the declarations instead
of restating them.

## Decisions

- Four checks, one hook, one change — **supersedes the grill's "subject format only"**. The layers
  share the script, the test file, the settings entry and the version bump, so splitting them meant
  touching the same four files twice.
- Every policy is a declared bullet, never inferred from `## Git conventions` prose. The trailer
  needs its own `- **Commit trailer**:` bullet for the same reason the pattern does: one line both
  the writer (model reads `AGENTS.md`) and the enforcer (hook greps it) can read without guessing.
- Pattern default ships in the script (Conventional Commits); the trailer default is `none`, since
  a trailer requirement that nobody declared should not start failing commits in existing repos.
- Named `enforce-commit-hygiene.sh`, not `-pattern` — it grew past the subject. The change slug
  stays `commit-pattern-hook`; it is already in the history.
- `git add -A` is a staging call, not a commit, but it rides the same `PreToolUse`/`Bash` matcher
  and the same declaration file, so it stays in this hook rather than earning a fourth one.
- Hook and `dw-git` trim land together — the trim removes prose enforcement, so it can only ship
  once the hook replaces it.
- Pass through `-F`/`--file`, editor commits (no `-m`), and `Merge `/`Revert `/`fixup! `/`squash! `/
  `amend! ` subjects — same allowances as the buildwithclaude original; `dw-git` uses `-m`.
- The three _new_ hooks (guard on `plugins/**`, credential-leak, large-file) stay in
  `.ai/backlog/guardrail-hooks-next-wave.md`: separate scripts, separate events, no shared code.

## Tasks

One task by the user's call — the pieces only make sense landing together.

- [ ] 1. The whole change in one slice:
  - `templates/hooks/enforce-commit-hygiene.sh` + byte-identical executable copy in
    `.claude/hooks/`, wired as the third `PreToolUse`/`Bash` command in both `.claude/settings.json`
    and `templates/settings.json`. Shape after `block-dangerous-commands.sh` (jq guard,
    wrapper-aware `git … commit` detection), `-m` extraction after the buildwithclaude script
    (`xargs -n1` tokenization; `-m`/`--message`/`--message=`/`-mfix:`/clustered `-am`). Four checks:
    subject pattern, trailer policy, backtick inside `-m`, `git add -A` / `git add .`.
  - `scripts/tests/enforce-commit-hygiene.test.sh` after `block-env-access.test.sh`: default
    allowed/blocked subjects, trailer required/forbidden/none, backtick cases, `git add` forms,
    `rtk` wrapper form, `-F`/editor/`Merge` pass-throughs, and both bullets overridden or set to
    `none` via a temp `AGENTS.md`.
  - `- **Commit pattern**:` and `- **Commit trailer**:` in this repo's `AGENTS.md` (`## Solo lane`,
    beside the lint and typecheck bullets) and placeholders in `templates/AGENTS.md` so `dw-init`
    users see the overrides exist. Watch the root doc budget (120 lines / 10 KB).
  - Trim `skills/dw-git/SKILL.md` commit Defaults to point at the declarations (subject per
    `- **Commit pattern**:`, trailer per `- **Commit trailer**:`, hook enforces both; body
    what+why; one logical change), keep the backtick hazard note but shorten it now that the hook
    catches it, document the hook in `docs/agents/tooling.md`, bump the owning plugin versions
    - `marketplace.json`.

## Anchors

- `templates/hooks/block-dangerous-commands.sh:27-45` — the `WRAPPER`/`BOUNDARY`/`GIT` constants;
  the new hook must see through `sudo`/`rtk` the same way.
- `templates/hooks/lint-on-edit.sh` — the `- **Lint command**:` bullet resolution both new bullets
  copy (including `none` as a standalone declaration).
- `scripts/tests/block-env-access.test.sh` — the self-test shape: `jq -n --arg` payloads,
  blocked/allowed helpers, SKIP without jq, target = template.
- `scripts/tests/hooks-in-sync.test.sh` — enforces template↔installed byte identity and +x; add the
  template first.
- `skills/dw-git/SKILL.md:58-68` — the commit Defaults block being trimmed; `:83-90` — the backtick
  hazard note the hook now enforces.
- `AGENTS.md` `## Git conventions` — the trailer rule (`Co-Authored-By: <the model that wrote it>`)
  the new bullet has to express machine-readably.
- buildwithclaude.com/hook/conventional-commits — the `-m` extraction and pass-through list
  (tokenize via `xargs -n1`; allow `-F`, editor commits, `Merge`/`Revert`/`fixup!`).

## Notes

Full grill/plan record: `/Users/dominik.wozniak/.claude/plans/zastanawiam-sie-nad-nowym-shimmying-gosling.md`.

The hook enforcing the trailer will police this repo's own commits the moment it is installed —
including the commit that installs it. Wire it after the message convention is confirmed working,
or expect the first commit to bounce.
