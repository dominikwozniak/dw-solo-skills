---
decision: 0005
status: active
date: 2026-08-02
---

# 0005 — Eval case files live at the repo root, never beside the skill they measure

## Context

A plugin ships a skill by symlinking the whole `skills/<name>/` directory, and install dereferences
that symlink. Anything sitting next to a `SKILL.md` therefore travels to every consumer of the
marketplace, whether or not it has any business there. The routing evals needed a home for seven case
files and two runners, and the obvious one — `skills/<name>/evals.json`, right next to the
description it measures — is the one option the packaging forbids.

## Decision

`evals/` sits at the repo root, in the same never-shipped bracket as `scripts/` root. A skill's
routing cases are `evals/cases/<name>.json`.

## Trade-off

Locality, and it is not free. The cases now live in a different tree from the description they
measure, and nothing in a skill directory hints that a second edit exists elsewhere — so adding a
skill means remembering two places, and renaming one means remembering three.
That was paid back by `scripts/validate-evals.sh`, which failed when a model-invocable skill had no
case file and when a case file had no model-invocable skill; it was deleted in
`de-ratchet-the-solo-lane`, and the contract is now one line of the add-a-skill checklist in
`AGENTS.md` — so the cost sits on the reader again. Colocation would have removed it entirely. It
would also have shipped test fixtures to every consumer, and left a skill's own directory able to fail
its own install.

The same reasoning does not extend to everything: a script only one skill uses still belongs in
`skills/<name>/scripts/`, because there the shipping is the point.

## Revisit when

Claude Code stops dereferencing symlinks at install, or gains a way to mark a path inside a plugin as
not-shipped. Either one removes the constraint this decision is built on, and colocation becomes the
better answer the moment it does.
