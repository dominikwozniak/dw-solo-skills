---
change: decisions-get-a-gate-and-a-finder
branch: decisions-get-a-gate-and-a-finder
created: 2026-09-08
status: building # shaping | building | landed
---

# Change — a decision record is written only where the bar is read, and found without scanning the folder

## Goal

- `skills/dw-next/SKILL.md` no longer instructs a record to be written; it instructs a nomination,
  and the nomination lands in `CHANGE.md`'s `## Decisions` in the task's own commit.
- `dw-land` judges every nomination against the three legs before any record exists, and a
  nomination it rejects is still readable in the archived receipt with the leg that failed.
- A record declares `touches:` and `rule:`, and `dw-shape` reaches the records governing a path by
  one grep over frontmatter instead of reading the folder.
- `agents/dw-decisions.md` exists, is read-only by its tool list, and answers three questions —
  which records govern this path, does this nomination clear the bar, which records in the folder
  no longer hold.
- `pnpm validate:manifests`, `validate:docs`, `validate:artifacts`, `validate:versions` and
  `eval:routing` stay green, and `@dw-solo-extras:dw-docs-drift` still routes to the drift agent
  rather than to the new one.

## Decisions

- **One `CHANGE.md` for two goals** — the scope count is two (the gate, and the finder: either
  could be dropped without rewriting the other, and their consumers differ). Asked and declined;
  recorded here so it is not reopened. The agent is the reason: its `judge` mode serves the gate and
  its `ask` mode serves the finder, and splitting would build the same file twice.
- **The gate is single, and it is `dw-land`** — `dw-next` nominates, never promotes. The mechanical
  cause of the 47-record folder is that the writer has no `references/` at all, so it cannot read
  the bar it is told to apply; and leg 1, "hard to reverse", is unanswerable at task 2 of 6.
- **`dw-land` calls the agent only when there is at least one nomination** — zero nominations is
  most closes, and it should cost nothing.
- **`dw-land` degrades to its own judgement when the agent is not installed** (assumed) — `dw-land`
  ships in `dw-solo`, the agent in `dw-solo-extras`, and `0025:12` put the doc-layer reviewer
  outside the spine precisely because "the loop grows no reviewer of its own". An optional call
  keeps `dw-solo` standalone and keeps that decision intact; a mandatory one would make `dw-solo`
  depend on `dw-solo-extras`. Extras already describes itself as installed alongside `dw-solo`.
- **`touches:` and `rule:` are editorial, not validated** — the plan assumed the shipped checker
  would resolve `touches:` paths. It cannot: `docs/decisions/README.md:22` records that nothing
  enforces the record contract mechanically any more, `templates/check-agents-docs.mjs:9` gates
  size and nothing else over that folder, and `0022` grants a layer exactly one shape rule per
  declared budget — for records that is `Ceiling:`, a size. Adding a path check is a second shape
  rule and reopens `0022`.
- **A stale `touches:` path is a report, not a failure** — `dw-docs-drift` already walks
  `docs/decisions/` for named referents (`agents/dw-docs-drift.md:27`) and reports a path as dead
  or absent. That covers the decay without a gate and without new machinery.
- **No `evals/cases/` entry for the agent** (assumed) — `evals/routing.ts:387` requires a matching
  `skills/<name>/SKILL.md`, and `0025:23-25` states an agent sits outside every measurement here.
  What this change owes instead is that the two agent descriptions do not compete for one prompt,
  which is `0025`'s own revisit trigger firing.
- **`rule:` is a norm, not a summary** — one line, imperative, what a reader is bound to.
  `templates/decisions-README.md:15` refuses a second copy of the contract; a `summary:` would be a
  third rendering of the slug and `## Decision`.
- **`dw-next` greps `touches:` directly rather than asking the agent** — a subagent paraphrases,
  and a paraphrased prohibition is worse than none. The agent's `ask` mode answers open questions;
  the verbatim norm comes from the file.
- **The agent carries the method, never the bar** (nominated) — `dw-decisions` ships in
  `dw-solo-extras` while the bar lives in `dw-solo`'s `references/decision-record.md`, so it
  cannot read the contract at runtime and a copy in its prompt is the copy that goes stale. A
  caller hands the legs over verbatim; invoked directly the agent looks for them and, finding
  none, says where it looked and stops. This constrains task 6.
- **The archive receipt keeps a rejected nomination** (nominated) — this narrows `0018`, which
  deletes `## Decisions` wholesale. Its own reasoning grants the exception: it deletes what the
  promotion step already harvested and keeps what found no durable home, and a rejection is the
  second kind. `0018`'s revisit trigger is a session reaching for a deleted section, so this is a
  supersession candidate rather than an edit to it.
- **A nomination is a marked line in `## Decisions`, not a new section** (assumed) — `dw-shape`
  already marks a line `(assumed)` in that section, so the shape exists and `dw-next` already
  re-reads the section on every resume.
- **Read-only is carried by the tool list, not by a clause** (assumed) — `tools: Read, Grep, Glob`
  and no `Write`, the same way `0025` fixed it for `dw-docs-drift`.
- **Backfill is lazy** (assumed) — the fields are expected of a record written from now on. Nothing
  requires them of the 47 existing records, and none of them is rewritten.

## Out of scope

- **Extending `dw-docs-drift`** — its contract forbids judging prose (`:46-47`) and inventing
  thresholds (`:95-96`); a decision auditor does exactly both.
- **An agent on the application side** (`grateful-me/.claude/agents/`) — one copy per consumer repo,
  drifting from the versioned `references/decision-record.md`.
- **An `INDEX.md` under `docs/decisions/`** — refused on purpose by `templates/decisions-README.md:7`.
- **Rewriting any of the 47 existing records in `grateful-me`** — append-only, and the audit reports
  rather than repairs.
- **A ceiling on records per change** — arbitrary, and it would drop the second real decision of a
  change that genuinely took two.
- **Collision detection as a CI gate** — the `audit` mode is on demand; a judgement over prose has
  no deterministic result to gate on.
- **`dw-check` reading nominations** — a separate consumer, never discussed.
- **Nominating a glossary term or a gotcha through the same mechanism** — only decisions need the
  bar; a term and a trap have no legs to fail, so a nomination step would buy nothing.
- **Running the audit over `grateful-me`** — that is a session after this lands, not a task here.

## Tasks

<!-- Convention: `- [ ]` pending, `- [x]` done — `dw-next` flips the box in the task's own commit.
A task that stopped being necessary keeps its box and gains `**skip:** <reason>`; every later
invocation reads that as not remaining. Never rename a task title. -->

- [x] 1. `agents/dw-decisions.md` — the contract for three modes (`ask`, `judge`, `audit`),
      `tools: Read, Grep, Glob`, `model: sonnet`; symlink at `plugins/dw-solo-extras/agents/`,
      listed by path in the `agents` array, extras version bumped.
- [x] 2. Sharpen both agent descriptions so `dw-docs-drift` keeps referent-existence prompts and
      `dw-decisions` keeps decision prompts — `0025`'s revisit trigger fires the moment a second
      agent lands.
- [x] 3. `skills/dw-land/references/decision-record.md` — `touches:` and `rule:` in the frontmatter
      shape, with what each is for and the note that neither is machine-checked.
- [x] 4. `templates/decisions-README.md` — the two fields for a consumer repo, still no index and
      still no second copy of the bar.
- [x] 5. `skills/dw-next/SKILL.md` — the promote bullet becomes a nominate bullet, plus the narrow
      `touches:` grep for a file the change doc did not anchor.
- [x] 6. `skills/dw-land/SKILL.md` — the gate: judge every nomination, call the agent when there is
      one and it is installed, and stop claiming the promotion already happened at `:49`.
- [x] 7. `skills/dw-land/SKILL.md` — the receipt keeps a rejected nomination with its failing leg;
      `:71` currently deletes the section it lives in.
- [x] 8. `skills/dw-shape/SKILL.md` (and `dw-grill`'s read step) — grep `touches:` over the anchors'
      paths and carry the matching `rule:` into `## Decisions`; the agent's `ask` mode for an open
      question.
- [x] 9. Green: `pnpm validate:manifests`, `validate:docs`, `validate:artifacts`,
      `validate:versions`, `eval:routing`, `format`; both plugin versions bumped.

## Anchors

- `agents/dw-docs-drift.md:1-12` — the frontmatter and description shape a sibling agent copies.
- `agents/dw-docs-drift.md:27` — `docs/decisions/` is already a scaffolded target of the drift audit.
- `agents/dw-docs-drift.md:46-47,95-96` — the two clauses that make this a second agent, not an extension.
- `plugins/dw-solo-extras/.claude-plugin/plugin.json:9` — `agents` is an array of file paths.
- `scripts/validate-manifests.sh:191-210` — an agent's canon-and-symlink rule, enforced.
- `skills/dw-next/SKILL.md:18` — the read step, which does not include `docs/decisions/`.
- `skills/dw-next/SKILL.md:62-64` — "Promote as you decide", citing a bar it cannot read.
- `skills/dw-land/SKILL.md:49` — "most closes only sweep", the other half of the cause.
- `skills/dw-land/SKILL.md:53-54` — the Decisions bullet of the closing sweep, where the gate goes.
- `skills/dw-land/SKILL.md:71` — trimming to a receipt deletes `## Decisions` wholesale.
- `skills/dw-shape/SKILL.md:48` — `docs/decisions/` is read at plan time, with no stated method.
- `skills/dw-land/references/decision-record.md:18-45` — the bar and the frontmatter to extend.
- `templates/decisions-README.md:7,15` — no index on purpose; no second copy of the contract.
- `templates/check-agents-docs.mjs:9` — over `docs/decisions/` it checks size and nothing else.
- `evals/routing.ts:387` — a case file requires a matching `SKILL.md`, so an agent gets none.

## References

- `~/.claude/plans/podczas-pracy-przy-zuzyciu-keen-map.md` — the `dw-grill` playback this doc is
  shaped from, with the decision-by-decision reasoning; tasks 1, 5, 6 and 8 lean on it.
- `docs/decisions/0025-the-doc-layer-reviewer-is-an-agent-not-a-skill.md` — why an agent and not a
  skill, why it sits in extras, and the revisit trigger task 2 answers.
- `docs/decisions/0022-a-declared-budget-switches-on-its-layers-shape-rule.md` — one shape rule per
  declared budget; the reason `touches:` is not validated.
- `docs/decisions/0013-a-validator-over-git-history-gets-a-self-test.md` — why this change adds no
  validator: one would owe a self-test, and there is nothing deterministic to test.
- `/Users/dominik.wozniak/workspace/private/byarcadia-app/grateful-me-app-v2/docs/decisions/` — the
  47-record folder that prompted this; `0018`/`0032` are the known collision the `audit` mode has to
  surface once it exists.

## Notes

- Built by the rule this change introduces: the bar-carrying call is nominated in `## Decisions`, not promoted mid-build. Cheapest way to test the mechanism is to use it.
- `validate-manifests.sh` needs three things per agent, not one: the symlink, the exact `../../../agents/<name>` target, and the `"./agents/<name>"` string in the `agents` array.
- Splitting the two descriptions found a duplicated finding: `audit` reported dead `touches:` paths, which `dw-docs-drift` already walks the same folder for. Dropped from `dw-decisions`.
- The boundary is NAMES vs MEANING: drift asks whether what a doc cites exists, `dw-decisions` asks what the records decide. Both descriptions now say it, since a description is the only routing control an agent has (`0025`).
- Task 4 shrank on contact: `templates/decisions-README.md:15` already refuses to restate the frontmatter shape, so the two fields must NOT be described there. What was untrue is the no-index rationale, which rested on the slug alone — rewritten in both READMEs.
- `main` moved during this session (another session pushed dw-solo-setup 0.4.2). The branch was rebased onto origin/main before the bumps, or the merge would have reverted that number.
- `templates/` ships in dw-solo-setup, so touching `templates/decisions-README.md` obliges a setup bump too — three plugins move in this change, not two.
- The corpus ratchet caught +481 words. A tightening pass gave 130 back; the remaining 351 are re-recorded, because a gate with three outcomes and a read step in three skills is growth on purpose.
- `eval:routing` 27/27 rank-1, no description pair at or above 0.5 — the two agents are outside that scan entirely, which is why task 2 had to be done by hand.
