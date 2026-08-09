---
change: decision-record-contract-for-consumer-repos
branch: decision-record-contract-for-consumer-repos
created: 2026-08-08
landed: 2026-08-09
status: landed # shaping | building | landed
---

# Change — `docs/decisions/` ships its own contract, and supersession becomes a thing a skill does

## Goal

A repo scaffolded by `dw-init` gets `docs/decisions/README.md` stating what a decision record is —
the bar, the file shape, the numbering, and how to supersede one — instead of a bare `.gitkeep`. You
know it worked when a fresh `dw-init` run leaves that file in place, and when `dw-land`'s promote step
tells a session to flip an old record rather than only ever appending a new one.

## Decisions

- **The README carries the record contract, not the promotion split** — the "decisions vs `CONTEXT.md`
  vs `## Gotchas`" table already lands in the same target repo via `templates/work-README.md:37-46`;
  a second copy is the drift trap in `## Gotchas`. What a consumer repo genuinely lacks is the
  contract, which lives only in the plugin cache.
- **No index of records** — the request was a router over `docs/decisions/`. Rejected: a table
  appended one row at a time by `dw-land`, in a repo this project never sees and cannot validate,
  goes stale silently. Descriptive `<NNNN>-<slug>.md` filenames are the index; `superseded-by:` in
  frontmatter is greppable.
- **The supersession fix ships with the README, not after it** — splitting was offered and declined:
  a shipped README documenting a protocol no skill performs is decoration.
- **One change, not two** — the payload half (`dw-solo-setup`) and the skill half (`dw-solo`) could
  each land green on their own, but the second is what makes the first true. Two bumps, one PR.
- **No `dw-doctor` check** — it already reports the folder's presence; a README warning is noise on a
  read-only diagnostic.
- **The dogfood copy is hand-written, not a symlink** — `templates/` is payload copied verbatim into
  a target project; `plugins/dw-solo-setup/templates` is the only symlink to it.

## Tasks

- [x] 1. `templates/decisions-README.md` (new, 26 lines): the bar (all three, zero records is the
      correct number), superseding, and one "not here" line pointing at `CONTEXT.md` and
      `## Gotchas`. **The shape is not described at all** — reversed after review against
      `grateful-me-app-v2/docs/decisions/README.md`, which is the same contract at 24 lines and
      proves the point: in a folder that has records, the records are the shape spec, so
      "`0001` is the worked example — copy its shape" replaces the whole section. A prose spec for
      the frontmatter and the four H2s would have been a third copy of what `dw-land`'s reference
      already holds, and the copy most likely to drift. It shipped at 41 lines with that section
      first; cutting it landed back inside the ~25-35 this task asked for.
      Then `skills/dw-init/SKILL.md:81-87` — drop `docs/decisions` from the `.gitkeep` list, add the
      README to the verbatim-copy bullet, existing records left alone. Bump `dw-solo-setup`
      0.1.8 → 0.1.9 in `.claude-plugin/marketplace.json` **and**
      `plugins/dw-solo-setup/.claude-plugin/plugin.json`, identical.
- [x] 2. `skills/dw-land/references/decision-record.md` — replace the two-line `:22-24` paragraph
      with a short `## Superseding` section: never rewrite, flip `status`, reciprocal `supersedes:` /
      `superseded-by:`, **`dw-land` is what flips the old record**, and readers do **not** skip
      superseded records. Then `skills/dw-land/SKILL.md:67-71` — one appended sentence, no new
      bullet, and fix `or` → **all three** in the same breath (`:70`, the drift bullet below). Bump
      `dw-solo` 0.4.10 → 0.4.11 in both manifest files.
- [x] 3. `docs/decisions/README.md` — the dogfood copy, hand-written, mirroring the template.

## Anchors

- `skills/dw-init/SKILL.md:81-82` — the `mkdir` + `.gitkeep` line to edit; `:83-90` is the
  verbatim-copy pattern for the other three READMEs to follow. Check `:28` (scaffold table) and
  `:159` (the tracked/ignored split) for whether they enumerate seeded files.
- `templates/backlog-README.md` — the closest neighbour in voice and length; the new template copies
  its shape, not `archive-README.md`'s three-paragraph essay form.
- `skills/dw-land/references/decision-record.md:7-24` — the bar and the two-line supersession
  paragraph being replaced; `:26-56` is the fenced record template the new README must **not**
  duplicate; `:58-67` the glossary-vs-records split.
- `skills/dw-land/SKILL.md:67-71` — the **Promote the decisions** bullet: both the appended sentence
  and the `or` → all-three fix land here.
- `scripts/validate-manifests.sh:159-179` — asserts only that `templates/hooks` exists and that
  `plugins/dw-solo-setup/templates` is a symlink. It will **not** catch a missing or misnamed
  template file; verify that one by hand.
- `.claude-plugin/marketplace.json:13,21` — the two versions to bump, each mirrored in its own
  `plugins/*/.claude-plugin/plugin.json:3`.

## Notes

- **Candidate `## Gotchas` line for `dw-land`**: the contract now exists in three places that no
  validator ties together — `templates/decisions-README.md` (payload),
  `skills/dw-land/references/decision-record.md` (the canon the loop reads), and
  `docs/decisions/README.md` (dogfood). The dogfood copy says so in its own second paragraph, which
  is the only thing pointing a reader at the other two. Same shape as the vendored-from-`dw-skills`
  trap, but inside one repo.
- **The consumed bullet has moved since shaping.** `.ai/backlog/skill-and-docs-drift.md` is gone —
  it was already promoted to `.ai/work/skill-and-docs-drift/CHANGE.md`, still `unclaimed`. So at
  close, `dw-land` drops the first bullet from **that change doc**, not from a backlog entry. Task 2
  resolved it here; whoever claims that change must not fix the same sentence twice.
- **Consumes one bullet from `.ai/backlog/skill-and-docs-drift.md`** — the first, `dw-land/SKILL.md:68-70`
  writing the bar as "or" against `decision-record.md:9`'s "all three". Folded in because it is the
  same sentence task 2 edits and the shipped README states "all three". `dw-land` should drop that
  bullet from the entry at close, leaving the other four.
- `.ai/backlog/setup-payload-sweep.md` also touches `dw-solo-setup` payload and its bump. Not merged
  here — different files, and it is explicitly bundled for its own single bump. If it lands first,
  re-check the version this change targets (`## Gotchas`: a squash-merge can take the number).
- Both edited skill bodies are **unexercised until reinstall**. The session that builds this serves
  `dw-solo/0.4.10` from the plugin cache — read the canon text, never validate by invoking the skill.
- Full gate before push:
  `pnpm lint && pnpm format && pnpm validate:manifests && pnpm validate:artifacts && pnpm validate:docs && pnpm validate:evals && pnpm eval:routing`.
  No new skill and no `description` change, so `eval:routing` should be unmoved; a shift means
  something else drifted.
- Task 1 also had to touch `dw-init:28` — the scaffold table enumerates seeded READMEs per row
  (`.ai/backlog/` + its `README.md`), so `docs/decisions/` needed the same treatment; prettier
  realigns the whole table when that cell grows. `:163` (tracked/ignored) names the directory only
  and needed nothing.
