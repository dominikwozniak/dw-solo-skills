---
change: decision-record-contract-for-consumer-repos
branch: unclaimed
created: 2026-08-08
status: shaping # shaping | building | landed
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

- [ ] 1. `templates/decisions-README.md` (new, ~25-35 lines, voice of `templates/backlog-README.md`):
      the bar (all three, zero records is the correct number), the shape (`<NNNN>-<slug>.md`, next in
      sequence, never renumbered; frontmatter; the four H2s) as condensed prose not a second fenced
      template, superseding, and one "not here" line pointing at `CONTEXT.md` and `## Gotchas`.
      Then `skills/dw-init/SKILL.md:81-87` — drop `docs/decisions` from the `.gitkeep` list, add the
      README to the verbatim-copy bullet, existing records left alone. Bump `dw-solo-setup`
      0.1.8 → 0.1.9 in `.claude-plugin/marketplace.json` **and**
      `plugins/dw-solo-setup/.claude-plugin/plugin.json`, identical.
- [ ] 2. `skills/dw-land/references/decision-record.md` — replace the two-line `:22-24` paragraph
      with a short `## Superseding` section: never rewrite, flip `status`, reciprocal `supersedes:` /
      `superseded-by:`, **`dw-land` is what flips the old record**, and readers do **not** skip
      superseded records. Then `skills/dw-land/SKILL.md:67-71` — one appended sentence, no new
      bullet, and fix `or` → **all three** in the same breath (`:70`, the drift bullet below). Bump
      `dw-solo` 0.4.10 → 0.4.11 in both manifest files.
- [ ] 3. `docs/decisions/README.md` — the dogfood copy, hand-written, mirroring the template.

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
