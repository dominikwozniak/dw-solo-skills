---
change: validate-decision-records
branch: validate-decision-records
created: 2026-08-09
status: building # shaping | building | landed
---

# Change — the decision-record contract gets a check, run before `dw-land` writes the next record

## Goal

`docs/decisions/` in a lane repo is validated by a shipped script instead of by nobody. `dw-land`
runs it before it writes a new record and stops on a failure; `dw-doctor` runs it on demand and
reports each finding as its own line. You know it worked when a folder holding a record with
`decision: 4` instead of `0004`, or a `superseded` record whose `superseded-by:` names nothing that
exists, fails the script by name and line — and when a clean folder is silent.

The contract already exists in prose: `.ai/archive/decision-record-contract-for-consumer-repos/`
shipped `templates/decisions-README.md` yesterday. This change makes it enforceable.

## Decisions

- **Drift check, not collision prevention** — `dw-land` runs inside one worktree and cannot see a
  sibling worktree that already wrote `0004` and has not merged. Widening the scan to
  `git worktree list` was rejected: it buys a narrow window at real cost and is blind to another
  machine anyway. The two-worktree collision is caught after merge, by the same script.
- **Never renumber, always report and stop** — not a preference: `templates/decisions-README.md`
  says numbers are never reused and `references/decision-record.md:57` says never renumbered,
  because the number is what `superseded-by:` is made of. Auto-repair would break the pointers it
  is protecting.
- **Contiguity is a `WARN`, everything else is an error** — a gap means a record was deleted, which
  is past tense and breaks nothing being written now. A repo that got the skills without `dw-init`
  and starts at `0010` should complain once, not block every close.
- **Fixed path, silent when absent** — `docs/decisions/` relative to the repo root, no config. A
  repo with no records is legal, so a missing folder is `exit 0` with no output.
- **`scripts/runtime/`, not a skill-bundled script** — two skills in two different plugins call it
  (`dw-land` in `dw-solo`, `dw-doctor` in `dw-solo-setup`), which is exactly the case
  `CLAUDE.md`'s "shipped script" rule covers. `doctor.sh` stays bundled because only one skill
  calls it.
- **Only the ADR block is generalised** — the rest of `check-agents-docs.mjs` (Task Router, Skills
  table sync, `pnpm <script>` ↔ `package.json`, `built:` paths, symlinks) is the contract of
  `grateful-me-app-v2`, not of the lane, and stays there. `agnix` cannot replace any of it: ~447
  built-in rules, no custom rules, no plugin API.

## Tasks

- [x] 1. `scripts/runtime/check-decisions.sh` — bash 3.2 safe, read-only, adapted from
      `check-agents-docs.mjs:98-163`. Takes an optional repo root (default `git rev-parse
--show-toplevel`), reads only `docs/decisions/*.md`, skips `README.md`. Errors: filename not
      `<NNNN>-<kebab-slug>.md`, duplicate number, missing frontmatter, `decision:` ≠ filename
      number, `date:` not `YYYY-MM-DD`, `status:` ∉ {`active`, `superseded`}, `superseded` with a
      missing or dangling `superseded-by:`. Warning: first gap in the sequence from `0001`, that
      one only. Values may carry a trailing `# active | superseded` comment — strip it, the way
      `field()` does at `:99-103`. Exit 0 clean or warnings-only, non-zero on any error. Plus
      `scripts/tests/check-decisions.test.sh` with a fixture folder per case, and the basename
      added to `RUNTIME_SCRIPTS` in `scripts/validate-manifests.sh:47`. Symlinks into **both**
      `plugins/dw-solo/scripts/` and `plugins/dw-solo-setup/scripts/` (mode 120000, `git add`
      them). Bump `dw-solo` 0.4.11 → 0.4.12 and `dw-solo-setup` 0.1.9 → 0.1.10, each in
      `.claude-plugin/marketplace.json` **and** its own `plugin.json`, identical — one bump per
      plugin covers this whole change, later tasks do not bump again.
- [x] 2. `skills/dw-land/SKILL.md:67-73` — the **Promote the decisions** bullet runs
      `bash "${CLAUDE_PLUGIN_ROOT}/scripts/check-decisions.sh"` **before** allocating a number, and
      stops on a non-zero exit: report what it found and let the user fix the folder, never
      renumber or rewrite a record to make it pass. One or two sentences appended to the existing
      bullet, not a new step — the closing sequence is already long.
- [x] 3. `skills/dw-doctor/scripts/doctor.sh:196-201` — the `docs/decisions/` presence check gains
      the content pass: when the folder exists, run the shared script and turn its output into
      `report ok` / `report warn` / `report fail` lines with the usual "gap + fix to paste" shape.
      Keep the absent branch as it is. `doctor.sh` reaches the script via `${CLAUDE_PLUGIN_ROOT}`
      like the skill bodies do; confirm that variable is actually set for a bundled script before
      relying on it, and fall back to a path relative to the script's own location if it is not.
- [x] 4. `skills/dw-doctor/SKILL.md:36` — one clause saying the decisions check now reads the
      records, not just the folder, so the skill's own description of what it checks stays true.

## Anchors

- `/Users/dominik.wozniak/workspace/private/byarcadia-packages/grateful-me-app-v2/scripts/check-agents-docs.mjs:98-163`
  — the block being adapted, read-only. `:99-103` `field()`, `:110-116` filename shape, `:117-122`
  duplicate, `:124-128` frontmatter, `:132-141` field checks, `:146-154` contiguity, `:156-163`
  supersede link. Self-contained, zero dependencies.
- `templates/decisions-README.md` — the contract being enforced: append-only, numbers never reused.
  Shipped into every `dw-init` repo, which is why contiguity is lane canon and not a foreign rule.
- `skills/dw-land/references/decision-record.md:55-58` — "never renumbered — the old record's
  number is what the pointers are made of". The reason task 2 reports instead of repairing.
- `skills/dw-land/SKILL.md:67-73` — the bullet task 2 edits.
- `skills/dw-doctor/scripts/doctor.sh:196-201` — the check task 3 extends; `:28-36` is the `report`
  helper and its four levels.
- `scripts/validate-manifests.sh:47` — `RUNTIME_SCRIPTS="slugify.sh worktree.sh"`, plus `:48-54`
  (canonical file exists and is executable) and `:98-104` (shipped by at least one plugin).
- `scripts/runtime/slugify.sh` + `scripts/tests/slugify.test.sh` — the closest neighbour in size
  and shape: a small pure-bash runtime script with a fixture-driven self-test. Copy that voice,
  not `worktree.sh`'s.
- `docs/decisions/` here — five real records (`0001`–`0005`) and a `README.md`. The script must be
  silent on this folder; if it is not, the script is wrong before the folder is.

## Notes

- **Task 1 — findings are line-prefixed `error: ` / `warn: `.** The shape wasn't specified; the
  script needs one because two callers route the same output differently (`dw-land` stops on a
  non-zero exit, `dw-doctor` turns each line into a `report` row). Anything parsing that output
  depends on the prefix.
- **Task 1 — `plugins/dw-solo-setup/scripts/` did not exist**; this is the first shipped script
  that plugin carries. `validate-manifests.sh` skips a plugin with no `scripts/` dir, so nothing
  had to change for it to appear.
- **Task 1 — fixtures are built under `mktemp -d`, not committed.** One synthetic
  `docs/decisions/` per case, thrown away by an `EXIT` trap. Committing 20 fixture folders to
  assert one defect each would be more repo than signal, and the test reads better with the
  defect visible beside the assertion.
- **Task 2 — the bullet says explicitly what to do with a `warn:` line.** Without it the "stops on
  a non-zero exit" instruction reads as "any output is a problem", which would turn a gap into a
  blocked close — exactly the outcome the WARN decision exists to prevent.
- **Task 3 — `CLAUDE_PLUGIN_ROOT` is NOT in the environment a skill's Bash call runs in.** Checked
  with `env` in this session: it is substituted into skill _bodies_ at load, and nothing exports
  it, so a bundled script that reads it gets an empty string. `doctor.sh` resolves from `$0`'s
  directory and treats the variable as an optional first candidate only. Anything else bundled
  that wants a sibling shipped script has the same problem.
- **Task 3 — the three rendered levels were checked by hand** (OK on the clean folder, FAIL on a
  planted duplicate-number record, WARN on a planted gap), then the folder was restored from
  `HEAD`. `doctor.sh` has no self-test in this repo and this change did not add one.
- **Neighbour, deliberately not merged**: `.ai/backlog/validator-blind-spots.md`, third bullet,
  wants a validator asserting that the three copies of the contract
  (`templates/decisions-README.md`, `skills/dw-land/references/decision-record.md`,
  `docs/decisions/README.md`) all state the bar as **all three**. That polices _this_ repo's prose;
  this change validates a _consumer_ repo's records. Different files, different failure. Leave the
  entry where it is.
- **Version collision risk.** `.ai/work/skill-and-docs-drift/` is `unclaimed` and targets a
  `dw-solo` bump; `.ai/backlog/setup-payload-sweep.md` is bundled around a single `dw-solo-setup`
  bump. Whichever lands first takes the number. After any rebase onto `main`, re-check both
  versions — `validate-manifests.sh` only checks the two files are _equal_, never that either grew
  (`## Gotchas`).
- Both edited skill bodies are **unexercised until reinstall** — the session that builds this
  serves `dw-solo/0.4.11` from the plugin cache. Read the canon text; never validate by invoking
  the skill.
- Full gate before push:
  `pnpm lint && pnpm format && pnpm validate:manifests && pnpm validate:artifacts && pnpm validate:docs && pnpm validate:evals && pnpm eval:routing`.
  No new skill and no `description` edit, so `eval:routing` should be unmoved; a shift means
  something else drifted.
- Candidate follow-up for `dw-land` to park: run `check-decisions.sh` over this repo's own
  `docs/decisions/` from `scripts/validate-artifacts.sh`, so the dogfood folder is held to the
  contract in CI rather than only when someone closes a change.
