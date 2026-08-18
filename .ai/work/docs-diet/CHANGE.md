---
change: docs-diet
branch: docs-diet
created: 2026-08-17
status: building # shaping | building | landed
---

# Change — the doc layer and the skill descriptions say the same things in fewer words

## Goal

Three `docs/agents/` files and twelve `SKILL.md` descriptions carry every rule this repo has learned,
wrapped in narration. Cut the words, keep every rule: each lesson and gotcha survives as 1–3
sentences plus a pointer, each description reads as ~one sentence with `eval:routing` still ≥ 67, and
the size rule lands in `dw-shape` and `dw-next` so the verbosity stops re-entering at the source.
Known worked when the corpus baseline has **fallen** below 15 200 and the full gate is green.

## Decisions

- One change, not three — one goal, one version bump, one gate run; asked and settled at shape time.
- All 12 skills, not the seed's "11" — that count predates `dw-prune`.
- Explicit-invoke descriptions keep a bare `Explicit-invoke only.`; the trigger lists go.
- A rank-1 drop below 67 is fixed in `evals/cases/*.json` prompts, never by restoring words.
- No line target for the rewritten docs — "essence" is the bar; `docs/agents/*.md` are unbudgeted.

## Tasks

- [x] 1. Rewrite `docs/agents/tooling.md` to essence — the three passes and their exit-2 rules, the
      hook table, the `jq` no-op, the four grep-read bullets and the `none` sentinel, and every
      gotcha at 1–3 sentences + pointer.
- [x] 2. Rewrite `docs/agents/skills-and-plugins.md` — indirection rationale, the explicit-only rule
      and its delegation cost, the vendored/fork enumerations, both numbered checklists intact in
      substance (CI enforces them), six gotchas compressed.
- [x] 3. Rewrite `docs/agents/README.md` — the three-tier table, what-goes-where, the budget's
      "editorial, not a harness ceiling" point, gotchas-live-here, the router rules, the same-commit
      triggers, what `validate:docs` enforces, the deliberately-not-used list.
- [x] 4. Twelve descriptions to ~one sentence — drop the trigger lists, the "Prefer this over…"
      tails and the mode recaps `argument-hint` already carries. `pnpm eval:routing` after each
      batch; land at rank-1 ≥ 67 with no description pair ≥ 0.5.
- [x] 5. Size discipline at the source — goal ≤ ~5 lines, one-line decisions, a finding is one line
      in the notes section, details stay in the diff — into `dw-shape` step 2 and `dw-next` step 4,
      mirrored in `references/CHANGE.md`. Re-record the corpus baseline in this same commit.
- [x] 6. Patch-bump all three plugins in `marketplace.json` and each `plugin.json`, kept equal, then run
      every script in `package.json`'s `scripts` block.

## Anchors

- `docs/agents/README.md` gotchas — moving prose conserves entries while losing content, and a line
  target buys itself out of the content.
- `scripts/skill-corpus.baseline.json` — was `words: 15200`; pass 3 of `validate:artifacts` reads it.
- `docs/agents/skills-and-plugins.md` — editing a `description` shifts every term's idf, so an unrelated
  skill can lose rank-1. Run the eval; never leave a description wrong to avoid it.
- `evals/routing.ts`, `evals/cases/*.json` — 7 case files, model-invocable skills only.

## Notes

- Rule preservation per file: extract the old rule list, rewrite, re-extract, diff the lists, then run a
  fact-token diff (scripts in the scratchpad).
- The 8-gram word-stream window drowns in noise when a rewrite rewords every sentence — 98 runs on
  tooling.md; the fact-token diff is what reads a rewrite that heavy.
- tooling.md 3 103 → 2 692 words, one fact dropped on purpose: `check-decisions.test.sh`, a script
  already deleted.
- skills-and-plugins.md 1 777 → 1 657 with zero facts dropped; the two checklists are pure rule.
- README.md nets 1 338 → 1 338: the narration cut paid for the new fact-token gotcha.
- Shortening the descriptions dropped rank-1 to 55% before choosing the vocabulary back in reached 71%.
- `dw-git` gained the synonyms `evals/README.md` named as its weakness; `dw-next` gave up "pick back up"
  so `dw-shape` keeps its checklist prompts.
- One `evals/cases` prompt was rewritten, only for gate 2 (neither side scored) — not to buy the number.
- A `description` is a routing surface, so shortening one is a measurement, not an edit.
- `pnpm lint docs/agents/tooling.md` reports a false frontmatter error; judge with the bare `pnpm lint`.
- `proseWrap: "preserve"` hides prose width from the gate — check with `grep -nE '^.{108,}'`.
- A script that splits this file at its first `## Notes` truncates it, because a task can quote that
  heading inline — it ate task 6 and the anchors here. Split on the heading at line start, or don't.
