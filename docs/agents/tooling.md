# Tooling — pnpm, Node, lint, format, self-tests and the guardrail hooks

The commands themselves are in the root's `## Commands`; the gate is the `scripts` block of
`package.json`. This file is how that tooling misbehaves, and what the misbehaviour looks like when
it is not what it appears to be.

## The hooks

Wired in tracked `.claude/settings.json`, with the scripts in `.claude/hooks/` — so a fresh clone and
a `git worktree` checkout get the same guardrails. They are also vendored copies of what this repo
ships in `templates/hooks/`; `scripts/tests/hooks-in-sync.test.sh` pins the two together.

| hook                          | fires on                                          |
| ----------------------------- | ------------------------------------------------- |
| `block-dangerous-commands.sh` | PreToolUse(Bash) — destructive shell              |
| `block-non-pnpm.sh`           | PreToolUse(Bash) — npm/yarn invocations           |
| `block-env-access.sh`         | PreToolUse(Read/Edit/Write/Grep/Bash) — `.env`    |
| `lint-on-edit.sh`             | PostToolUse(Write/Edit) — the root's Lint command |
| `link-local-memory.sh`        | SessionStart — worktree local-memory symlink      |

Every one opens with `command -v jq >/dev/null || exit 0` — **without `jq` on `PATH` they all
silently no-op**, and nothing says so. `/dw-doctor` is the check. `templates/hooks/` ships a sixth,
`typecheck-on-stop.sh`, deliberately not wired here — this repo has no typecheck.

`lint-on-edit.sh` is no longer inert: `evals/*.ts` matches its `.ts/.tsx/.js/.jsx/.mjs/.cjs` filter,
so every edit there runs the lint command over the whole tree (`scripts/lint.sh` ignores the file
argument it is handed). Slow, and the OOM below applies. `.husky/pre-commit` is still the real gate.

## Gotchas

- **A new check needs a new `paths:` entry, or it never runs on the commit shape it exists to
  catch.** Every workflow here is path-filtered, so a check added to an existing script inherits that
  script's triggers — which are the paths the _old_ checks cared about. `validate-docs.sh`'s
  agent-docs check grades `AGENTS.md`, and `validate-docs.yaml` did not list `AGENTS.md`: a commit
  that pushed the root over its budget — the exact regression the check exists for — matched no
  filter and CI stayed green with nothing run. It has bitten twice; `validate-artifacts.yaml` carries
  a comment about the first. When you add a check, add every path it _reads_ to both the
  `pull_request` and `push` lists, not just the script you edited.
- **pnpm here is three traps deep, and every one of them looks like a broken repo.**
  - **The lint script can be hijacked before it reaches `scripts/lint.sh`.** With the `rtk` proxy
    hook active it is rewritten to `rtk lint` — an _ESLint_ wrapper — and dies with
    `Command "eslint" not found` while the repo is perfectly green. The format script is unaffected
    (rtk has no `format` command), which makes it look like a real lint failure. Verify with
    `bash scripts/lint.sh` or `node_modules/.bin/agnix .`. CI has no rtk.
  - **It also OOMs locally.** `agnix` over the whole tree can die with "terminated abnormally" under
    memory pressure; `scripts/lint.sh` turns that into a hard error rather than a silent pass.
    Re-run it, or lint only the staged paths the way `.husky/pre-commit` does. CI has the headroom.
  - **Both versions this repo pins live in one field, and three things have to line up for it to
    hold.** `devEngines.packageManager` states pnpm `11.18.0` and `devEngines.runtime` Node
    `24.16.0`; there is no `packageManager` field and no `.nvmrc` any more. (1) The **bootstrap on
    `PATH` must be pnpm 11** — v10 cannot read `devEngines` at all and would run this repo with v11
    settings half-applied, so `engines.pnpm` is the floor that turns that into a loud
    `ERR_PNPM_UNSUPPORTED_ENGINE` instead. (2) **`onFail` governs every command now**, not just
    installs: `"error"` refuses unless your pnpm matches the pin _exactly_ (which no `brew upgrade`
    survives), `"download"` fetches the pinned version and runs it — the behaviour the deleted
    `packageManager` field used to provide. (3) **CI reads both fields through one inputless
    `pnpm/setup@v2` step**, which installs pnpm, installs Node, and runs the install — so a workflow
    needs no `with:` block. The one input that would not merely restate the manifest, `cache: true`,
    was **measured on #28 and reverted: a hit is ~1.2s slower than no cache at all** (37.1s baseline →
    38.3s warm on `agnix lint`), and the reason is structural rather than a matter of tree size — the
    action installs the runtime _before_ it restores, so the Node tarball is most of a 45MB entry that
    is uploaded and restored on every hit and then never used. The store cache also cannot touch the
    ~30s that actually dominates these jobs, which is `agnix`'s postinstall fetching its prebuilt
    binary. Don't re-add it without re-measuring; if CI time is the real complaint, that postinstall
    is the target. (A related non-trap, since the key is `pnpm-cache-<os>-<arch>-<lockfile hash>` with
    no job component: three jobs racing it is safe — the losers warn, the winner saves.) The Node half
    carries a tail:
    `devEngines.runtime` makes Node a **locked dependency** (a `node@runtime:…` entry with a hash per
    platform), so bumping it is the field **plus** a regenerated `pnpm-lock.yaml` — edit the version
    alone and CI's frozen install refuses it. Locally the pin reaches scripts run through pnpm only:
    `pnpm exec node --version` is the pinned Node, a bare `node --version` is still whatever your
    shell has.
- **The lint hooks disagree with the gate, in more than one direction.**
  - **`.lintstagedrc.json`'s glob and `prettier --check .` disagree by construction.** Prettier checks
    every file it understands; lint-staged only formats the extensions listed, so a new file type is
    unformatted at commit and rejected at push — which reads as a lint failure in a green repo.
    Adding `evals/*.ts` needed `ts` in that glob. Add the extension with the first file of a kind.
  - **Prettier is not idempotent on a paragraph nested inside a task-list item**, so `--write` and
    `--check` can loop forever disagreeing — which the format check fails and `.husky/pre-commit` does
    not, because lint-staged writes and re-stages, committing the very content the push gate then
    refuses. It bites in `.ai/work/<slug>/CHANGE.md`, where writing findings under a `- [x] N.` box is
    the natural thing to do. Keep task bodies to one paragraph; findings belong in `## Notes`.
  - **`evals/*.ts` must never get the executable bit.** `lint-on-edit.sh` `eval`s its resolved lint
    command against the file path; the pre-fix version resolved to a bare space and executed the
    target. Fixed and pinned by `scripts/tests/lint-on-edit.test.sh`.
- **`block-env-access.sh` inspects the whole Bash command, and now stops reading at a `<<`.** Commit
  messages are fine either way — quoted prose passes, and heredoc bodies are dropped before
  tokenizing, so `git commit -F - <<'MSG'` no longer blocks. But that drop is unconditional: a
  literal `<<` anywhere in a command starts body mode and **nothing below it is scanned**. The other
  half is that a bare `.env` token still blocks anywhere, so a probe of the hook cannot be typed
  literally — build the string (`D=$(printf ".%s" env)`) or your own test call never runs. **The same
  blindness sits in `block-non-pnpm.sh`**, which cannot tell a mention from an invocation either: a
  `git grep "npm install" -- .github/` is refused for containing the string it is searching _for_.
  Grep the shorter token, or build it. **`block-dangerous-commands.sh` is the third**, and the worst
  to probe by hand: its patterns anchor after `;`, `&` and `|`, so a one-liner looping over test cases
  contains `; git restore .` by construction and blocks itself. Put the cases in a file under the
  scratchpad and run that — which is what `scripts/tests/` already does, and the reason to reach for it
  first.
- **When you change one of these patterns, diff the old hook against the new one instead of reading
  the regex.** `git show origin/main:templates/hooks/<hook>.sh > /tmp/old.sh`, run the same probe
  through both, and compare exit codes: the answer you need is _which commands changed verdict_, and
  nothing else. Anchoring the bare `.` was meant to be a one-row delta and was — but the same
  comparison is what exposed the two holes that had been there all along (a quoted `"."`, and
  `git -C <path>`), because those rows were identically wrong on both sides. A loosened guardrail is
  invisible to a self-test that never had the case.
- **A self-test can be green for a reason that has nothing to do with the contract.** Two shapes, one
  root cause: the assertion never reaches the code it names.
  - **A fixture that is the live repo is a content gate under a unit test's name.** The case that
    taught this is gone with its script (`check-decisions.test.sh`), and the shape outlives it: a
    `no-arg` case ran the script against this repo and demanded silence — gating `docs/decisions/`
    from under the heading `arguments:`, and stricter than the contract it was testing. Use a
    synthetic fixture; live-content checks belong in `validate-artifacts.sh`.
  - **A case placed outside the region the code scans, or asserting the bug as the contract.** Both
    shipped here and an outside reviewer found them, not the suite: a router row appended after
    `## Solo lane` passed only because the check grepped the whole file, and a `value-matches-hook`
    case asserted that explanatory backticks beat the `none` sentinel — pinning the defect as
    intended behaviour. When a test passes first try, prove it can fail: break the code, or move the
    fixture line, and watch it go red.
