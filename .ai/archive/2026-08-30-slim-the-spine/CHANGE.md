---
change: slim-the-spine
branch: slim-the-spine
created: 2026-08-30
status: landed
landed: 2026-08-30
pr: ""
---

# Change — slim the spine and retire the unclaimed queue

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
- [x] 7. dw-start and dw-ship: claim and sweep logic out, worktree mechanics kept
- [x] 8. templates: typecheck hook incremental + commit-time variant, one bash-guard dispatcher for
      the four PreToolUse hooks, check-agents-docs.mjs format checks downgraded to warnings,
      templates/AGENTS.md solo-lane section matches the new skills
- [x] 9. docs sweep: AGENTS.md loop, README, CONTEXT.md (Claim term out, duplicate Ratchet entry
      merged), docs/agents/change-artifacts.md, a decision record for the queue move
- [x] 10. wiring: evals cases still route, plugin versions bumped (dw-solo, dw-solo-setup),
      corpus baseline re-recorded, full gate green

## Notes

- The template check-agents-docs.mjs needed no loosening — the strict format checks (ADR gapless
  numbering, lane frontmatter stamps) are grateful-me-app-v2's own vendored extensions, so the
  relaxation belongs in that repo.
- Line proxies vs byte goals: dw-shape 76/70, dw-next 85/70, dw-land 103/80 lines — over the line
  targets, under the byte ones (4.0 / 4.2 / 5.8 KB); a full cycle now loads ≈4.3k tokens of
  instruction (goal ≤6k) and a close 7.4 KB (goal ≤8 KB).
- Corpus: 17,932 → 12,127 words (−32%), baseline re-recorded.
- No `skills/shared/rules.md` (the plan sketched one): a non-skill dir under `skills/` has no
  owning plugin path, so the ask-policy lines live in dw-next and dw-land directly.
