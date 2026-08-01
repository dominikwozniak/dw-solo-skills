# Skill anatomy

Every `skills/<name>/SKILL.md` in this repo follows one shape. It is not arbitrary house style — the
shape is what makes a skill resumable, groundable, and composable. New skills copy a near neighbour
and keep the section order; reviews check against this file.

## Frontmatter

```yaml
---
name: dw-thing # kebab-case, MUST equal the directory name
description: >- # multi-line; this is what the model matches on
  One sentence on what it does and the artifact it writes. Then the trigger
  phrases — "Use when …", the things a user says ("shape this", "land this"),
  or the explicit "dw-thing" invocation. End with a "Prefer this over …"
  line so the model picks it over an ad-hoc approach.
argument-hint: "What the skill expects as $ARGUMENTS" # short, optional for pure read-only skills
disable-model-invocation: true # ONLY for explicit-invoke-only skills (see below)
---
```

- **`name`** — kebab-case, equals the directory. Linted.
- **`description`** — the discovery surface. Pack the trigger phrases here; the model reads this, not
  the body, to decide whether to fire.
  - **Never name a skill from another repo here.** Every installed description sits in the context
    window of every session, so a "prefer this over `dw-spec`" clause costs tokens in every session to
    disambiguate against something that isn't installed. Describe the _shape_ you're preferring over
    ("a multi-file spec-and-plan ceremony"), not the skill name.
- **`argument-hint`** — a short hint string. Read-only skills that take no real argument may omit it.
- **`disable-model-invocation: true`** — set this _only_ on skills that scaffold a repo, install
  shared tooling, or take an outward-facing/irreversible action (create a worktree and branch, push
  and merge), so the model never reaches for them unbidden. The cost: an explicit-only skill can't
  be reached by other skills' prose either. Setting it obliges you to mark the skill `⭑` in the
  README task-router **and** name it in the explicit-only lists in README and `docs/DESIGN.md`;
  `pnpm validate:docs` enforces the agreement in both directions.

## Body order

A `# <name> — <tagline>` H1 and a short intro/rationale paragraph, then these sections in order
(skip the ones marked optional when they don't apply):

1. **Output location** — the baked-in `.ai/` path the skill writes, plus the line
   "`.ai/` is tracked in git". This is the persistence contract: the path lives _in the skill_, not
   in a wrapper. Two acceptable headings:
   - `## Output location` — for skills whose main job is to produce one artifact.
   - `## What it reads and writes` — for skills that both consume the change doc and update it.
   - **Read-only exception:** a skill that writes nothing replaces this with `## What it reads` and
     states plainly that it writes no `.ai/` artifact.
2. **Workflow** — numbered `### 1.`, `### 2.`, … steps. The procedure itself. Bake the HARD STOP
   gates here (see invariants).
3. **The `<artifact>` shape** _(optional)_ — points at the `references/` template to copy; lists the
   artifact's sections. Omit for read-only skills.
4. **References** _(optional)_ — present iff the skill has a `references/` folder; lists each file and
   when to read it.

## Cross-cutting invariants

These hold across every skill, regardless of section layout:

- **HARD STOP gates.** Before an assumption-laden or irreversible step, stop and ask — surface the
  unknown before it costs a rewrite, and get explicit consent before mutating anything outside
  `.ai/`.
- **Anti-hallucination grounding.** Every finding, scenario, or claim points at a real referent —
  a `file:line`, a route, a schema column the skill confirmed with Read/grep. If it can't be
  grounded, it isn't reported.
- **Always write the artifact.** A run never finishes without writing its output — even "no findings,
  ready to merge" is a durable result worth recording. (Read-only skills are the explicit exception.)
- **Trailing "Next:" pointer.** End the body with a `**Next:**` line naming the skill a user would
  reasonably reach for next. This is the composable-not-chained link — a recommendation, never a
  forced sequence. It **must name a skill that exists in this repo**; `pnpm validate:docs` fails a
  pointer at a team-lane skill, because that's a dead end for anyone who only installed `dw-solo`.
- **Technology-agnostic.** No hardcoded stack. Read test/lint/run commands from the project
  (`## Commands` block → manifests → code). Stack-specific detail lives in `references/`, marked as
  examples. Full rationale in [`DESIGN.md`](DESIGN.md).
- **Branch reads use `git rev-parse --abbrev-ref HEAD`.** Never `git branch --show-current` — it
  returns an empty string on a detached HEAD, silently turning a branch match into a no-match.
- **One job, not one persona.** A skill is a unit of work (shape a change, land it), not a role. The
  closing pass weighs every axis in one go rather than splitting into persona skills — see
  [`DESIGN.md`](DESIGN.md), "One gate, not a skill boundary."
- **One reader.** This lane assumes you are the only audience. A skill that only pays off with a
  second reader (a validated status table, a handoff doc, an auditor/writer split) belongs in
  `dw-skills`, not here.
