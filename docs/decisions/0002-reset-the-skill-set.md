---
decision: 0002
status: active
date: 2026-08-01
---

# 0002 — Wipe the inherited skill set, keep the harness

## Context

[`0001`](0001-separate-repo-from-dw-skills.md) split this repo out of `dw-skills` and shipped eight
skills in the same commit: the five loop skills plus `dw-git`, `dw-doctor` and `dw-setup-precommit`.
None of them were designed for this lane — the loop five were carried over wholesale and the other
three were forks. The result was a catalogue nobody had authored against the thin lane's actual
constraint (one reader), only adapted toward it.

## Decision

Delete all eight skills — canon directories, `references/`, `skills/dw-doctor/scripts/doctor.sh`, and
the eight plugin symlinks — and design the replacements from scratch. Plugin version `0.2.0` → `0.3.0`.

Everything that is not a skill stays: the marketplace and plugin manifests, the symlink canon, the
three validators, the five bash self-tests, six CI workflows, this repo's own `.claude/hooks/`, the
whole `templates/` payload, and `scripts/runtime/slugify.sh` with its symlink. The harness is the
part that took ~40 files to stand up; the skills are the cheap part to rewrite.

Two consequences worth naming:

- `scripts/validate-manifests.sh` needed a real fix — its `for d in skills/*/` loop passed the
  unexpanded glob through when `skills/` is empty and errored on a literal `*`. It now guards with
  `[ -d "$d" ] || continue`.
- The docs are coupled to the skill list on purpose (`validate:docs` enforces it), so the README
  task-router, both loop diagrams and every explicit-only list were removed rather than left
  dangling. `docs/DESIGN.md` and `docs/SKILL-ANATOMY.md` were rewritten to name **roles** — "the
  closing pass", "the resume step" — so the design constraints survive without referents on disk.

## Trade-off

The design rationale in `docs/DESIGN.md` was derived from skills that no longer exist, so it is now
asserted rather than demonstrated. That is accepted: those constraints are the reason the lane exists
and are worth writing the new skills against, but until a skill implements one it is a claim, not
evidence.

`scripts/runtime/slugify.sh` is kept with no consumer — it was `dw-shape`'s. Keeping it holds the
shipped-script path proven end to end by CI, at the cost of one file of dead weight.

`templates/CLAUDE.local.md` and `templates/work-README.md` still name `dw-shape`, `dw-next` and
`dw-land` in prose. Nothing validates the template payload, so those references dangle until the new
workflow skills land and the templates are rewritten to match.

## Revisit when

The first three or four new skills exist. At that point re-read `docs/DESIGN.md` against what was
actually built and correct whatever the rebuild disproved — and rewrite the template payload's prose.
