---
change: shaping-scales-to-a-large-change
branch: shaping-scales-to-a-large-change
created: 2026-09-06
status: building # shaping | building | landed
---

# Change — dw-grill asks in rounds, and dw-shape carries a large change in one doc

## Goal

The shaping half of the loop scales to a large change without a second artifact type or a second
pass. You know it worked when:

- `/dw-grill` asks five questions a round; after the fifth it plays back what is decided, what is
  still open with the default it would assume, and offers another round · shape now · split, then
  waits — and an idea spanning several goals is named as such before question one.
- `/dw-shape` sizes depth by content: tasks, anchors and references stay one line each, goal and
  decisions take the lines a decision or a risk needs; Large stays one `CHANGE.md` with
  `## Out of scope` and, where a line cannot hold it, a sibling file named in `## References`;
  every count and consumer a task names is grep-confirmed before it is written.
- The template carries `## Out of scope`, the `(assumed)` marker and the sibling hint; `dw-next` reads
  a sibling the doc names; `dw-land` removes siblings at archive so the receipt stays one file.
- Behaviour cases exist for the pause, the split exit and a large shape; the gate is green with the
  skill-corpus baseline re-recorded and `dw-solo` and `dw-solo-setup` bumped in both manifests.

## Decisions

- **Five per round, not a session cap** — the number came verbatim from dw-skills (`8e5af44`) and was
  never argued here; every inspiration defines what happens when the budget runs out, ours defined
  nothing. Rounds keep the anti-interrogation property (spec-kit's Deferred list, gstack's rounds,
  addyosmani's "several rounds, then step back").
- **Sibling files, not a longer doc and not a second artifact type** — the mechanism exists already:
  `HANDOFF.md` sits beside `CHANGE.md`, `dw-next` reads every `## References` line, `dw-land` moves the
  folder. The receipt stays one file (`0018`) because `dw-land` removes siblings at archive.
- **Depth by content, not by line count** — the re-read-on-every-resume cost is real, so tasks,
  anchors and references stay one line; goal and decisions grow only for a decision or a risk, never
  for template completeness (gstack: "no page cap — extra length must come from genuinely open
  questions").
- **The standalone "offer to cut" goes** — refused 3 of 3 times in the archive; the count test already
  asks the split question, and Large is sizing, not splitting
  (`.ai/archive/2026-08-18-backlog-discipline-one-change-bias-and-dw-prune/CHANGE.md:123-125`).
- **`## Out of scope` is required beyond small** — the left-out list's "dropped" fate had no home in the
  doc; every inspiration carries the section and Anthropic's own guidance names it.
- **No decision record** — reversing either choice is a prose edit, so the hard-to-reverse leg of
  `skills/dw-land/references/decision-record.md` fails. `dw-land` re-checks at close.
- **One change** — one goal, one bump per plugin, one template; the two skills are the two halves of
  the same step.

## Out of scope

- Build-time Notes discipline — the 100–150-line build logs in the archive are a `dw-next` compliance
  problem, not a shaping one. Backlog if it recurs after this lands.
- A confidence number per question (addyosmani `interview-me`) — the round playback buys the same
  legibility for less ceremony.
- Risk-first task ordering (addyosmani, pstack) — a `dw-next` ordering concern, a separate goal.
- mattpocock's objection to file-path anchors going stale — Anchors stay; nothing here shows the cost.
- Paid behaviour runs (`node evals/behaviour.ts --go`) — the change ships the cases and the free plan;
  spending is the user's call.

## Tasks

<!-- Convention: `- [ ]` pending, `- [x]` done — `dw-next` flips the box in the task's own commit.
A task that stopped being necessary keeps its box and gains `**skip:** <reason>`; every later
invocation reads that as not remaining. Never rename a task title. -->

- [x] 1. **`dw-grill` asks in rounds.** `skills/dw-grill/SKILL.md`: a scope check before question one
      (several independent goals → name the pieces, grill the first); step 2's "at most five" becomes
      "five a round", and the assume-and-say-so rule extends from repo facts to decisions below the
      cut; a new **Pause at five** step before any sixth question — playback, open items each with a
      default and the cost of a wrong one, three ways forward, wait; a retry of a question takes no
      slot; the close playback gains **assumed** and **deferred** lists. `description` says rounds.
      `README.md:73` drops "max five questions". `pnpm eval:routing` after — the description shifts idf.
- [x] 2. **`dw-shape` sizes by content and carries Large.** `skills/dw-shape/SKILL.md`: step 1 gains
      the grep-confirm rule for counts and consumers; step 2 replaces "Every size writes short …" with
      the content rule and rewrites **Large** (say so, run the count test, one doc with
      `## Out of scope`, sibling files for detail); a **Sibling files** paragraph — what they hold, where,
      named in `## References`, most changes have none, `dw-land` removes them; step 4's fates become
      into the change · backlog · out of scope, and the grill's assumed/deferred lists land as
      `(assumed)` decisions and out-of-scope lines.
- [ ] 3. **The template.** `skills/dw-shape/references/CHANGE.md`: `## Out of scope` after
      `## Decisions` with a row that carries its own why; the `(assumed)` hint under Decisions; the
      sibling hint under References; Goal's "~5 lines at most" becomes one line per observable result.
- [ ] 4. **The readers, the payload and the glossary.** `skills/dw-next/SKILL.md:17` names sibling files
      among what it reads; `skills/dw-land/SKILL.md:68-71` `git rm`s every sibling at archive
      (`HANDOFF.md` included — closing the drift where `templates/work-README.md:38-39` credits `dw-land`
      with a removal its body never had); `templates/work-README.md` layout and lifetimes gain the
      sibling line; `docs/agents/change-artifacts.md:8` says the folder may hold one;
      `CONTEXT.md:122` lets a Reference point at a file beside the doc.
- [ ] 5. **Behaviour cases.** New `evals/behaviour/dw-grill.json` with fixture
      `evals/fixtures/grill-round-pause/` — case 1 carries five answered questions in the prompt and
      expects the pause, not a sixth; case 2 is a three-goal idea and expects the pieces named and one
      grilled first. `evals/behaviour/dw-shape.json` case 3 with `evals/fixtures/shape-large-change/`
      on a feature branch, planting a count a naive read gets wrong — expects `## Out of scope`,
      numbers matching disk, a sibling (if any) named in References and repeating nothing, and one
      change written rather than a cut offered. `node evals/behaviour.ts` lists all three.
- [ ] 6. **Bumps, baseline, gate.** `dw-solo` 0.8.0 → 0.8.1 and `dw-solo-setup` 0.4.0 → 0.4.1 in
      `.claude-plugin/marketplace.json` and each `plugin.json`; `node scripts/check-skill-corpus.mjs
--update-baseline`; every command in `package.json`'s `scripts` block green.

## Anchors

- `skills/dw-grill/SKILL.md:5-6` — the description's "at most five"; `:21-24` step 2, the cap and the
  assume-and-say-so rule; `:29-33` step 5, the close playback the assumed/deferred lists join.
- `skills/dw-shape/SKILL.md:45-52` — step 1, where the grep-confirm rule goes; `:54-61` the ladder and
  the "Every size writes short" line being replaced; `:75-78` step 4's read-back and fates.
- `skills/dw-shape/references/CHANGE.md:10-21` — Goal and Decisions hints; `:38-43` References.
- `skills/dw-next/SKILL.md:17-19` — what it reads; `:37` the References bullet that already reads them.
- `skills/dw-land/SKILL.md:68-71` — the Archive bullet.
- `templates/work-README.md:9-18` — the layout block; `:37-40` the `HANDOFF.md` lifetime to mirror.
- `docs/agents/change-artifacts.md:8` — "One folder per change".
- `CONTEXT.md:122-125` — the **Reference** glossary entry.
- `README.md:73` — the `dw-grill` router row.
- `evals/behaviour/dw-shape.json` and `evals/fixtures/shape-two-scopes/` — the case and fixture shape
  to copy; `.eval/branch` puts a fixture on a feature branch.
- `.claude-plugin/marketplace.json:13,21` · `plugins/dw-solo/.claude-plugin/plugin.json:3` ·
  `plugins/dw-solo-setup/.claude-plugin/plugin.json:3` — 0.8.0 and 0.4.0 today.
- `scripts/skill-corpus.baseline.json` — the ratchet task 6 re-records.

## References

- `~/.claude/plans/zastanawiam-sie-nad-dw-shape-eager-metcalfe.md` — the approved plan with the
  research behind every decision above; outside the repo.
- `.inspirations/github-spec-kit/templates/commands/clarify.md:129-180,233,283` — the five-question
  loop with a Deferred list, retries that take no slot, and re-entry after planning.
- `.inspirations/mattpocock-skills/docs/productivity/grilling.md:66-67` — why a cap was rejected, and
  "break the work up and grill the pieces".
- `.inspirations/gstack/office-hours/sections/design-and-handoff.md:39-44` — the content budget.
- `.inspirations/addyosmani-agent-skills/skills/spec-driven-development/SKILL.md:71-82` — the
  assumption dump the extended assume-and-say-so rule copies.
- `.ai/archive/2026-08-12-de-ratchet-the-solo-lane/CHANGE.md` and
  `.ai/archive/2026-08-14-the-doc-layer-says-one-thing-once/CHANGE.md` — the large changes whose Notes
  record the wrong shape-time counts task 2's rule answers.
- https://code.claude.com/docs/en/best-practices — "Let Claude interview you": keep interviewing until
  everything is covered, and a spec states what is out of scope.

## Notes

- Written in the new template shape on purpose: this doc carries `## Out of scope` before task 3 adds it.
- Unexercised until reinstall — the session serves the cached plugin, so verify the canon text by hand.
