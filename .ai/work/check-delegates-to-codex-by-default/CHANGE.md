---
change: check-delegates-to-codex-by-default
branch: check-delegates-to-codex-by-default
created: 2026-08-17
status: building # shaping | building | landed | rejected
---

# Change — bare dw-check delegates to codex, with a triviality floor

## Goal

Bare `dw-check` hands the diff to `codex:rescue` whenever the codex plugin is present. A trivial
diff — 2 files or fewer and under 50 lines — gets the self-review instead, and a missing plugin
falls back to self-review with a one-line install hint. Finding-by-finding verification before the
report stays.

## Decisions

- Default-on with degradation (gstack's shape), triviality floor from addyosmani (≤2 files,
  <50 lines) — the cross-model pass is the value; silent skipping was the failure mode.
- At an open PR, suggest `/codex:review --wait` — explicit-invoke, so the user types it; pairs with
  the land-opens-the-pr sibling, which makes the PR exist before the merge decision.

## Tasks

- [x] 1. `skills/dw-check/SKILL.md`: rewrite step 2 ("Delegate only when asked for it" → codex by default, floor, fallback); keep `codex` as the force argument; update argument-hint and description.
- [ ] 2. `evals/cases/dw-check.json` reviewed; `pnpm eval:routing` ≥ 67; corpus baseline only on net growth; bump `plugins/dw-solo` + `marketplace.json`.

## Anchors

- `skills/dw-check/SKILL.md:36` — the step being rewritten

## Notes

- **The corpus baseline moved in task 1's commit, not task 2's.** Pass 3 of `validate:artifacts` fails
  per-commit on growth, and `docs/agents/skills-and-plugins.md:81` requires the re-record in the same
  commit as the growth anyway. So task 2's baseline clause is already satisfied; it keeps only the
  eval, the case-file review and the version bumps.
- **The install hint is verified, not guessed**: the plugin is `codex`, from the `openai-codex`
  marketplace (github `openai/codex-plugin-cc`) — read off `~/.claude/plugins/known_marketplaces.json`
  and that marketplace's own `marketplace.json`. `dw-doctor` points a missing codex at `/codex:setup`,
  which only exists once the plugin is installed; step 2 now names the install for the absent case and
  keeps `/codex:setup` for installed-but-not-ready.
- **`docs/SKILL-ANATOMY.md` is gone.** `.ai/archive/shape-splits-changes/CHANGE.md:46` cites it for the
  "one word, no flags" argument convention; the file did not survive the reset, so that convention now
  lives only in the shipped `argument-hint` strings. `codex` stays a bare word for that reason.
- Trimmed the `/codex:review --wait` bullet mid-task: the first draft restated _dw-land's_ condition for
  offering it (a change that skipped `dw-check`), which is the second copy `skills-and-plugins.md`
  warns drifts. dw-check now states only its own moment — an open PR.
