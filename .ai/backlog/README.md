# `.ai/backlog/` — one file per follow-up

Ideas not being worked on now. `dw-land` parks them here; `dw-shape` takes one as the seed of a new
change (`git mv` → `.ai/work/<slug>/CHANGE.md`) — the slug travels backlog → work → archive.

Shape of an entry, `<slug>.md`: frontmatter `created: YYYY-MM-DD` (optional `source:` naming the
change that parked it), an H1 saying what-and-why in one line, at most ~3 lines of context.
Findings go by pointer to `.ai/archive/<slug>` — never inlined. No status, no priority, and
nothing validates these files, deliberately.

One exception to the three lines: an entry may **bundle** several small fixes as a bullet list when
they ship together — same version bump, same gate run, one PR. Say in the lead sentence what makes
them one change, and keep each bullet to what a session needs to find the code.

Two bars, and an entry clears both. **Will you ever?** — if you would not pick it up within a month,
don't write it. **Should it have been done now?** — if doing it costs less than describing it, do it
now: a fix that fits in a file the change already touched, or that is smaller than the entry
describing it, is a commit in that change, not a file here.

**This folder is capped** — `validate-artifacts.sh` holds the number and fails with it (this README
doesn't count). One over means one of three things happens first: bundle the new entry with a cousin
that ships alongside it, absorb the cheapest one into the change that is open, or admit an old one
failed the month bar and `git rm` it. The cap exists because a backlog nobody ever deletes from stops
being a queue and becomes a record of everything you once considered.
