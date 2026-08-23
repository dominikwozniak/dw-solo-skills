# `.ai/backlog/` — one file per follow-up

Ideas not being worked on now. `dw-land` and `dw-shape` both park them here — the first at land time,
the second when shaping decides an item is out of the change. `dw-shape` also takes one as the seed of
a new change (`git mv` → `.ai/work/<date>-<slug>/CHANGE.md`) — the **bare slug** travels backlog →
work → archive, while each lane stamps its own date.

**An entry is the expensive tier, and most follow-ups never reach it.** The default resting place
for a leftover is a line in the land report and the PR body — no file. A file here is only for work
that genuinely exceeds the session it was found in, and it pays for that: frontmatter
`created: YYYY-MM-DD` (the same date as the prefix), `why-not-now:` naming what blocks it, and
`effort:` with an honest size (optional `source:` naming the change that parked it). A blocker you
cannot name means the item belonged in the report — or done on the spot.

Shape of an entry, `<date>-<slug>.md` from `slugify.sh dated`: the frontmatter above, an H1 saying
what-and-why in one line, at most ~3 lines of context. Findings go by pointer to
`.ai/archive/<date>-<slug>` — never inlined. No status, no priority, and
nothing validates these files, deliberately.

One exception to the three lines: an entry may **bundle** several small fixes as a bullet list when
they ship together — same version bump, same gate run, one PR. Say in the lead sentence what makes
them one change, and keep each bullet to what a session needs to find the code.

Two bars, and an entry clears both. **Will you ever?** — if you would not pick it up within a month,
don't write it. **Should it have been done now?** — **nothing blocks it and doing it costs less than
describing it → the current change, now**, not a file here. That is the default, not a judgement to
weigh: a fix that fits in a file the change already touched, or that is smaller than the entry
describing it, is a commit in that change. Only genuinely blocked work — waiting on a decision, a
dependency, or a change not yet made — earns an entry.
