---
change: eager-doc-size-budget
branch: unclaimed
created: 2026-08-09
status: shaping # shaping | building | landed
---

# Change — a file that is loaded every session can declare a size budget, and a hook holds it to it

## Goal

A repo can write `Budget: **120 lines / 10 KB**` into `AGENTS.md`, `CLAUDE.md` or
`CLAUDE.local.md`, and a `PostToolUse` hook enforces it on every edit: a message from about 90% of
either limit, a blocking `exit 2` above 100%. A file that declares no budget is never checked and
never mentioned. You know it worked when editing a file past its declared line count blocks with the
measured numbers, and when this repo — which declares nothing — stays completely silent.

## Decisions

- **Opt-in per file, no default limit** — reversing the earlier "a default when the file declares
  none". Measured here: `AGENTS.md` is 214 lines / 16132 B and `CLAUDE.local.md` is 131 lines /
  8443 B. Any honest default lights the lane's own flagship repo red on install day, and a default
  picked high enough not to hurt is decoration — the same charge levelled at agnix's `CC-MEM-014`,
  `XP-007`, `CDX-AG-004` and `AS-012`, which encode platform ceilings nobody ever hits and are not
  configurable. A budget is chosen editorial discipline, so it must be chosen.
- **The declaration is prose in the file itself** — no new config file. Two numbers pulled with
  `grep -oE` and validated against `^[0-9]+$`, never `sed`-into-`eval`: `lint-on-edit.sh:29-34`
  documents what that costs when it goes wrong.
- **Matched by path relative to the repo root, not by basename** — `references/AGENTS.md` in
  `grateful-me-app-v2` is 99 lines / 10742 B under its own larger budget; a basename match would
  fail it against the wrong number. Symlinks are skipped, or `CLAUDE.md → AGENTS.md` counts one
  file twice.
- **Eager files only** — `docs/**` is read on demand and costs nothing per session; `SKILL.md`
  loads only its frontmatter `description` eagerly.
- **Hook only, no `dw-doctor` section** — they live in different trees. The hook is payload copied
  **into** the target repo (`.claude/hooks/`); `doctor.sh` runs from the plugin and reads the repo
  from outside. A doctor section means either a second parser or a plugin depending on a file it
  copied earlier, silent when `dw-init` never ran. Unlike `validate-decision-records`, there is no
  shared script that satisfies both callers.
- **Two thresholds, warn then block** — going over budget is a refactor, not a typo, so the ~90%
  message is a run-up rather than an ambush.
- **`dw-init` installs it by default** — free to do, now that a repo declaring nothing is silent.
- **This hook is lane-native, not vendored** — `templates/hooks/` is otherwise a copy of the
  `dw-skills` canon, but this file has no upstream. Do not "sync" it there.

## Tasks

- [ ] 1. `templates/hooks/doc-budget.sh` (new, `chmod +x`) — `command -v jq || exit 0` guard,
      `tool_input.file_path` off stdin like every sibling. Resolve the repo root, take the path
      relative to it, and exit 0 unless it is `AGENTS.md`, `CLAUDE.md` or `CLAUDE.local.md` at the
      root; exit 0 for a symlink. Parse the budget line from the file, exit 0 when absent or
      malformed. Measure `wc -l` and byte length, print to stderr from ~90% of either limit, and
      `exit 2` above 100% naming both measured values and both limits. Plus
      `scripts/tests/doc-budget.test.sh` driving it with synthetic stdin payloads and fixture
      files — the pattern `scripts/tests/lint-on-edit.test.sh` already uses. Note the real
      declaration in the wild reads `120 lines / 10 KB`, so the byte figure carries a unit: accept a
      bare number as bytes and a `KB` suffix as ×1024, reject anything else as malformed rather than
      guessing. Bump `dw-solo-setup`
      by one patch in `.claude-plugin/marketplace.json` **and**
      `plugins/dw-solo-setup/.claude-plugin/plugin.json`, identical.
- [ ] 2. `templates/settings.json:65-77` — add the hook to the existing `PostToolUse` /
      `Write|Edit|MultiEdit` entry beside `lint-on-edit.sh`, with a short `timeout` and a
      `statusMessage`. Then `skills/dw-init/SKILL.md:60-69` — list it with the three always-offered
      stack-agnostic hooks, since it depends on no stack — and check `:32` and `:109` need nothing
      beyond what the glob already covers.
- [ ] 3. Dogfood: copy the template into this repo's `.claude/hooks/` byte-identical, wire it into
      tracked `.claude/settings.json`, and add its line to `## Hooks installed` in
      `CLAUDE.local.md`. Declare no budget in `AGENTS.md` — the hook must be provably silent here,
      which is the whole point of task 1's opt-in decision. `scripts/tests/hooks-in-sync.test.sh`
      then pins the copy.

## Anchors

- `/Users/dominik.wozniak/workspace/private/byarcadia-packages/grateful-me-app-v2/scripts/check-agents-docs.mjs:44-58`
  — `BUDGETS` + `checkBudget()`, ~10 lines. `:44` is the comment explaining why `docs/agents/*.md`
  are deliberately not budgeted.
- `/Users/dominik.wozniak/workspace/private/byarcadia-packages/grateful-me-app-v2/AGENTS.md` —
  declares `Budget: **120 lines / 10 KB**` in prose and sits at 112/120 lines, 8179/10240 B: the
  live test case for the 90% threshold.
- `/Users/dominik.wozniak/workspace/private/byarcadia-packages/grateful-me-app-v2/references/AGENTS.md`
  — 99 lines, 10742 B, its own 12288 B budget. The basename trap, in one real file.
- `templates/hooks/lint-on-edit.sh:20-24` — the `jq` guard and `file_path`-off-stdin preamble to
  copy. `:29-34` — the sed-parsing comment that ends in an `eval` executing the edited file; the
  reason task 1 uses `grep -oE` plus a numeric guard. `resolve_lint_cmd()` is the precedent for
  reading configuration out of prose at all.
- `templates/settings.json:65-77` — the `PostToolUse` array task 2 extends.
- `skills/dw-init/SKILL.md:60-69` — the hook-picking step and its stack-agnostic / stack-specific
  split; `:109` copies the selected templates and `chmod +x`es them.
- `scripts/tests/hooks-in-sync.test.sh:28-40` — templates must be executable, and an installed copy
  must match byte for byte. Task 3 lands inside this invariant.
- `AGENTS.md` here — 214 lines / 16132 B, the measurement that killed the default limit.

## Notes

- **Lands second, by preference not by dependency.** The earlier claim that this waits on a "lazy
  place to move content to" does not survive the opt-in decision: whoever declares a budget has
  already decided where content goes, so the message can stay generic. `validate-decision-records`
  is still the better first change, and the real coupling is narrower — both bump `dw-solo-setup`,
  as does `.ai/backlog/setup-payload-sweep.md`. Whichever lands first takes the number; re-check
  after any rebase, because `validate-manifests.sh` only checks the two files are equal.
- **Explicitly out of scope**: transplanting the Task Router and the `docs/agents/` layer. That
  layer in `grateful-me-app-v2` was designed up front, not grown under pressure — exactly one of
  its eight files carries a `## Gotchas` section (`docs/agents/tooling.md:25`), so there is no
  growth mechanism to copy. It earns its keep at five submodules and seven skills, not in a repo
  with three files. `agnix` is out too: not installed, topic closed.
- **`.lintstagedrc.json` glob check** — no new file type here (`.sh`, `.json`, `.md` all covered),
  but confirm before the first commit; a type outside the glob is unformatted at commit and
  rejected at push (`## Gotchas`).
- Full gate before push:
  `pnpm lint && pnpm format && pnpm validate:manifests && pnpm validate:artifacts && pnpm validate:docs && pnpm validate:evals && pnpm eval:routing`.
