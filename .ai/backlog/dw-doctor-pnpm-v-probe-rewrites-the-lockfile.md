---
created: 2026-08-12
source: setup-lives-in-tracked-agents-md
---

# `dw-doctor`'s `pnpm -v` probe rewrites `pnpm-lock.yaml`, and hides the mismatch it exists to report

Two bugs from one line — `cur_pnpm="$(pnpm -v)"` in `doctor.sh`, run with the target repo as cwd. Both
appeared once `devEngines.packageManager` became the pin (PR #23); the probe itself is older.

- **It is not read-only.** In a repo declaring `devEngines.packageManager`, that probe makes pnpm
  fetch itself and rewrite `pnpm-lock.yaml` — `packageManagerDependencies`, `packages:`, `snapshots:`,
  ~200 lines of pnpm's own binaries. The skill's own header promises it "never installs a tool, never
  edits a file". Measured: the file's sha changes across a single doctor run on a throwaway fixture.
- **It measures the wrong pnpm.** The value comes back as the _downloaded pinned_ version, so
  `$cur_pnpm` equals `$pmver` by construction and the "the pin is not in effect" warning can no longer
  fire — which is the one thing that block exists to say. Before #23 it fired correctly here
  (11.21.0 on PATH vs a 11.18.0 pin).

Likely fix is one line: take the version from outside the repo, so `devEngines` does not apply
(`(cd / && pnpm -v)`), which also makes it the PATH pnpm the comparison actually wants. Also blocks a
self-test for the pre-v11 lockfile check — see the comment where that case would go in
`scripts/tests/doctor.test.sh`.
