---
change: doctor-version-probes-read-only-and-read-devengines
branch: doctor-version-probes-read-only-and-read-devengines
created: 2026-08-14
status: building
---

# Change — `doctor.sh`'s version block probes without mutating, and reads both `devEngines` pins

## Goal

The JavaScript/TypeScript group in `skills/dw-doctor/scripts/doctor.sh` stops writing to the repo it
diagnoses, and takes both version pins from where pnpm 11 actually keeps them. Known when: a doctor
run over a fixture declaring `devEngines.packageManager` leaves `pnpm-lock.yaml`'s sha unchanged; the
"the pin is not in effect" warning fires again for a PATH pnpm that differs from the pin; the node
line reports against `devEngines.runtime` when present; and the pre-v11 lockfile case that
`scripts/tests/doctor.test.sh:375` explains it cannot write becomes a real case.

## Decisions

- **One change, not two** — the user asked for it merged, and the reason holds: both entries edit the
  same ~40-line version block in one file, both ship in the same `dw-solo-setup` bump, and the
  `pnpm -v` fix is what unblocks the fixture the runtime work would want anyway. Splitting would mean
  two bumps and two passes over the same lines.
- **Probe pnpm from outside the repo** (`(cd / && pnpm -v)`) rather than suppressing `devEngines` some
  other way — it is one line, it is the PATH pnpm the comparison actually wants, and it keeps the
  existing "pnpm refuses to run here" branch meaningful (that branch stays repo-local, since refusing
  is a repo-local fact).
- **`devEngines.runtime` first, then `engines.node`** — mirrors exactly what the pnpm pin already does
  with `devEngines.packageManager` → `packageManager`, so the block reads as one idea twice.
- **`.nvmrc` stays in the hint text, conditionally** — this repo dropped the file, but a consumer repo
  that still has one deserves the advice. Name it only when it exists.

## Tasks

- [x] 1. Take `cur_pnpm` from outside the repo so the probe is read-only and measures the PATH pnpm;
      keep the empty-result branch and its message intact.
- [ ] 2. Turn `scripts/tests/doctor.test.sh:375`'s comment into the pre-v11 LOCKFILE case it describes,
      plus an assertion that a doctor run leaves the fixture's `pnpm-lock.yaml` sha unchanged.
- [ ] 3. Read the Node pin from `devEngines.runtime.version` when present, falling back to
      `engines.node`; report it as a pin (`==`) vs a floor (`>=`) the way the pnpm block distinguishes
      an exact version from a range.
- [ ] 4. Make the `.nvmrc` mentions at `doctor.sh:111` and `:117` conditional on the file existing,
      and update `skills/dw-doctor/SKILL.md:29-31` to name `devEngines.runtime` as the Node source.
- [ ] 5. Bump `plugins/dw-solo-setup/.claude-plugin/plugin.json` (0.1.17 → next) and run the full
      `scripts` block from `package.json`.

## Anchors

- `skills/dw-doctor/scripts/doctor.sh:137` — `cur_pnpm="$(pnpm -v 2>/dev/null)"`, the one line that
  causes both the lockfile rewrite and the dead `$cur_pnpm = $pmver` comparison at `:149`.
- `skills/dw-doctor/scripts/doctor.sh:102-118` — the node block: `engines.node` as a floor via
  `ver_ge`, with `.nvmrc` named unconditionally in both the warn and the fail message.
- `skills/dw-doctor/scripts/doctor.sh:124-134` — the `devEngines.packageManager` → `packageManager`
  precedence and its `pmsrc` label; task 3 copies this shape for the runtime.
- `scripts/tests/doctor.test.sh:375-383` — the comment standing in for the blocked case, and the
  record of the measurement (sha changes across one run). It goes when the case lands.
- `package.json:24-39` — this repo declares both `engines` and both `devEngines` entries, so it is its
  own fixture for the "pin present" path.
- `.ai/archive/migrate-ci-to-the-pnpm-setup-successor-action/CHANGE.md:151-179` — why
  `devEngines.runtime` makes Node a lockfile dependency, and where it parked this follow-up.

## Notes

The second backlog entry (`dw-doctor-reads-devengines-runtime-as-the-node-pin`) is folded in here and
removed from `.ai/backlog/`; the file this doc was `git mv`'d from is the first.

**Task 1 — the empty-result message could not stay intact, and the shaping decision was wrong about
why.** It read "on PATH but refuses to run here", blaming a devEngines `onFail: "error"`. That is a
repo-local diagnosis, and probing from `/` puts the probe where no repo applies — so the branch can no
longer be reached for that reason, only by a pnpm that cannot run at all. Message reworded to say
that instead. The refusal case is now undetectable without re-introducing the write, and that is the
trade the goal takes deliberately: a wrong-but-visible pin beats a right diagnosis bought with a
lockfile rewrite. Nothing asserted the old wording (`grep` over `skills/`, `docs/`, the self-tests).

Measured on this repo after the fix: `pnpm-lock.yaml`'s sha is identical across a doctor run, and the
pin warning fires again (PATH 11.21.0 vs the 11.18.0 pin) — both halves of the two-bug report.
