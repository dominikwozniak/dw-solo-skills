# `.ai/` — tracked agent working memory

Not throwaway chat scratch. Committed, travels with the repo, matched to the current
git branch. Written and read by the `dw-*` skills as the source of truth for what the
active change is and where it stands.

## Layout

```
backlog/<slug>.md       follow-ups not being done now   (dw-land + dw-shape park, dw-shape takes)
                        created: frontmatter · H1 one-liner · ≤3 lines of context
work/<slug>/CHANGE.md   the live state of ONE change    (dw-shape writes, dw-next ticks)
                        goal · decisions taken · task checklist · anchors
                        branch: unclaimed until dw-start / dw-next claims it into a branch
work/<slug>/HANDOFF.md  the middle of a task, saved     (dw-handoff writes, dw-next clears)
                        optional — appears only with the dw-solo-extras plugin installed
archive/<slug>/         landed changes, kept as history (dw-land moves the doc at close)
```

One slug travels the three states: an idea starts as `backlog/<slug>.md`, `dw-shape` moves
it in as `work/<slug>/CHANGE.md` (`status: shaping → building`), and `dw-land` closes it
into `archive/<slug>/` (`status: landed`, stamped `landed:` + `pr:`).

## The lifetimes to know

- **`work/<slug>/CHANGE.md` is persistent, then archived.** Tracked, so a week-long
  gap and a `/clear` change nothing — and **moved to `archive/` by `dw-land`** at
  merge, once anything durable has been promoted out. A squash merge would otherwise
  erase its worked state from history entirely.
- **`work/<slug>/HANDOFF.md` is short-lived.** It describes the middle of one task, so
  `dw-next` deletes it as soon as that task is ticked — and `dw-land` removes a
  leftover one before archiving. Only ever one at a time; a new handoff overwrites
  the old.
- **`archive/` is history, not guidance.** Nothing reads it to decide anything; the
  durable layer lives in `docs/decisions/`, `CONTEXT.md` and `## Gotchas`.

## Where the durable parts go

`dw-land` promotes out of `CHANGE.md` before archiving it, to four targets:

- `docs/decisions/` — hard-to-reverse decisions, one record each
- `CONTEXT.md` — domain terms, glossary only
- `## Gotchas` in `CLAUDE.md` — traps that cost real time (auto-loaded, so the next
  session reads them unasked)
- `.ai/backlog/<slug>.md` — ordinary follow-ups that clear none of the above bars;
  findings by pointer to `.ai/archive/<slug>`, never inlined

## Rules

- **Tracked on purpose** — `git add` and commit these alongside the code.
- Skills own these files; don't hand-edit mid-change.
- Safe to read anytime. To pick up after a `/clear`: `dw-next` bare reads from disk.
- Backlog entries stay minimal — `created:` plus an H1; no status, no priority. The
  moment the backlog grows a schema it is the validated plan this lane exists to
  avoid, and nothing validates it, deliberately.
