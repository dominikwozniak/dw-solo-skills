---
change: pnpm-pin-in-one-field
branch: pnpm-pin-in-one-field
created: 2026-08-12
status: landed # shaping | building | landed
landed: 2026-08-12
---

# Change — the pnpm version lives in one field, and everything that reads it agrees

## Goal

`devEngines.packageManager` is the only place this repo states its pnpm version, and every reader
agrees with it: CI (`pnpm/action-setup` bumped past the SHA that cannot see the field), npm's
`EBADDEVENGINES` guard, and the `dw-doctor` this repo ships. Known when: `packageManager` is gone
from `package.json`, all three Node workflows are green **on the PR** (a feature-branch push fires
nothing here), `pnpm --version` still reports `11.18.0` locally, `bash skills/dw-doctor/scripts/doctor.sh`
reports the pin from `devEngines`, and the paired-version sub-bullet is out of `## Gotchas`.

Second half of the same goal, pointed outward: `dw-doctor` stops giving v11 repos wrong advice
(`corepack enable`) and starts catching the two failures pnpm 11 makes **silently** — an orphaned
`package.json#pnpm` block, and a lockfile written by pnpm 10 or older.

## Decisions

Taken in the `dw-grill` pass; the measurements they rest on are in
`.ai/archive/pnpm-v11-migration/CHANGE.md`.

- **Bump `pnpm/action-setup` v4 → v6.0.10, rather than migrate to `pnpm/setup@v2`** — one SHA line
  per workflow retires the hazard. v6's `readTargetVersion` reads `devEngines.packageManager` and
  gives it priority over `packageManager`; v5 moved the action to Node 24 and v6 added pnpm 11
  support, so nothing else in the workflows changes. `pnpm/setup@v2` (the successor its README now
  points at) is 8 days old and would rewrite all three workflows and force `devEngines.runtime`.
- **Drop `packageManager` entirely** — no Dependabot, no Renovate, no corepack in this repo, and
  npm's `EBADDEVENGINES` guard comes from `devEngines`, so the `pnpm/only-allow` replacement
  survives the deletion. This is the whole point of the bump.
- **No `devEngines.runtime`** — closes the question the migration parked. `.nvmrc` is the CI pin
  (`setup-node` reads it) and `engines.node` is the floor `doctor.sh` checks; a third copy would
  have no reader, and `onFail: "download"` would have pnpm fetch its own Node locally.
- **`dw-doctor` reports, it does not audit policy** — no check for `minimumReleaseAge` /
  `allowBuilds` / `trustPolicy` in a target repo. The skill's charter is whether the guardrails fire,
  not whether a repo follows this one's supply-chain policy.
- **One change, not two, though each half could ship alone** — dropping `packageManager` makes this
  repo's own shipped diagnostic blind to the pin it checks, so the drop and the read are one scope.
  The split question is answered; don't reopen it.
- **`templates/` is untouched** — it ships no `package.json`, so there is nothing there to migrate.

## Tasks

- [x] 1. **The pin.** Swap `pnpm/action-setup@b906affcce14559ad1aafd4ab0e942779e9f58b1 # v4` for
      `@0977fd99725f1db4007ccb2928dbb4e90d06cc86 # v6.0.10` in all three Node workflows, delete
      `package.json:7`, and retire the fourth sub-bullet of the pnpm entry in `## Gotchas`
      (`AGENTS.md:279-282` — the entry becomes "three traps deep", and `:281` stops being true the
      moment the SHA moves). Green when `pnpm install` still resolves 11.18.0 and the full gate
      passes; CI itself can only be confirmed on the PR. **Took two extra edits nobody predicted —
      an `engines.pnpm` floor and `onFail: "download"`; the third `## Gotchas` sub-bullet was
      rewritten rather than the fourth merely deleted. See `## Notes`.**
- [x] 2. **The doctor reads the right field.** `doctor.sh:98-113`: take the version from
      `.devEngines.packageManager` first, fall back to `.packageManager` (a target repo may still
      have only that), and replace both `corepack enable` hints — missing pnpm is
      `brew install pnpm`, a version mismatch is `pnpm install`, since v11 self-manages. Update
      `skills/dw-doctor/SKILL.md:29`, which names `packageManager` as what it reads. Bump
      `dw-solo-setup` by one patch in `.claude-plugin/marketplace.json` **and**
      `plugins/dw-solo-setup/.claude-plugin/plugin.json:3` — read the current number rather than
      trusting this doc (see `## Notes`).
- [x] 3. **The two silent traps.** Two new WARN-tier checks in the same block, never FAIL: a
      `package.json#pnpm` block that merely _exists_ (v11 drops unrecognised keys with no warning at
      all — measured), and a lockfile written before v11, detected by the absence of
      `packageManagerDependencies`, never by `lockfileVersion`, which still reads `'9.0'`. Both
      pnpm-gated, so a non-pnpm repo sees nothing. No further version bump — task 2's covers the PR.

## Anchors

- `.github/workflows/agnix-lint.yaml:23`, `format-check.yaml:23`, `evals-routing.yaml:23` — the
  same pinned v4 SHA in all three, each with `run_install: false`. `setup-node` runs before it in
  every one, which is why none has `cache: pnpm`.
- `package.json:7` — `"packageManager": "pnpm@11.18.0"`, the line to delete. `:28-33` is the
  `devEngines.packageManager` block that stays (`onFail: "error"`).
- `skills/dw-doctor/scripts/doctor.sh:98-113` — the whole pnpm check: reads `.packageManager` via
  `jq`, falls back to `pnpm-lock.yaml` presence, and hints `corepack enable` twice (`:106`, `:111`).
- `skills/dw-doctor/SKILL.md:29` — the "What it reads" bullet naming `packageManager`.
- `AGENTS.md:263-282` — `**pnpm here is four traps deep…**`; `:279-282` is the sub-bullet this change
  retires, `:273-278` (`pnpm view` / `pnpm info` broken on purpose) stays true and must survive.
- `.ai/archive/pnpm-v11-migration/CHANGE.md:98-127` — the measurements task 3 rests on: question 1
  (`lockfileVersion` unchanged at `'9.0'`; `packageManagerDependencies` is the tell) and question 3
  (pnpm warns only about keys on its known-relocation list, so an orphaned block goes silent).
- `.ai/work/setup-lives-in-tracked-agents-md/CHANGE.md:69-70` — task 6 of a change already shaping,
  which rewrites a different region of the same file and takes the same plugin's next patch number.

## Notes

**The `dw-solo-setup` version is a moving target.** It was 0.1.12 when this was shaped and 0.1.13 by
the time the file was written — PR #21 landed a `templates/hooks/` fix in between. Read
`.claude-plugin/marketplace.json` at build time and take the next patch; both manifests must state
the same number, and `validate-manifests.sh` only checks they are _equal_, never that either moved.

**Ordering against `setup-lives-in-tracked-agents-md`.** That change's task 6 rewrites
`doctor.sh:227-230` (the `CLAUDE.local.md` presence-warn) and adds the script's first self-test;
this one rewrites `98-113`. Different regions, no conflict — but whichever lands second takes the
later patch number, and if the self-test harness lands first, tasks 2 and 3 should add cases to it
rather than leave the new parsing untested. That change's own anchor for the region reads
`doctor.sh:270-274`, which is past EOF at 265 — worth fixing when it is picked up.

**Left out, for `dw-land` to park:** migrating all three workflows to `pnpm/setup@v2`
(`84cb39b217b10273981911c288cd62326dc7c6d2`, v2.0.2). It installs pnpm and the runtime in one step,
reads `devEngines.runtime` and `devEngines.packageManager` with no inputs, and runs `pnpm install`
automatically unless `install: false` — so `actions/setup-node` and `.nvmrc` would leave CI, and
`devEngines.runtime` would become required. That is where the parked Node question goes to be
answered, not here.

### From task 1 — `devEngines` alone is not a pin, it is a pin plus two preconditions

**`devEngines.packageManager` is a pnpm 11 field, and the bootstrap that must read it lives outside
the repo.** Homebrew had pnpm 10.14.0 on `PATH` here. Measured both ways in the worktree: with
`packageManager` present `pnpm --version` reported 11.18.0, with it deleted, 10.14.0 — v10 cannot see
`devEngines` at all. The demotion is nearly silent: v10 does read `pnpm-workspace.yaml` (`pnpm config
get minimumReleaseAge` → `10080`), but `allowBuilds` is a v11 key and `strictDepBuilds` a v11 default,
so build approval and lockfile handling quietly differ. **Fix: an `engines.pnpm` floor**
(`>=11.0.0 <12.0.0`), measured to hard-fail with `ERR_PNPM_UNSUPPORTED_ENGINE  Expected version: …
Got: 10.14.0`. `brew upgrade pnpm` took this machine to 11.21.0.

**`onFail` had to change from `"error"` to `"download"`, and that retires an archived decision.**
While `packageManager` existed, pnpm's own self-management resolved the version and `onFail` never
fired. With the field gone it governs every command: on 11.21.0 against a pinned 11.18.0, `"error"`
refused outright — `[ERROR] This project is configured to use 11.18.0 of pnpm` — so no `brew upgrade`
would survive it. `"download"` fetches 11.18.0 and runs it, which is precisely what the deleted field
used to do. `pnpm --version` → 11.18.0 on an 11.21.0 bootstrap.

**Open, and it needs a human to probe: is npm still refused here?**
`.ai/archive/pnpm-v11-migration/CHANGE.md:166-198` chose `onFail: "error"` as the `pnpm/only-allow`
replacement and measured `pnpm view` as the proxy for "npm refuses". That proxy is no longer valid —
under `"error"` pnpm refuses before it ever delegates, and under `"download"` `pnpm view prettier
version` returns `3.9.6` here, so nothing about npm is being observed either way. `block-non-pnpm.sh`
stops the agent from testing npm directly. One command in the repo root settles it:
`npm install --dry-run` — `EBADDEVENGINES` means the guard survived the switch, a normal dry-run
report means it did not, and the archived decision needs a `superseded-by:` record at land time.

**The third `## Gotchas` sub-bullet was rewritten, not just the fourth deleted.** "`pnpm view` and
`pnpm info` are broken here on purpose" became false the moment `onFail` changed. The replacement
states the pin's three preconditions (v11 bootstrap, `onFail` semantics, action-setup ≥ v6) and
deliberately makes no claim about npm until the probe above is run. Entry count is unchanged at
12/12 — these are sub-bullets.

### From task 3 — `packageManagerDependencies` alone would have false-positived

The task said to detect a pre-v11 lockfile by the absence of `packageManagerDependencies`. Reading
this repo's lockfile shows why that is too narrow: the archive's own finding
(`CHANGE.md:98-103`) is that the key appears **once `devEngines.packageManager` exists** — so a v11
lockfile in a repo without that field carries no such key and would be reported as stale. The check
therefore accepts any of v11's marks: the leading `---` document separator, `configDependencies:`, or
`packageManagerDependencies:`. `lockfileVersion` is still never consulted, which was the real
instruction.

Both checks are gated on v11 actually being in play — the running pnpm or the pin reading 11 or
higher — because on v10 a `package.json#pnpm` block is correct and the old lockfile is current.
Exercised against a throwaway fixture repo (a v10-shaped lockfile plus an
`onlyBuiltDependencies` block): both fired there, both stay silent here. `doctor.sh` still has no
self-test — see the ordering note above.

**Verification is PR-only.** Every workflow fires on `pull_request:` or `push: branches: [main]`,
with no `workflow_dispatch` — a feature-branch push confirms nothing. `validate-plugin-manifests`
is known safe either way: it runs `npm install -g @anthropic-ai/claude-code` in the repo root and
was green on `main` today, so the `onFail: "error"` guard does not block global installs.
