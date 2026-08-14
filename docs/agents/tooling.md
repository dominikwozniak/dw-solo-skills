# Tooling — pnpm, Node, lint, format, self-tests and the guardrail hooks

The commands themselves are in the root's `## Commands`; the gate is the `scripts` block of
`package.json`. This file is how that tooling misbehaves, and what the misbehaviour looks like when
it is not what it appears to be.

## `pnpm validate:artifacts` — three passes

`scripts/validate-artifacts.sh` runs every self-test under `scripts/tests/` (pass 1), then two
governors over the durable layer: the cap on `.ai/backlog/` (pass 2) and the ratchet over
`skills/*/SKILL.md` (pass 3, `scripts/check-skill-corpus.mjs` against
`scripts/skill-corpus.baseline.json`).

Pass 3 exists because the corpus grew 19% in three days with nothing looking. It sets **no
threshold** — the baseline records what the corpus is, and the check fails only on an increase, so
growth stays legal and costs one `node scripts/check-skill-corpus.mjs --update-baseline` in the same
commit. Adding a skill therefore always touches two files. It counts words rather than bytes or
lines because prettier reflows Markdown at 100 columns, which moves both of those on a pure
reformat — ASCII whitespace only, so the count matches `cat skills/*/SKILL.md | wc -w` under the
`LC_ALL=C` the gate exports.

A baseline it cannot trust exits **2**, never a silent pass: missing, unparseable, wrong-shaped, or
internally inconsistent (`words` disagreeing with the sum of `perSkill`). The one exception is being
asked to create one — `--update-baseline` on a missing file bootstraps it. Bad flag spellings exit 2
too, because the two that matter both look like success: `--update-baselines` would run a plain check
and write nothing, and `--root ""` resolves relative to the cwd, so from the repo root it measures the
live tree the fixture was meant to stand in for.

A new self-test needs no wiring: pass 1 globs `scripts/tests/*.test.sh`.

## The hooks

Wired in tracked `.claude/settings.json`, with the scripts in `.claude/hooks/` — so a fresh clone and
a `git worktree` checkout get the same guardrails. They are also vendored copies of what this repo
ships in `templates/hooks/`; `scripts/tests/hooks-in-sync.test.sh` pins the two together.

| hook                          | fires on                                                           |
| ----------------------------- | ------------------------------------------------------------------ |
| `block-dangerous-commands.sh` | PreToolUse(Bash) — destructive shell                               |
| `block-non-pnpm.sh`           | PreToolUse(Bash) — npm/yarn/bun invocations                        |
| `enforce-commit-hygiene.sh`   | PreToolUse(Bash) — commit subject, trailer, backtick, `git add -A` |
| `credential-leak-guard.sh`    | PreToolUse(Bash) — credential stores, env hunting, exfil           |
| `block-env-access.sh`         | PreToolUse(Read/Edit/Write/Grep/Bash) — `.env`                     |
| `guard-plugin-canon.sh`       | PreToolUse(Edit/Write) — an edit aimed through a plugin symlink    |
| `lint-on-edit.sh`             | PostToolUse(Write/Edit) — the root's Lint command                  |
| `large-file-guard.sh`         | PostToolUse(Write) — an oversized write, after the fact            |

Every one opens with `command -v jq >/dev/null || exit 0` — **without `jq` on `PATH` they all
silently no-op**, and nothing says so. `/dw-doctor` is the check. `templates/hooks/` ships a ninth,
`typecheck-on-stop.sh`, deliberately not wired here — this repo has no typecheck.

`lint-on-edit.sh` is no longer inert: `evals/*.ts` matches its `.ts/.tsx/.js/.jsx/.mjs/.cjs` filter,
so every edit there runs the lint command over the whole tree (`scripts/lint.sh` ignores the file
argument it is handed). Slow, and the OOM below applies. `.husky/pre-commit` is still the real gate.

## The four declared bullets

Four values under the root's `## Solo lane` are **grep-read** rather than inferred, which is why they
live there and nowhere else: `- **Lint command**:`, `- **Typecheck command**:`, `- **Commit
pattern**:` and `- **Commit trailer**:`. Every one resolves the same way, in four separate scripts
that deliberately share the extraction shape — one bug fixed once:

1. `AGENTS.md`, the tracked file the scaffold writes.
2. `CLAUDE.local.md`, legacy only — a repo scaffolded before decision 0007 still keeps its own there.
   `CLAUDE.md` is absent from the chain on purpose: it is a symlink to `AGENTS.md`, so reading it is
   reading step 1 twice.
3. The script's own default. For lint and typecheck that is a probe (eslint / `tsc`); for the commit
   pattern it is Conventional Commits, and for the trailer it is `none` — a requirement nobody
   declared must not start failing commits in a repo that never asked for one.

The value is **the first backticked span** on the line, and a standalone `none` **disables the check
and stops the chain**. `none` is tested on the raw remainder _before_ any backtick extraction, because
it has to win over explanatory prose: `none — see `scripts/lint.sh`` must skip, and the version that
picked the backticks first ran that script on every edit. An unrendered `{{…}}` placeholder is not a
declaration either, and each script names the tokens it rejects.

## Gotchas

- **agnix warnings do not fail the build, and one of them is true right now.** `scripts/lint.sh`
  exits **0** with 51 warnings; only `Found N errors` gates. So a rule firing is not a rule
  enforced — `CLAUDE.md:1:0 warning: File exceeds recommended token limit (~1752 tokens, limit is
1500)` has been true and ignored the whole time `pnpm validate:docs` has been calling the same file
  green at 117/120 lines. Two checkers, two units, one of them advisory, and the advisory one looks
  identical to the binding one in the output. Before citing agnix as the thing that would have caught
  something, check whether it gates: `severity` sets a reporting floor, and `[[overrides]]` can only
  _disable_ a rule for a glob, never turn its threshold down. That is why the corpus ratchet is its
  own checker rather than a tuned `AS-012`.
- **A new check needs a new `paths:` entry, or it never runs on the commit shape it exists to
  catch.** Every workflow here is path-filtered, so a check added to an existing script inherits that
  script's triggers — which are the paths the _old_ checks cared about. `validate-docs.sh`'s
  agent-docs check grades `AGENTS.md`, and `validate-docs.yaml` did not list `AGENTS.md`: a commit
  that pushed the root over its budget — the exact regression the check exists for — matched no
  filter and CI stayed green with nothing run. It has now bitten **three times**;
  `validate-artifacts.yaml` carries a comment about the first. When you add a check, add every path it
  _reads_ to both the `pull_request` and `push` lists, not just the script you edited.
  - **The third bite was the corpus ratchet, and it is the one that shows how the trap hides.** Pass 3
    reads `skills/**`, and `validate-artifacts.yaml` listed none of it — so appending words to a
    `SKILL.md`, the exact shape the ratchet exists to catch, matched no filter. `.husky/pre-commit`
    does not run `validate:artifacts` either, so there was no automatic path at all. What made it
    invisible: `validate-docs.yaml` **does** list `skills/**`, so that commit still showed a green
    tick — from a workflow that never measures the corpus. A green check on a skill edit does not mean
    the corpus was measured; only the _Validate artifacts_ run does.
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
    `pnpm exec node --version` is the pinned Node, and a bare `node --version` is whatever your shell
    has — **unless that `node` is a version-proxy shim, and then a version probe is not a read.**
    A `vp`-style shim (and pnpm's own) resolves the declaration of whatever repo it is run _in_,
    downloads a runtime to satisfy it, and answers as that version; `pnpm -v` likewise fetches the
    pinned pnpm and rewrites `pnpm-lock.yaml` — `packageManagerDependencies`, `packages:`,
    `snapshots:`, some 200 lines. Two consequences for any script probing versions: the answer is the
    repo's own declaration compared against itself, and an unsatisfiable one makes the probe exit 1
    with no version at all. Probe from `/` (`(cd / && pnpm -v)`), where no manifest applies —
    `dw-doctor` does, and `scripts/tests/doctor.test.sh` fails if a probe moves back inside.
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
  blindness sits in `block-non-pnpm.sh`**, which cannot tell a mention from an invocation either —
  though only when the quoted text carries a command separator, since the patterns anchor after `;`,
  `&` and `|`. `git grep "npm install"` is fine; `git grep "; npm install"` and
  `grep -rn "npm install\|yarn add" .` are both refused for containing the string they search _for_,
  and so is `git commit -m "ci: replace | yarn with pnpm"`. Grep the shorter token, or build it. (This
  entry named the harmless spelling as the trap for a while — the example was never reproducible, and
  the fix was to probe both hooks rather than re-read the sentence.) **`block-dangerous-commands.sh` is the third**, and the worst
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
- **Only exit 2 blocks, so a hook that fails any other way is a hook that is silently off.** Every one
  of these runs `set -uo pipefail`, and each of the three ways below aborts it at exit 1 — which the
  harness reads as "not a block" and never mentions. The lesson is not the individual traps; it is that
  a guardrail's failure mode is indistinguishable from its happy path, so every hook needs a case
  proving it still refuses something.
  - **`local a="$1" n=${#a}` does not work.** Every word of a `local` is expanded _before_ the builtin
    runs, so `${#a}` reads an `a` that is not set yet. Two statements, always.
  - **bash 3.2 errors on `"${arr[@]}"` for an EMPTY array under `set -u`.** Which is why
    `enforce-commit-hygiene.sh` carries its per-commit message group as scalars rather than an array.
  - **A `while read` loop's exit status is its last test**, false for the ordinary case, which sinks
    the enclosing pipeline under `pipefail`. `strip_heredocs` ends in a bare `return 0` for exactly
    this reason, in two hooks now.
- **`${path#"$repo_root"/}` is not "make this path repo-relative".** It is a string-prefix test, and
  the two strings routinely name the same directory in different spellings: git reports the physical
  path while the tool hands over one that still contains a symlinked ancestor — `/private/var/…`
  against `/var/…` on macOS is the everyday case, and a repo under a symlinked home dir is another.
  The strip then silently does nothing, the path reads as "outside the repo", and the hook exits 0
  without guarding. Compare directories with `-ef`, which is device-and-inode and answers the question
  actually being asked; keep the walk itself textual (`dirname`) so it cannot resolve the very symlink
  it is looking for. `guard-plugin-canon.sh` is the worked example.
- **Reaching for `xargs -n1` to re-tokenize a shell command does not survive a newline.** BSD xargs
  (macOS) aborts with "unterminated quote" the moment a quoted argument contains one — and a
  multi-line `-m` commit body is this repo's normal shape, so tokenization stopped at the flag and
  every commit read as having no message. `enforce-commit-hygiene.sh` carries a ~40-line quote-tracking
  lexer instead; copy that rather than re-deriving this. It also earns its keep twice, because
  distinguishing an inert single-quoted backtick from a live double-quoted one needs the quote state
  that no token list retains.
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
