---
change: gotcha-shape-and-speaking-gates
branch: gotcha-shape-and-speaking-gates
created: 2026-09-03
status: shaping
---

# Change — the promoted trap gets a shape, and the silent size gates speak

## Goal

`dw-land` promotes a trap as **one undated rule bullet of at most two lines** into the topic file
`AGENTS.md` routes to, and deletes the prose a new mechanism made redundant. Wherever a repo
declares a layer's budget, `templates/check-agents-docs.mjs` refuses a date-prefixed bullet in
`docs/agents/*.md` and a `CONTEXT.md` term over two lines, naming the file and the shape. `dw-doctor`
names every switched-off size gate with a copy-paste fix. This repo carries
`docs/agents/corpus.baseline.json` and the whole gate stays green.

## Decisions

- **Shape checks are gated behind the layer's budget declaration** — declaring the budget opts into
  its cap _and_ its shape rule; `0015`'s install-day protection and the flagship both survive.
- **The flagship adopts the ratchet and declares no budget** — `docs/agents/README.md:19` says
  `docs/agents/*.md` are unbudgeted (settled at `docs-diet` #38) and stays true as written.
- **Two declarations, two homes** — `Topic budget:` in `docs/agents/README.md` (governs many files,
  mirrors `Ceiling:`), `Term budget:` in `CONTEXT.md`'s own header (governs one, mirrors `Budget:`).
- **The caps enter as section 7 and the ratchet renumbers to 8** — the ratchet `process.exit(0)`s on
  `--update-baseline`, so a cap placed after it would let a re-record succeed over an oversized file.
- **Keep two regexes, not one** — lines-only for `Ceiling:`, lines/bytes for the rest; merging them
  loosens `Budget:`'s strictness, which `check-agents-docs.test.sh` explicitly pins.
- **Banning the date only works if "newest first" stays positional** — `docs/agents/README.md:39`
  requires that order, so the record and the shipped contract must say the order is positional.
- **`0022` supersedes `0015`** by narrowing "never shape" to "only where the repo opted in"; `0015`
  is flipped in two fields, never rewritten. `0008` stays untouched and is cited as evidence.
- **The eval fixture carries a real copy of the checker** plus a drift guard, so the fixture cannot
  silently rot against the template.
- **Eight tasks is above this lane's normal size**, kept whole because the plan is approved and each
  task is independently committable and leaves the repo green.
- **`dw-unslop` is out of scope** — its refusal to touch `docs/agents/*` is deliberate.

## Tasks

<!-- Convention: `- [ ]` pending, `- [x]` done — `dw-next` flips the box in the task's own commit.
A task that stopped being necessary keeps its box and gains `**skip:** <reason>`; every later
invocation reads that as not remaining. Never rename a task title. -->

- [ ] 1. The checker gains a shared declaration-prefix helper and a new section 7 — the two optional
      caps and the two shape checks, each silent when undeclared — with the ratchet renumbered to 8,
      `measured` hoisted to module scope, and cases in `scripts/tests/check-agents-docs.test.sh`.
- [ ] 2. `templates/agents-docs-README.md` states the two declarations, the trap's shape, the
      positional order, and the ratchet's same-commit bargain.
- [ ] 3. `skills/dw-land/SKILL.md` — three edits by replacement: the subtractive half of the lead-in,
      the `CONTEXT.md` bullet cap, and the gotcha's shape plus the baseline re-record.
- [ ] 4. `dw-doctor` reports each switched-off size gate as `report info` with a copy-paste fix, plus
      one sentence in its `SKILL.md` and cases in `scripts/tests/doctor.test.sh`.
- [ ] 5. `skills/dw-init/SKILL.md` — the `{"words": 0}` trap, the stale "empty `docs/agents/`" prose,
      the seed's position as the last action, and the forked-checker diff gate.
- [ ] 6. This repo seeds `docs/agents/corpus.baseline.json` and `docs/agents/README.md` gains one
      clause: unbudgeted but ratcheted.
- [ ] 7. Behaviour fixture `evals/fixtures/land-gotcha-shape/` plus case 3 in
      `evals/behaviour/dw-land.json`, the drift guard in `scripts/validate-artifacts.sh`, and the
      re-counted sentence in `evals/README.md`.
- [ ] 8. Record `0022`, flip `0015`'s two fields, patch-bump `dw-solo` and `dw-solo-setup` in both
      manifests, and re-record `scripts/skill-corpus.baseline.json`.

## Anchors

- `templates/check-agents-docs.mjs:94-134` — the `Budget:` parser and its strict lines/bytes regex;
  the prefix-finding half is what tasks 1 reuses, the regex is not merged.
- `templates/check-agents-docs.mjs:280-323` — section 6 `Ceiling:`, the opt-in-and-silent precedent:
  lines-only regex, `null` when the label is absent.
- `templates/check-agents-docs.mjs:337-341` — the "no baseline file means no check and no mention"
  comment to update, `BASELINE` const, and `measured` (the `README.md` exclusion) to hoist.
- `templates/check-agents-docs.mjs:385` — `process.exit(0)` under `--update-baseline`; why the caps
  must run before the ratchet.
- `skills/dw-land/SKILL.md:50` — "**replace, don't append**, deleting what this change made untrue",
  the lead-in the subtractive clause extends.
- `skills/dw-land/SKILL.md:54-55` — Vocabulary, "one line each; rewrite a line, never add a second".
- `skills/dw-land/SKILL.md:56-58` — Gotchas: the threshold with no shape, and the "build or backlog
  that instead of writing prose" half that never says what happens to the prose already there.
- `skills/dw-doctor/scripts/doctor.sh:379` — `group "Agent memory"`; `:541` a `report info` inside it
  and the insertion point's neighbour.
- `scripts/tests/check-agents-docs.test.sh:92` — `expect_silent_about`, how an opt-in is proved
  silent rather than merely passing; `:297` its existing use for the ceiling.
- `scripts/validate-docs.sh:169` — runs the shipped checker against this repo's own root, so every
  new check judges the flagship on day one.
- `docs/agents/README.md:19` — "`docs/agents/*.md` are unbudgeted, which is where prose belongs";
  `:39` — topic gotchas ordered "newest first".
- `docs/decisions/README.md:9` — `Ceiling: **80 lines** per record`, the cap record `0022` must meet.
- `evals/README.md:339` — "Nine cases across six of the twelve skills", the live count task 7
  re-measures from disk.
- `docs/agents/skills-and-plugins.md:40` — the patch bump in both manifests, kept identical.

## References

- `~/.claude/plans/kontekst-w-grateful-me-app-v2-curried-crescent.md` — the approved plan: the
  numbers behind each decision, the blast radius table, and why `0015` reopens but `0008` does not.
- `grateful-me-app-v2` PR #73 (branch `cut-the-agent-docs-to-a-budget`, **open, not merged**) — the
  consumer-side fix and the worked example; its fork hardcodes what this change keeps declarative.
- `docs/decisions/0015-the-shipped-checker-gates-size-never-shape.md` — the record `0022` supersedes.
- `docs/decisions/0008-root-budget-replaces-the-gotcha-cap.md` — its revisit condition is met by a
  consumer's 371-line `tooling.md`; cited as evidence, not reopened.
- `docs/decisions/0020-the-behaviour-tier-returns-as-measurement.md` — the dated result row task 7
  appends.
- `skills/dw-land/references/decision-record.md` — already says `CONTEXT.md` is "terms only, no
  rationale", but in `## Superseding`, where nothing writing a gotcha would read it.

## Notes

- Version contingency: `dw-solo` 0.7.0 and `dw-solo-setup` **0.2.3** on disk (the hygiene change took
  0.2.3), so this change is 0.7.1 and **0.2.4**. Re-derive at task 8 rather than trusting this line.
- `rtk`'s git filter served stale `git status`, `git log` and `git diff` for this repo — a landed,
  merged change still read as an uncommitted branch. Verify git state with `rtk proxy git …`.
