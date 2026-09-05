---
change: the-audit-closes-the-blind-gate-and-the-mute-router
branch: skills-audit
created: 2026-09-05
status: landed # shaping | building | landed
landed: 2026-09-05
pr: "#58"
---

# Change — the manifest gate reads what it ships, and the router learns the words users type

## Tasks

<!-- Convention: `- [ ]` pending, `- [x]` done — `dw-next` flips the box in the task's own commit.
A task that stopped being necessary keeps its box and gains `**skip:** <reason>`; every later
invocation reads that as not remaining. Never rename a task title. -->

- [x] 1. `scripts/validate-manifests.sh` validates a `cp -RL` dereferenced copy of every plugin and
      fails on warnings, not just on exit code. `scripts/tests/validate-manifests.test.sh` pins both
      halves: a broken `SKILL.md` behind a symlink fails, a clean tree passes.
- [x] 2. `skills/dw-next/SKILL.md` description — drop the meta opener that collides with `dw-doctor`,
      add `continue` / `catch up` / `left to do`, strip the literal path. Re-measure; leave
      "pick … back up" out, traded away on 2026-08-18.
- [x] 3. `skills/dw-check/SKILL.md` description — the corpus has zero occurrences of `bug`,
      `mistake`, `wrong`, `broken`; add that vocabulary plus `so far` and `second opinion`, and move
      `codex` out of the unscored `argument-hint`. Re-measure.
- [x] 4. `skills/dw-land/SKILL.md` description — add `pull request`, `done`, `leftovers`; release
      `diff` to `dw-check`; strip the literal paths. Re-measure alone, `dw-shape` is at risk here.
- [x] 5. `skills/dw-doctor/SKILL.md` and `skills/dw-grill/SKILL.md` descriptions — `pre-commit` and
      `silently skipping`; `ambiguous` and `requirements`. Uncontested vocabulary. Re-measure.
- [x] 6. `argument-hint` is one style everywhere: the middot argument list. `dw-grill` and
      `dw-shape` stop asking a question in a slot that describes arguments; `dw-doctor` and
      `dw-prune` say in the body that they take none, the way `dw-ship` already does.
- [x] 7. Verify what the harness does with `$ARGUMENTS` mid-prose. If it substitutes, the four
      skills that explain the token inline lose the explanation at the moment it applies — fix them
      to name "the argument" in prose and keep one bare trailer.
- [x] 8. `license` in all three `plugin.json` and their marketplace entries. The root MIT `LICENSE`
      never ships: `source` is `./plugins/<p>`, so the install cache carries no license at all.
- [x] 9. Version bumps for every plugin whose shipped payload moved, synced into
      `.claude-plugin/marketplace.json`; corpus baseline updated in this diff if the corpus grew.
- [x] 10. Fold the parked follow-ups into `2026-08-30-slim-the-off-loop-skills`: the `dw-init`
      268-line split, the `dw-grain` opener, the `dw-doctor` check enumeration.

## Notes

- The loaded `dw-shape` came from the install cache at 0.7.0 while the repo canon is 0.7.1 — the
  audit's "you do not run what you edit" finding, observed live during this shaping.
- `claude plugin eval` is gated behind early access, so the first-party harness that would measure
  these skills against a no-plugin baseline was unavailable; the routing eval carried the whole
  measurement, which it could because this change moved only descriptions.
- `enforce-commit-hygiene.sh` falsely blocks a heredoc whose body mentions `git add -A`, including
  a `git commit -F -` writing a message about that very rule. Found here, not fixed here.
