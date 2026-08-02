---
change: ai-folder-lifecycle
branch: ai-folder-lifecycle
created: 2026-08-02
status: building # shaping | building | landed
---

# Change — .ai lifecycle: archive landed changes, per-file backlog, backfill closed PRs

## Goal

One slug carries a theme through three folders: `.ai/backlog/<slug>.md` (idea) →
`.ai/work/<slug>/` (shaping → building) → `.ai/archive/<slug>/` (landed). `dw-land` stops deleting
worked docs — squash merges erase them from `main`'s history entirely, proven on PR #2 — and stops
inlining findings into the backlog. Known when: `dw-land`'s close phase moves and flips instead of
deleting; `.ai/BACKLOG.md` is gone, replaced by per-file entries under `.ai/backlog/`; both closed
PRs' docs sit recovered in `.ai/archive/` with `status: landed`; the five-command gate is green.

## Decisions

- **Archive, don't delete** — `git mv .ai/work/<slug>/ .ai/archive/<slug>/` at close, flip
  `status: landed`, add `landed: YYYY-MM-DD` and `pr:` to the frontmatter, keep `branch:` verbatim
  as history. The promotion step (decisions / CONTEXT / Gotchas) stays: archive is history, not a
  read layer — a "history, not guidance" README says so. Rationale: PRs squash-merge, so the worked
  doc's final state (ticked boxes, answered Notes) reaches no commit on `main`.
- **Backlog per-file, slug-only names** — `.ai/backlog/<slug>.md`: frontmatter `created:` (plus
  optional `source:`), H1 as the one-line what-and-why, at most ~3 lines of context, optional
  pointer to `.ai/archive/<slug>` for findings — never inlined findings again. One name travels
  backlog → work → archive. Parallel lands stop conflicting structurally (separate files).
- **`HANDOFF.md` dies at land, explicitly** — today `git rm -r` sweeps it implicitly; a plain
  `git mv` would carry a stale handoff into the archive, so the close step `git rm`s it first.
- **Defensive `landed` checks dropped as dead** — landed docs never sit in `.ai/work/`, so the
  "isn't `landed`" clauses in `dw-next` / `dw-handoff` / `dw-shape` guard nothing.
- **No `LOG.md` / changelog** — the archive with frontmatter dates is the log; a second append-only
  file is a new conflict magnet.
- **Payload updated in the same change** — unlike the pnpm-v11 split there is no experiment to
  learn from first; the `dw-init` + `templates/` edits are small and land together.
- **Backfill sources** — PR #2 from `79f7c3b^` (verified: full worked state, `status: building`,
  3/3 tasks ticked); PR #1 from `refs/pull/1/head` (fetch, take the parent of the commit that
  deleted the doc), falling back to shape-time `6bd71dc` plus a one-line "worked state lost to
  squash" note. Both merged 2026-08-02.

## Tasks

- [x] 1. `dw-land` archives instead of deletes — description `:6`, reads/writes `:24-28`, phase 3
      `:82-87` ("Drop the scaffolding" → "Archive the scaffolding": `git rm` a leftover
      `HANDOFF.md`, `git mv` to `.ai/archive/<slug>/`, flip `status: landed`, add `landed:` +
      `pr:`, commit promotion+archive together). Add `.ai/archive/README.md` ("history, not
      guidance", ~3 lines) to this repo.
- [x] 2. Backlog goes per-file — `dw-land:77-81` (Promote the follow-ups → create
      `.ai/backlog/<slug>.md` via `slugify.sh`, file shape per Decisions); `dw-shape:63-65`
      (read the dir as prior context) and `:95-96,100` ("delete that line" → `git mv` the file as
      the `CHANGE.md` seed, same commit); add `.ai/backlog/README.md` with the convention. Prose
      touches: `dw-next:25,81,104`, `dw-grill:81`, `dw-ship:71,73`, `dw-handoff:19`.
- [x] 3. Migrate the live backlog — split `.ai/BACKLOG.md` entries (12 by direct count; re-verify)
      into slug-named files under `.ai/backlog/`, `git rm .ai/BACKLOG.md`, one commit.
- [x] 4. Backfill the archive for PRs #1 and #2 per the recovery procedure in Decisions; both docs
      get `status: landed`, `landed: 2026-08-02`, `pr:` lines.
- [x] 5. Payload: `dw-init` + `templates/` — `dw-init` description `:4-5`, writes table `:25-27`,
      write steps `:81-85` (`mkdir -p .ai/work .ai/backlog .ai/archive` + seeds, copy the
      backlog/archive READMEs the way `work-README.md` is consumed at `:82`), replace the verbatim
      `BACKLOG.md` block `:132-149` with the per-file convention (keep the spirit of `:147-149`:
      entries carry `created:` only, still no status/priority, still nothing validates it).
      `templates/work-README.md` layout `:9-16`, asymmetry `:20-30`, targets `:34-40`, rules `:47`
      — CHANGE.md is _archived_, not deleted; `BACKLOG.md` rows become `backlog/` + `archive/`
      rows. `templates/CLAUDE.local.md:18-30` workflow lines. New template file(s) for the two
      READMEs.
- [ ] 6. Docs, dead checks, versions — `README.md:30-32,80,111-112`; `docs/DESIGN.md:26,66-84,104`;
      `CONTEXT.md:11-13`; repo `CLAUDE.local.md:18-29` (same edit as the template; gitignored, edit
      directly). Drop the dead "isn't `landed`" clauses (`dw-next:35,47`, `dw-handoff:32`,
      `dw-shape:44`); update `dw-handoff:73-75` (the `git rm -r` contract line); scope the
      detached-HEAD prose (`dw-next:50`, `dw-handoff:35`) to `.ai/work/`. Bump versions in lockstep
      (marketplace.json + each plugin.json): dw-solo 0.4.4→0.4.5, dw-solo-setup 0.1.2→0.1.3,
      dw-solo-extras 0.1.0→0.1.1.

## Anchors

- `skills/dw-land/SKILL.md:82-87` — the `git rm -r` close mechanics this change replaces.
- `skills/dw-next/SKILL.md:31`, `skills/dw-handoff/SKILL.md:28`, `skills/dw-shape/SKILL.md:43` —
  the locator contract: every grep is anchored on the literal `.ai/work/*/CHANGE.md`, nothing greps
  all of `.ai/`, so `archive/` and `backlog/` collide with nothing.
- `skills/dw-ship/SKILL.md:32-34` — the "land first if the doc is still there" precondition;
  survives unchanged because an archived doc stops matching the work-scoped grep.
- `skills/dw-handoff/SKILL.md:73-75` — asserts the old "dw-land clears with `git rm -r`" contract;
  must change with task 1.
- `skills/dw-init/SKILL.md:81-85,132-149` — the `.ai/` scaffold steps and the verbatim `BACKLOG.md`
  block being replaced.
- `templates/work-README.md`, `templates/CLAUDE.local.md:16-30` — the payload copies of the
  lifecycle prose.
- `79f7c3b^` and `refs/pull/1/head` (= `714751e`) — backfill sources; PR #3 never had a CHANGE.md
  (`git log --all --diff-filter=AD -- .ai/work/`).
- `.claude-plugin/marketplace.json:13,21,29` — the three plugin versions to bump.

## Notes

- Backfill commands verified read-only on 2026-08-02: `git show
79f7c3b^:.ai/work/pnpm-v11-migration/CHANGE.md` shows the full worked state; `git ls-remote
origin 'refs/pull/*/head'` lists pulls 1–3.
- CI cannot see a `.ai/` lifecycle regression — deliberate (`validate-artifacts.sh:7-10`); rely on
  the five-command gate plus read-back.
