---
change: carry-references-through-the-loop-and-keep-them-accurate
branch: carry-references-through-the-loop-and-keep-them-accurate
created: 2026-08-25
status: landed # shaping | building | landed
landed: 2026-08-25
pr: "#47"
---

# Change — a reference given at grill or shape time reaches the build, and stays true

## Goal

A pointer named in a grill prompt survives into `CHANGE.md`, and a change that made one stale gets
the chance to fix it. Done when `dw-grill`'s playback names every resource the conversation pointed
at, `dw-shape:166` and `templates/work-README.md:13` both list `## References` alongside the other
sections, and `dw-land` offers a reference edit as its own promote decision — taken only on the
user's go, never on its own.

## Decisions

- The `## References` section already exists and is unchanged — the fix is the four seams around it,
  not a new mechanism, because a second mechanism would be the drift this change exists to stop.
- References become a promote target in `promote.md`, making it **six**, not a convention a project
  must first adopt — the section itself is the input, so this works in any repo.
- **A `references/` folder is not assumed, and most projects have none.** grateful-me-v2 has one
  because it carries five prior projects; nothing here may require the folder, name it, or scaffold
  it. The input is whatever the doc's own `## References` happens to list — a URL, a design doc, a
  sibling repo, a folder — so a change with no pointers reaches an inert step.
- `dw-land` flags and edits on approval, never silently: it writes into a file the change never
  touched, and a wrong guess would be committed.
- `dw-start` is left alone — it hands straight to `dw-next`, which already reads the section.
- No rename, though `## References`, `skills/*/references/` and a project's `references/` are three
  meanings of one word — it touches every skill to buy clarity one reader does not need.

## Tasks

- [x] 1. `dw-grill` step 5 — the playback names every resource the conversation pointed at, beside
      the left-out list, so `dw-shape` has them to write down.
- [x] 2. `skills/dw-shape/SKILL.md:166` — add `References` to the enumeration of the skeleton it
      already writes; `:63-66` already requires the section.
- [x] 3. `templates/work-README.md:13` and its byte-identical `.ai/README.md` twin — the change-doc
      line gains references, in one commit, verified with `cmp`.
- [x] 4. `promote.md` + `dw-land` step 3 — a reference this change made stale becomes a target:
      flagged with the others, edited on the user's go, and **skipped outright when the doc named
      none**. Title and count move from five to six.
- [x] 5. Bump `dw-solo` and `dw-solo-setup` in both manifests, re-record the corpus baseline, run
      every check in the `scripts` block.

## Anchors

- `skills/dw-grill/SKILL.md:80-87` — step 5's playback, which names the decisions and the left-out
  list and never the pointers. That omission is task 1.
- `skills/dw-shape/SKILL.md:63-66` — the rule already requiring a `## References` line per resource;
  `:166` is the enumeration that forgets it.
- `skills/dw-next/SKILL.md:44-47` — the read-back obligation, already correct. Task 4 must not
  restate it; the loop reads this section exactly once.
- `skills/dw-land/references/promote.md:1` — "the five targets", the title and count task 4 moves.
- `skills/dw-land/references/promote.md:24-27` — the vocabulary bullet: the shape, and the
  "rewrite the line rather than adding a second" rule a reference bullet copies.
- `templates/work-README.md:13` — "goal · decisions taken · task checklist · anchors"; `.ai/README.md`
  is byte-identical today (`cmp` clean), so both move together.
- `scripts/skill-corpus.baseline.json` — pass 3 of `validate-artifacts.sh`; growth costs one visible
  `--update-baseline` in the diff.

## References

- `~/.claude/plans/w-pracy-z-grateful-me-v2-ancient-sundae.md` — the grill playback this comes from:
  the five seams, the two ruled out, and the post-approval corrections.
- `/Users/dominik.wozniak/workspace/private/byarcadia-app/grateful-me-app-v2/references/AGENTS.md` —
  **one worked example, not a shape any project must have**: the `how` column and the "Keep it
  current — same-commit triggers" contract that currently has no executor. Read it for what a stale
  reference looks like, never as a layout to require.
- `…/grateful-me-app-v2/.ai/README.md:52` — "Disagreements with a reference project stay in
  `references/conflicts.md` instead": a project already naming the target no skill promotes to.

## Notes

- Shaped alongside `the-archive-is-a-receipt-not-a-second-copy`, which deletes `## References` from
  the archived doc. Both edit `promote.md`, so whichever lands second rebases onto the other. The
  order is coherent either way: `dw-land` reads the section to promote, then drops it from the
  archive.
- Two of grateful-me-v2's five submodules are uninitialized on disk right now, so a `## References`
  line into either resolves to nothing today. Not this change's — `worktree.sh:161-170` already
  reports the worktree half.
- A third unclaimed change sits beside these — `dw-grain-audits-reinvented-and-excess-code`, a 14th
  skill — and it already claims `dw-solo` `0.5.2` and a `--update-baseline`. Three changes cannot
  take the same number: whichever lands later re-reads both manifests and takes the next one, and
  re-records the corpus baseline against its own base. `validate-manifests.sh` only checks the two
  numbers are **equal**, never that either moved, so it will not catch a duplicate.
- Took `dw-solo` `0.5.2` and `dw-solo-setup` `0.1.32`; `dw-grain` must now take `0.5.3`.
- The corpus ratchet counts `skills/*/SKILL.md` only, so `references/*.md` prose is unratcheted —
  which is why the sixth target's detail lives in `promote.md` and step 3 stays four lines.
- `dw-land`'s frontmatter description still names four promote targets, left alone on purpose: it is
  a routing surface, and step 3 is what a reader follows.
