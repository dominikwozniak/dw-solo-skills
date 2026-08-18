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
- [ ] 2. Rewrite `docs/agents/skills-and-plugins.md` — indirection rationale, the explicit-only rule
      and its delegation cost, the vendored/fork enumerations, both numbered checklists intact in
      substance (CI enforces them), six gotchas compressed.
- [ ] 3. Rewrite `docs/agents/README.md` — the three-tier table, what-goes-where, the budget's
      "editorial, not a harness ceiling" point, gotchas-live-here, the router rules, the same-commit
      triggers, what `validate:docs` enforces, the deliberately-not-used list.
- [ ] 4. Twelve descriptions to ~one sentence — drop the trigger lists, the "Prefer this over…"
      tails and the mode recaps `argument-hint` already carries. `pnpm eval:routing` after each
      batch; land at rank-1 ≥ 67 with no description pair ≥ 0.5.
- [ ] 5. Size discipline at the source — goal ≤ ~5 lines, one-line decisions, a finding is one line
      in `## Notes`, details stay in the diff — into `dw-shape` step 2 and `dw-next` step 4, mirrored
      in `references/CHANGE.md`. Re-record the corpus baseline in this same commit and assert it fell.
- [ ] 6. Patch-bump all three plugins in `marketplace.json` and each `plugin.json`, kept equal, then
      run every script in `package.json`'s `scripts` block.

## Anchors

- `docs/agents/README.md:52-72` — the gotchas that govern this change: moving prose conserves entries
  while losing content, and a line target buys itself out of the content.
- `scripts/skill-corpus.baseline.json` — `words: 15200`; pass 3 of `validate:artifacts` reads it.
- `docs/agents/skills-and-plugins.md:106` — editing a `description` shifts every term's idf, so an
  unrelated skill can lose rank-1. Run the eval; never leave a description wrong to avoid it.
- `evals/routing.ts`, `evals/cases/*.json` — 7 case files, model-invocable skills only.

## Notes

- Rule preservation is verified per file, not by reading the diff: extract the old rule list, rewrite,
  re-extract, diff the lists, then slide an 8-gram word-stream window over the old text and judge every
  window missing from the new one as narration or content.
- Baseline at shape time: rank-1 68% (21/31), one point above the floor.
- `pnpm lint docs/agents/tooling.md` reports a false frontmatter error — that directory is excluded
  from the project walk; judge with the bare `pnpm lint`.
- `proseWrap: "preserve"` means the format gate never checks prose width; rewrap whole paragraphs and
  check with `grep -nE '^.{108,}'`.
- The 8-gram window is too noisy on a rewrite this heavy (98 runs, nearly all reworded prose). A
  **fact-token diff** — every backticked span, path, flag, number and error string in the old file absent
  from the new — is the instrument that works; both scripts sit in the scratchpad.
- tooling.md: 3 103 → 2 692 words, one fact dropped on purpose (`check-decisions.test.sh`, the name of a
  script already deleted, which the old entry itself said the shape outlives). A rule-dense file diets
  about 13%; a bigger number here would mean rules went with the words.
