---
change: contributing-pre-push-gate-list-is-stale
branch: contributing-pre-push-gate-list-is-stale
created: 2026-08-10
status: building # shaping | building | landed
---

# Change — `CONTRIBUTING.md`'s pre-push gate catches up to CI, and a check keeps it there

## Goal

`CONTRIBUTING.md:21` names all seven gates instead of five, its gate table has rows for
`pnpm validate:evals` and `pnpm eval:routing`, and `validate-docs.sh` fails when that block stops
matching `AGENTS.md`'s or when a gate in it has no table row. You know it worked when deleting
`&& pnpm eval:routing` from either file, or dropping the `eval:routing` table row, turns
`pnpm validate:docs` red naming the file and the gate.

## Decisions

- **`AGENTS.md` is the source, `CONTRIBUTING.md` the copy.** `AGENTS.md:108-113` is already correct
  and is what the agent reads every session; the check compares and never rewrites, so the fix is a
  human edit and the guard is mechanical.
- **The `## Before you push` fence must match verbatim across docs**, normalized only for
  surrounding whitespace. A containment check ("CONTRIBUTING names at least these gates") would pass
  a reordered or padded command, and the point of the block is that it is copy-pasteable.
- **`AGENTS.md:76` is deliberately excluded.** Step 7 of the add-a-skill checklist is a narrower
  list (no `validate:artifacts`) for a specific situation, not the pre-push gate. Anchor the check to
  the `## Before you push` heading so it cannot pick that line up.
- **Drop the number word from `CONTRIBUTING.md:24`.** "CI runs those five" is a count that rots on
  every gate added and that no cheap check can verify; "CI runs those, plus a `trufflehog` secrets
  scan" carries the same information with nothing to go stale. Leave `AGENTS.md:113`'s
  "those seven" alone — it is currently true, and rewriting the source doc is not this change.
- **A doc list, not two hardcoded paths** — `GATE_LIST_DOCS`, following `EXPLICIT_LIST_DOCS`'s
  precedent at `validate-docs.sh:29`. The comment there records a doc drifting precisely because it
  wasn't in the loop; a third doc growing a pre-push block should be one edit.
- **No `scripts/tests/validate-docs.test.sh` here.** `.ai/backlog/validator-blind-spots.md` already
  parks fixtures for this validator alongside the `awk -F'|' '{print $4}'` fix that changes its
  behaviour. Pinning it twice, from two changes, in a repo with one reader, is ceremony.
- **`CLAUDE.local.md`'s copy of the gate stays unchecked** — it is gitignored, so CI cannot see it,
  and its `## Keep this file current` section already owns that duty.

## Tasks

- [x] 1. `CONTRIBUTING.md` — replace the `:21` command with `AGENTS.md:110` verbatim, rewrite `:24`
      to drop the count, and add table rows for `pnpm validate:evals` (the skills ↔ eval-case-files
      contract) and `pnpm eval:routing` (`node evals/routing.ts --min-rank1 67` — the deterministic
      free tier). Keep the existing column alignment; `prettier` will reflow the table, so run
      `pnpm format:fix` and re-read it.
- [x] 2. `scripts/validate-docs.sh` — add check 6: extract the fenced block under the
      "Before you push" heading from each of `GATE_LIST_DOCS` (`AGENTS.md`, `CONTRIBUTING.md`), fail
      on any doc where it is missing or differs from the first, then fail on any `pnpm <script>` in
      that command that has no row of its own in `CONTRIBUTING.md`'s gate table (match a leading pipe
      followed by the backticked script name, the way check 5 matches rows). Update the header
      comment's "Five mechanical, no-judgement checks" and its numbered list. No version bump —
      nothing under `templates/` or `scripts/runtime/` is touched.

## Anchors

- `CONTRIBUTING.md:18-35` — the block, the sentence and the table being fixed.
- `AGENTS.md:107-113` — the correct source: heading, fence, and the "those seven" sentence.
- `scripts/validate-docs.sh:27-29` — `EXPLICIT_LIST_DOCS` and the comment justifying a doc list over
  hardcoded paths; `:1-18` the header comment to extend; `:196-202` the `FAILED` / exit convention
  every check appends to.
- `.github/workflows/` — seven gate jobs plus `secrets-scan.yaml`; the ground truth the docs claim.
- `package.json:16-17` — `validate:evals` and `eval:routing`, for the table rows' wording.

## Notes

- **Ordering against `.ai/backlog/validator-blind-spots.md`**: that change rewrites
  `validate-docs.sh:157` and adds the fixtures. It should land **second** — this one appends a check
  and touches nothing it edits, so going first keeps the conflict to zero and gives its fixtures a
  sixth check to cover.
- **A gate name contains a space, and `for gate in $(…)` tears it in half.** The first cut of check 6
  reported `pnpm`, `lint`, `format` … as seven separate missing gates. Fixed with
  `while IFS= read -r` over a process substitution — the same shape check 5 already uses for the
  backticked tokens in an Arguments cell. Worth knowing before the next check iterates anything whose
  items aren't single words.
- **Both halves were proved by breaking them, not by reading them.** Deleting `&& pnpm eval:routing`
  from `CONTRIBUTING.md` fails with both commands printed side by side; deleting only its table row
  leaves the fences equal and fails the row check alone. Since there is no
  `scripts/tests/validate-docs.test.sh` yet (see the Decisions), those two probes are the only record
  that check 6 can fail at all — re-run them by hand when `validator-blind-spots` touches this file.
- No new file types, so `.lintstagedrc.json`'s glob is fine. Full gate before push:
  `pnpm lint && pnpm format && pnpm validate:manifests && pnpm validate:artifacts && pnpm validate:docs && pnpm validate:evals && pnpm eval:routing`.
