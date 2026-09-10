---
change: a-ticked-box-names-the-evidence-that-checks-it
branch: a-ticked-box-names-the-evidence-that-checks-it
created: 2026-09-10
status: building # shaping | building | landed
---

# Change — a ticked box names the evidence that checks it

## Goal

A tick in `CHANGE.md` means "checked", not "written".

- A task line written by `dw-shape` carries the check that would prove it: `- [ ] 1. [slice] — proof: [what checks it]`.
- `dw-next` flips a box only after that named check has run, and the commit body says what ran.
- `dw-land`'s rung ladder reads the boxes instead of re-deriving each claim from memory; a box whose
  proof never ran is a claim at the `said so` rung.
- A task nobody can name a check for is visibly badly cut at shaping time, not at landing time.
- The repo says once, in the one place a builder reads before writing a test, what makes a test real:
  a test that also passes against the unfixed code is not a test.

## Decisions

- **`proof:` is a phrase on the task line, not a section.** The alternative — a `**Verify.**` block per
  task, pstack's shape (`multi-phase-plan.md:97-119`) — buys structure this lane cannot spend: its
  boxes are unit/live/perf lanes with screenshots, which needs an application to drive. One phrase
  survives `dw-next`'s re-read on every resume; a block per task turns a 6-task doc into a plan file.
- **Nothing validates the clause.** A missing `proof:` is caught by a reader, never by a script —
  `templates/work-README.md:70` ships the rule that `.ai/` is deliberately unvalidated, and a schema
  here would be the validated plan this lane exists to avoid.
- **The falsifiability clause lands beside the mechanism requirement, at `dw-land:75`, not in phase 3.**
  The plan filed it under "phase 3"; phase 3 is `### 3. Open the PR`, and the requirement it makes
  checkable ("Where a mechanism (hook, lint rule, check) could refuse the trap outright, build or
  backlog that") is the phase-2 **Gotchas** bullet. Correcting the plan, not following it.
- **The test bar is quoted from `0013`, not invented.** `docs/decisions/0013` already carries this
  repo's strongest version — "each was confirmed by mutating the checker back to the broken behaviour
  and watching exactly that case fail" — and it has never left `docs/decisions/`. One sentence of it
  moves into `dw-next`, where a builder reads it before writing the test.
- **`attack-the-premise` enters as a stop rule, not a census script.** pstack's version
  (`principle-attack-the-premise/SKILL.md`) demands a rerunnable census per `build-the-lever`; in a
  solo Markdown lane the actors are fixes, not machines, and the census is a list. What carries is the
  trigger and the stop: two fixes sharing one premise, both refused by the same gate, means the
  premise gets written down before the third fix.
- Trimming an archive receipt keeps `## Decisions`' `(rejected:)` and `(unsettled:)` lines, nothing
  else. (inherited: 0026)

## Out of scope

- **A schema or `check-plan.mjs` for `CHANGE.md`** — contradicts `templates/work-README.md:70`, which
  this repo ships to every target project.
- **unit / live / perf boxes, ten lanes, screenshots** — needs an application to drive; the same reason
  PR #42 turned down pstack's verification-skill generator.
- **A `tdd` skill** — a 13th skill arguing for thin slices in a repo that already subtracts them; the
  test bar lands as one line inside `dw-next` instead.
- **`dw-check` and `dw-grill`** — neither reads or writes a box; change A is merged and closed.
- **Running `node evals/behaviour.ts --go`** — measurement, never a gate (`docs/decisions/0020`), and
  no behaviour case here asserts a tick.

## Tasks

<!-- Convention: `- [ ]` pending, `- [x]` done — `dw-next` flips the box in the task's own commit.
A task that stopped being necessary keeps its box and gains `**skip:** <reason>`; every later
invocation reads that as not remaining. Never rename a task title. -->

- [x] 1. The task line in `skills/dw-shape/references/CHANGE.md` gains the `proof:` clause, and the tick-convention comment above it gains the sentence that a box is ticked only once its named proof exists — proof: `sed -n '43,49p' plugins/dw-solo/skills/dw-shape/references/CHANGE.md` shows both through the shipped symlink
- [x] 2. `skills/dw-shape/SKILL.md:89-92` — a task with no nameable check is badly cut, one sentence in step 3 — proof: `grep -n 'proof' plugins/dw-solo/skills/dw-shape/SKILL.md` returns the new line
- [ ] 3. `skills/dw-next/SKILL.md:78` — the box flips after the named check ran, not after the code was written, and what ran goes in the commit body — proof: `sed -n '76,84p' plugins/dw-solo/skills/dw-next/SKILL.md`
- [ ] 4. `skills/dw-next/SKILL.md:60`, **Test the way the project does** — the `0013` bar in one sentence — proof: the sentence read back beside `docs/decisions/0013`'s own wording, no third variant introduced
- [ ] 5. `skills/dw-next/SKILL.md` step 3 — `attack-the-premise` as one bullet: two fixes on one premise refused by the same gate means write the premise down and list the cases before the third fix — proof: `grep -n 'premise' plugins/dw-solo/skills/dw-next/SKILL.md`
- [ ] 6. `skills/dw-land/SKILL.md:34` and `:75` — the rung ladder reads the boxes and grades a proofless box as `said so`; the mechanism requirement gains `build-the-lever`'s falsifiable half (cited a mechanism, no hook, validator or self-test in the diff, then you did not do it) — proof: `sed -n '32,36p;73,78p' plugins/dw-solo/skills/dw-land/SKILL.md`
- [ ] 7. `node scripts/check-skill-corpus.mjs --update-baseline`, and bump `dw-solo` 0.9.2 → 0.9.3 in `plugins/dw-solo/.claude-plugin/plugin.json` and `.claude-plugin/marketplace.json`, all in one commit — proof: `pnpm validate:artifacts` and `pnpm validate:versions` both green

## Anchors

- `skills/dw-shape/references/CHANGE.md:43-48` — the tick-convention comment and the two bare `[slice]` task lines the clause attaches to.
- `skills/dw-shape/SKILL.md:89-92` — step 3, four lines, the only place a task's shape is described.
- `skills/dw-next/SKILL.md:60` — **Test the way the project does**; today the repo's only sentence about tests, and it says nothing about what makes one real.
- `skills/dw-next/SKILL.md:78` — "Flip the box … and set `status: building` on the first tick"; today the tick has no precondition.
- `skills/dw-land/SKILL.md:34` — the rung ladder: `said so · pointed at the line · showed the bad case impossible · ran it · reproduced it in the artifact a user gets`.
- `skills/dw-land/SKILL.md:75` — the Gotchas bullet PR #42 added: build the mechanism instead of writing the prose. Unfalsifiable as written.
- `docs/decisions/0013-a-validator-over-git-history-gets-a-self-test.md` — `## Decision`, third paragraph: the non-vacuous bar the task-4 sentence quotes. No `rule:` or `touches:` field; it predates both.
- `docs/decisions/0026-a-turned-down-decision-survives-the-archive-trim.md` — the one active record whose `touches:` names `skills/dw-land/SKILL.md`.
- `templates/work-README.md:70` — "Nothing here is validated, deliberately"; why task 1 adds a phrase and not a schema.
- `plugins/dw-solo/skills/` — every entry mode 120000 back to `skills/`; the proof commands above read the shipped side of the symlink, never a second copy.

## References

- `/Users/dominik.wozniak/.claude/plans/co-jeszcze-z-pstack-snug-fox.md`, section "Zmiana B" — the approved plan; its only durable copy lives outside this repo.
- `.inspirations/cursor-plugins/pstack/skills/poteto-mode/playbooks/multi-phase-plan.md:24` — "Check a box only when its evidence exists, a file, a log line, a screenshot, a test run, or a SHA."
- `.inspirations/cursor-plugins/pstack/skills/principle-attack-the-premise/SKILL.md` — task 5's source; the census half is deliberately left behind.
- `.inspirations/cursor-plugins/pstack/skills/principle-build-the-lever/SKILL.md` — task 6's source: "If you cited it and there is no codemod, script, generator, or delegate skill in the diff, you didn't apply it."
- `.ai/archive/2026-09-10-dw-grill-asks-the-frontier-in-one-round/CHANGE.md` — change A, the sibling this one was split from and now follows.

## Notes
