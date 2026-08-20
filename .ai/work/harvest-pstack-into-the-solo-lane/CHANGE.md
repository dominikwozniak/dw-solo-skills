---
change: harvest-pstack-into-the-solo-lane
branch: harvest-pstack-into-the-solo-lane
created: 2026-08-20
status: building # shaping | building | landed
---

# Change — a prose pass for outbound text, rigour the loop states as rules, and a scaffolded `VERIFY.md`

## Goal

Three results harvested from `.inspirations/cursor-plugins/pstack`, observable after a reinstall:
`/dw-unslop` rewrites a PR body and declines a `SKILL.md` in one line; a task `dw-next` decides not to
build leaves a `**skip:**` marker instead of vanishing; `dw-land`'s verdict names the rung its proof
reached and sends a hook-enforceable trap to the backlog rather than `## Gotchas`; `/dw-init` writes a
tracked `VERIFY.md` whose router row `agents:check` accepts.

## Decisions

- **One change, not three** — the count test yields three scopes (a skill in `dw-solo-extras`,
  sharpenings in `dw-solo`, a scaffold addition in `dw-solo-setup`); the user ruled out splitting
  explicitly, so it is not reopened.
- **`dw-unslop` is `disable-model-invocation: true`** — rank-1 measures 68% against a 67% floor, and
  explicit-invoke skills sit outside that population entirely, so the risk is zero.
- **The catalog lives in `references/patterns.md`** — the ratchet counts `skills/*/SKILL.md` only, so
  the catalog is unmetered while the body stays in the house band.
- **unslop's em-dash ban and abstract-metaphor list are softened, not adopted** — both name vocabulary
  this repo defines (`ratchet`, `surface`, `canon`), and artifact density is already ruled load-bearing.
- **`dw-unslop` refuses agent-facing artifacts by name** — they are read by agents, where a trimmed
  sentence is an instruction lost; no task here is a compression pass.
- **`VERIFY.md` is built inline like `CONTEXT.md`** — no new `templates/` file, so the shipped payload's
  surface does not grow.
- **pstack's verification-skill generator is not taken** — two skills plus a new artifact class, and it
  pays only in a repo with an app to drive.
- **`dw-land`'s `VERIFY.md` reference is written as a condition** — `dw-solo` and `dw-solo-setup`
  install separately, so a loop-only install has no such file.
- **`dw-check` gains a filter over findings, not a reviewer** — the calibration is what a delegated
  report lacks; giving the step its own reviewer is the one thing `0012` keeps it out of.

## Tasks

- [x] 1. `skills/dw-unslop/SKILL.md` (70–90 lines: refusal list, four-step workflow, the two delete
      tests) plus `skills/dw-unslop/references/patterns.md` (the numbered catalog).
- [x] 2. The `dw-solo-extras` symlink, the README task-router row with `⭑`, the name in the
      "Explicit-only skills" paragraph, and the badge `skills-12` → `skills-13`.
- [x] 3. `dw-next` §4 — the `**skip:**` marker plus its fence against goal-shrinking, and the marker
      documented in `skills/dw-shape/references/CHANGE.md`.
- [x] 4. `dw-land` phase 3 — the encode-in-structure filter as a third item before a gotcha is written.
- [x] 5. `dw-land` step 2 — five rungs on **Is "done" proven?** and **Blast radius?**, with `VERIFY.md`
      named as a condition.
- [x] 6. `dw-init` — the `VERIFY.md` row in `## What it writes`, the create-if-absent step with its
      Launch / Doctor / Drive stub, and the `templates/AGENTS.md` router row.
- [x] 7. `dw-check` step 3 — the lead-judgment filter: all-nits means the diff is probably fine and
      say so, "I would have done it differently" is the commonest false positive, and more than five
      act-on items means the filter is too loose.
- [ ] 8. Three version bumps, identical in both manifests each — `dw-solo-extras` `0.1.6` → `0.1.7`,
      `dw-solo` `0.4.24` → `0.4.25`, `dw-solo-setup` `0.1.27` → `0.1.28` — then
      `node scripts/check-skill-corpus.mjs --update-baseline`, then the full gate.

## Anchors

- `scripts/check-skill-corpus.mjs:129-131` — the ratchet walks `skills/<name>/SKILL.md` only, which is
  why the catalog goes in `references/`.
- `evals/routing.ts:448-451` — a case file for an explicit-invoke skill is a hard failure, so
  `dw-unslop` gets none.
- `evals/routing.ts:57-61` — explicit skills stay in the corpus but outside the rank-1 population.
- `skills/dw-next/SKILL.md:98` — the tick bullet the skip marker sits beside.
- `skills/dw-next/SKILL.md:78-82` — the existing refusal to park a gap in the `## Goal`; the fence
  extends it rather than opening a new axis.
- `skills/dw-land/SKILL.md:52-54` — **Is "done" proven?**, already separating "looks right" from
  running the project's command; the rungs name the steps between.
- `skills/dw-land/SKILL.md:117-124` — "Two things before you write" under the gotcha promotion; the
  filter becomes a third.
- `skills/dw-init/SKILL.md:110-111` — `CONTEXT.md` built inline when absent; the precedent `VERIFY.md`
  copies.
- `templates/AGENTS.md:40-46` — the Task Router table the `VERIFY.md` row joins.
- `plugins/dw-solo-extras/skills/` — `dw-handoff` and `dw-prune`, both explicit-invoke; the shape to
  match.
- `docs/decisions/0010-policies-the-hooks-enforce-are-declared-bullets.md` — the thesis the phase-3
  filter cites.
- `.ai/archive/language-discipline-in-grill-and-next/CHANGE.md` — separate installs force the hedge,
  and the same doc rules artifact density load-bearing.
- `skills/dw-check/SKILL.md:84-85` — the grounding rule and "no findings is a normal, useful answer";
  the filter extends that licence rather than opening a new axis.
- `docs/decisions/0012-bare-dw-check-delegates-by-default.md` — why the step delegates but never grows
  a reviewer of its own; the filter has to stay on the near side of that line.
- `.inspirations/cursor-plugins/pstack/skills/interrogate/references/lead-judgment.md` — the source:
  four things a reviewer cannot know, five filtering principles, and the >5 calibration.
- `.inspirations/cursor-plugins/pstack/skills/unslop/SKILL.md` — the source catalog. Gitignored, so
  from a worktree read it through the main tree's absolute path.

## Notes

- `validate:artifacts` pass 3 fails from task 1 until task 8 re-records the baseline. That is the
  ratchet working; re-recording per task is churn a reviewer has to read through. Task 1 measured +812.
- A worktree-isolated session refuses a Bash heredoc-plus-redirect as too complex to prove it stays in
  the worktree. Write files with the Write/Edit tools here; `sed -i ''` is accepted.
- `dw-unslop` keeps the upstream rule numbers so a citation is portable both ways; new rules start at 32.
- A new skill declaring `argument-hint` must reference `$ARGUMENTS` in its body, or agnix's pre-commit
  autofix appends a bare `$ARGUMENTS` line after `**Next:**`. Name it where the target is resolved.
- A shipped skill must not cite this repo's decision numbers: `0010` in a target project is that
  project's tenth decision. Task 4 drafted one, caught it, and put the reasoning in the body instead.
  No skill body cited a decision before, so nothing enforces it — a `docs/decisions/` grep over
  `skills/*/SKILL.md` would, which is the phase-3 filter's own verdict on this note.
- Nothing checks that every path `templates/AGENTS.md` routes to is one `dw-init` actually creates;
  `check-agents-docs.mjs` only ever runs in the scaffolded repo. `CONTEXT.md`'s row stands on the same
  footing, so this is not new — but it is a validator waiting to be written.
