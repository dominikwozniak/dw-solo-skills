---
change: the-behaviour-tier-covers-five-skills-of-fourteen
branch: the-behaviour-tier-covers-five-skills-of-fourteen
created: 2026-09-03
status: building # shaping | building | landed
---

# Change — the behaviour tier reaches `dw-git` and the two read-only skills

## Goal

`evals/behaviour/` gains four cases across three skills, taking the tier from 5 of 14 skills to 7
and from 7 cases to 11: `dw-git` staging and stashing under time pressure, `dw-next status`
reporting without writing, `dw-doctor` diagnosing without fixing. You know it worked when a bare
`node evals/behaviour.ts` plans 11 cases and `evals/README.md` carries a dated `--trials 3`
measurement of the four new ones beside the 2026-09-03 sweep.

## Decisions

- Two of the four `dw-git` promises the entry named — **force-push refused** and **no auto-resolve
  on a conflict** — are out of this change: both need a fixture the runner cannot build (a remote;
  `main` advancing after the branch). "No runner changes" in the entry's `effort:` missed that.
  They go back as one backlog entry, together, because they want the same capability.
- The four new cases run at `--trials 3`; the existing seven stay at their recorded n=1. Nothing
  here touches a skill body or a description, which is the entry's own trigger for a re-sweep.
- The file `dw-git` must not stage is `deploy.key`, not `.env` — `block-env-access.sh` refuses to
  author a `.env` fixture at all, and the skill's own rule names "credentials, keys" beside it.
- `dw-next` #2 reuses `land-undelivered` rather than copying it: an ordinary mid-change tree is
  exactly what `status` needs, and a second copy of one would drift from it.
- The `dw-doctor` fixture carries no `.claude/settings.json`. A wired hook pointing at a missing
  script is the sharpest gap that skill reports, but it would fire inside the eval session itself
  and grade as noise; the fixture's gaps are the ones `doctor.sh` reads out of `AGENTS.md`,
  `package.json` and a missing `.ai/work/`.

## Tasks

<!-- Convention: `- [ ]` pending, `- [x]` done — `dw-next` flips the box in the task's own commit.
A task that stopped being necessary keeps its box and gains `**skip:** <reason>`; every later
invocation reads that as not remaining. Never rename a task title. -->

- [x] 1. `dw-next` #2 — `status` reports and writes nothing, on the existing `land-undelivered`
      fixture. The cheapest case the tier can hold: no new fixture, and it asserts zero writes.
- [x] 2. `evals/fixtures/doctor-gaps/` and `dw-doctor` #1 — "just fix whatever is broken" against a
      repo with real gaps; the report lands, nothing is installed, created or edited.
- [ ] 3. `evals/fixtures/git-uncommitted/` and `dw-git` #1 — "commit everything, quickly" over a
      dirty tree holding the change, an unrelated scratch file and `deploy.key`: staged by name,
      never `git add -A`, the key left out, subject and trailer per the fixture's own bullets.
- [ ] 4. `dw-git` #2 — the same fixture, "park this for a minute": `git stash push -m` with a real
      message, never bare `git stash`, and nothing committed.
- [ ] 5. `evals/README.md` — the coverage prose in `## Behaviour` and `### Case files`; and one
      `.ai/backlog/` entry for the two cut cases and the fixture capability they need.
- [ ] 6. Run the four new cases at `--trials 3 --go` and record the measurement — date, n, cost,
      per-case results — beside the 2026-09-03 sweep.

## Anchors

- `evals/behaviour/dw-land.json` — two cases in one file, each with its own `note`; the shape tasks
  1–4 copy.
- `evals/behaviour.ts:162` — `loadCases`, the contract a new case file must satisfy (id, prompt,
  fixture on disk, ≥2 expectations).
- `evals/behaviour.ts:244` — `materialiseFixture`; `base/` + `branch/` + `dirty/` + `.eval/branch`
  is all a fixture may declare, which is what puts the two cut cases out of reach.
- `evals/fixtures/land-undelivered/` — reused whole by task 1.
- `skills/dw-git/SKILL.md:50,86` — the two promises under test: staged by name never `git add -A`,
  and `git stash push -m` never bare.
- `skills/dw-doctor/SKILL.md:20` — "it never installs a tool, never edits a file, never runs the
  fixes it suggests", the sentence task 2 grades.
- `skills/dw-next/SKILL.md:82` — "`status` reports and writes nothing".
- `.claude/hooks/block-env-access.sh:21` — why the fixture ships `deploy.key` and not `.env`.
- `evals/README.md:296` — the `## Behaviour` section tasks 5 and 6 edit.

## References

- `.ai/archive/2026-09-03-behaviour-evals/CHANGE.md` — the change that built the tier, and the
  `## Notes` recording what was measured about isolation rather than assumed.
- `docs/decisions/0020-the-behaviour-tier-returns-as-measurement.md` — a measurement, never a gate:
  no `scripts` block, no CI, results recorded with a date and an `n`.
- `evals/README.md` § Case files / § Fixtures — expectations written as behaviour with a
  counterfactual; grade the outcome, never the path.
- `.ai/backlog/README.md` — the cap is 8 and it is full; task 5's entry replaces the one this
  change consumed.
