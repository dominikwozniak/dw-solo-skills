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
- [x] 2. `evals/cases/dw-check.json` reviewed; `pnpm eval:routing` ≥ 67; corpus baseline only on net growth; bump `plugins/dw-solo` + `marketplace.json`.

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
- **The description rewrite is routing-neutral, measured rather than assumed.** Ran the eval against a
  `git archive main` snapshot in a scratch tree (the technique
  `.ai/archive/start-builds-and-next-builds-by-default/CHANGE.md` records): every per-skill number is
  identical on both sides — dw-check 2/4, TOTAL 20/30 — and the two dw-check positives that fail
  ("give what I have written so far a once-over…" loses to `dw-grill`; "anything wrong with the code I
  just wrote?…" loses to `dw-next`) fail identically on `main`. Pre-existing corpus weakness, not this
  change's to fix. The new positive then took the suite to 21/31 = **68%**, a point above `main`.
- **One candidate positive was probed and left out, deliberately.** "have a second model go over this
  diff before I move on" lands rank 3 at 0.049 — "move on" pulls `dw-next` to 0.230, and "second
  model" appears in no description. Adding it would put the suite at 21/32 = 66%, under the floor, for
  that same pre-existing weakness. Named here rather than dropped silently. Not filed to the backlog:
  the sibling change already declined the same entry pending a reason to raise the floor, and the list
  sits at 7/8 — `dw-land` gets the call at promotion time, now with a second data point.
- **`pnpm lint` lies in this environment.** Under the rtk command-rewriting hook it reports
  `Command "eslint" not found` / `ERR_PNPM_RECURSIVE_EXEC_FIRST_FAIL`, which has nothing to do with
  this repo — there is no `eslint` here and no `packages:` key in `pnpm-workspace.yaml`. Run
  `bash scripts/lint.sh` directly for the truth, and read its **exit code**, not its tally: agnix
  exits 0 on warnings (59 here, every one pre-existing) and 1 on a single error, so a summary that
  looks like a wall of harmless warnings can still be a failing build.
- **agnix's unclosed-XML-tag check counts backticks per line, so wrapping a code span breaks it.** An
  angle-bracketed placeholder inside a code span is exempt — but only while that span opens and closes
  on one line. Hand-wrapping an _earlier_ span across the newline leaves the next line with odd
  backtick parity, and a placeholder further along it is then read as bare prose — one unclosed-tag
  error, which fails CI's agnix job while the summary still shows nothing but warnings. It happened in
  the bullet above, in this file. Verified both ways against fixtures: a span intact on its own line is
  clean, the same span split across the newline errors at the placeholder. Keep such a span short
  enough that it never needs wrapping. Candidate `## Gotchas` line for `docs/agents/tooling.md`, with
  the rtk trap above.
