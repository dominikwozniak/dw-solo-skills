---
change: dw-grain-audits-reinvented-and-excess-code
branch: dw-grain-audits-reinvented-and-excess-code
created: 2026-08-25
status: building
---

# Change — `dw-grain`, an off-loop audit for the code the gate passes

## Goal

A 14th skill, `skills/dw-grain/SKILL.md`, explicit-invoke in `dw-solo-extras`: run after
implementation, it reads wide, judges only the new code, and hands back one short table — a helper
reinvented beside its canonical home, a wrapper with one caller, config for a case that does not
exist, a pattern the neighbouring files do differently. It worked when a run over a real branch
yields a table whose every row is a deletion or a reuse, nothing changes until rows are named, and a
pattern the project's own conventions bless is absent from it.

## Decisions

- Report and fix are two phases, the first read-only — you read the table and name rows; fixing is a
  separate step, never the same breath.
- Reads wide, judges narrow — whole touched files, neighbours and the project's declared conventions
  as input; every row has to be fixable by changing the new code.
- Scope from git's merge-base, narrowed by `$ARGUMENTS` — no `.ai/` dependency, so it runs in a repo
  without the lane, on a path or an old PR.
- A new skill rather than a third axis in `dw-check` — different moment, different cost, different
  output; and the boundary goes inside the step, because an intro sentence did not hold it last time.
- KISS wins the tie, made structural rather than stated — every category's remedy is a deletion or a
  reuse, so no category is able to propose an abstraction.
- `dw-check`'s `**Next:**` line names it, breaking the pattern the three existing extras follow.
  `0012`'s reasoning outweighs that consistency: an option you have to remember goes unused, and a
  skill nobody reaches is not a delivered skill. It costs a `dw-solo` bump as well.
- `dw-grain` over `dw-simplify`: the built-in `/simplify` owns that word and does the opposite,
  applying fixes with no table and no choice point.

## Tasks

- [x] 1. `skills/dw-grain/SKILL.md` — the extras anatomy: H1 as a claim, the reads-and-writes
      section, a numbered workflow, a fenced table template, `**Next:**`. Five categories, the
      quote-or-drop gate, the suppression layer, the `dw-check` boundary written into step 3, and
      `$ARGUMENTS` named where scope resolves. Run `pnpm eval:routing` the moment the frontmatter
      exists, before writing the body.
- [x] 2. Ship it — the `plugins/dw-solo-extras/skills/dw-grain` symlink, the README Off-loop row with
      `⭑`, the name in the explicit-only sentence, the badge `skills-13` → `skills-14`, the extras
      line in `AGENTS.md`, and `dw-grain` on `dw-check`'s `**Next:**` line.
- [x] 3. Versions — extras `0.1.8` → `0.1.9` and `dw-solo` `0.5.1` → `0.5.2`, each identical in both
      manifests; rewrite the extras plugin's "Three today:" clause to four; extend the marketplace
      `keywords`.
- [x] 4. `node scripts/check-skill-corpus.mjs --update-baseline`, then the full gate.

## Anchors

- `evals/routing.ts:447-452` — a case file for a `disable-model-invocation` skill is a hard fail, so
  `dw-grain` gets none.
- `evals/routing.ts:56-61` — explicit skills stay in the corpus but outside the rank-1 population, so
  the risk is the idf shift, never `dw-grain`'s own score.
- `skills/dw-check/SKILL.md:82` — "a pattern used once elsewhere in this repo beats a better pattern
  used nowhere in it": the one bullet `dw-grain` gives a procedure to.
- `skills/dw-check/SKILL.md:92-98` — the lead-judgment filter already lives here; `dw-grain` gets its
  own structural filter instead of a second copy of this prose.
- `skills/dw-check/SKILL.md:14` — "never grows a reviewer of its own"; a fixed-category auditor has
  to stay on the near side of that line too.
- `skills/dw-check/SKILL.md:110` — the `**Next:**` line `dw-grain` joins. Check 4 resolves every
  `dw-*` token there against disk, so this edit cannot land before task 1.
- `skills/dw-unslop/SKILL.md` — the extras anatomy to copy, and the nearest namespace: `dw-grain`
  must not borrow "slop", "tells" or "flatten".
- `README.md:9`, `README.md:52`, `README.md:86-93` — the badge, the explicit-only sentence, the
  Off-loop table.
- `plugins/dw-solo-extras/.claude-plugin/plugin.json` — `0.1.8`, and the "Three today:" clause that
  enumerates all three.

## References

- `.inspirations/cursor-plugins/pstack/skills/interrogate/references/code-quality-review.md` — the
  best-written source for the categories: code judo, reuse the canonical helper, keep logic in the
  canonical layer.
- `.inspirations/gstack/review/specialists/maintainability.md` — the closest checklist: DRY, dead
  code, module boundaries.
- `.inspirations/gstack/review/SKILL.md` — the pre-emit verification gate: quote the motivating line
  or the finding does not count.
- `.inspirations/gstack/review/design-checklist.md` and
  `.inspirations/mattpocock-skills/skills/engineering/code-review/SKILL.md` — repo docs as a
  suppression layer, and "skip anything tooling already enforces".
- `.inspirations/addyosmani-agent-skills/skills/code-simplification/SKILL.md` — the nearest dedicated
  skill anywhere, and the counter-example: it applies fixes and defines no report at all.
- `.inspirations/github-spec-kit/templates/commands/analyze.md` — the table shape, over specs rather
  than code.
- `.ai/archive/2026-08-20-harvest-pstack-into-the-solo-lane/CHANGE.md` — the prior harvest from the
  same source; its `lead-judgment` and `blast-radius` takes already sit in `dw-check` and `dw-land`.

## Notes

- The routing floor has one point of headroom: rank-1 68%, `--min-rank1 67`, 21/31 cases. One lost
  case is 64% and red. Diagnose with `node evals/routing.ts --explain "<lost prompt>" --top 4` and
  trade the colliding word out of `dw-grain`'s description, not out of the incumbent's.
- A skill declaring `argument-hint` must reference `$ARGUMENTS` in its body, or agnix's pre-commit
  autofix appends a bare `$ARGUMENTS` line after `**Next:**`.
- A shipped `SKILL.md` must not cite this repo's decision numbers or `docs/agents/` paths — write
  repo-specific mechanisms as conditions instead.
- The gate is red mid-train: `validate:docs` check 2 from task 1 until task 2, `validate:artifacts`
  pass 3 from task 1 until task 4. That is the router and the ratchet working, not breakage.
- `AGENTS.md` sits at 116 of its 120 lines.
- `.inspirations/` is gitignored, so a `dw-start` worktree will not have it — build this in the main
  tree, or read those paths through the main tree's absolute path.
- The headroom held: with `dw-grain`'s description in the corpus, rank-1 stays 68% / 21-31 and the
  closest description pair is 0.165, so no word had to be traded.
- `dw-grain` measures 1325 words, above every existing extra (`dw-unslop` 849) — the five categories,
  the three-part gate and the table template each carry a rule, so the size is the content. Nothing in
  it is branch-only, so there is no block to shed to `references/` the way `dw-unslop` shed its catalog.
- An audit against `.inspirations/mattpocock-skills/skills/productivity/writing-for-agents/` bought
  three edits: step 2 gained an exhaustiveness bar (flat reference needs one as much as a sequence
  does), the fourth category became the leading word **Speculative** so all five are single tokens
  that recruit priors, and step 1 stopped restating the scope the reads section already fixes.
- That same source says a `disable-model-invocation` description should be a human-facing one-liner
  with triggers stripped. Not taken: all three existing extras end theirs "Explicit-invoke only." after
  a full description, and `dw-grain`'s own **Drift** rule gives the neighbours the tie.
