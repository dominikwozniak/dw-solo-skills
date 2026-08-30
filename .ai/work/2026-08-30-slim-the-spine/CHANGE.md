---
change: slim-the-spine
branch: slim-the-spine
created: 2026-08-30
status: shaping
---

# Change — slim the spine and retire the unclaimed queue

## Goal

A full change through the spine loads ≤6k tokens of skill instruction (from 12–16k), closing a
change loads ≤8 KB (from 25.6 KB), and a squash-merge resurrects nothing: `grep -r unclaimed
skills/ templates/` returns no hits, every spine SKILL.md meets its line target, and the corpus
baseline is re-recorded lower.

## Decisions

- Evidence, not taste: a 3-week audit of grateful-me-app-v2 (the only active consumer) found 3
  src-only commits out of 149, 41 `.ai/`-only commits, 14 squash-resurrection sweeps, and a 2:1
  agent-prose-to-product-code ratio — the numbers this change answers to.
- Retire `branch: unclaimed` — the unclaimed queue moves to `.ai/backlog/`; a `CHANGE.md` exists
  only on its feature branch. Kills the resurrection at the root (a shape commit on the local
  default branch is what the post-squash rebase replays) and deletes the claim protocol.
- Rationale in a skill body is capped at one sentence per rule (pstack `principle-*` format);
  enumerated edge cases the model handles anyway are cut.
- Promotion becomes continuous: `dw-next` writes a decision record / `CONTEXT.md` line in the
  task's own commit when the decision happens; `dw-land` keeps a ~25-line closing checklist and
  `references/promote.md` is deleted.
- No new `skills/shared/rules.md` (the plan sketched one): a non-skill dir under `skills/` has no
  owning plugin path, so the two cross-cutting blocks (ask-only-when-irreversible, banned trivial
  confirmations) are stated once in `dw-next` and once in `dw-land` — net tokens equal, zero new
  shipped surface.
- Descriptions stay verbatim — they are the routing surface `eval:routing` scores; only bodies slim.

## Tasks

<!-- Convention: `- [ ]` pending, `- [x]` done; append ` — <short sha>` when the task's commit lands. -->

- [x] 1. dw-shape ≤70 lines: shape on the branch (offer `git switch -c <slug>` from the default
      branch, or a backlog entry when queueing), fold splitting.md in, one stop instead of three
- [x] 2. dw-next ≤70 lines: claiming ladder out (claiming.md deleted), fixed resume-report contract
      with status tags, inline promotion rule, tick-convention moved into references/CHANGE.md
- [x] 3. dw-land ≤80 lines + promote.md deleted + decision-record.md ≤40 lines
- [x] 4. dw-grill ≤40 lines, behaviour unchanged
- [x] 5. dw-check ≤70 lines
- [x] 6. dw-git ≤90 lines
- [ ] 7. dw-start and dw-ship: claim and sweep logic out, worktree mechanics kept
- [ ] 8. templates: typecheck hook incremental + commit-time variant, one bash-guard dispatcher for
      the four PreToolUse hooks, check-agents-docs.mjs format checks downgraded to warnings,
      templates/AGENTS.md solo-lane section matches the new skills
- [ ] 9. docs sweep: AGENTS.md loop, README, CONTEXT.md (Claim term out, duplicate Ratchet entry
      merged), docs/agents/change-artifacts.md, a decision record for the queue move
- [ ] 10. wiring: evals cases still route, plugin versions bumped (dw-solo, dw-solo-setup),
      corpus baseline re-recorded, full gate green

## Anchors

- `skills/dw-ship/SKILL.md:95` — the documented resurrection mechanism this change deletes the
  cause of
- `scripts/check-skill-corpus.mjs:19` — the ratchet; re-record with `--update-baseline`
- `docs/agents/skills-and-plugins.md:34` — the add/rename checklist and version-bump rules

## References

- `../../byarcadia-app/grateful-me-app-v2` — the consumer audit that motivated every number above
- `.inspirations/mattpocock-skills` — assert-flat style, `implement` (15 lines) as the size bar
- `.inspirations/cursor-plugins` — pstack `principle-*` micro-format, `recall` status tags,
  `never-block-on-the-human` ask policy
- `.inspirations/open-mercato-skills` — convention embedded in the artifact (`om-auto-continue-pr`)

## Notes
