# Tooling — pnpm, Node, lint, format, self-tests and the guardrail hooks

The commands live in the root's `## Commands`; the gate is the `scripts` block of `package.json`. This
file is how that tooling misbehaves.

## `pnpm validate:artifacts` — three passes

`scripts/validate-artifacts.sh` runs every self-test under `scripts/tests/` (pass 1 — it globs
`scripts/tests/*.test.sh`, so a new test needs no wiring), then the cap on `.ai/backlog/` (pass 2) and
the ratchet over `skills/*/SKILL.md` (pass 3, `scripts/check-skill-corpus.mjs` against
`scripts/skill-corpus.baseline.json`). **Pass 3 is conditional**: with no `node` on `PATH` it prints
`SKIP` and the command still exits 0, so a green run is not by itself proof the corpus was measured.

Pass 3 sets **no threshold**: the baseline records what the corpus is and the check fails only on an
increase, so growth costs one `node scripts/check-skill-corpus.mjs --update-baseline` in the same
commit, and adding a skill always touches two files. The unit is words; why words rather than lines or
bytes, and why a ratchet rather than a number, are in
[`0009`](../decisions/0009-skill-corpus-ratchet.md).

A baseline it cannot trust exits **2**, never a silent pass: missing, unparseable, wrong-shaped, or
`words` disagreeing with the sum of `perSkill`. The one exception is `--update-baseline` on a missing
file, which bootstraps it. Bad flag spellings exit 2 too, because the two that matter both look like
success: `--update-baselines` runs a plain check and writes nothing, and `--root ""` resolves against
the cwd — from the repo root it measures the live tree the fixture stood in for.

## The hooks

Wired in tracked `.claude/settings.json` with the scripts in `.claude/hooks/`, so a fresh clone and a
`git worktree` checkout get the same guardrails. Each is a byte-identical copy of its template under
`templates/hooks/`, pinned by `scripts/tests/hooks-in-sync.test.sh` — the hooks you run are the hooks
you ship.

| hook                          | fires on                                                                               |
| ----------------------------- | -------------------------------------------------------------------------------------- |
| `bash-guard.sh`               | PreToolUse(Bash) — the dispatcher: one stdin parse, spawns the Bash guards below       |
| `block-dangerous-commands.sh` | PreToolUse(Bash) — destructive shell                                                   |
| `block-non-pnpm.sh`           | PreToolUse(Bash) — npm/npx/yarn/bun invocations                                        |
| `enforce-commit-hygiene.sh`   | PreToolUse(Bash) — commit subject, trailer, backtick, `git add -A`                     |
| `credential-leak-guard.sh`    | PreToolUse(Bash) — credential stores, env hunting, exfil                               |
| `block-env-access.sh`         | PreToolUse(Read/Edit/Write/MultiEdit/NotebookEdit/Grep) — `.env`; Bash via bash-guard  |
| `guard-plugin-canon.sh`       | PreToolUse(Edit/Write/MultiEdit/NotebookEdit) — an edit aimed through a plugin symlink |
| `lint-on-edit.sh`             | PostToolUse(Write/Edit/MultiEdit) — the root's Lint command                            |
| `large-file-guard.sh`         | PostToolUse(Write) — an oversized write, after the fact                                |

Every hook that parses a payload opens with `command -v jq >/dev/null || exit 0`, the dispatcher
included — so **without `jq` on `PATH` they all silently no-op**, and nothing says so. (A Bash guard
spawned with `--bash-command` takes the command off stdin and needs no `jq` of its own; the
dispatcher above it is what bails.) `/dw-doctor` is the check. `templates/hooks/` ships a ninth,
`typecheck-on-commit.sh`, deliberately unwired here because this repo has no typecheck.

`hooks-in-sync.test.sh` pins the templates ≡ installed copies invariant **inside this repo only**;
`dw-doctor` is the only thing that sees it in a consumer, comparing every wired `.claude/hooks/*.sh`
against the `templates/hooks/` of the installed plugin version. `WARN`, never `FAIL` — a patched or
deliberately older hook is a legitimate choice, and a hook with no template is that repo's own. What
it buys is concrete: a vendored `block-non-pnpm` that stripped only one leading `sudo `, and so let
`rtk npm install` straight through, sat in a consumer repo reporting `OK` on existence and the
executable bit.

`lint-on-edit.sh` is live on `evals/*.ts`, which matches its `.ts/.tsx/.js/.jsx/.mjs/.cjs` filter:
`scripts/lint.sh` lints the one path it is appended and only walks the tree when handed nothing.
`.husky/pre-commit` is still the real gate.

## The five declared bullets

`- **Lint command**:`, `- **Typecheck command**:`, `- **Commit pattern**:`, `- **Commit trailer**:`
and `- **Bootstrap command**:` under the root's `## Solo lane` are **grep-read** rather than
inferred, which is why they live there and nowhere else. Five separate scripts repeat one extraction
shape — four independent copies of it, not a shared one, so a bug there is fixed four times or not at
all. Four are read by hooks; the fifth is read by `worktree.sh
create`, which prints it and never runs it — a worktree arrives with tracked files and no installed
dependencies, and only the repo knows what makes it buildable. The chain:

1. `AGENTS.md`, the tracked file the scaffold writes.
2. `CLAUDE.local.md`, legacy only — a repo scaffolded before decision 0007 still keeps its own there.
   `CLAUDE.md` is absent on purpose: it is a symlink to `AGENTS.md`, so reading it is reading step 1
   twice.
3. For the commit pattern only, `CLAUDE_COMMIT_PATTERN_DEFAULT` when the caller set it — the knob a
   copy wired from outside the repo (`~/.claude/hooks/`) uses to pass `none` where the log was never
   Conventional Commits. It replaces the fallback below, never a declared bullet.
4. The script's own default — a probe (eslint / `tsc`) for lint and typecheck, Conventional Commits
   for the pattern, `none` for the trailer, because a requirement nobody declared must not start
   failing commits, and for bootstrap the lockfile guess (`pnpm install` and friends) that
   `worktree.sh` falls back to.

The value is **the first backticked span** on the line, and a standalone `none` **disables the check
and stops the chain**. `none` is tested on the raw remainder _before_ any backtick extraction so it
wins over explanatory prose: `none — see `scripts/lint.sh`` must skip, and the version that picked the
backticks first ran that script on every edit. An unrendered `{{…}}` placeholder is not a declaration
either, and each script names the tokens it rejects.

## Gotchas

- **A Bash heredoc that writes a file runs the file's text past every PreToolUse guard.** The hooks
  lex the whole command, and a `cat > x.test.sh <<'EOF'` body holding `git commit -qm "$3"` read to
  `enforce-commit-hygiene.sh` as a commit whose subject was `$3)` — refused, the file never written.
  Whatever the guards would refuse as a command they refuse as text on its way into a file. Write such
  a file with the Write tool, or spell the trap in a form the lexer skips (`git commit -F -`, which is
  what `base-ref.test.sh` does).
- **`dw-check`'s delegated pass returns empty once Codex runs past 120 s, and recovering it is the
  parent's job.** `codex:codex-rescue` is allowed exactly one `task` forward — it is barred from
  `status`, `result` and from reading the repo, and it will say so if asked again. So when the Bash
  tool's 120 s limit moves the Codex run to the background, the subagent returns with no findings and
  cannot fetch them. The parent thread collects them:
  `node ~/.claude/plugins/cache/openai-codex/codex/<v>/scripts/codex-companion.mjs result <job>`.
  - **The id Bash reports is not the Codex job id.** Bash hands back its own background id
    (`bfhu1elhj`-shaped); the companion wants the `task-…` id, and asking it about the former answers
    `No job found`. Bare `codex-companion.mjs status` lists the real one.
  - A full review of a 17-file prose diff took **~7 minutes**, so this is the normal path rather than
    an edge case. Wait on it with one backgrounded `until` loop over `status`, not a poll in the
    conversation.
- **agnix warnings do not gate, and one of them is true right now.** `scripts/lint.sh` exits **0**
  with dozens of warnings; only `Found N errors` gates, so a rule firing is not a rule enforced —
  agnix's `File exceeds recommended token limit` has been firing on `CLAUDE.md` the whole time
  `pnpm validate:docs` has called that same file green. Two checkers, two units, and the advisory one's
  output looks identical to the binding one's; run either for the current figures, no copy of which is
  kept here. Before citing agnix as the thing that would have caught
  something, check that it gates: `severity` only sets a reporting floor, and `[[overrides]]` can only
  _disable_ a rule for a glob, never lower its threshold — which is why the corpus ratchet is its own
  checker rather than a tuned `AS-012`.
  - **Read the exit code, never the tally**, because one real error hides in the wall of warnings and
    markdown you read as code can be its source. The unclosed-XML-tag rule counts backticks **per
    line**, so an angle-bracketed placeholder is exempt only while its code span opens and closes on
    the same line; hand-wrap an _earlier_ span across the newline and the next line is left with odd
    parity, its placeholder read as bare prose and erroring. Keep such a span short enough that it
    never needs wrapping.
- **A new check needs its `paths:` entry in both the `pull_request` and `push` lists**, or it never
  runs on the commit shape it exists to catch. Only the three `validate-*` workflows are
  path-filtered — `agnix-lint`, `evals-routing`, `format-check` and `secrets-scan` run on everything —
  so a check added to one of those three scripts inherits that script's old triggers. Add every path the
  check _reads_, not just the script you edited; those workflows carry the reasoning inline beside the
  entries that were missing. It hides because an unfiltered workflow matches anyway, so the commit still
  shows a green tick from a run that never performed the check: a green tick on a skill edit does not
  mean the corpus was measured — only the _Validate artifacts_ run does.
- **`validate:versions` passes locally and fails on push, because the bases differ.** Local diffs
  `origin/main`, CI's push job diffs `HEAD~1`. So the **last commit touching shipped surface must carry
  the bump** — which `dw-land`'s close commit breaks by construction, the bump being an earlier task.
  `4e4edb3` shipped `promote.md` at an unchanged `0.4.26` that way. Bump again inside the close.
- **pnpm here is three traps deep, and every one looks like a broken repo.**
  - **The lint script can be hijacked before it reaches `scripts/lint.sh`.** With the `rtk` proxy hook
    active it is rewritten to `rtk lint`, an _ESLint_ wrapper, and dies with
    `Command "eslint" not found` while the repo is green; the format script is unaffected (rtk has no
    `format` command), which makes it read as a real lint failure. Verify with `bash scripts/lint.sh`
    or `node_modules/.bin/agnix .`. CI has no rtk.
  - **`agnix` also OOMs locally** — "terminated abnormally" under memory pressure, which
    `scripts/lint.sh` turns into a hard error rather than a silent pass. Re-run it, or scope it
    (`pnpm lint <path>...`); CI has the headroom. **But a scoped run is not a subset of the full
    one**: `.agnix.toml`'s `exclude` list governs the project walk only, so a path named explicitly is
    linted even when the walk skips it — `pnpm lint docs/agents/tooling.md` reports an
    `Agent file must have YAML frontmatter` error the bare run never sees, that directory being
    excluded for exactly that reason. Scope to debug an OOM, never to decide whether a file is clean.
    Nothing automated hits this: `lint-on-edit` filters to `.ts/.js` and `.husky/pre-commit` filters
    `templates/`.
  - **Both pinned versions live in one field, and three things must line up.**
    `devEngines.packageManager` states pnpm `11.18.0` and `devEngines.runtime` Node `24.16.0`; there
    is no `packageManager` field and no `.nvmrc`. (1) The **bootstrap on `PATH` must be pnpm 11** — v10
    cannot read `devEngines` at all and would half-apply v11 settings, so `engines.pnpm` is the floor
    that turns that into a loud `ERR_PNPM_UNSUPPORTED_ENGINE`. (2) **`onFail` governs every command**,
    not just installs: `"error"` refuses unless your pnpm matches the pin _exactly_ (which no
    `brew upgrade` survives), `"download"` fetches the pinned version and runs it, the behaviour the
    deleted `packageManager` field used to provide. (3) **CI reads both fields through one inputless
    `pnpm/setup@v2` step** — it installs pnpm, installs Node and runs the install, so no `with:` block
    is needed.
    - **Don't add `cache: true` without re-measuring.** It was measured on #28 and reverted: the
      action installs the runtime _before_ it restores, so most of the entry is a Node tarball
      uploaded and restored on every hit and then never used, making a cache hit slower than no cache.
      What actually dominates these jobs is `agnix`'s postinstall fetching its prebuilt binary, which
      no store cache touches.
    - **Bumping Node is the field _plus_ a regenerated `pnpm-lock.yaml`.** `devEngines.runtime` makes
      Node a locked dependency (a `node@runtime:…` entry with a per-platform hash), so editing the
      version alone makes CI's frozen install refuse it.
    - **A version probe is not a read when `node` is a version-proxy shim.** Locally the pin reaches
      only what runs through pnpm (`pnpm exec node --version` is pinned; a bare `node --version` is
      your shell's), and a `vp`-style shim — pnpm's own included — resolves the declaration of
      whatever repo it runs _in_, downloads a runtime to satisfy it and answers as that version.
      `pnpm -v` likewise fetches the pinned pnpm and rewrites `pnpm-lock.yaml`
      (`packageManagerDependencies`, `packages:`, `snapshots:`, some 200 lines). So the answer is the
      repo's own declaration compared against itself, and an unsatisfiable one exits 1 with no version
      at all: probe from `/` (`(cd / && pnpm -v)`), as `dw-doctor` does and
      `scripts/tests/doctor.test.sh` enforces.
- **The lint hooks disagree with the gate, in more than one direction.**
  - **`.lintstagedrc.json`'s glob and `prettier --check .` disagree by construction.** Prettier checks
    every file it understands while lint-staged only formats the listed extensions, so a new file type
    is unformatted at commit and rejected at push — a lint failure in a green repo. Add the extension
    with the first file of a kind; `evals/*.ts` needed `ts` there.
  - **Prettier is not idempotent on a paragraph nested inside a task-list item**, so `--write` and
    `--check` disagree forever: the format check fails while `.husky/pre-commit` does not, because
    lint-staged writes and re-stages the very content the push gate then refuses. It bites in
    `.ai/work/<date>-<slug>/CHANGE.md`, where writing findings under a `- [x] N.` box is the natural thing to
    do. Keep task bodies to one paragraph; findings belong in `## Notes`.
  - **`prettier --check` never looks at prose width**, because `.prettierrc.json` sets
    `proseWrap: "preserve"` and `printWidth: 100` governs only code and reflowed tables. So the gate
    passes a 128-column line in a file hand-wrapped to 100, and an edit that rewraps just the line it
    touches pushes the overflow onto the next. Rewrap the whole paragraph and check with
    `grep -nE '^.{108,}'`.
  - **`evals/*.ts` must never get the executable bit.** `lint-on-edit.sh` `eval`s its resolved lint
    command against the file path, and the pre-fix version resolved to a bare space and executed the
    target. Pinned by `scripts/tests/lint-on-edit.test.sh`.
- **Three hooks cannot tell a mention of a command from an invocation of it, so a probe cannot be
  typed literally.**
  - **`block-env-access.sh` stops reading at a `<<`.** Heredoc bodies are dropped before tokenizing,
    which is why `git commit -F - <<'MSG'` no longer blocks — but the drop is unconditional, so a
    literal `<<` anywhere starts body mode and **nothing below it is scanned**. A bare `.env` token
    still blocks anywhere, so build the string (`D=$(printf ".%s" env)`) or your own test call never
    runs.
  - **`block-non-pnpm.sh` has the same blindness**, but only when the quoted text carries a command
    separator, since the patterns anchor after `;`, `&` and `|`. `git grep "npm install"` is fine;
    `git grep "; npm install"`, `grep -rn "npm install\|yarn add" .` and
    `git commit -m "ci: replace | yarn with pnpm"` are all refused for containing the string they name.
    Grep the shorter token, or build it.
  - **`block-dangerous-commands.sh` is the worst to probe by hand**: its patterns anchor after the same
    separators, so a one-liner looping over test cases contains `; git restore .` by construction and
    blocks itself. Put the cases in a file under the scratchpad and run that — which is what
    `scripts/tests/` already does, and the reason to reach for it first.
- **When you change one of these patterns, diff the old hook against the new one instead of reading the
  regex.** `git show origin/main:templates/hooks/<hook>.sh > /tmp/old.sh`, run the same probe through
  both and compare exit codes: the answer you need is _which commands changed verdict_. That comparison
  is what exposed two holes that had been there all along (a quoted `"."`, and `git -C <path>`) — rows
  identically wrong on both sides, and a loosened guardrail is invisible to a self-test that never had
  the case.
- **Only exit 2 blocks, so a hook that fails any other way is a hook that is silently off.** Every one
  runs `set -uo pipefail`, and each trap below aborts it at exit 1 — which the harness reads as "not a
  block" and never mentions. The lesson is not the individual traps but that a guardrail's failure mode
  is indistinguishable from its happy path, so every hook needs a case proving it still refuses
  something.
  - **`local a="$1" n=${#a}` does not work** — every word of a `local` is expanded before the builtin
    runs, so `${#a}` reads an `a` that is not set yet. Two statements, always.
  - **bash 3.2 errors on `"${arr[@]}"` for an EMPTY array under `set -u`**, which is why
    `enforce-commit-hygiene.sh` carries its per-commit message group as scalars rather than an array.
  - **A `while read` loop's exit status is its last test**, false for the ordinary case, which sinks the
    enclosing pipeline under `pipefail`. `strip_heredocs` ends in a bare `return 0` for exactly this
    reason, in two hooks now.
  - **A hook that exits before consuming stdin kills its caller with SIGPIPE.** `large-file-guard.sh`
    resolved its threshold above `input=$(cat)`, so the disable path returned without draining the
    payload and the writer took the signal (`zero-disables` exiting 141). It surfaced **once**, under
    the full suite's load, and would not reproduce in 20 standalone runs — the payload fits the pipe
    buffer, so the race only opens when the hook wins. Read stdin first, then decide; the other hooks
    are safe only because they happen to read immediately.
- **`${path#"$repo_root"/}` is not "make this path repo-relative"** — it is a string-prefix test, and
  the two strings routinely name the same directory in different spellings (git reports the physical
  path while the tool hands over one containing a symlinked ancestor: `/private/var/…` against `/var/…`
  on macOS, or a repo under a symlinked home). The strip then silently does nothing, the path reads as
  outside the repo, and the hook exits 0 without guarding. Compare directories with `-ef`, which is
  device-and-inode, and keep the walk itself textual (`dirname`) so it cannot resolve the very symlink
  it is looking for. `guard-plugin-canon.sh` is the worked example.
- **`xargs -n1` does not survive a newline**, so it cannot re-tokenize a shell command here: BSD xargs
  (macOS) aborts with "unterminated quote" the moment a quoted argument contains one, and a multi-line
  `-m` commit body is this repo's normal shape — tokenization stopped at the flag and every commit read
  as having no message. `enforce-commit-hygiene.sh` carries a ~40-line quote-tracking lexer instead;
  copy that rather than re-deriving it. It earns its keep twice, because distinguishing an inert
  single-quoted backtick from a live double-quoted one needs quote state that no token list retains.
- **A self-test can be green for a reason that has nothing to do with the contract** — two shapes, one
  root cause: the assertion never reaches the code it names.
  - **A fixture that is the live repo is a content gate under a unit test's name.** A `no-arg` case ran
    its script against this repo and demanded silence, gating `docs/decisions/` from under the heading
    `arguments:` and stricter than the contract it tested. Use a synthetic fixture; live-content checks
    belong in `validate-artifacts.sh`.
  - **A case placed outside the region the code scans, or asserting the bug as the contract.** Both
    shipped here and an outside reviewer found them, not the suite: a router row appended after
    `## Solo lane` passed only because the check grepped the whole file, and a `value-matches-hook` case
    asserted that explanatory backticks beat the `none` sentinel, pinning the defect as intended
    behaviour. When a test passes first try, prove it can fail — break the code, or move the fixture
    line, and watch it go red.
- **Every guard is self-contained, which means the shared parts are copies and nothing measures their
  drift.** `strip_heredocs` and its `HEREDOC_OPEN` are byte-identical in `block-env-access.sh` and
  `credential-leak-guard.sh`, and the declared-bullet extractor exists four times over. That is not an
  oversight to refactor away: `bash-guard.sh` spawns each guard on its own and skips any that is
  missing, so a guard that sourced a helper would be a guard that stops working the moment the helper
  is pruned. The cost is that fixing one copy fixes one copy. When you touch either shape, grep for its
  twin in the same commit — `grep -rln strip_heredocs templates/hooks/` — because no test compares them.
