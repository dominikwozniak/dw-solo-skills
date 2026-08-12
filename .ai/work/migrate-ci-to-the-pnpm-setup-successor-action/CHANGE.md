---
change: migrate-ci-to-the-pnpm-setup-successor-action
branch: migrate-ci-to-the-pnpm-setup-successor-action
created: 2026-08-12
status: building # shaping | building | landed
---

# Change — one action sets up CI, and `devEngines` holds both versions it reads

## Goal

The three Node workflows each open with a single `pnpm/setup@v2` step: no `actions/setup-node`, no
`pnpm/action-setup`, no `pnpm ci`. Both versions that step needs come from `package.json#devEngines` —
`packageManager` (already there) and `runtime` (new) — so `.nvmrc` loses its last reader and goes.
Known when: `git grep -n "setup-node\|action-setup\|nvmrc"` returns nothing under `.github/`, `.nvmrc`
is deleted, `pnpm eval:routing` and `pnpm lint` still pass locally, the full gate is green, and all
three workflows are green **on the PR** (a feature-branch push fires nothing here — no
`workflow_dispatch`). This is where the Node-pinning question `pnpm-v11-migration` parked and
`pnpm-pin-in-one-field` deliberately closed as "no" finally gets answered "yes".

**Amended mid-build, on request:** npm leaves CI as well. `validate-plugin-manifests` — the fourth
workflow, and the only one that never had a Node setup — installs the Claude Code CLI with
`npm install -g` while this repo blocks npm from the agent with `block-non-pnpm.sh`. Also known when
every `npm` hit under `.github/` is the tail of a `pnpm` one, and that workflow is green on the same
PR.

## Decisions

- **`devEngines.runtime` becomes the Node pin, and the archived "no" is not being re-litigated — its
  premise is gone.** `pnpm-pin-in-one-field` rejected the field because `setup-node` read `.nvmrc` and
  a third copy would have no reader (`.ai/archive/pnpm-pin-in-one-field/CHANGE.md:38-39`). Under
  `pnpm/setup@v2` the field _is_ the reader and `.nvmrc` is the copy with none. That call lives only in
  an archived `CHANGE.md`, not in `docs/decisions/`, so nothing needs a `superseded-by:` record.
- **Exact `24.16.0` with `onFail: "download"`, mirroring `packageManager`.** Exact because that is
  what `node-version-file: .nvmrc` pins today and a range would quietly un-pin CI. `"download"`
  because the alternatives are all worse here — **measured**: this machine runs Node **24.19.0**
  against a `.nvmrc` of 24.16.0, so the default `"error"` would refuse every pnpm command in the repo,
  and `"warn"` would print on all of them. `"download"` has pnpm fetch 24.16.0 and run scripts on it,
  which is exactly the deal `packageManager.onFail: "download"` already struck for pnpm itself — one
  field, one version, same in CI and locally. The archive named this download as a _cost_; it is now
  the point.
- **`.nvmrc` is deleted, not kept as a version-manager courtesy.** Keeping it recreates the
  no-reader duplicate this change exists to remove, and nothing in the repo would notice the two
  drifting apart — they already have. Asked and confirmed at shape time, with the cost accepted:
  `nvm use` / `fnm use` stop resolving a version in this repo. Do not reopen it mid-build.
- **The action's own `pnpm install` replaces `pnpm ci`, and losing `pnpm clean` costs nothing.**
  `pnpm ci` is `pnpm clean` + `pnpm install --frozen-lockfile`; `CI=true` already makes install frozen,
  and there is no `node_modules` to clean on a fresh runner.
- **`install:` stays at its default `true` in all three, including `evals-routing`** — whose comment
  claiming the eval needs no install is **already false**. Measured in run `31635610235`, where
  `pnpm eval:routing` triggered pnpm 11's `runDepsStatusCheck`, which ran a full `pnpm install` (and
  died in `agnix`'s postinstall) before the script ever started. The action installing explicitly is
  the honest version of what already happens.
- **Pin v2.0.2 by SHA despite the action being three days old.** Verified:
  `84cb39b217b10273981911c288cd62326dc7c6d2` is the commit both `v2.0.2` and the moving `v2` tag point
  at. `minimumReleaseAge: 10080` is a pnpm _resolution_ policy over npm packages and does not reach a
  GitHub Action; the threat it answers — a fresh release auto-resolving into the tree — cannot happen
  behind an immutable SHA that was read by hand. Reverting is three one-line diffs.
- **No version bump.** Nothing this change touches is shipped payload: `.github/`, `package.json`,
  `.nvmrc`, `evals/`, `AGENTS.md`. `templates/` and `scripts/runtime/` are untouched, so neither
  plugin moves — the one case where the `## Gotchas` bump rule does not fire.
- **`dw-doctor` is out of scope.** It names `.nvmrc` only inside two hint strings and one SKILL.md
  bullet, all still true advice for a consumer repo that has the file. Teaching it to read
  `devEngines.runtime` is a real follow-up, parked, not part of this request.

## Tasks

- [x] 1. **One step, one pin.** Atomic on purpose: the workflow rewrite alone would leave CI on the
      runner's default Node with nothing pinning it. In all three of `agnix-lint.yaml`,
      `format-check.yaml`, `evals-routing.yaml`, replace lines 20–26 (`setup-node`, `action-setup`,
      `run_install: false`, and the `pnpm ci` step / the stale no-install comment) with a single
      `- uses: pnpm/setup@84cb39b217b10273981911c288cd62326dc7c6d2 # v2.0.2` — **no `with:` block at
      all**, since the action reads both versions from `package.json`. Add
      `runtime: { name: node, version: 24.16.0, onFail: download }` to `devEngines`
      (`package.json:28-34`) and `git rm .nvmrc`. Green when `pnpm install`, `pnpm lint`,
      `pnpm format` and `pnpm eval:routing` all still pass locally — and record in `## Notes` what
      pnpm actually did with the runtime entry (a first-run Node download is expected; whether
      `pnpm eval:routing` then runs on 24.16.0 while a bare `node --version` still says 24.19.0 is
      worth stating, because it is the surprise a future session hits).
- [x] 2. **The two prose readers that name what just left.** `evals/routing.ts:20` — "this repo pins
      24 in .nvmrc" becomes `devEngines.runtime`; keep the `>=22.18` type-stripping constraint, which
      is the reason the sentence exists. `AGENTS.md:284-286` — clause (3) of the pnpm sub-bullet
      ("CI reads the field only from `pnpm/action-setup` v6 up") names an action the repo no longer
      uses; replace it with what is true after task 1: CI reads `devEngines` through `pnpm/setup@v2`,
      which needs no inputs and installs the runtime too. Clauses (1) and (2) stay verbatim — they are
      about the local bootstrap and `onFail`, both still exactly right. Sub-bullet edit only, so the
      12/12 entry count does not move.
- [ ] 3. **The gate, then the PR.** Run the full gate, push, open the PR, and read all four rewritten
      workflows there — the only place they run. **The npm probe this task originally demanded is
      gone, twice over.** It was scoped wrong: the manifests workflow's `paths:` filter did not match
      this diff, so no dry-run here would have gated anything. And task 4 then removed the premise
      entirely — with npm out of that workflow, a second `devEngines` entry has no npm left to
      refuse it. Do this task **last**, after 4, or the probe question comes back.
- [x] 4. **npm leaves CI too.** Added mid-build on request, and it lands here rather than in the
      backlog for one reason that reverses the objection to bundling it: the workflow's `paths:`
      filter includes **its own path**, so editing it triggers it on this PR — the change is
      verifiable where the manifests-only filter would have hidden it. In
      `validate-plugin-manifests.yaml`, add `pnpm/setup@v2` with `install: false` (this job wants
      pnpm and Node, not the dev tree) and swap `npm install -g @anthropic-ai/claude-code@2.1.179`
      for `pnpm add -g --allow-build=@anthropic-ai/claude-code @anthropic-ai/claude-code@2.1.179`.
      **`--allow-build` is not optional**: the package's `postinstall: node install.cjs` would be
      denied by v11's `strictDepBuilds` and **fail** the install rather than warn. The flag keeps
      `pnpm-workspace.yaml`'s `allowBuilds` a one-entry allowlist over the dev tree, which is what
      its "this single entry is the whole blast radius" comment claims. Version stays `2.1.179` —
      published 2026-06-16, so `minimumReleaseAge: 10080` is satisfied and a bump would confound two
      variables. Green when the workflow passes on the PR; nothing local exercises it.

      Two things it settled on the way. **`block-non-pnpm.sh` blocks reading about npm, not just
              running it** — `git grep -n "npm install" -- .github/`, the verification this task's own goal
              asks for, is refused because the pattern contains the string. Build it (`git grep "npm"`) the
              way the `.env` trap in `## Gotchas` already documents. And the pinned version is safely old:
              `pnpm view @anthropic-ai/claude-code time` dates 2.1.179 to **2026-06-16**, so the seven-day
              cooldown is not in play; a fresher pin would need `minimumReleaseAgeExclude` and should be its
              own change.

## Anchors

- `.github/workflows/agnix-lint.yaml:19-27`, `format-check.yaml:19-27`, `evals-routing.yaml:19-28` —
  identical five-step preambles bar the last `run:`. `:20-22` is `setup-node` +
  `node-version-file: .nvmrc`, `:23-25` the `action-setup` v6.0.10 SHA with `run_install: false`,
  `:26` the `pnpm ci` step — except in `evals-routing`, where `:26-27` is the two-line comment
  asserting no install is needed.
- `package.json:24-34` — `engines` (`node >=24.16.0`, `pnpm >=11.0.0 <12.0.0`, the floors
  `doctor.sh` checks) then the `devEngines.packageManager` block the new `runtime` sibling joins.
- `.nvmrc` — one line, `24.16.0`; three `node-version-file:` references and two `dw-doctor` hint
  strings are everything that names it.
- `AGENTS.md:267-286` — `**pnpm here is three traps deep…**`. `:277-286` is the one-field sub-bullet;
  `:284-286` is clause (3), the only false half after this change.
- `evals/routing.ts:20` — the `.nvmrc` mention inside the no-build-step comment.
- `.github/workflows/validate-plugin-manifests.yaml:32-34` — the only npm in this repo, the step
  task 4 replaces. It has no Node setup at all today: it uses whatever the runner ships, because
  `scripts/validate-manifests.sh:13` needs `claude plugin validate` on `PATH` and nothing else.
  `:5-8` is the `paths:` filter that includes the workflow's own path — the reason task 4 is
  verifiable on this PR.
- `pnpm-workspace.yaml:15-20` — `minimumReleaseAge: 10080` / `minimumReleaseAgeStrict: true`, the
  seven-day cooldown the freshness decision above argues does not reach an action SHA.
- `.ai/archive/pnpm-pin-in-one-field/CHANGE.md:29-32,38-39` — the two decisions this change reverses,
  and `:104-109`, the left-out paragraph that became the backlog entry seeding this file.

## Notes

**Ordering against the two changes already shaped.** `setup-lives-in-tracked-agents-md` (task 7) and
`loop-prose-disagrees-with-the-bodies`' successor both rewrite `AGENTS.md`, and both bump plugin
versions; this one edits `AGENTS.md:284-286` only and bumps nothing, so it can land in any order —
but re-read `AGENTS.md` at build time rather than trusting the line numbers above, and re-check them
after any rebase. The squash-merge trap in `## Gotchas` applies: `main` moving under this branch
resurrects merged commits.

**CI's last two runs on `main` are red for an unrelated reason.** `agnix-lint` and `evals-routing`
both failed at `agnix`'s `postinstall` with `Failed to install agnix: socket hang up` — a flake
downloading the prebuilt binary, on the commit that landed `pnpm-pin-in-one-field`. Nothing to fix
here, but do not read a green/red flip on this PR as evidence about the migration until that step is
seen to pass.

### From task 1 — the Node pin is a lockfile entry, not just a field

**`devEngines.runtime` makes Node a locked dependency, and nobody predicted the lockfile diff.**
`pnpm install` printed `+ node 24.16.0` and wrote **126 lines** into `pnpm-lock.yaml`: the importer
gains `node: specifier: runtime:24.16.0`, and a `node@runtime:24.16.0` package carries a
`type: variations` block with a SHA-256 integrity hash per platform — eleven of them, aix through
win32. Two consequences worth more than the diff: the runtime download is **checksummed and
cross-platform**, not a naked fetch; and **bumping the Node version is now a two-file change**, the
field plus a regenerated lockfile, because CI installs `--frozen-lockfile` and would refuse a field
the lock disagrees with. Editing `24.16.0` alone will fail CI, exactly as editing a dependency
version by hand would.

**The pin governs pnpm, not your shell — measured.** `node --version` → **24.19.0**;
`pnpm exec node --version` → **24.16.0**; `pnpm --version` → 11.18.0. So every `pnpm <script>` runs
on the pinned runtime while a bare `node` keeps the system one. That is the surprise a future session
hits: `node evals/routing.ts` typed by hand and `pnpm eval:routing` are no longer the same Node, and
only the second one is the version CI uses.

**Green locally, all four:** `pnpm install`, `bash scripts/lint.sh` (0 errors, 93 pre-existing
warnings), `pnpm format`, `pnpm eval:routing` (rank-1 67%, at the floor as before). `pnpm lint` was
run as `bash scripts/lint.sh` on purpose — the rtk hijack in `## Gotchas`.

**One thing only the PR can answer.** In CI the action installs the runtime itself
(`pnpm runtime set node 24.16.0 -g`) and _then_ runs `pnpm install`, which now also sees a runtime in
the lockfile. Whether that is a no-op or a second download of the same Node is not observable from
here; read the `pnpm/setup` step's log rather than assuming.

### From task 2 — the sub-bullet's title had to move too, and the lockfile trap is already promoted

Two departures from the task as written, both deliberate. The sub-bullet's **heading** said "The pnpm
version is pinned in exactly one field"; with a runtime entry beside it that undercounts, so it now
reads "Both versions this repo pins live in one field". Clauses (1) and (2) are untouched as
specified. And clause (3) **already carries the lockfile-coupling trap** from task 1 — a Node bump
needs the field plus a regenerated lockfile — because that is the sentence a session editing
`24.16.0` needs in the file that loads unasked. `dw-land` should treat that promotion as done rather
than adding a second copy. Entry count still 12/12, `.ai/backlog/` 6/8.

**Left out, for `dw-land` to park:**

- **`cache: true` on the new step.** The repo caches nothing today; now that one action owns install,
  the pnpm store cache is a one-line input away. Deliberately not bundled — it changes CI timing and
  wants its own green/red comparison.
- **`dw-doctor` reads `devEngines.runtime` as a Node pin**, the mirror of what
  `pnpm-pin-in-one-field` task 2 did for `packageManager`, plus dropping `.nvmrc` from the two hint
  strings at `skills/dw-doctor/scripts/doctor.sh:89,95` and the bullet at `SKILL.md:31`. Ships alone,
  bumps `dw-solo-setup`, and is the reason this change needs no bump at all.
