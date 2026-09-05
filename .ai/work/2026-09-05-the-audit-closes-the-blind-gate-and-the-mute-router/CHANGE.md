---
change: the-audit-closes-the-blind-gate-and-the-mute-router
branch: skills-audit
created: 2026-09-05
status: shaping # shaping | building | landed
---

# Change — the manifest gate reads what it ships, and the router learns the words users type

## Goal

Two audit findings, both measured, both closed in this branch.

- `pnpm validate:manifests` fails when a `SKILL.md` is malformed. Today it cannot: the validator
  skips symlinks and the script reads only the exit code, so all 12 skills are unchecked in CI.
- `pnpm eval:routing` clears 75% rank-1 with at most one blank, up from 70% and three blanks
  against a `--max-blank 3` ceiling that is already full.

## Decisions

- Both findings land as one change, not two — asked and answered; `dw-shape`'s N≥2 split rule was
  overridden deliberately, so it is not reopened. They share the version bump, the release and the
  audit that produced them.
- Every cheap follow-up the audit raised is done here rather than queued — the backlog is at its
  cap of 8 with zero headroom, and an entry that costs less to do than to file should not be filed.
- Only the genuinely large follow-ups are parked, folded into the existing
  `2026-08-30-slim-the-off-loop-skills` entry — no new backlog file, so the cap holds.
- `dw-shape`'s own description is never touched. It scores 6/6, the only perfect scorer; any word
  added to it is a measurement, not an edit.
- `diff` goes to `dw-check` alone. Three descriptions hold it today, which is why every prompt
  containing it is decided by the rest of the vector; `dw-check` is the mid-build owner.
- Descriptions carry English nouns, never literal paths. `.ai/work/<slug>/CHANGE.md` tokenizes to
  `ai`, `work`, `slug`, `md` — dead stems that enlarge the vector norm and divide down real terms.
- This change is **large** — ten slices. It is being built in one pass at the user's explicit call.

## Tasks

<!-- Convention: `- [ ]` pending, `- [x]` done — `dw-next` flips the box in the task's own commit.
A task that stopped being necessary keeps its box and gains `**skip:** <reason>`; every later
invocation reads that as not remaining. Never rename a task title. -->

- [ ] 1. `scripts/validate-manifests.sh` validates a `cp -RL` dereferenced copy of every plugin and
      fails on warnings, not just on exit code. `scripts/tests/validate-manifests.test.sh` pins both
      halves: a broken `SKILL.md` behind a symlink fails, a clean tree passes.
- [ ] 2. `skills/dw-next/SKILL.md` description — drop the meta opener that collides with `dw-doctor`,
      add `continue` / `catch up` / `left to do`, strip the literal path. Re-measure; leave
      "pick … back up" out, traded away on 2026-08-18.
- [ ] 3. `skills/dw-check/SKILL.md` description — the corpus has zero occurrences of `bug`,
      `mistake`, `wrong`, `broken`; add that vocabulary plus `so far` and `second opinion`, and move
      `codex` out of the unscored `argument-hint`. Re-measure.
- [ ] 4. `skills/dw-land/SKILL.md` description — add `pull request`, `done`, `leftovers`; release
      `diff` to `dw-check`; strip the literal paths. Re-measure alone, `dw-shape` is at risk here.
- [ ] 5. `skills/dw-doctor/SKILL.md` and `skills/dw-grill/SKILL.md` descriptions — `pre-commit` and
      `silently skipping`; `ambiguous` and `requirements`. Uncontested vocabulary. Re-measure.
- [ ] 6. `argument-hint` is one style everywhere: the middot argument list. `dw-grill` and
      `dw-shape` stop asking a question in a slot that describes arguments; `dw-doctor` and
      `dw-prune` say in the body that they take none, the way `dw-ship` already does.
- [ ] 7. Verify what the harness does with `$ARGUMENTS` mid-prose. If it substitutes, the four
      skills that explain the token inline lose the explanation at the moment it applies — fix them
      to name "the argument" in prose and keep one bare trailer.
- [ ] 8. `license` in all three `plugin.json` and their marketplace entries. The root MIT `LICENSE`
      never ships: `source` is `./plugins/<p>`, so the install cache carries no license at all.
- [ ] 9. Version bumps for every plugin whose shipped payload moved, synced into
      `.claude-plugin/marketplace.json`; corpus baseline updated in this diff if the corpus grew.
- [ ] 10. Fold the parked follow-ups into `2026-08-30-slim-the-off-loop-skills`: the `dw-init`
      268-line split, the `dw-grain` opener, the `dw-doctor` check enumeration.

## Anchors

- `scripts/validate-manifests.sh:13` — `if ! claude plugin validate "$file"` — exit code only, so
  the validator's own warnings are discarded.
- `evals/skills.ts:108` — "Name plus description, and nothing else. That is the whole surface the
  router chooses" — why `argument-hint` is unscored.
- `evals/routing.ts:5` — the scorer: `name: description` pairs, TF-IDF + cosine.
- `scripts/validate-artifacts.sh:64` — `BACKLOG_CAP=8`, currently full.
- `skills/dw-ship/SKILL.md:12` — the model for a skill that says it takes no arguments.

## References

- `node evals/routing.ts --explain "<prompt>"` — measures a candidate description before it is
  committed; shows which stems were kept and who holds them.
- `claude plugin validate <manifest>` — prints "N entries here are symlinks and were not read …
  validate the real paths separately", then exits 0.
- `.ai/archive/2026-09-03-evals-accuracy-and-gates/CHANGE.md` — added the blank tally and the
  `--max-blank` gate; the blanks this change closes were left there as measurement.

## Notes

Appended while building — surprises, dead ends, things the next session needs, **one line each**;
the diff holds the detail. `dw-land` reads this when deciding what is durable enough to promote.

- The loaded `dw-shape` came from the install cache at 0.7.0 while the repo canon is 0.7.1 — the
  audit's "you do not run what you edit" finding, observed live during this shaping.
