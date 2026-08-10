---
change: check-decisions-in-ci
branch: check-decisions-in-ci
created: 2026-08-10
status: building # shaping | building | landed
---

# Change — CI holds this repo's own `docs/decisions/` to the contract it ships

## Goal

`scripts/validate-artifacts.sh` runs `scripts/runtime/check-decisions.sh` over this repo's own
`docs/decisions/`, and the workflow that backs it actually fires when a record changes. You know it
worked when planting a duplicate-number or dangling-`superseded-by:` record fails
`pnpm validate:artifacts` by name and line, a planted gap prints a `warn:` line and still exits 0,
and the clean folder stays silent — and when a commit touching **only** `docs/decisions/` triggers
the Validate artifacts workflow, which today it does not.

Seeded by `.ai/backlog/check-decisions-over-own-docs-decisions-in-ci.md`; the script itself shipped
in `.ai/archive/validate-decision-records/`.

## Decisions

- **The dogfood pass lives in `validate-artifacts.sh`, not a new `scripts/tests/*.test.sh`** — the
  test files prove the script's _behaviour_ against synthetic fixtures (`check-decisions.test.sh`
  already does that, 20 cases). This is a different job: running the real script over the real
  folder. A self-test that asserts against live repo content would fail every time someone adds a
  record.
- **Invoke `scripts/runtime/check-decisions.sh` directly, not through a plugin symlink** — this is
  repo CI, not a skill invocation. `${CLAUDE_PLUGIN_ROOT}` does not exist here and the canon is the
  file CI should read.
- **`warn:` does not fail the build** — the script already exits 0 on warnings-only, and the WARN
  decision (contiguity, from the archived change) exists precisely so a gap complains without
  blocking. Print the output either way; fold only the exit code into `FAILED`.
- **No version bump** — `scripts/validate-artifacts.sh` is repo CI tooling under `scripts/` root,
  never shipped, and the workflow file is not payload. `validate-manifests.sh`'s equal-versions
  check is untouched. (`## Gotchas` in `AGENTS.md` demands a bump for `templates/` and
  `scripts/runtime/` only — neither is touched here.)

## Tasks

- [x] 1. `scripts/validate-artifacts.sh` — after the self-test loop, add a second section that runs
      `bash "$ROOT/scripts/runtime/check-decisions.sh" "$ROOT"`, echoes its stdout, and sets
      `FAILED=1` only on a non-zero exit. Update the file's opening comment: it currently reads as
      "run every self-test", and the `NOTE:` about deliberately not sweeping `.ai/` stays true and
      must not be confused with this — `docs/decisions/` has a machine-parsed identity (`decision:`
      ↔ filename, `superseded-by:` pointers), which is exactly what `.ai/` lacks. Verify by planting
      a bad record under `mktemp`-free conditions (edit, run, restore from `HEAD`), including the
      warnings-only case.
- [x] 2. `.github/workflows/validate-artifacts.yaml` — add `docs/decisions/**` to **both** the
      `pull_request` and `push` `paths:` lists. Without it the check is dead for the case it exists
      for: a commit that only adds or edits a record matches none of the six existing filters, so
      the workflow never runs. Follow the existing comment style — one line saying why the folder is
      listed.
- [x] 3. The three prose descriptions that say `validate:artifacts` is "the bash self-tests in
      `scripts/tests/`" become true again: `AGENTS.md:98`, `CONTRIBUTING.md:31` (table row) and
      `CLAUDE.local.md:71`. Keep the command name identical in all three — `CLAUDE.local.md`'s
      "Keep this file current" rule pairs it with `AGENTS.md`, and the lint hook greps that file by
      heading.

## Anchors

- `scripts/validate-artifacts.sh:1-9` — the header comment task 1 rewrites, including the `NOTE:`
  about `.ai/`; `:17-30` the self-test loop and the `found -eq 0` guard the new section sits after;
  `:33-39` the summary and `exit $FAILED` it must fold into.
- `scripts/runtime/check-decisions.sh:1-25` — the interface: `[repo-root]` optional arg defaulting
  to `git rev-parse --show-toplevel`, findings on **stdout** prefixed `error: ` / `warn: `, non-zero
  exit on errors only. Currently silent and `exit=0` on this repo's five records.
- `.github/workflows/validate-artifacts.yaml:5-16` / `:19-25` — the two `paths:` lists task 2
  extends; `:7-9` is the comment style to copy (it explains why the filter names the canon and not
  the symlinks).
- `scripts/tests/check-decisions.test.sh` — the synthetic-fixture coverage this change deliberately
  does **not** duplicate; read it before considering a new test file.
- `.ai/archive/validate-decision-records/CHANGE.md` — the change that shipped the script; its
  closing note is the backlog entry this one consumes, and its Decisions record why WARN is not an
  error.

## Notes

- **Task 1 — the dogfood pass already half-existed, in the wrong place and with the wrong
  semantics.** `check-decisions.test.sh` carried a case called `no-arg-checks-this-repo` that ran
  the script with no argument — which resolves to this repo — and asserted total silence. So a unit
  test was the live-content gate, and a stricter one than the contract: a `warn:` gap exits 0 by
  design but would have failed that assertion. The change's premise ("only checked when someone
  closes a change here") was therefore wrong in letter, right in spirit.
  Amended in the same commit rather than left as a second, conflicting assertion: the case is now
  `no-arg-resolves-the-repo-root-from-a-subdirectory`, built on a synthetic `git init` fixture with
  a planted duplicate and run from `nested/deeper/`. That actually proves the
  `git rev-parse --show-toplevel` fallback it always claimed to test — the old version passed
  identically whether the script resolved the root or just `$PWD`.
- **The general shape, worth more than the instance**: a unit test whose fixture is the live repo
  reads as coverage of the code but silently becomes a gate on content. It fails for a reason its
  own name does not describe — here, `arguments:` / `no-arg-…` would have been the heading over a
  broken decision record.
- **Task 3 — `CLAUDE.local.md` could not be edited from this session, and that is structural.**
  `worktree.sh create` links it in from the main tree, and the harness resolves the symlink and
  refuses the write as leaving the worktree. The file is gitignored anyway, so no commit could
  carry it: the line has to be changed in the main tree by hand, and it is the one part of task 3
  a merge does **not** deliver. The generalisation: **no `CLAUDE.local.md` edit is ever reachable
  from a `dw-start` worktree** — schedule it as a main-tree step, or it silently doesn't happen.
  Outstanding replacement for the **Test command** line under `## Project specifics`:

  ```
  - **Test command**: `pnpm validate:artifacts` (the bash self-tests in `scripts/tests/`, then
    `check-decisions.sh` over this repo's own `docs/decisions/`)
  ```

- **Task 1 — verified against the real folder, all three paths**: clean (silent, one
  `• docs/decisions/ clean` line, exit 0), a planted duplicate `0005` (finding printed,
  `Artifact validation FAILED`, exit 1), a planted `0007` gap (`warn:` printed,
  `All artifact checks passed`, exit 0). Both fixtures were untracked files, deleted after.
