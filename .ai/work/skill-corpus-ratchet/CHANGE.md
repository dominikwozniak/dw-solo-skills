---
change: skill-corpus-ratchet
branch: worktree-skill-corpus-ratchet
created: 2026-08-14
status: building # shaping | building | landed
---

# Change — the skill corpus can only shrink unless growth is recorded on purpose, and the budgets say what kind of number they are

## Goal

`skills/*/SKILL.md` gets a ratchet: `scripts/skill-corpus.baseline.json` records the corpus word count,
and `pnpm validate:artifacts` fails when the corpus is larger than the baseline, naming the skills that
account for the delta. Growth stays legal but costs a visible `--update-baseline` commit. Alongside it,
`docs/agents/README.md` states what kind of number `120 lines / 10 KB` is, and `docs/agents/tooling.md`
records that agnix warnings do not fail the build.

You know it worked when appending one word to any `SKILL.md` makes `pnpm validate:artifacts` fail with
the total, the baseline, the delta and the skill that grew; deleting one word passes with the
re-record nudge; `pnpm format:fix` moves neither number; and no line was added to the root `AGENTS.md`.

## Why now — the measurements, not a preference

- **The corpus grew 19% in three days with nothing looking.** `de-ratchet-the-solo-lane` (`1182f7f`,
  2026-08-11) landed the corpus at **11 116** words as an explicit goal, then the number stopped being
  anybody's job: `d5027df` → 12 955, `1816a2d` → 13 267, HEAD (`8ec8d98`) → **13 243**.
- **The only mechanical check over skill size is decoration.** agnix `AS-012` fires at 500 body lines;
  the largest skill (`dw-init`) is 228. `AS-008` caps `description` at 1024; the longest (`dw-shape`)
  is 489.
- **`120 lines / 10 KB` has no stated basis.** It reads like a harness ceiling and is not one. The
  root is at 116/120 lines but 7088/10240 B — only the line half has ever bound, and nothing says
  whether that is by design.

## Decisions

- **A ratchet, not a threshold** — the baseline records what the corpus is; the check fails when it
  grows. No number is chosen, so no number can be set too high. This is the whole reason the answer is
  not "lower `AS-012` to 250".
- **Changing agnix cannot do this, and that was checked rather than assumed.** Four findings, each one
  sufficient on its own: (1) `agnix schema` exposes no numeric knob — `rules.<category>` is a boolean,
  `rules.disabled_rules` a list of IDs, `[[overrides]]` only _disables_ rules for globs, `severity`
  sets the reporting floor; a threshold can be turned off, never turned down. (2) `AS-012` is per file,
  and the 2127-word growth is spread across 11 of them. (3) **agnix warnings do not gate** —
  `bash scripts/lint.sh` exits **0** with 50 warnings. (4) It already fails silently: agnix's eager-size
  rule is tripping right now (`CLAUDE.md:1:0 warning: File exceeds recommended token limit (~1752
tokens, limit is 1500)`) while `pnpm validate:docs` calls the same file green at 116/120 lines.
- **Words, not bytes or lines** — continuity with the 11 116 that `de-ratchet-the-solo-lane` recorded
  and this change re-anchors, plus invariance: prettier reflows `.md` at 100 columns, so line and byte
  counts move on a pure reformat while `wc -w` does not. Task 5 proves that rather than asserting it.
- **No tolerance band** — a percentage would put a taste number back in. The friction is the
  mechanism: it forces the choice an append skips, the same bargain `.ai/backlog/`'s cap already
  strikes (`scripts/validate-artifacts.sh:52-58`).
- **Pass 3 of `validate-artifacts.sh`, not a new gate** — that script already owns the governors over
  the durable layer and already has a CI workflow. No new `pnpm` script, so nothing new to document in
  the root and no `check-agents-docs.mjs` command-sync surface to keep in step.
- **`0008`'s cost test binds**: no hook, no `templates/` payload, no plugin version bump, no new CI
  workflow. This is the test `0006` failed the earlier attempt on, and the reason it is met here is
  that the checker is repo tooling rather than shipped payload.
- **Not a split, though the letter of the test says N = 2.** The prose half
  (`budgets-say-what-kind-of-number-they-are`) is independently shippable and was offered as its own
  change; kept as one at the user's call. Recorded so the question is not reopened.
- **One follow-up parked, one dropped.** `templates/` shipping no `docs/agents/README.md` goes to the
  backlog — a scaffolded repo gets the "move a topic into `docs/agents/<topic>.md`" rule _and_ the
  router-coverage gate that enforces it, without the contract saying what belongs there. Narrowing
  `.agnix.toml`'s blanket `docs/agents/**` exclude to `[[overrides]]` on one rule ID is dropped: the
  exclude already carries its reasoning inline, and the entry would not pass the backlog's own bar.

## Tasks

- [x] 1. **The baseline + the checker.** `scripts/skill-corpus.baseline.json` — `$comment` carrying
      the rationale (ratchet, words not bytes, how to re-record), `words`, and `perSkill` as a
      name→words map. **Re-measure at HEAD**; do not trust the 13 243 in this document, since task 4
      edits no skill but a rebase might. Then `scripts/check-skill-corpus.mjs`, ~70 lines,
      dependency-free ESM, styled on `templates/check-agents-docs.mjs`: `--root <dir>` (task 2 needs
      it), `--update-baseline`, and no `--json` — that would be a flag with no consumer. Counts
      whitespace-separated runs over the whole file including frontmatter, so the number matches
      `cat skills/*/SKILL.md | wc -w`. Exit 1 over baseline naming total / baseline / delta / the
      per-skill deltas; exit 2 on a missing or malformed baseline, never a silent pass; the
      "now smaller — re-record to tighten" nudge when under.
- [ ] 2. **`scripts/tests/check-skill-corpus.test.sh`.** Synthetic fixtures under `mktemp` driven
      through `--root`, **never the live tree** — `check-agents-docs.test.sh:2-4` states why, and a
      case asserting the real corpus would make the self-test a second content gate. Five cases: at
      baseline → 0; one word added → 1, naming the skill; one word removed → 0 plus the nudge;
      `--update-baseline` → file rewritten, exit 0; malformed baseline → 2. Picked up by
      `validate-artifacts.sh` pass 1 with no wiring.
- [ ] 3. **Wire pass 3** into `scripts/validate-artifacts.sh`, and extend its header comment. The
      existing `NOTE:` — pass 2 is a count, not a precedent for a schema — stays true and gains the
      ratchet rather than being replaced.
- [ ] 4. **The three doc edits.** `docs/agents/README.md:17-19` — what kind of number the budget is
      (chosen editorial discipline; Codex truncates project docs near 32 KB, so this is deliberately
      ~3× stricter; the line half is the half that binds). `docs/agents/tooling.md` — pass 3 under the
      gate material, plus a `## Gotchas` entry that agnix warnings do not fail the build and one of
      them is currently true. `docs/agents/skills-and-plugins.md` — a new skill raises the baseline,
      re-recorded in the same commit. Root `AGENTS.md` gets **nothing**: it is at 116/120 and the Task
      Router already routes self-tests and CI to `tooling.md`.
- [ ] 5. **Prove both directions, then revert** — the way `own-root-under-budget-and-router` proved
      its two failure modes rather than assuming them. Append a word to a `SKILL.md` → one `::error::`
      naming it, exit 1; delete a word → exit 0 plus the nudge; `pnpm format:fix` → word count
      unchanged. Then the full gate from the `scripts` block of `package.json`, with
      `bash scripts/lint.sh` in place of `pnpm lint`.
- [ ] 6. **Park the follow-up**: `.ai/backlog/templates-ship-the-docs-agents-contract.md`. Backlog
      goes 5 → 6 of 8.

## Anchors

- `scripts/validate-artifacts.sh:1-29` — the header comment naming both passes and the `NOTE:` about
  counts-not-schemas; `:52-58` is the backlog cap, the closest sibling to what pass 3 does.
- `templates/check-agents-docs.mjs:68-107` — the budget parser and `fail()`/`abs()`/`read()` helpers;
  the style task 1 copies, including "a budget nobody can parse is a budget nobody enforces".
- `scripts/tests/check-agents-docs.test.sh:1-45` — the fixture-under-`mktemp` harness, the
  `note_pass`/`note_fail` counters, the `command -v node` skip guard, and the reason a self-test must
  not read the live tree.
- `.inspirations/open-mercato/scripts/check-agents-md-budget.mjs:88-157` — `analyze()` and
  `formatReport()`: baseline-vs-measured, the failure text that names the resolution, and the
  `--update-baseline` semantics this change borrows (`:195-210`); its `chains` ratchet does not
  transfer — there are no nested `AGENTS.md` here.
- `.inspirations/open-mercato/scripts/agents-md-budget.baseline.json` — the `$comment`-carries-the-why
  shape task 1 copies, and the one place a budget states its derivation (`32768` = Codex
  `project_doc_max_bytes`).
- `docs/decisions/0006-delete-the-second-copy-and-cap-the-pile.md` and
  `0008-root-budget-replaces-the-gotcha-cap.md` — the thread this is the third act in; `0008`'s
  "Revisit when" and its cost test are what task 1 has to satisfy.
- `.ai/archive/eager-doc-size-budget/CHANGE.md` — the rejected hook version. Its `## Why rejected`
  names the revisit condition being invoked ("evidence that an eager file grew past the point of being
  read"), and its `## Decisions` is where the "AS-012 is a platform ceiling nobody hits and is not
  configurable" reading came from.
- `docs/agents/README.md:17-19` — the budget sentence task 4 rewrites, and `:19`'s "`docs/agents/*.md`
  are unbudgeted, which is where prose belongs", which stays true.
- `grateful-me-app-v2/scripts/check-agents-docs.mjs:49-52` — the `BUDGETS` map this repo's checker
  descends from, and the original of that same unbudgeted-topic-docs comment. Outside this repo;
  read-only reference.

## Notes

- **`dw-land` owes a decision record**, `docs/decisions/0009-*`: third act in the `0006` → `0008`
  thread. It must carry the threshold-free-by-construction argument, words-for-invariance, all four
  agnix findings with the 1752-token warning as the concrete proof, and the price — every
  skill-adding commit now also touches the baseline.
- **The plan this was shaped from** is `~/.claude/plans/czy-rozmiar-skilli-jest-polished-flamingo.md`.
  Two of its statements were already stale when this file was written, both because three commits
  landed mid-session: `.ai/backlog/` is at **5/8**, not 8/8 (so task 6 is possible at all), and the
  corpus re-measured to the same 13 243 at `8ec8d98`.
- **The re-measure at HEAD came back 13 243**, the same number this document carried — and the
  checker agrees with `cat skills/*/SKILL.md | wc -w` exactly, which is what makes the baseline's
  "reproduce it with" line true rather than aspirational. `wc -w` per file also sums to the same
  total, since prettier gives every `SKILL.md` a trailing newline.
- **This document was written in the shared checkout and the worktree branched before it was
  committed**, so the branch that was supposed to build it could not see it (`git status` in the
  worktree was clean, `.ai/work/` empty but for `.gitkeep`). It was copied in and claimed in `77d46db`.
  The untracked original is still sitting in the shared checkout and wants deleting by hand — a
  `dw-start` that shapes and worktrees in one session should commit the doc before branching.
- **`pnpm lint` is not the lint command here** — the `rtk` proxy hook rewrites it to an ESLint
  wrapper and it dies with `Command "eslint" not found` while the repo is green
  (`docs/agents/tooling.md:41-44`). Use `bash scripts/lint.sh`.
