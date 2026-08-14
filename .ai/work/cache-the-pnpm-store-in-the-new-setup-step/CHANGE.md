---
change: cache-the-pnpm-store-in-the-new-setup-step
branch: cache-the-pnpm-store-in-the-new-setup-step
created: 2026-08-14
status: building # shaping | building | landed
---

# Change — the pnpm store is cached in CI, and the numbers decide whether it stays

## Goal

The three dev-tree workflows (`agnix-lint`, `format-check`, `evals-routing`) pass `cache: true` to
their `pnpm/setup@v2` step, and a warm run is measured against the ~7s baseline the parent change
recorded. Known when: a PR shows all three restoring from a `pnpm-cache-Linux-x64-<hash>` key on the
second run, the setup step's wall time on that warm run is written into `## Notes` beside the cold
one, and the change ends in one of two states — kept, with the measured saving in the workflow
comment, or **reverted, with the finding archived**. A revert is a real outcome here, not a failure:
the backlog entry that seeded this file asked for the comparison precisely because the tree is nine
locked entries and the win was never assumed.

## Decisions

- **One scope, so one change.** Three workflows, but a single seam: the same one-line input, measured
  once, kept or reverted once. Splitting per workflow would mean three PRs sharing one measurement.
- **`validate-plugin-manifests` is deliberately left out — the cache key is not namespaced by job.**
  Read from source: the key is `pnpm-cache-${RUNNER_OS}-${arch}-${hashFiles('pnpm-lock.yaml')}`
  (`src/cache-restore/run.ts` at the pinned SHA), with no workflow or job component. That job runs
  `install: false` and populates its store with the Claude Code CLI's dependencies instead of the dev
  tree's, so turning cache on there lets it save a store the other three would then restore on an
  exact key hit — and, because save is skipped on an exact hit
  (`src/cache-save/run.ts`), never replace with the right one until the lockfile changes. Same key,
  wrong contents, and the cache would be worse than none. It also gains nothing itself: one global
  `pnpm add -g`, no lockfile install.
- **Turn all three on at once, not one as a canary.** They share the key by design, so a single-workflow
  trial measures the cold-save path only and tells you nothing about the steady state — the state that
  decides this.
- **The comment above each step has to change with it.** It currently ends "Inputs would only restate
  the file", which stops being true the moment a `with:` block appears. The replacement says what the
  one input buys, which is also where the measured number lands if the change is kept.
- **No version bump.** Nothing here is shipped payload — `.github/` only. Same reasoning the parent
  change recorded, and the one case where the `## Gotchas` bump rule does not fire.
- **The concurrent shape on disk is not this change's business.** `dw-solo-skills-4f` staged
  `.ai/work/doctor-version-probes-read-only-and-read-devengines/` in this repo's index while this file
  was being written. Commit **by name**; do not sweep the index.

## Tasks

- [x] 1. **The input, in three files, and the comment that has to move with it.** Add
      `with:` / `cache: true` under the `pnpm/setup` step in `agnix-lint.yaml:22`,
      `format-check.yaml:22` and `evals-routing.yaml:27`, and rewrite the shared comment's last
      sentence in each (`:21`, `:21`, and evals-routing's longer block) so it no longer claims inputs
      would only restate `package.json`. Leave `validate-plugin-manifests.yaml:35-37` untouched.
      Green when `pnpm format` passes locally — nothing else here is exercisable off a runner.
- [x] 2. **The cold run: push, open the PR, read all three setup steps.** Record per workflow: the
      "Cache is not found" line, the setup step's wall time, `pnpm install`'s reused/downloaded split,
      and what `pnpm store prune` — which only runs when caching is on
      (`src/pnpm-store-prune/index.ts`) — costs. Also watch for the three-way save race: all three jobs
      miss the same key and try to save it at the end, and only the first can. Whether the losers log
      it quietly or fail the step is the one thing the source does not settle — `saveCache` returning
      `-1` is handled, a throw is not.
- [ ] 3. **The warm run, and the verdict.** Re-run the same PR with the lockfile unchanged so the key
      hits, and put the three warm setup times beside the cold ones and beside the ~7s baseline. Then
      decide in `## Notes`, in writing: keep, with the number in the workflow comment from task 1, or
      revert the three files. Expect the honest answer to be small — the store covers pnpm's own
      downloads, and `agnix`'s postinstall pulls a prebuilt binary into `node_modules`, which no store
      cache restores.

## Anchors

- `.github/workflows/agnix-lint.yaml:20-22`, `format-check.yaml:20-22` — the identical two-line
  comment plus the bare `pnpm/setup` step, no `with:` block anywhere. The two files task 1 treats
  identically.
- `.github/workflows/evals-routing.yaml:20-27` — the same step behind a longer comment that also
  argues why `install: false` would be dishonest here. Only its "Inputs would only restate the file"
  sentence is in scope.
- `.github/workflows/validate-plugin-manifests.yaml:34-37` — the fourth `pnpm/setup`, the one with
  `install: false`, and the one this change leaves alone. Its `paths:` filter (`:5-8`) means it rarely
  runs at all, which is a second, weaker reason.
- `pnpm/setup@84cb39b217b10273981911c288cd62326dc7c6d2` — `src/cache-restore/run.ts` (key shape and
  the `pnpm-cache-${OS}-${arch}-` prefix restore-key, which is what buys partial reuse across a
  lockfile bump), `src/cache-save/run.ts` (no save on an exact hit), `src/pnpm-store-prune/index.ts`
  (prune runs only under `cache: true`). `action.yml` confirms `cache` defaults to `'false'` and
  `cache-dependency-path` to `pnpm-lock.yaml`, so no second input is needed.
- `.ai/archive/migrate-ci-to-the-pnpm-setup-successor-action/CHANGE.md` — the baseline this measures
  against: setup ~7s, `reused 1, downloaded 8` over **9** locked entries (Node is one of them, via
  `devEngines.runtime`), from run `31638505867`. Its "Left out, for `dw-land` to park" paragraph is
  what became this change.

## Notes

**The cache is over the store, not `node_modules`.** Worth holding onto while reading task 3's
numbers: `pnpm store path` is what gets cached, so the saving is bounded by what pnpm downloads from
a registry — not by linking time, and not by any postinstall that fetches its own binary.

### From task 1 — the exclusion has no home in the file it is about

**The replacement comment is three lines, not the fuller one the task implied**, and it deliberately
stops before naming `validate-plugin-manifests`. Two facts earn their place in all three files: the
versions still need no input, and the key has no job component, so the three share one entry. The
second is the one that makes the exclusion legible without asserting it from a file that cannot show
it.

**Which leaves a gap a future session will read as an inconsistency.** Nothing in
`validate-plugin-manifests.yaml` says its bare `pnpm/setup` step is uncached _on purpose_, and the
obvious tidy-up — "three of four have `cache: true`, finish the job" — is precisely the change that
poisons the shared key. The reasoning currently lives only in `## Decisions` here, which is archived
at land time. **For `dw-land`:** this belongs in `docs/agents/tooling.md`, not in a fourth workflow
comment, and it survives even if task 3 ends in a revert — a reverted cache still leaves the
"why not just turn it on everywhere" question open.

### From task 2 — the cold run, and the ~7s baseline was measuring the wrong thing

PR [#28](https://github.com/dominikwozniak/dw-solo-skills/pull/28), run `31782343054`/`58`/`64`, all
four checks green.

**The baseline this change quotes is mis-scoped, and the correction shrinks the ceiling.** "The whole
setup step is ~7s" in the parent change is really the time to `Progress: … added 9, done` — the pnpm
download, the Node install and the package resolution. Measured on the baseline job itself
(`94254808206`): the step opens at `20:36:54.35` and the next step opens at `20:37:31.47`, so the
step is **37.1s**, of which ~6.7s is everything the archive was timing and the remaining **~30s is
`agnix`'s postinstall** fetching its prebuilt binary. A store cache cannot touch that 30s. **The
honest ceiling for this change is a fraction of ~7s, not of ~37s** — task 3's verdict has to be read
against that, and the goal's "~7s baseline" should be read as "~7s of a 37s step".

**Cold numbers, cache on** — setup step, group-open to next-group-open: `agnix lint` **37.8s**
(`08:03:28.60` → `08:04:06.36`), `Routing evals` **37.2s**. All three logged `Cache is not found`
and then the identical `resolved 9, reused 1, downloaded 8, added 9, done`, i.e. exactly the
baseline's install. So enabling the cache costs nothing measurable on a miss.

**The save race resolves as a warning, not a failure — the open question is answered.** All three
jobs missed the same key concurrently; `Routing evals` won and logged `Cache saved with the key:
pnpm-cache-Linux-x64-58e0f01…`. The other two logged
`##[warning]Failed to save: Unable to reserve cache with key … another job may be creating this
cache.` and stayed green. `@actions/cache` swallows the `ReserveCacheError` itself, so the action not
catching it never mattered. **Three concurrent jobs on one key is safe**, and that is what makes the
shared-key design tolerable rather than merely tolerated.

**`pnpm store prune` runs before the save and is cheap but not free:** each job removed all cached
metadata files, `6 files (7.31 MB)` and `1 package`, in about 1s.

**The saved cache is 45.1 MB** (`gh cache list`), because `pnpm store path` holds the Node 24.16.0
runtime as well as the eight dev packages. That is the number that decides this: the warm run has to
download and extract ~45 MB to avoid fetching eight small packages and one Node tarball. It is
entirely plausible that the restore is _slower_ than the misses it replaces, which is the outcome
task 3 must be willing to report.
