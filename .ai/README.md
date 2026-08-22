# `.ai/` — tracked agent working memory

Not throwaway chat scratch. Committed, travels with the repo, matched to the current
git branch. Written and read by the `dw-*` skills as the source of truth for what the
active change is and where it stands.

## Layout

```
backlog/<date>-<slug>.md      follow-ups not being done now   (dw-land + dw-shape park, dw-shape takes)
                              entry shape and the two bars: backlog/README.md
work/<date>-<slug>/CHANGE.md  the live state of ONE change    (dw-shape writes, dw-next ticks)
                              goal · decisions taken · task checklist · anchors
                              branch: unclaimed until dw-start / dw-next claims it
work/<date>-<slug>/HANDOFF.md the middle of a task, saved     (dw-handoff writes, dw-next clears)
                              optional — only with the dw-solo-extras plugin installed
archive/<date>-<slug>/        landed changes, kept as history (dw-land moves the doc at close)
```

`<date>` is `YYYY-MM-DD` from `slugify.sh dated`, and **each lane stamps its own**: the day
the entry was noted, the day the change was shaped, the day it landed. That is what makes a
plain listing read as a timeline.

The **bare slug** is what travels the three states: an idea starts as `backlog/<date>-<slug>.md`,
`dw-shape` moves it in as `work/<date>-<slug>/CHANGE.md` (`status: shaping → building`), and
`dw-land` closes it into `archive/<date>-<slug>/` (`status: landed`, stamped `landed:` + `pr:`)
under a fresh date. Only the slug is comparable across the lanes — which is why `CHANGE.md`'s
`change:` field holds it bare, and why anything matching one lane against another strips the
prefix with `slugify.sh undate` rather than comparing folder names.

## The lifetimes to know

- **`work/<date>-<slug>/CHANGE.md` is persistent, then archived.** Tracked, so a week-long
  gap and a `/clear` change nothing — and **moved to `archive/` by `dw-land`** at
  merge, once anything durable has been promoted out. A squash merge would otherwise
  erase its worked state from history entirely.
- **`work/<date>-<slug>/HANDOFF.md` is short-lived.** It describes the middle of one task, so
  `dw-next` deletes it as soon as that task is ticked — and `dw-land` removes a
  leftover one before archiving. Only ever one at a time; a new handoff overwrites
  the old.
- **`archive/` is history, not guidance.** Nothing reads it to decide anything; the
  durable layer lives in `docs/decisions/`, `CONTEXT.md` and wherever this repo keeps
  its `## Gotchas`.

## Where the durable parts go

`dw-land` promotes out of `CHANGE.md` before archiving it, to four targets:

- `docs/decisions/` — hard-to-reverse decisions, one record each
- `CONTEXT.md` — domain terms, glossary only
- `## Gotchas` — traps that cost real time. An existing root section stays the home
  where the repo already keeps one; otherwise the matching `docs/agents/<topic>.md`,
  beside the topic that sprang the trap rather than in the always-loaded root
- `.ai/backlog/<date>-<slug>.md` — ordinary follow-ups that clear none of the above bars;
  findings by pointer to `.ai/archive/<date>-<slug>`, never inlined

## Rules

- **Tracked on purpose** — `git add` and commit these alongside the code.
- Skills own these files; don't hand-edit mid-change.
- Safe to read anytime. To pick up after a `/clear`: `dw-next` bare reads from disk.
- Nothing here is validated, deliberately: the moment these files grow a schema they
  are the validated plan this lane exists to avoid. The backlog entry's shape and the
  two bars it clears are in `backlog/README.md`, which owns them.
