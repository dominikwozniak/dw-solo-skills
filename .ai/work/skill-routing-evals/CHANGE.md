---
change: skill-routing-evals
branch: unclaimed
created: 2026-08-02
status: shaping # shaping | building | landed
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

- [ ] 1. `evals/routing.ts` end to end on two case files — `evals/cases/dw-shape.json` and
      `evals/cases/dw-grill.json`: read every `skills/*/SKILL.md` description into a corpus, tokenize,
      stem, TF-IDF, cosine, print the ranking for each positive prompt. This pair is the suspected
      collision, so the slice answers something on its first run.
- [ ] 2. Fill the remaining case files for the 7 model-invocable skills (`dw-check`, `dw-doctor`,
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
