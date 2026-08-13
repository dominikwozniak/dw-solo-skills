---
change: own-root-under-budget-and-router
branch: worktree-own-root-under-budget-and-router
created: 2026-08-12
status: building # shaping | building | landed
---

# Change — this repo's own root under a declared budget, with a task router

## Goal

This repo's `AGENTS.md` (288 lines / 21.6 KB on the de-ratchet base) declares
`Budget: **120 lines / 10 KB**` and holds it: boundaries, commands and a Task Router stay in the
root; procedure and the 12 `## Gotchas` entries move to routed topic files read on demand. The
config content of the gitignored `CLAUDE.local.md` (`## Git conventions`, the command bullets)
moves into `AGENTS.md`, mirroring what the scaffold now ships. You know it worked when the root is
within budget, `pnpm validate:docs` fails on an over-budget root or a topic file with no router
row, and a fresh clone gets the git conventions and the lint command without any gitignored file.

## Decisions

- **The root budget replaces the root-gotcha cap** — `validate-artifacts.sh`'s "`## Gotchas` ≤ 12
  in `AGENTS.md`" check chases a section this change empties; the budget plus router coverage in
  `validate-docs.sh` is the successor. The backlog cap stays.
- **Topic files grow from the existing 12 gotchas' themes, not from a designed taxonomy** — the
  de-ratchet merge already grouped them (worktrees, pnpm, git history, lint hooks); those groups
  are the first topic files, applying `dw-land`'s new growth rule retroactively.
- **`CLAUDE.local.md` here is deleted by the user, not the agent** — it is a personal, gitignored
  file; the change moves its config content and reports what remains (About-me placeholders,
  tools list), and the user decides the file's fate.

## Tasks

- [x] 1. **Budget + router into the root.** Add the budget line and a `## Task Router` section to
      `AGENTS.md`; carve the root to boundaries/commands/routing; move the procedure-weight prose
      (symlink-canon walkthrough, add-a-skill details beyond the checklist, `.ai/` layout detail)
      into routed topic files (`docs/agents/…`, 2–4 files, sized to the content).
- [x] 2. **Gotchas out of the root.** Move the 12 entries into the topic files their router rows
      name, thematic groups intact; delete the root section.
- [x] 3. **Local memory in.** Move `## Git conventions` and the `**Lint/Typecheck/Test command**`
      bullets from `CLAUDE.local.md` into `AGENTS.md` (Solo-lane-style section) — **the bullet names
      are the contract**, so re-spell rather than assume the root's existing `## Commands` already
      did it (see Notes); update `CLAUDE.local.md`-naming prose in README/AGENTS.md; report what's
      left in the local file for the user to delete.
- [x] 4. **The checks.** `validate-docs.sh` gains root-budget and router-coverage checks (~2 checks
      in the existing script, no new file); re-point or drop the root-gotcha cap in
      `validate-artifacts.sh` per the first decision; full gate.

## Anchors

- `AGENTS.md` **on the `de-ratchet-the-solo-lane` branch** — 288 lines / 21,651 B; the absorbed
  DESIGN.md rules are the procedure-weight content task 1 moves out. Re-verify sections at claim.
- `/Users/dominik.wozniak/workspace/private/byarcadia-packages/grateful-me-app-v2/AGENTS.md` +
  `docs/agents/README.md` there — the target shape and the "what belongs in the root vs a topic
  file" rules.
- `scripts/validate-docs.sh` (post-de-ratchet: ~80 lines, four checks) — where the two new checks
  land.
- `scripts/validate-artifacts.sh` — the gotcha-cap check the first decision retires or re-points.
- `CLAUDE.local.md` (this repo, gitignored) — `## Git conventions` and `## Project specifics` are
  the content task 3 migrates.

## Notes

- **Lands after `setup-lives-in-tracked-agents-md`** — task 3 moves the `**Lint command**` line
  out of the file the current hooks grep; without that change's AGENTS.md-first chain,
  `lint-on-edit.sh` would silently lint nothing. Also waits on the de-ratchet merge itself: it
  edits the same `AGENTS.md`.
- No plugin bump: everything touched (own docs, `scripts/validate-*.sh`) is repo CI surface, not
  payload — unless task 3's prose edits reach a skill body; check at land time.
- **The root's `## Commands` is a false friend for task 3.** `AGENTS.md:154-155` already reads
  `- **Test**:` and `- **Lint**:` — neither matches the `Lint command` / `Typecheck command` the
  guardrail hooks grep, and there is no typecheck bullet at all. So this repo's hooks are answered
  **only** by `CLAUDE.local.md` today: the section looks migrated and answers nothing, which is what
  makes the ordering note above load-bearing rather than tidy. Mirror the shipped
  `templates/AGENTS.md` — one copy each of the two hook-read bullets under `## Solo lane`, with
  `## Commands` pointing at them instead of repeating them.
- **What landing this unblocks.** `link-local-memory` becomes subjectless here once `CLAUDE.local.md`
  is gone: the hook (two copies, 90 lines), `worktree.sh`'s `link_local_memory()` (32) and its
  `worktree.test.sh` group (60) are ~182 lines and one retired carry class, plus the
  `.claude/settings.json` wiring, `dw-init`'s legacy-only offer clause and `dw-start`'s sentence. It
  is already incoherent: `dw-init` **moves** a found `CLAUDE.local.md`, so the condition that offers
  the hook is the one the same run eliminates. A separate change, not a task here — it edits shipped
  payload and needs the plugin bump this one avoids. Keep the `AGENTS.md`-first **fallback** in the
  two hooks regardless: one string per `for` loop, and it is what keeps them byte-identical with the
  `dw-skills` copies that still read the legacy file.
- **Two of the twelve gotchas were retired rather than moved**, because the move made them true by
  construction: the `CLAUDE.md`-is-a-symlink entry is now the root's first header line, and the
  "`templates/hooks/` and `slugify.sh` are vendored" entry is the `## Vendored from dw-skills`
  section of `docs/agents/skills-and-plugins.md`. Ten entries landed in four topic files.
- **`dw-land` needed no change.** Its promotion step already reads "an existing `## Gotchas` section
  in `AGENTS.md`/`CLAUDE.md` stays the home; **otherwise** the routed topic file" — so deleting the
  root section is exactly the switch that turns its fallback on. No shipped payload edited, so the
  no-bump note above still holds.
- **Task 3's prose half was already done by the prerequisite.** `setup-lives-in-tracked-agents-md`
  (d5027df) removed every `CLAUDE.local.md` mention from `README.md` and `AGENTS.md`; the ones left
  in the tree are all deliberate — the decision records (history), `worktree.sh`'s explicitly
  legacy-labelled `link_local_memory()`, and the hook self-test fixtures that pin the legacy
  fallback. None of them wanted editing here.
- **The root is at 117/120 lines, 7.1/10 KB.** Bytes have room; lines do not, which is the budget
  binding as designed. Three paragraphs were compressed to buy the headroom back (the loop's
  `**Next:**` sentence, the Commands preamble, the push-gate wording) — each of them said something
  a topic file now says in full.
- **What is left in `CLAUDE.local.md` for the user to delete.** Nothing tracked reads it any more.
  Migrated out: `## Git conventions` and the lint/typecheck/test command bullets (now `AGENTS.md`),
  `## Hooks installed` (now `docs/agents/tooling.md`), `## Gotchas`-adjacent material (the topic
  files). Genuinely local and worth keeping somewhere personal if wanted: the `## About me` block,
  which is still unfilled placeholders, and `## Tools active in this session` (gh, rtk, ctx7). The
  rest — `## Workflow`, `## Project specifics`, `## Keep this file current` — is now duplicated by
  tracked docs and is the stale-copy risk the whole change exists to remove.
- **Task 4 delegates instead of reimplementing, and the shape of task 4 changed because of it.** The
  task was written before `setup-lives-in-tracked-agents-md` landed `templates/check-agents-docs.mjs`
  (d5027df), which already implements the budget and router-coverage checks — and three more. So
  `validate-docs.sh` gained one check that runs the shipped checker against this repo's own root,
  rather than two bash reimplementations of it. The change doc's success criterion is met verbatim
  (`pnpm validate:docs` fails on an over-budget root or an unrouted topic file), and the repo now
  dogfoods its own payload the way `hooks-in-sync.test.sh` does for the hooks.
- **Both new failure modes were proved, not assumed.** An unrouted `docs/agents/zz-orphan.md` and ten
  junk lines appended to the root each produced one `::error::` and exit 1; both were reverted.
- **`agnix` fails every `docs/agents/*.md` for having no YAML frontmatter** — it classifies anything
  under a directory named `agents` as an agent _definition_. Excluded in `.agnix.toml` with the
  reasoning inline; the root `AGENTS.md` is still linted, and `validate:docs` is what holds the
  directory to its real contract. This was a genuine regression the gate caught, not a pre-existing
  warning.
- **`CLAUDE.local.md` names a `pnpm validate:evals` that no longer exists** in `package.json` — one
  more piece of evidence that the file is now a stale second copy rather than a source of truth.
- **A `dw-check` pass found four things the move dropped, and the count was not the way to find
  them.** Entry counts were perfectly conserved — 12/12 top-level gotchas, 17/17 sub-bullets — while
  four separate pieces of content had gone missing inside surviving text. What caught them was an
  8-gram sweep of the old root against the new corpus, not reading the diff. Worth repeating on any
  change that moves prose between files: conservation of _entries_ says nothing about conservation
  of _content_.
