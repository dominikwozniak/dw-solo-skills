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
- [ ] 2. Answer the four open questions under `## Notes` and write the results there — they are the
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

Four things the research could not settle from pnpm's own docs. Task 2 answers them here.

1. **Does `lockfileVersion` change in v11?** Docs are silent; the `'9.0'` value seen elsewhere comes
   from a third-party issue thread. Check the regenerated lockfile directly.
2. **Does `pnpm/action-setup` read `devEngines.packageManager`?** If it does, `packageManager` is
   redundant and can be dropped later.
3. **Does pnpm warn when it ignores `package.json#pnpm`, or is it silent?** Undocumented. If silent,
   `dw-doctor` check D1 goes from useful to necessary — that is the whole "config present, does
   nothing" failure class the doctor exists for.
4. **Does `minimumReleaseAgeStrict: true` actually hard-fail?** Try adding a package published in the
   last day; it must fail. If it installs, the protection is theatre and the setting name is a lie.

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
