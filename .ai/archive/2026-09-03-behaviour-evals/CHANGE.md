---
change: behaviour-evals
branch: behaviour-evals
created: 2026-09-03
status: landed # shaping | building | landed
landed: 2026-09-03
pr: "#52"
---

# Change — a second eval tier that measures what a skill does, not whether it fires

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

## Notes

- Task 1, measured: `--safe-mode` disables `--plugin-dir` too — 0 skills under test. Unusable.
- Task 1, measured: only the 7 model-invocable skills are visible to the model at all; built-in
  skills load regardless and cannot be suppressed by `enabledPlugins: false`.
- The repo's own bash-guard hook blocks `git add -A` and a trailerless commit even inside a
  throwaway fixture, because it fires on the session's tool calls. The runner's own `execFileSync`
  is not affected.
- dw-land's close case is the expensive one — 24 turns, $1.16 — because it does real work.
- agnix lints a fixture's AGENTS.md as a real instruction file; `evals/fixtures/**` is excluded for
  the same reason `templates/**` is.
