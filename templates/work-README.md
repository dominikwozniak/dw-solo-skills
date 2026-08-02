# `.ai/` — tracked agent working memory

Not throwaway chat scratch. Committed, travels with the repo, matched to the current
git branch. Written and read by the `dw-*` skills as the source of truth for what the
active change is and where it stands.

## Layout

```
work/<slug>/CHANGE.md   the live state of ONE change    (dw-shape writes, dw-next ticks)
                        goal · decisions taken · task checklist · anchors
                        branch: unclaimed until dw-start / dw-next claims it into a branch
work/<slug>/HANDOFF.md  the middle of a task, saved     (dw-handoff writes, dw-next clears)
                        optional — appears only with the dw-solo-extras plugin installed
BACKLOG.md              follow-ups not being done now   (dw-land parks, dw-shape takes)
```

## The one asymmetry to know

- **`work/<slug>/CHANGE.md` is persistent but disposable.** Tracked, so a week-long
  gap and a `/clear` change nothing — and **deleted by `dw-land`** at merge, once
  anything durable has been promoted out.
- **`work/<slug>/HANDOFF.md` is shorter-lived still.** It describes the middle of one
  task, so `dw-next` deletes it as soon as that task is ticked. Only ever one at a
  time; a new handoff overwrites the old.
- **`BACKLOG.md` survives.** It is the one file here that carries content forward
  between changes.

Getting this backwards is the common mistake: `CHANGE.md` does **not** survive a
merge, `BACKLOG.md` does.

## Where the durable parts go

`dw-land` promotes out of `CHANGE.md` before deleting it, to four targets:

- `docs/decisions/` — hard-to-reverse decisions, one record each
- `CONTEXT.md` — domain terms, glossary only
- `## Gotchas` in `CLAUDE.md` — traps that cost real time (auto-loaded, so the next
  session reads them unasked)
- `.ai/BACKLOG.md` — ordinary follow-ups that clear none of the above bars

## Rules

- **Tracked on purpose** — `git add` and commit these alongside the code.
- Skills own these files; don't hand-edit mid-change.
- Safe to read anytime. To pick up after a `/clear`: `dw-next` bare reads from disk.
- `BACKLOG.md` stays a flat list — no status column, no priority, no frontmatter. The
  moment it grows a schema it is the validated plan this lane exists to avoid.
