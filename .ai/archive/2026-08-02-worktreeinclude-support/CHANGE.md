---
change: worktreeinclude-support
branch: worktreeinclude-support
created: 2026-08-01
status: landed # shaping | building | landed
landed: 2026-08-02
pr: "#1"
---

# Change — make a `/dw-start` worktree as usable as the main tree, and make it say when it isn't

## Goal

A worktree created by `worktree.sh create` carries everything a working checkout needs beyond
tracked files, and reports out loud whatever it cannot carry.

Today it carries none of it. `create` shells out to plain `git worktree add`, which checks out
tracked state only, and every gap fails **silently**:

- no `.env` → the build dies with an error that explains nothing;
- no `CLAUDE.local.md` → the agent falls back to generic git conventions and commits with a trailer
  this repo forbids (the symptom `link-local-memory.sh`'s own header predicts);
- no `.husky/_/` → `core.hooksPath` points at a directory that doesn't exist, git finds no hooks, and
  **every commit skips prettier, agnix and the manifest version check with no output at all**.

Claude Code's `.worktreeinclude` covers only the first gap and only for worktrees it creates itself
(`--worktree`, subagent worktrees, desktop) — not `git worktree add`. The `SessionStart` hook covers
the second only when the session _starts_ in the worktree, so `/dw-start` (which enters mid-session)
misses it.

Done when: `worktree.sh create <slug>` copies the `.worktreeinclude` matches, symlinks
`CLAUDE.local.md`, prints a readiness report naming what still has to be regenerated, and still puts
nothing but the path on stdout.

## Decisions

- **Four classes, three mechanisms.** Everything untracked in a working tree gets exactly one correct
  treatment, and conflating them is the bug:

  | class                             | example                               | treatment                                                    |
  | --------------------------------- | ------------------------------------- | ------------------------------------------------------------ |
  | local config / secrets            | `.env`, `config/secrets.json`         | **copy**                                                     |
  | personal agent memory             | `CLAUDE.local.md`                     | **symlink** — one source of truth, edits propagate both ways |
  | installed deps, generated tooling | `node_modules/`, `.husky/_/`, `.venv` | **regenerate** — never copy; platform-specific and large     |
  | build cache, scratch              | `.next/`, `.inspirations/`, `TASK.md` | **leave absent**                                             |

- **Match with two `git ls-files` calls, intersected — never reimplement gitignore matching.**
  `git ls-files -o -i --exclude-standard` is the gitignored set, `git ls-files -o -i
--exclude-from=.worktreeinclude` the pattern-matching set, `comm -12` over the sorted pair is
  exactly the documented rule ("matches a pattern **and** is gitignored"). Git owns the pattern
  semantics, so they cannot drift from what `claude -w` does.
- **The refusals are hard, not advisory.** `.worktreeinclude` is hand-written and a careless pattern
  is destructive: measured in this repo, `*` matches 421 files of which 394 are `node_modules/`, and
  `.claude/worktrees/` matches too — copying worktrees into a worktree. `create` refuses
  `node_modules/`, `.claude/worktrees/` and `.git` regardless of what the file says, and warns
  above a volume threshold instead of silently copying a dependency tree.
- **Symlink `CLAUDE.local.md` at create time, not at session start.** `EnterWorktree` does not fire
  `SessionStart`, so the hook cannot cover `/dw-start`. `create` has no session lifecycle to miss.
  The hook stays for `claude -w`, which `worktree.sh` is not involved in; both test with `-e` before
  linking, so they compose instead of racing.
- **The file stays out of `templates/worktreeinclude.txt`.** Copy and symlink are different
  treatments; listing it there would produce a second, diverging copy.
- **The report is information, never a gate.** It goes to stderr and cannot fail `create` — a
  worktree that exists but prints a warning is strictly better than one that half-exists.
- **A failed copy warns; it does not fail `create`.** The worktree already exists by then and
  `create`'s own guards refuse to re-run on an existing path, so aborting would leave a state that
  needs manual cleanup before a retry.
- **stdout stays path-only.** `dw-start` parses it (`skills/dw-start/SKILL.md:49`); copy chatter,
  warnings and the report all go to stderr, the way line 56 already redirects git's.
- **Filenames containing a newline are unsupported**, documented in place — `comm` has no `-z`.
- **Both plugins get a patch bump.** The change straddles `dw-solo` (`worktree.sh`, `dw-start`) and
  `dw-solo-setup` (`templates/`, `dw-init`); `validate-manifests.sh` checks the two are equal.

## Tasks

- [x] 1. `worktree.sh create` copies `.worktreeinclude` matches — absent file is a silent no-op,
      `mkdir -p` for nested patterns, `cp -p` to preserve mode, a failed copy warns without failing
      create. Hard refusals for `node_modules/`, `.claude/worktrees/`, `.git` plus a volume warning.
      Header comment extended. Tests: no-file no-op, ignored+matching copied, tracked+matching
      skipped, ignored+non-matching skipped, nested pattern, `600` preserved, each refusal, and
      stdout still path-only while copying.
- [x] 2. `create` symlinks `CLAUDE.local.md` from the main tree, idempotently (skip when the target
      already exists, matching the hook's `-e` test). Tests: link made and readable through,
      pre-existing file left alone, absent source is a no-op.
- [x] 3. Readiness report on stderr at the end of `create`: what was copied, what was linked, and
      what must be regenerated — `package.json` present → name the install command; `.husky/` tracked
      with no `.husky/_/` → say plainly that **commit hooks are inactive until you install**. Tests:
      report lands on stderr, stdout stays path-only, the husky line fires only in that state.
- [x] 4. `templates/worktreeinclude.txt` — commented-out examples only, plus a warning comment about
      the refused paths. Wired into `dw-init`: listed in the step-3 gate marked **tracked**, written
      idempotently in step 4.
- [x] 5. `skills/dw-start/SKILL.md` step 4 rewritten — the install stops being an offer and becomes a
      required step, with the hooks-are-inactive consequence stated; plus a line that the worktree now
      carries `.worktreeinclude` files and `CLAUDE.local.md`. Patch bump for both plugins in
      `.claude-plugin/marketplace.json` and each `plugins/*/.claude-plugin/plugin.json`.

## Anchors

- `scripts/runtime/worktree.sh:56-57` — `git worktree add … 1>&2` then `printf '%s\n' "$path"`.
  Everything new goes between them; the redirect on 56 is the precedent for keeping stdout clean.
- `scripts/runtime/worktree.sh:18` — `set -euo pipefail`, so the new sections must tolerate failure
  explicitly rather than inheriting an abort.
- `templates/hooks/link-local-memory.sh:11-12,36` — the symlink-not-copy rationale, and the `-e`
  test that lets the hook and `create` compose without racing.
- `templates/gitignore-block.txt` — the "dotfile payload stored with a `.txt` suffix" convention the
  new template follows.
- `skills/dw-init/SKILL.md:80-104` — step 4's write list and the step-3 hard gate above it.
- `scripts/tests/worktree.test.sh:22-42` — the throwaway-repo harness (`mktemp -d`, `git init`,
  PASS/FAIL counters, bash 3.2 safe) every new case extends.
- `skills/dw-start/SKILL.md:49` — the `worktree.sh create` call site whose stdout contract must hold.
- `.husky/pre-commit` + `package.json` `prepare: husky` — the pair that makes `.husky/_/` a
  regenerate-class artifact rather than a copy-class one.
- `scripts/validate-manifests.sh` — enforces marketplace ≡ plugin version equality.

## Notes

- This is the repo's **first real run of its own loop**. Friction in the skills is an output of this
  change: park it in `.ai/BACKLOG.md` or `## Gotchas` at land time rather than patching mid-build.
- The scope above is wider than the original shaping, which covered `.worktreeinclude` alone.
  Widened after `dw-start` exposed two more instances of the same class — see findings 3 and 4.
- Verification beyond the self-tests: a manual `create`/`remove` round-trip on this repo. Use a
  throwaway gitignored name (e.g. `local-probe.txt`), **not** `.env` — `block-env-access.sh` blocks
  that path and there is no reason to fight our own guardrail.
- **Loop friction, run 1 (`dw-shape`).** `block-env-access.sh` blocked the shaping commit for its
  **message body** naming the file this change is about. The hook's own self-test pins
  `git commit -m "load .env in prod"` as allowed, but that survives only because the prose sits in
  double quotes — a heredoc gives the matcher no quoting to see. Worked around with
  `git commit -F <path outside the repo>`. The fix belongs to the hook, and the hook is vendored from
  `dw-skills`, so it has to be applied in both repos.
- **Loop friction, run 2 (`dw-start`).** `dw-start` is `disable-model-invocation`, so the agent cannot
  follow `dw-shape`'s own `**Next:**` pointer. Deliberate — worktree creation is outward-facing — but
  the chain reads as if it flows, and the docs should say it doesn't.
- **Loop friction, run 3 (`dw-start`).** `EnterWorktree` does not fire `SessionStart`, so
  `link-local-memory.sh` never ran and `CLAUDE.local.md` was absent. **Absorbed into this change** as
  task 2.
- **Loop friction, run 4 (`dw-start`).** The claim commit ran no pre-commit hook at all —
  `core.hooksPath` is `.husky/_`, generated by `husky init` and gitignored, so a fresh worktree has
  `.husky/pre-commit` and no `_/`. `pnpm install` restores it. **Absorbed into this change** as
  task 3, which reports the state rather than fixing it by copying (wrong class).
- The end-to-end run on this repo caught what the self-test could not: the volume warning counted
  candidates **before** the refusals, so a `.worktreeinclude` naming `node_modules/` announced "395
  files" and then copied 1. A warning that fires on what it is about to refuse is a warning you
  learn to skip. Now counted post-refusal, with a test that fails if it cries wolf again.
- Park at land time: `typecheck-on-stop.sh` `eval`s the `**Typecheck command**` value from
  `CLAUDE.local.md`, and the only way to say "this repo has no typecheck" is to leave the
  `{{TYPECHECK_COMMAND}}` placeholder — which the same template's closing section calls a mistake.
