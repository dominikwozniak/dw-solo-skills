---
change: behaviour-evals
branch: behaviour-evals
created: 2026-09-03
status: building # shaping | building | landed
---

# Change — a second eval tier that measures what a skill does, not whether it fires

## Goal

`node evals/behaviour.ts` runs a named behavioural case in a throwaway fixture and reports a
graded verdict, spending nothing until `--go`. You know it worked when a bare run prints the plan
and its estimated cost without calling `claude` once, when `scripts/tests/behaviour-eval.test.sh`
is green without spending a token, when `pnpm eval:routing` is byte-identical to before the shared
module was extracted, and when `evals/README.md` carries a dated measurement from a real run.

## Decisions

- **`evals/behaviour/<skill>.json`, not an `evals[]` block inside the routing case files** — the
  backlog entry settled on the latter, and it cannot work: `routing.ts` hard-fails a case file for
  a `disable-model-invocation` skill, and 7 of 14 skills are exactly that. The tighter coupling
  would have permanently excluded half the corpus, `dw-ship` and `dw-grain` included.
- **`--settings` suppression, never `--safe-mode`** — measured in task 1: `--safe-mode` disables
  `--plugin-dir` along with everything else, so the skills under test vanish too.
- **Explicit-invoke skills are reached by slash** (`/dw-solo:dw-ship`), because the model is never
  offered them. Measured: the CLI expands the slash before the model, so such a run leaves **no
  `Skill` tool_use in the trace** — the runner records the invocation mode instead of asserting on
  a call that cannot appear.
- **Slash by default for every case** — tier 2 already owns routing, so letting the router pick
  here would make a behavioural failure ambiguous. `invoke: "prompt"` stays available for a case
  that wants both.
- **Executor keeps its write tools.** The archive's note is explicit: `--disallowedTools Write
Edit` was right for observing a trigger and is wrong here — "the agent narrates instead of
  acting".
- **The runner never joins the `scripts` block** in `package.json`; that block is the pre-push
  gate, and this spends quota.
- **Grader pinned to sonnet, executor to opus** — the loop runs opus, so behaviour must be measured
  there; grading is cheaper and did not need it.

## Tasks

- [x] 1. Prove the invocation is hermetic before building on it: one plugin copy each, no global
      plugins, and a way to reach an explicit-invoke skill. Findings in `## Notes`.
- [x] 2. `evals/skills.ts` — `parseFrontmatter`, `stripQuotes`, `buildCorpus`, `type SkillDoc` out
      of `routing.ts`; `routing.ts` imports them. No behaviour change, proven by a byte-identical
      run.
- [x] 3. `evals/behaviour.ts` — the runner: case loading, fixture materialisation, executor,
      grader, the `--go` cost gate, results under `evals/results/` (gitignored).
- [x] 4. Seven cases in `evals/behaviour/` plus their fixtures under `evals/fixtures/`.
- [x] 5. `scripts/tests/behaviour-eval.test.sh` over the free parts only — zero model calls.
- [x] 6. `evals/README.md` (both stale passages), `docs/decisions/0020-*.md`, `AGENTS.md`, and
      `git rm` the backlog entry this change completes.
- [x] 7. Run at least two cases for real and record the measurement with its date, n and cost.

## Anchors

- `evals/routing.ts:78-120`, `:252-284` — the functions task 2 moves.
- `evals/routing.ts:441-452` — the hard fail that makes an `evals[]` block impossible for the
  explicit-invoke half of the corpus.
- `skills/dw-ship/SKILL.md:24-25` — "Landed first, and that is a refusal", case 4.
- `skills/dw-land/SKILL.md:39-40`, `:44-45`, `:76-77` — cases 1 and 2.
- `skills/dw-next/SKILL.md:25-27` — case 5. `skills/dw-shape/SKILL.md:29-30`, `:54` — cases 6, 7.
- `skills/dw-check/SKILL.md:22`, `:52` — case 3.

## References

- `https://www.philschmid.de/testing-skills` — outcome / style / efficiency, and grade outcomes,
  not paths.
- `.inspirations/addyosmani-agent-skills/scripts/run-evals.js` — the tier-3 shape being ported.
- `git show 1182f7f^:evals/trigger.ts` — the deleted predecessor; its `--go` gate and its
  `pluginDirs()` / `suppressGlobalPlugins()` pair are reused.
- `.ai/archive/2026-08-02-skill-routing-evals/CHANGE.md` — why the last attempt died, and the two
  plugin-loading subtleties.

## Notes

- Task 1, measured: `--safe-mode` disables `--plugin-dir` too — 0 skills under test. Unusable.
- Task 1, measured: with `--settings` suppression of all 12 globally enabled plugins, each skill
  appears exactly once; `dw-personal-context` and `codex` are gone. Built-in skills (`code-review`,
  `simplify`, `run`, …) still load and cannot be suppressed this way — a fixed, known set.
- Task 1, measured: only the 7 model-invocable skills are visible to the model at all.
- Task 1, measured: case 4 already passes on sonnet — dw-ship refused, named dw-land, held under
  "I need this out today". 4 turns, $0.0920.
- Grader cost dominates: `--json-schema` on sonnet cost $0.1211 on a three-line trace.
- The repo's own bash-guard hook blocks `git add -A` and a trailerless commit even inside a
  throwaway fixture, because it fires on the session's tool calls. The runner's own `execFileSync`
  is not affected.
- Both failures in the first sweep were the eval's fault, not the skills': dw-shape #1 asserted a
  stop the skill correctly did not make (the prompt read as a planning sitting, the other half of
  its default-branch fork), and land-no-origin asked for a close on a change the diff did not
  deliver. Recorded in each case's own `note`.
- dw-land's close case is the expensive one — 24 turns, $1.16 — because it does real work.
- agnix lints a fixture's AGENTS.md as a real instruction file; `evals/fixtures/**` is excluded for
  the same reason `templates/**` is.
