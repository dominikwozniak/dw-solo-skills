---
decision: 0016
status: active # active | superseded
date: 2026-08-22
---

# 0016 — Each `.ai/` lane stamps its own date in the entry name

## Context

The three `.ai/` lanes sorted alphabetically, so 43 archive folders were a wall of names in arbitrary
order even though every entry already carried its date in frontmatter — readable only by opening the
file. [`0004`](0004-archive-landed-changes.md) settled that landed docs are archived rather than
deleted, and that decision stands; what it also described in passing — "one slug travels backlog →
work → archive", a single name moving between lanes by `git mv` — is what this record refines.

## Decision

Every entry in `.ai/work/`, `.ai/backlog/` and `.ai/archive/` is named `<YYYY-MM-DD>-<slug>`, derived
by `slugify.sh dated`. **Each lane stamps its own date**: the day a follow-up was noted, the day a
change was shaped, the day it landed. So the same change is one name in `work/` and another in
`archive/`, and only the **bare slug** is comparable across lanes — `slugify.sh undate` strips a
prefix, and `CHANGE.md`'s `change:` field holds the slug bare, being the identity that has to survive
the move. `docs/decisions/` is exempt: its `NNNN-` numbering already sorts, and every
`superseded-by:` pointer is made of that number.

`undate` strips rather than validates, so an undated entry passes through unchanged. A repo that
installs the new skills without renaming anything keeps a correct duplicate-work guard and a correct
work↔archive pairing — the migration is a tidy-up, never a prerequisite.

## Trade-off

Two comparisons that were string equality became slug equality, and that is a **loosening**, not a
translation: an exact folder name was unique by construction, a bare slug is reusable. `dw-ship`'s
resurrection sweep runs `git rm -r` on what it matches, so it needed a second condition — the folder
must also read `branch: unclaimed` and `status: shaping` against a twin reading `landed:` or
`rejected:` — where before the name alone was proof. Paying for a sortable listing with a weaker
identity on the one step that deletes work is the real cost here.

Keeping the date only in frontmatter was the alternative, and it costs nothing to maintain: no
renames, no per-lane rule, no prefix to strip. It was rejected because the date is then invisible at
exactly the moment it is wanted — reading the folder — and `dw-prune` and `dw-start` both had to
justify an ordering the folder could not give them.

## Revisit when

A bare-slug collision is observed between live work and an archived change — the case the sweep's
second condition exists to survive — or an entry is found whose name and `created:`/`landed:` field
disagree, which would mean a rename invented a date instead of reading one.
