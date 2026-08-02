---
change: pnpm-v11-migration
branch: pnpm-v11-migration
created: 2026-08-01
status: building # shaping | building | landed
---

# Change — migrate this repo to pnpm v11 and adopt its supply-chain defaults

## Goal

This repo installs under pnpm 11 with its security settings actually in effect, not silently
ignored. Known when: `rm -rf node_modules && pnpm ci` succeeds from cold, `agnix` lands in
`node_modules/.bin/` (proving `allowBuilds` works under the new `strictDepBuilds: true` default),
`pnpm config list` reports `minimumReleaseAge=10080`, and the five-command gate plus both Node CI
workflows pass on the regenerated lockfile.

This is the first of two changes. It is also the experiment: the second one (`pnpm-v11-payload` —
teaching `templates/`, `dw-init` and `dw-doctor` to set this up in every other repo) is shaped from
what this one learns, so the four questions under `## Notes` are a deliverable, not a curiosity.

## Decisions

- **Settings go to `pnpm-workspace.yaml`, not `.npmrc`** — v11 docs: _"Only auth and registry
  settings are read from `.npmrc` files."_ The `.npmrc` page is retitled "Authentication Settings".
  No choice here; `.npmrc` would be a no-op.
- **`pnpm-workspace.yaml` with no `packages:` key** — legal in a non-monorepo: _"If the `packages`
  field is omitted, only the root package is included in the workspace."_
- **`minimumReleaseAge: 10080`** (7 days, unit is minutes) rather than the v11 default `1440` — a
  day catches most malicious releases, a week catches the rest at near-zero cost for a 7-package tree.
- **`minimumReleaseAgeStrict: true` written out explicitly** — the v11 release notes and
  `/settings/dependency-resolution` state contradictory defaults (`false` vs "true when you set
  `minimumReleaseAge` yourself"). Pinning it removes the ambiguity. Accepted cost: `pnpm add` of a
  too-fresh package hard-fails instead of silently resolving to it; escape hatch is
  `minimumReleaseAgeExclude`.
- **`trustPolicy: no-downgrade`** — opt-in (default `off`). Cheap here, and a package losing its
  trust evidence is exactly the signal worth failing on.
- **Keep `packageManager` alongside the new `devEngines.packageManager`** — CI's `pnpm/action-setup`
  runs with no `version:` input and falls back to `packageManager`. Whether it reads `devEngines` is
  unverified, so dropping the old field would be a blind bet.
- **No corepack** — v11 self-manages its version via `pmOnFail: download` (the default), which
  replaced the removed `managePackageManagerVersions`. Corepack is also unbundled from Node 25.
- **`.nvmrc` and `engines.node` stay as they are; no `devEngines.runtime`** — CI pins Node through
  `node-version-file: .nvmrc`, and `onFail: "download"` would have pnpm fetch its own Node. Separate
  decision, parked for the backlog.
- **`pnpm/only-allow` is not adopted** — the package was archived in April 2026 and its own README
  points at `devEngines.packageManager` instead. (`https://pnpm.io/only-allow-pnpm` still recommends
  it; that page is stale.)

## Tasks

- [x] 1. Bump to pnpm 11 and relocate the config — atomic, because a v11 pin with the settings still
      in `package.json#pnpm` is a broken intermediate state (the field is ignored, `agnix`'s build is
      then unapproved, and `strictDepBuilds: true` fails the install). Run
      `pnpm dlx codemod run pnpm-v10-to-v11`, review the diff by hand, hand-write the remaining
      supply-chain keys, delete the `pnpm` block from `package.json`, add
      `devEngines.packageManager`. Commit the regenerated lockfile in the same commit. Green when
      `rm -rf node_modules && pnpm ci` succeeds cold and `node_modules/.bin/agnix` is executable.
- [x] 2. Answer the four open questions under `## Notes` and write the results there — they are the
      input to `pnpm-v11-payload`, and `dw-doctor` check D1's value depends directly on the third one.
- [ ] 3. Switch both Node workflows to `pnpm ci` (`agnix-lint.yaml:26`, `format-check.yaml:26`) and
      confirm they pass on the migrated lockfile — v11 hard-fails in CI on an incompatible lockfile,
      so this is where that shows up if anywhere.

## Anchors

- `package.json:31-35` — the `pnpm.onlyBuiltDependencies: ["agnix"]` block. Dead under v11; the one
  entry becomes `allowBuilds: { agnix: true }`.
- `package.json:6` — `packageManager: "pnpm@10.14.0"`, the pin CI resolves through.
- `node_modules/.pnpm/` — 7 packages, exactly one with a build script (`agnix@0.33.2`,
  `postinstall: node install.js`). Measured, not assumed: the blast radius of `strictDepBuilds: true`
  is that single entry.
- `.github/workflows/agnix-lint.yaml:19-27` and `format-check.yaml:19-27` — identical setup;
  `pnpm/action-setup@v4` with `run_install: false` and no `version:` input, so it reads
  `packageManager`. `setup-node` runs _before_ it, which is also why neither has `cache: pnpm`.
- `.husky/pre-commit` — three `pnpm` invocations (`pnpm exec lint-staged`, `pnpm exec agnix --fix`,
  `pnpm validate:manifests`); the real local gate, and the first thing to break if the pin misbehaves.
- `scripts/lint.sh:3` — calls `node_modules/.bin/agnix` by relative path, not through pnpm. It is
  the reason task 1's green condition is stated as "`agnix` is executable in `node_modules/.bin/`"
  rather than "install exited 0".
- `skills/dw-doctor/scripts/doctor.sh:99-113` — the pnpm check whose `corepack enable` fix hint
  (`:106`, `:111`) becomes wrong advice under v11. Not touched here; it is task D3 of the next change.

## Notes

Four things the research could not settle from pnpm's own docs. All four are answered below, each
measured on this repo under pnpm 11.18.0 rather than read off a page. These are the input to
`pnpm-v11-payload`.

**1. Does `lockfileVersion` change in v11? — No, and that is the trap.** It stays `'9.0'`, the same
string v10 wrote. The _contents_ are not compatible though: v11 adds a `---` document marker, drops
the `settings:` block (`autoInstallPeers`, `excludeLinksFromLockfile`) and adds two new per-importer
keys, `configDependencies: {}` and `packageManagerDependencies:` (which records the resolved pnpm
version — 11.18.0 here — once `devEngines.packageManager` exists). So the version field cannot be
used to detect a v11 lockfile; `packageManagerDependencies` or the `---` marker can.

**2. Does `pnpm/action-setup` read `devEngines.packageManager`? — Yes, but not at the SHA we pin.**
On `main` it reads it and gives it _priority_ over `packageManager` (`src/install-pnpm/run.ts:157-161`,
"devEngines.packageManager takes priority over packageManager, matching pnpm's getWantedPackageManager
logic"). The SHA both workflows pin — `b906aff`, tagged v4 — contains no `devEngines` string at all;
it reads `packageManager` and nothing else. **So `packageManager` is load-bearing in CI today** and
dropping it would break both workflows until the action pin is bumped past v4. The change's decision
to keep it is confirmed, for a sharper reason than the one it was made on.

**3. Does pnpm warn when it ignores `package.json#pnpm`? — It warns, but only about keys it
recognises.** Injecting `pnpm: { onlyBuiltDependencies: [], minimumReleaseAge: 1 }` produced exactly
one line:

```
[WARN] The "pnpm" field in package.json is no longer read by pnpm. The following keys were
ignored: "pnpm.onlyBuiltDependencies". See https://pnpm.io/settings for the new home of each setting.
```

`pnpm.minimumReleaseAge` was ignored just as completely — `pnpm config get minimumReleaseAge` still
returned `10080` — and was **not named**. Both settings were inert (`agnix` built anyway despite
`onlyBuiltDependencies: []`). So the warning enumerates only keys on pnpm's known-relocation list; a
`pnpm` block holding anything else is dropped in total silence. **`dw-doctor` check D1 is therefore
necessary, not merely useful** — and it must flag the presence of the `pnpm` block itself, not trust
pnpm's warning to enumerate what is being lost.

**4. Does `minimumReleaseAgeStrict: true` actually hard-fail? — Yes, and the fallback path is the
one to understand.** Three measurements against `rollup`, whose 4.62.4 was 1.08 days old:

- `pnpm add -D rollup` (strict `true`) **succeeded** and installed `4.62.2`, printing
  `(4.62.4 is available)`. Strict never fired because a version _older_ than the cutoff existed. The
  cooldown still did its job — silently, by downgrading.
- `pnpm add -D rollup@4.62.4` (strict `true`) **refused**, listing every offending package with its
  publish time and the computed cutoff, and left `package.json` untouched. No satisfying version
  exists for an exact fresh pin, so this is the path where strict decides.
- The same command with strict `false` **installed 4.62.4**, writing `"rollup": "4.62.4"` into
  `devDependencies`.

The protection is real and the setting name is honest. Worth carrying into the payload: the common
case is a _silent downgrade_, not a failure, so "install succeeded" is not evidence the cooldown is
off.

### From task 1 — running the codemod

- **The codemod needs three flags to run unattended.** Bare `pnpm dlx codemod run pnpm-v10-to-v11`
  dies with "The input device is not a TTY" — it asks to approve its own shell step. The working
  invocation is `--no-interactive --allow-fs --allow-child-process`. The payload change should ship
  that spelling, not the one on pnpm's migration page.
- **Its `--dry-run` is useless here — it reports "Would modify 0 files" and then the real run
  modifies two.** The work happens in a spawned `node -e`, which the dry-run cannot see. So "review
  the diff by hand" has to mean _run it on a clean tree and read `git diff`_, which is what happened.
- **It did more than the task assumed**: it bumped `packageManager` to `pnpm@11.18.0` itself, on top
  of moving `onlyBuiltDependencies` → `allowBuilds` in a new `pnpm-workspace.yaml`. Only the
  supply-chain keys and `devEngines` were hand-written.
- **`packageManager` and `devEngines.packageManager` must state the _same_ version.** A range in
  `devEngines` (`>=11.0.0 <12.0.0`) against the exact pin in `packageManager` makes every install
  warn `"packageManager" ... will be ignored`. Both are now pinned to `11.18.0` — two fields to bump
  together, which is the same paired-version discipline `marketplace.json` / `plugin.json` already
  carry here. This is a real amendment to the "keep `packageManager`" decision: keeping it is still
  right, but it is not free.
- **`pnpm ci` prints `✓ Lockfile passes supply-chain policies`** — the settings are not just parsed,
  they are enforced at install time and say so.

### From task 2 — `devEngines.packageManager` breaks `pnpm view` / `pnpm info`

Found while trying to answer question 4, because the tool used to look up publish dates stopped
working. `pnpm view` and `pnpm info` delegate to npm, and **npm validates `devEngines.packageManager`
and refuses to run when the required name is not `npm`**:

```
npm error EBADDEVENGINES Invalid name "pnpm" does not match "npm" for "packageManager"
npm error EBADDEVENGINES   required: { name: 'pnpm', version: '11.18.0', onFail: 'download' }
```

Measured, by sweeping `onFail` and by testing each subcommand:

| `onFail`   | `pnpm view` / `pnpm info` | plain `npm` blocked? |
| ---------- | ------------------------- | -------------------- |
| `download` | broken                    | yes                  |
| `error`    | broken                    | yes                  |
| `warn`     | broken                    | yes                  |
| `ignore`   | **works**                 | **no**               |

`outdated`, `audit`, `why`, `licenses list` and `list` are native and unaffected — the blast radius is
exactly the two npm-delegated commands. `onFail: ignore` still leaves pnpm self-managing its own
version (pinning both fields to `11.17.0` made `pnpm --version` report `11.17.0`), so `ignore` costs
nothing on that front.

The trade is therefore narrow and real: **`error` gives the `pnpm/only-allow` replacement the
decisions list gestures at** (npm refuses to operate in the repo) **at the price of `pnpm view` and
`pnpm info`**; `ignore` keeps every pnpm command working but drops the npm guard. Note the repo
already blocks npm for the _agent_ via `block-non-pnpm.sh`; the guard only adds cover for a human
typing `npm install` by hand. **Open — needs a decision before this change lands.**

### From task 3 — `pnpm lint` is not a reliable local check in this session

Both workflows now run `pnpm ci` (which is `pnpm clean` + `pnpm install --frozen-lockfile`, so on a
cold runner it is exactly what they did before, plus the supply-chain verification line). Simulating
CI locally from a clean tree: `pnpm ci` ✅, `pnpm format` ✅, lint ✅ (0 errors, 8 warnings).

The trap: **`pnpm lint` fails locally for a reason that has nothing to do with the repo.** The `rtk`
proxy hook rewrites it to `rtk lint`, which is an _ESLint_ wrapper, and this repo has no eslint — so
it dies with `Command "eslint" not found` while `scripts/lint.sh` is perfectly green. `pnpm format`
is untouched because rtk has no `format` command. CI has no rtk, so this is local-only noise. When
verifying lint here, run `bash scripts/lint.sh` (or `node_modules/.bin/agnix .`) directly. Worth
carrying to `## Gotchas` at land time — a green repo that looks broken is expensive.

CI confirmation itself is still pending: it needs the branch pushed, which has not happened.
