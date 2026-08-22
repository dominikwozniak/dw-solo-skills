---
change: date-prefix-the-solo-lane-slugs
branch: date-prefix-the-solo-lane-slugs
created: 2026-08-22
status: building # shaping | building | landed
---

# Change — the three `.ai/` lanes carry their date in the directory name

## Goal

`ls .ai/work`, `ls .ai/backlog` and `ls .ai/archive` read as timelines instead of alphabetical walls.
Every new entry is named `YYYY-MM-DD-<slug>` from `slugify.sh`, every existing entry is renamed to its
own recorded date, and the lane still pairs a work directory with its archive twin — `dw-ship`'s
resurrection sweep and `dw-shape`'s duplicate-work guard both keep working across differing prefixes.

## Decisions

- `docs/decisions/` keeps its `NNNN-` numbering — it already sorts, and `superseded-by:` is that number.
- Each lane stamps its own date (backlog = noted, work = shaped, archive = `landed:`/`rejected:`) — the
  dates already in frontmatter are the source, so no rename invents one.
- Cross-lane comparison moves to the date-stripped slug, via a `slugify.sh undate` subcommand — telling
  six skills to sed the prefix off is the drift that script exists to stop.
- New `dated` uses `date +%F`; the callerless `run-id` keeps `%Y%m%d` — different lanes, not a fix.
- No validator on the new format — `docs/decisions/0015` gates size never shape, and both
  `work-README` and `backlog-README` promise non-validation deliberately.
- `.ai/archive/design-rationale.md` is dated too (`2026-08-11-`, the date its banner declares) and
  stays a loose file — fit to the flow, but it is not a change, so no directory and no frontmatter.
- One change, not three — the retro-rename in both repos is the same goal as the mechanism, and the
  request said so ("ten sam work item").
- The retro-rename is a throwaway `git mv` sweep, not a shipped tool — two repos, once.

## Tasks

- [x] 1. `slugify.sh` gains `dated` and `undate`, with pinned `SLUG_DATE` cases in its self-test.
- [x] 2. `dw-shape` mints dated slugs for work and backlog, and runs its taken-slug guard on bare slugs.
- [x] 3. `dw-land` re-stamps the archive destination to `landed:`/`rejected:`; its backlog writes are dated.
- [x] 4. `dw-ship`'s resurrection sweep pairs work to archive on the bare slug — the destructive one.
- [x] 5. `dw-start` and `dw-prune` sort by name; prune's "age is the only signal" line stops being wrong.
- [x] 6. Templates and docs say "one slug, re-dated at each lane"; bump the plugins, refresh the ratchet.
- [ ] 7. Rename this repo's 43 archive dirs, the loose `design-rationale.md` and 7 backlog files; fix the
      `AGENTS.md` archive pointer.
- [ ] 8. Rename grateful-me-app-v2's 20 entries; fix its 3 code/doc pointers and its own lane prose.
- [ ] 9. Park grateful-me-app-v2's five verbatim-template `status:` comments in its own `.ai/backlog/`.

## Anchors

- `scripts/runtime/slugify.sh:24` — the one `slug()` function `dated`/`undate` must reuse; `:16` is the
  `$SLUG_DATE` override precedent.
- `skills/dw-shape/SKILL.md:34` mints the slug; `:36-42` is the taken-slug and `status: rejected` guard.
- `skills/dw-land/references/promote.md:68-75` — the `git mv` to archive, today a same-string move.
- `skills/dw-ship/SKILL.md:96,104` — `git rm -r` on an exact-slug twin match. Get this one wrong and it
  deletes live work.
- `skills/dw-prune/SKILL.md:31` — "oldest first, because age is the only signal the folder records".
- `templates/backlog-README.md:5`, `templates/work-README.md:20` — the "one slug travels" promise.
- `docs/agents/change-artifacts.md:25` — "never the date or the `status:`"; still true, now the bare slug.

## Notes

- `docs/decisions/0004` states "one slug travels backlog → work → archive" and is now partly
  superseded — records are never rewritten, so this change owes a new one at land time.
- `templates/work-README.md`'s layout block is where the name shape is stated once; every other
  `<date>-<slug>` in the docs is a placeholder swap that added no words to the corpus.

- Branches and worktrees stay undated — only the three lanes carry a date, and `worktree.sh`
  has no `.ai/` coupling at all, so `dw-start` says "the bare slug" where the ambiguity is new.

- A bare slug is reusable where an exact folder name was not, so `dw-ship`'s sweep needed a second
  condition (`unclaimed` + `shaping`, twin `landed:`/`rejected:`) or it could `git rm -r` live work.

- The skill-corpus ratchet moves with each skill edit here — the dated-name/bare-slug
  distinction is a new concept the hot-loop skills have to carry, so it is recorded, not trimmed away.

- `undate` strips only the `%F` form — eating 8 leading digits could truncate a real slug,
  and the `run-id` prefix belongs to a lane these three don't share.
- `undate` must never re-slugify: its input is a name off disk, so a name that already broke the
  rule has to come back unchanged instead of being silently rewritten.
