---
change: shape-time-parking-for-the-left-out-list
branch: worktree-shape-time-parking-for-the-left-out-list
created: 2026-08-12
status: building # shaping | building | landed
---

# Change — the "deliberately left out" list gets its choice at shape time

## Goal

`dw-shape` becomes the loop's second backlog writer. Every item on the "deliberately left out" list —
from a `dw-grill` playback, or from a split decision — gets an explicit three-way choice at shape time:
into this change, into `.ai/backlog/`, or dropped. Only the parked ones become files, under the two bars
that already exist. You know it worked by reading four things: `dw-shape`'s body carries that step
between the read-back and the commit, `dw-grill` no longer defers the list to land time, both backlog
READMEs name `dw-shape` as a writer beside `dw-land`, and the README router row for `dw-shape` shows the
backlog in what you get. `dw-solo` and `dw-solo-setup` are bumped in both manifests each.

## Decisions

- **The choice is forced per item, not filed wholesale.** Shape time is when the left-out pile is
  biggest and least tested, so an automatic filer floods a cap the repo only just installed
  (`BACKLOG_CAP=8`). Forcing the choice is the same move `two-gates-against-scope-shedding` made on the
  land side — the cap "forces the choice the append silently skipped", in
  `validate-artifacts.sh`'s own words.
- **The two existing bars are reused verbatim, not restated.** "Will you ever?" and "Should it have been
  done now?" are already word-for-word in four places (`dw-land`, `dw-next`, both backlog READMEs); a
  fifth wording is a fifth thing to keep in sync. Point at them.
- **This is a feature, not the fix for a false promise.** `dw-grill:86` already tells the truth — the
  promise `de-ratchet-the-solo-lane` deleted said `dw-shape` files the list, and it now says "at land
  time". So nothing is broken today: this moves parking earlier, where the alternative is taking the
  item into the change.
- **Split from `loop-prose-disagrees-with-the-bodies`** — that change is three corrections; this is one
  feature. They arrived in one backlog file because 1182f7f merged two entries under a new cap, not
  because they are one scope.

## Tasks

- [x] 1. **The step in `dw-shape`.** After the read-back and before the commit
      (`skills/dw-shape/SKILL.md:106-126`): walk the left-out list, force the three-way choice per item,
      and write only the parked ones as `.ai/backlog/<slug>.md` — slug from the shipped `slugify.sh`,
      frontmatter `created:` plus `source:` naming this change, an H1 in one line, at most ~3 lines of
      context. Point at the two bars rather than restating them. Committed with the shape commit: an
      uncommitted park is invisible to every other session, the same reason the `CHANGE.md` commit is
      load-bearing.
- [x] 2. **`dw-grill`'s closing sentence.** `skills/dw-grill/SKILL.md:85-88` — "what stays out reaches
      `.ai/backlog/` at land time" becomes shape time. Keep "**This skill still writes nothing**": the
      playback is the deliverable and an interviewer that files things is one you cannot run to think
      out loud.
- [x] 3. **Both backlog READMEs.** `.ai/backlog/README.md:3-4` and `templates/backlog-README.md:3-4` —
      "`dw-land` parks them here" becomes `dw-land` **and** `dw-shape`. They are **no longer
      byte-identical** (the repo copy carries a cap paragraph the template must not ship: 1692 B vs
      1217 B), so keep lines 1–18 identical and `diff` the two after editing. One commit — splitting it
      ships a disagreement between a skill and the README it copies out.
- [x] 4. **The README router row.** `README.md:76` — the `dw-shape` row's "What you get" column gains
      the backlog beside `.ai/work/<slug>/CHANGE.md`. The `## The loop` diagram is unchanged;
      `dw-shape`'s position in it does not move.
- [x] 5. **Two bumps, then the full gate.** `dw-solo` (tasks 1–2) and `dw-solo-setup` (task 3 touches
      `templates/`, which is payload), each in `.claude-plugin/marketplace.json` **and** its
      `plugin.json`. Last on purpose: `validate-manifests.sh` only checks the pairs are _equal_, so a
      forgotten bump ships green. If task 1 touches `dw-shape`'s `description`, `eval:routing` is
      mandatory rather than a formality — a description edit shifts every term's idf and can knock an
      unrelated skill off rank-1.

## Anchors

- `skills/dw-shape/SKILL.md:106-126` — step 4, "Write the file, check it back, commit it". Already the
  only place that `git mv`s a backlog entry into `work/`, so the new step's neighbour; `:58-61` is where
  the skill reads the backlog today.
- `skills/dw-grill/SKILL.md:80-88` — step 5, "Close explicitly": the playback that names the left-out
  list and currently defers it, plus the writes-nothing constraint to preserve.
- `.ai/backlog/README.md:3-4` and `templates/backlog-README.md:3-4` — the "`dw-land` parks them here"
  contract sentence. `:15-18` in both carry the two bars task 1 points at.
- `skills/dw-land/SKILL.md:105-119` — "Promote the follow-ups", the existing writer whose entry shape,
  slug derivation and collision rule task 1 mirrors rather than reinvents.
- `scripts/validate-artifacts.sh:44-49` — `BACKLOG_CAP=8` and the comment that a cap "forces the choice
  the append silently skipped". The reason task 1 is choice-forcing.
- `.ai/archive/two-gates-against-scope-shedding/CHANGE.md:112-116` — where this feature was first named:
  "the deepest fix available; beyond this change's land-side scope".

## Notes

- **Lands after `loop-prose-disagrees-with-the-bodies`.** Different bodies (`dw-shape` / `dw-grill` vs
  `dw-ship` / `dw-land` / `dw-check`), so no conflict — but both bump `dw-solo`, and
  `.ai/work/setup-lives-in-tracked-agents-md` bumps both plugins as well. Read every version off `main`
  at build time, and re-check after any rebase: the squash-merge trap is that another change may have
  taken the number this one targets.
- **There is no cap headroom left, and that sharpened task 1.** The 5/8 this was shaped against is now
  **8/8** — the folder is exactly full at build time. So the first real `dw-shape` run after this ships
  cannot park anything at all without bundling, absorbing or deleting first, which is precisely why the
  step forces the choice per item instead of filing the pile. Written as pointing at the README's cap
  paragraph rather than restating the number, so this stays true when the cap moves.
- **Versions taken off `origin/main`, both at `.16`.** `dw-solo` 0.4.16 → 0.4.17, `dw-solo-setup`
  0.1.16 → 0.1.17. Nothing else was in flight — `.ai/work/` held only this change and both changes the
  shaping named as neighbours are archived — so the numbers were uncontested. Re-check after a rebase
  anyway.
- **Task 1 landed as two steps, not one.** The parking step became step 5 and the commit moved out to
  its own step 6. Folding a choice-forcing interaction into a step already titled "write, check back,
  commit" buried it; the two-step split also makes "these ship in the shape commit below" a pointer at
  a real neighbour. `dw-shape`'s `description` was **not** touched, so `eval:routing` stayed a
  formality — it passes at 67%, exactly at the floor, unchanged.
- **Unexercised on merge, by design.** Prose in skill bodies, and nothing asserts skill body content;
  any `dw-shape` run during the work serves the cached plugin, not the canon being edited. The first
  real exercise is the next shape after reinstall.
