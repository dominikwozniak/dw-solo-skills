---
change: skill-routing-evals
branch: skill-routing-evals
created: 2026-08-02
status: building # shaping | building | landed
---

# Change — routing evals: a free lexical tier in CI, and a paid real-router tier on demand

## Goal

Catch a skill description drifting into its neighbour's territory before the loop misroutes in real
use. Two tiers: `pnpm eval:routing` scores every positive prompt against the whole description
corpus and fails when a skill stops ranking for its own vocabulary or two descriptions collide —
deterministic, no tokens, in CI; and `node evals/trigger.ts`, run by hand, asks the actual router
which skill fires. Known when: the gate rejects a deliberately broadened `dw-check` description, and
the trigger run produces a recorded verdict on whether `dw-grill` really outranks `dw-shape`.

Reconnaissance already found the lead this exists for: on `shape a change that adds a CSV export` —
containing `dw-shape`'s own documented trigger phrase — `dw-grill` fired 3/3. That was haiku, an
empty directory, n=3, so it is a lead and not a verdict.

## Decisions

- **Two tiers, lexical first** — TF-IDF over descriptions catches the same class of bug as a headless
  run, for free and deterministically; the paid tier stays because a lexical proxy is not the router
  and need not reproduce its answer. Dropping it would have lost the grill/shape lead.
- **Modelled on `addyosmani/agent-skills` (MIT), not software-mansion** — SWM grades generated code
  with `contains`/`not_contains`; these skills orchestrate workflow, so there is nothing textual to
  assert on. Their runner is 561 lines with zero dependencies.
- **`evals/` at the repo root, never `skills/<n>/evals.json`** — a plugin symlinks the _whole_ skill
  directory and install dereferences it, so anything colocated ships to consumers.
- **TypeScript with no build step** — Node 24 strips types natively (`.nvmrc` is 24.16.0, above the
  22.18 threshold), so no tsx, no tsconfig, no new dependency. Erasable syntax only: no `enum`, no
  parameter properties, no `namespace`.
- **Tier 3 never in CI and never in the pre-push gate** — it costs subscription quota (~20k input
  tokens per run, floor) and is nondeterministic; it must be pinned to opus because routing is
  model-dependent.
- **`.ai/backlog/delta-evals.md` is narrowed in place, not consumed** — the slug does not travel here
  because only part of the entry is being built; the artifact-delta tier stays parked.
- **Four `disable-model-invocation: true` skills get no `trigger` section** — routing is not the
  model's decision there — but their descriptions stay in the collision corpus, because they still
  compete for attention.

## Tasks

- [x] 1. `evals/routing.ts` end to end on two case files — `evals/cases/dw-shape.json` and
      `evals/cases/dw-grill.json`: read every `skills/*/SKILL.md` description into a corpus, tokenize,
      stem, TF-IDF, cosine, print the ranking for each positive prompt. This pair is the suspected
      collision, so the slice answers something on its first run.
- [x] 2. Fill the remaining case files for the 7 model-invocable skills (`dw-check`, `dw-doctor`,
      `dw-git`, `dw-land`, `dw-next`), each with at least 3 positives and 2 negatives carrying
      `owner`. Prompts paraphrase how the ask is really phrased — copying from `description` games
      the eval.
- [ ] 3. Collision detection (warn ≥0.5 cosine, error ≥0.75) and the `--min-rank1` ratchet, with the
      measured baseline written into `evals/README.md` so drift is visible.
- [ ] 4. `scripts/validate-evals.sh` — every `skills/<n>/` has `evals/cases/<n>.json` and back —
      plus `pnpm eval:routing` in the pre-push gate and `.github/workflows/evals-routing.yaml`.
- [ ] 5. `evals/trigger.ts` — Tier 3-lite: spawn `claude -p`, read the first `Skill` tool call out of
      stream-json, 3 trials, report the distribution. Record the grill/shape verdict in Notes.
- [ ] 6. Docs wiring: `## Commands`, `## Gotchas` and the add-a-skill checklist in `AGENTS.md`, plus
      `## Project specifics` in `CLAUDE.local.md`. (`.ai/backlog/delta-evals.md` was already narrowed
      in the shaping commit — live work must not also sit in the backlog.)

## Anchors

- `scripts/validate-docs.sh:36-69` — the disk↔docs bidirectional pattern `validate-evals.sh` copies.
- `scripts/validate-manifests.sh:47` — `RUNTIME_SCRIPTS`, the same shape as a list of eval-exempt
  skills if one turns out to be needed.
- `.github/workflows/format-check.yaml` — the only workflow that sets up Node; the model for
  `evals-routing.yaml`, minus `pnpm ci` since Tier 2 has no dependencies.
- `.claude/hooks/lint-on-edit.sh:25` — the extension filter that wakes on the first `.ts` file in
  this repo.
- `.prettierrc.json` — `printWidth: 100`, no semicolons, double quotes, `trailingComma: all`.
- `skills/dw-grill/SKILL.md:3-9`, `skills/dw-shape/SKILL.md:3-9` — the descriptions of the pair the
  reconnaissance flagged.
- `.ai/backlog/delta-evals.md` — the source entry, narrowed to the artifact-delta tier.

## Notes

Verified against the live CLI rather than docs, before shaping:

- `claude -p` runs on the subscription alone — no `ANTHROPIC_API_KEY` present, `provider:"firstParty"`.
  `--bare` is the one flag that demands a key, and it is not needed.
- `--plugin-dir plugins/dw-solo` loads the worktree canon, not `~/.claude/plugins/cache/`.
- `--settings '{"enabledPlugins":{…:false}}'` suppresses the globally-enabled plugin. It must be
  passed in the _with_ arm too, or the skills load twice — once from `--plugin-dir`, once from cache.
- `--max-turns 1` falsifies the result: the model spends its first turn exploring and never reaches
  the skill. Minimum 4.
- An empty cwd is unrepresentative — it lacks `dw-shape`'s "starting work on a private project" cue,
  which may itself explain the grill/shape lead. The trigger fixture needs `git init`, an empty
  `.ai/work/` and a stub `CLAUDE.md`.
- `agnix eval` is a dead end: it grades agnix's own lint rules (`AS-`, `MCP-`), not skills.
- `--disallowedTools Write Edit` is fine for observing a trigger but wrong for behavioural evals —
  the agent narrates instead of acting. Relevant when the parked tier is picked up.

### Task 1 — the first run does not reproduce the grill/shape lead, and finds a bigger problem

Baseline on the two case files: `dw-grill` 4/4 rank-1, `dw-shape` **2/5**, yields 6/6.

`dw-grill` is not the thief in the lexical tier. On the recon prompt `shape a change that adds a CSV
export`, `dw-grill` places third (0.137); the winner is **`dw-start`** at 0.198 vs `dw-shape`'s
0.188, because "Open a **shaped** change for building" stems to the same term as "shape". The other
two losses go to `dw-next` (0.307 on "task checklist on disk" — `dw-next` owns "disk" and "task")
and `dw-land` (0.224 on "change doc with the decisions" — `dw-land` owns "decisions"). So
`dw-shape`'s vocabulary is contested three ways and the pair the reconnaissance flagged is the least
of it. Whether the real router agrees is task 5's question; the tiers are allowed to disagree.

Deliberately deferred: gating. The runner reports and exits 0 — `--min-rank1` and collision
detection are task 3, so this baseline is what the ratchet gets pinned to.

### Task 2 — all seven scored: 16/30 rank-1, and the metric is measuring the wrong thing

Per skill: `dw-grill` 4/4, `dw-doctor` 3/4, `dw-land` 3/4, `dw-check` 2/4, `dw-next` 2/4,
`dw-shape` 2/5, **`dw-git` 0/5**. Yields 21/21 — no case file's skill ever outranks a named owner,
so the descriptions are not stealing each other's _negatives_; they are failing to hold their own
positives.

**The metric counts losses that cannot happen.** Of `dw-git`'s five failures, three are losses to
`dw-ship` (0.326 on "pull request") and `dw-start` (0.315, 0.327 on "branch") — both
`disable-model-invocation: true`, so the router can never choose them. Same for `dw-land` and
`dw-next` losing prompts to `dw-ship`. Rank-1 has to be computed among the model-invocable skills,
with an explicit-invoke win reported separately as overlap rather than as a routing failure. That
lands in task 3, before the ratchet is pinned to anything.

**`dw-git` has no synonyms, and the last refactor made it worse.** Two of its prompts score
literally zero — "save what I have with a sensible message" and "park these edits somewhere" share
no discriminating term with a description that lists operations (`commit, push, open PR, sync,
branch, stash`) and never names how anyone actually asks for them. Swapping in the description from
`44c06c7^` moves "bring my branch up to date with main" from rank 3 to **rank 1** (0.235), because
the sentence that commit removed contained the literal phrase "sync **with main**". So the eval
retroactively catches a real regression from this repo's own history, which is the premise of the
change working on the first corpus it was pointed at. Whether to restore that sentence is a
description decision, not an eval decision — parked, not silently fixed.

### Task 1 — three things the first `.ts` file in this repo shook out

- **`lint-on-edit.sh` executed the file it was asked to lint** — fixed in its own commit (129a875)
  with a self-test. `sed -E` with `\s` fails on BSD sed, the "command" resolved to a single space,
  which is not empty, and `eval " \"$file\""` ran the target. Silent exit 0 when the file is
  executable. Vendored from `dw-skills`, so `.ai/backlog/lint-on-edit-upstream-fix.md` carries it.
- **A hook fix does not take effect in the worktree session that makes it.** Claude Code resolves
  hooks from `${CLAUDE_PROJECT_DIR}`, which is the **main tree** — still on `main`, still holding the
  old hook. Every `.ts` edit for the rest of this change will print the old hook's "Permission
  denied". Harmless only because `evals/*.ts` is not executable; do not `chmod +x` it.
- **`.lintstagedrc.json` did not cover `*.ts`**, so pre-commit would not format TypeScript while
  `pnpm format` in the pre-push gate would fail on it. Added `ts`, plus `"type": "module"` in
  `package.json` — without it Node reparses every `.ts` and warns on stderr.
