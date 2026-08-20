---
change: doctor-lockfile-gate-and-hook-drift
branch: doctor-lockfile-gate-and-hook-drift
created: 2026-08-20
status: landed # shaping | building | landed
landed: 2026-08-20
pr: "#40"
---

# Change — dw-doctor's lockfile and hook verdicts stop lying

## Goal

Two findings this diagnostic got wrong, both found by running it against a real consumer repo rather
than reading it. The `pnpm-lock.yaml` check warned at every ordinary repo; the hook check reported
`OK` on a vendored copy that had fallen years behind its template. Known when: a repo pinning pnpm
through a plain `packageManager` string gets no lockfile warning, and a repo carrying a stale
`block-non-pnpm.sh` gets a `WARN` naming it.

## Decisions

- **Gate the lockfile check on `devEngines.packageManager`, don't delete it.** pnpm 11's marks (the
  leading `---`, `configDependencies`, `packageManagerDependencies`) appear only where pnpm
  self-manages its own binary, which is what `devEngines` with `onFail: download` sets up. A plain
  `"packageManager": "pnpm@x.y.z"` pin has nothing to self-manage, so v11 writes a lockfile with none
  of them — indistinguishable from a pre-v11 one, and correct. Their absence answers the question only
  where they were owed. The undecidable half is now silent; the decidable half still fires.
- **Hook drift is `WARN`, never `FAIL`.** A deliberately patched or deliberately older hook is a
  legitimate choice this cannot tell from neglect, and a hook with no template counterpart belongs to
  that repo and is left alone — comparing it to nothing would be inventing a finding.
- **Templates reached by one relative path, not `$CLAUDE_PLUGIN_ROOT`.** `../../../templates/hooks`
  from the script's own directory resolves in the source repo, in an installed plugin, and under the
  self-test, where that variable does not exist. Where it resolves to nothing the block is skipped: a
  diagnostic must not depend on how it was packaged.
- **Both fixes in one commit.** They live in the same two files and splitting them would split hunks.

## Tasks

- [x] 1. `doctor.sh`: gate the lockfile block on `devEngines.packageManager`; reword the finding.
- [x] 2. `doctor.sh`: resolve `TEMPLATE_HOOKS`, and `cmp -s` every wired hook against its template.
- [x] 3. `doctor.test.sh`: a `with_hooks()` fixture, three drift cases, one plain-`packageManager` case.
- [x] 4. `SKILL.md`, `docs/agents/tooling.md`, both version manifests to 0.1.26, corpus baseline.

## Anchors

- `skills/dw-doctor/scripts/doctor.sh:220-243` (lockfile), `:296-318` (drift).
- `scripts/tests/hooks-in-sync.test.sh` — the same invariant, pinned inside this repo only; its own
  comment says nothing across a repo boundary can see it. This is that.
- `skills/dw-init/SKILL.md:159` — hooks are copied byte-for-byte, which is what makes `cmp -s` sound.

## Notes

- **What the drift check buys, concretely.** A vendored `block-non-pnpm.sh` that stripped exactly one
  leading `sudo ` by parameter expansion let `rtk npm install` straight through, on a machine whose
  global hook rewrites every command to `rtk <cmd>`. A vendored `lint-on-edit.sh` spliced the filename
  into the string it `eval`ed, so a file named `a$(touch X).ts` ran the substitution. Both were
  present, executable, and reported `OK`. The current templates fixed both
  (`templates/hooks/block-non-pnpm.sh:19-29`, `templates/hooks/lint-on-edit.sh:94-101`) — the point is
  that nothing told the consumer repo it was missing them.
- **The lockfile check's old failure mode.** It fired at every ordinary repo and suggested `pnpm
install`, which changed nothing because there was nothing to change. This repo declares `devEngines`,
  so its own lockfile carries the marks and the heuristic looked sound from the inside. A diagnostic
  that always warns is one nobody reads.
- Both pre-existing lockfile self-test cases kept their assertions: `pin_v11()` writes `devEngines`, so
  they were always testing the decidable half. Only the message wording moved.
- The drift cases are the **first coverage of the hook-wiring block at all** — `scaffold()` writes no
  `.claude/` — hence the `with_hooks()` helper.
- The `WARN` names the absolute template path, which in an installed plugin is a long plugin-cache
  path. Ugly, kept: the user needs something to `diff` against.
- Reviewed after the fact: the prose had ended up in four copies (commit message, `doctor.sh`,
  `doctor.test.sh`, `tooling.md`) — the exact failure `.ai/archive/contributing-pre-push-gate-list-is-stale/`
  records. Cut to one copy each; the anecdote lives here and in `tooling.md`, the code comments carry
  mechanism only.
