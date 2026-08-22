---
change: worktree-remove-with-submodules
branch: worktree-remove-with-submodules
created: 2026-08-09
status: landed # shaping | building | landed
landed: 2026-08-09
pr: "#15"
---

# Change — `worktree.sh` survives a superproject at both ends: create says what's empty, remove can tear it down

## Goal

`worktree.sh remove <slug>` completes in a superproject: the worktree goes, the branch goes, `prune`
runs — and a **dirty** worktree still refuses, with nothing deleted. Before this, `dw-ship`'s
teardown step could never finish in a repo that keeps its reference projects as submodules; it
failed at the first call and left the directory and the branch behind for hand cleanup.

The other end of the same hole: `create`'s readiness report now names the empty submodule
directories it leaves behind, the way it already names the missing dependency install.

Known when: `submodule-remove-ok` and `readiness-names-submodule-init` both pass here and both fail
against the unfixed script, and `submodule-remove-dirty-refused` passes in both.

## Decisions

- **Plain call first, `--force` only for the submodule refusal.** git refuses
  `worktree remove` outright once a submodule is populated — cleanliness never enters into it — and
  `--force` lifts that refusal _and_ the dirty-worktree one in the same breath. An unconditional
  `--force` would have turned a stuck teardown into silent deletion of uncommitted work, so
  `remove_worktree` matches git's message and re-runs forced only after making its own cleanliness
  check. The script header's "never `--force` on the worktree itself" line was rewritten rather than
  deleted: the rule still holds, it just names its one exception now.
- **The cleanliness check is the whole guard, not a belt-and-braces.** git checks submodules
  _before_ dirtiness, so on this path git's own dirty refusal never fires — verified by hand
  (`fatal: working trees containing submodules cannot be moved or removed` is the message in both
  the clean and the dirty case). Without the check the fix would be a data-loss bug.
- **Matching English stderr is legitimate here** only because `export LC_ALL=C` already sits at the
  top of the script for the `comm` collation; the comment says so at both sites, so a future
  removal of that line has a reason to stop.
- **The submodule cases get their own throwaway superproject.** Adding a submodule to the shared
  `$REPO` would have routed _every_ earlier `remove` assertion through the `--force` branch, and the
  plain path would have stopped being tested at all.
- **`create` reports the empty submodules, it does not populate them.** They are the same regenerate
  class as `node_modules`: `worktree add` checks out a gitlink, not contents. Running
  `submodule update --init` would turn a two-second `create` into a network round trip, and whether
  this worktree needs its references at all is the caller's call — `report_readiness` exists exactly
  to say so instead of deciding. Detection is `submodule status`'s `-` prefix, which is git's own
  marker and survives any locale, unlike matching prose.

## Tasks

- [x] 1. `remove_worktree()` in `scripts/runtime/worktree.sh`: capture the plain call's output,
      return on success, and on a `*submodule*` refusal re-run with `--force` — but only after
      `git -C "$path" status --porcelain` comes back empty; anything else is reprinted and its exit
      code returned unchanged. Wire the `remove` case to it and update the header comment.
- [x] 2. Three cases in `scripts/tests/worktree.test.sh` under a fresh superproject:
      `submodule-populated-in-worktree` (asserts the precondition, so the section cannot silently
      degrade into testing nothing), `submodule-remove-ok` (the fix), and
      `submodule-remove-dirty-refused` (the guard).
- [x] 3. Bump `dw-solo` to 0.4.11 in `.claude-plugin/marketplace.json` and
      `plugins/dw-solo/.claude-plugin/plugin.json` — `scripts/runtime/` is shipped payload, and
      `validate-manifests.sh` only checks the two agree, never that either moved.
- [x] 4. A submodule clause in `report_readiness()`: `.gitmodules` present and
      `submodule status` showing a `-` prefix → one line naming `git submodule update --init`.
      Two cases — `readiness-names-submodule-init` in the superproject section, before the init
      hides the evidence, and `readiness-no-false-submodule-warning` in `$REPO`, which has no
      submodules like most repos. No further version bump: 0.4.11 has not shipped yet.

## Anchors

- `scripts/runtime/worktree.sh:211-242` — `remove_worktree()`, the removal fix.
- `scripts/runtime/worktree.sh:172-185` — the submodule clause in `report_readiness()`.
- `scripts/runtime/worktree.sh:20-24` — the header rule the change amends; `:28` — the
  `export LC_ALL=C` the stderr match depends on.
- `scripts/runtime/worktree.sh:305` — the `remove` case's call site.
- `scripts/tests/worktree.test.sh:326-399` — the superproject section.

## Notes

- Shipped from a sibling repo that keeps its reference projects as submodules, where `dw-ship`'s
  teardown was the thing that broke. Verified here rather than re-derived: each half's case was run
  against the script without it — `submodule-remove-ok` fails on `main`, and
  `readiness-names-submodule-init` fails against the removal-only commit.
- The gitlink alone is harmless — `git worktree add` leaves submodules empty and plain removal works.
  The refusal starts at `submodule update --init`, which is exactly what such a repo needs before it
  can build. That is why the test inits the submodule in the worktree; without that line the section
  would pass through the plain path and prove nothing.
- The cleanliness check does cover dirt **inside** the submodule: both an untracked file and a
  modified tracked file there surface as ` M vendor/sub` in the superproject's
  `status --porcelain`, so the refusal holds. Ignored files are invisible to it, but plain
  `worktree remove` deletes those too — no behaviour drift against the non-submodule path.
- Known slack, deliberately not tightened: the `*submodule*` glob is matched against the captured
  output, so a worktree path containing the word would take the submodule branch on an unrelated
  failure. The outcome stays safe — the forced retry surfaces the same error — and narrowing the
  pattern would pin it to a git message that changes more often than the word does.
- `submodule-remove-dirty-refused` passes on `main` too, vacuously: the unfixed script never forces
  anything. It pins the future, not the fix.
- Task 4 was `.ai/backlog/worktree-create-leaves-submodules-empty.md`, parked and then picked up the
  same day — the report-only half was six lines and the superproject scaffolding was already there.
  The backlog file is deleted in the same commit rather than left to be read as open work.
- `readiness-names-submodule-init` has to run **before** the `submodule update --init` two lines
  below it: that init is what the removal cases need, and it destroys the state this case asserts.
- Full gate green on the branch: 0 errors / 51 warnings (all pre-existing), prettier clean,
  manifests, docs, evals, `eval:routing` (rank-1 67%, 55 pairs), and all six self-tests —
  38 passed / 0 failed in `worktree.test.sh`. Run lint as `bash scripts/lint.sh`; the `rtk` hook
  rewrites `pnpm lint` into an ESLint wrapper that fails on a green repo.
- No decision record and no `## Gotchas` line: the trap is git's, not this repo's, and it is now
  encoded in the script's comments and pinned by three tests — the only two places a future session
  would look.
