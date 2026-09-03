---
created: 2026-09-03
source: evals-accuracy-and-gates
why-not-now: it is a second tier with its own runner and its own failure modes, and the accuracy pass had to land first so the tier-2 numbers it is judged against are true
effort: a day — a ~200-line runner, three or four cases, and the archive entry that says what it measured
---

# A skill is measured on whether it fires, never on what it does once it has

`evals/routing.ts` scores descriptions. Nothing scores behaviour: no check says `dw-shape` writes a
`CHANGE.md` with real anchors, that `dw-land` stops for the go it promises, or that `dw-git` follows
this repo's `## Git conventions` rather than generic ones. Of the three dimensions in
`https://www.philschmid.de/testing-skills` — outcome, style, efficiency — only efficiency is covered,
by `check-skill-corpus.mjs`.

Shape, decided 2026-09-03 and settled: **an own runner**, following
`.inspirations/addyosmani-agent-skills/scripts/run-evals.js`, not a wait on `claude plugin eval`.

- An `evals[]` block **inside the existing case files**, each entry a prompt plus `expectations[]`
  written as observable behaviours. One file per skill stays one file per skill.
- `claude -p --output-format stream-json` in a `mkdtemp` fixture with `git init`; a second model
  grades the trace against `expectations[]` and returns JSON. Grade what the trace shows, never the
  prose claim.
- **Opt-in, never in CI, and behind a flag** — that is what killed `evals/trigger.ts` (see
  `docs/decisions/0006`, `.ai/archive/2026-08-02-skill-routing-evals/`), and the reason stands: there
  is no login to inherit in CI and it spends subscription quota. Results are recorded in
  `evals/README.md` with a date and an n, the way `Asking the real router` already is.
- Start with **pressure cases** for the three skills whose whole value is holding a line under
  argument — `dw-land`, `dw-check`, `dw-ship`. addyosmani's authority-pressure and time-pressure
  fixtures are the model: assert the workflow still holds when the prompt argues for skipping it.

`claude plugin eval` would subsume most of this — it has a `tool_used: Skill` grader, `llm` graders
and a `--ablation with-without` arm that answers "has the model absorbed this skill". It is in the
CLI (2.1.259) and returns `plugin eval is currently in early access` on this account, with no ETA.
Its eval dir also sits **below the plugin**, which collides with `docs/decisions/0005`. Revisit when
it unlocks; do not wait on it.
