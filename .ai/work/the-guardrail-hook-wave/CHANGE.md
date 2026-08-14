---
change: the-guardrail-hook-wave
branch: unclaimed
created: 2026-08-14
status: shaping # shaping | building | landed
---

# Change — the hook layer's whole open list, done in one pass: three rules move from prose to script, three new guards land, one guardrail gap closes, one dead hook retires

## Goal

Every rule this repo states in prose and enforces on trust gets a script, and the hook layer's
backlog empties in the same pass. Afterwards: a `git commit` that misses the declared subject
pattern, drops the declared trailer, hides a backtick in `-m`, or a `git add -A`, each exits 2 with
the fix named; an `Edit`/`Write` under `plugins/**` is refused and points at the canon; credential
hunting and oversized writes are guarded; `git -C sub push --force` blocks like the bare form;
`link-local-memory.sh` is gone and `block-non-pnpm.sh` has a self-test. Both new policies are
**declared, not inferred** — `- **Commit pattern**:` and `- **Commit trailer**:` in `AGENTS.md`,
each disabled by `none`, the `lint-on-edit.sh` resolution shape. `pnpm validate:artifacts` covers
every new hook, `hooks-in-sync.test.sh` stays green, and `skills/dw-git/SKILL.md` points at the
declarations instead of restating them.

**This is a large change, deliberately** — the user chose one feature over five items, to keep the
context in one place and close the hook layer at once. The task list below is progress tracking for
`dw-next`, not a split: it all lands together.

## Decisions

- One change, not five — the user's call, twice reaffirmed. Every piece edits
  `templates/hooks/` + both `settings.json` + `scripts/tests/` and needs the same plugin version
  bump, so separate changes meant paying that tax five times and re-deriving the context each time.
- Every policy is a declared bullet, never inferred from `## Git conventions` prose. The trailer
  needs its own `- **Commit trailer**:` for the same reason the pattern does: one line both the
  writer (model reads `AGENTS.md`) and the enforcer (hook greps it) read without guessing.
- Pattern default ships in the script (Conventional Commits); the trailer default is `none`, since
  a requirement nobody declared must not start failing commits in existing repos.
- The commit hook is `enforce-commit-hygiene.sh` — it outgrew "pattern". The change slug moved from
  `commit-pattern-hook` for the same reason; the old slug survives in two commit messages.
- `git add -A` is a staging call, not a commit, but it rides the same `PreToolUse`/`Bash` matcher
  and the same declaration file, so it stays in the commit hook rather than earning its own.
- Absorbed from `.ai/backlog/`: `guardrail-hooks-next-wave`, `the-other-git-guardrails-still-miss-
the-dash-c-form`, `shell-test-sweep`. Left there: `start-branch-check-ignores-remote` (claim
  protocol, not hooks), `validator-blind-spots`, `doctor-version-blocks-…`, `stemmer-derivational-
audit` — none touch the hook layer.
- Pass through `-F`/`--file`, editor commits (no `-m`), and `Merge `/`Revert `/`fixup! `/`squash! `/
  `amend! ` subjects — same allowances as the buildwithclaude original; `dw-git` uses `-m`.

## Tasks

Order is a hint. Each box leaves the repo green; the change ships when all are ticked.

- [ ] 1. `templates/hooks/enforce-commit-hygiene.sh` + byte-identical executable copy in
      `.claude/hooks/`, wired into the `PreToolUse`/`Bash` block of both `.claude/settings.json` and
      `templates/settings.json`. Four checks: subject pattern, trailer policy, backtick inside `-m`,
      `git add -A` / `git add .`. Shape after `block-dangerous-commands.sh` (jq guard, wrapper-aware
      `git … commit` detection); `-m` extraction after the buildwithclaude script (`xargs -n1`
      tokenization; `-m`/`--message`/`--message=`/`-mfix:`/clustered `-am`). Plus
      `scripts/tests/enforce-commit-hygiene.test.sh`.
- [ ] 2. `- **Commit pattern**:` and `- **Commit trailer**:` in this repo's `AGENTS.md`
      (`## Solo lane`, beside the lint and typecheck bullets) and placeholders in `templates/AGENTS.md`.
      Mind the root doc budget (120 lines / 10 KB) — `pnpm validate:docs` enforces it.
- [ ] 3. Trim `skills/dw-git/SKILL.md` commit Defaults to point at the declarations, shorten the
      backtick hazard note now that the hook catches it, and keep the mechanics (staging by name, `-F`,
      read-back via `git cat-file`).
- [ ] 4. `templates/hooks/guard-plugin-canon.sh` — `PreToolUse` on `Edit|Write|MultiEdit`, refuses a
      path under `plugins/` and names the `skills/…` canon behind the symlink. Wire both settings, add
      the self-test. This is the `AGENTS.md` "absolute" rule, today prose-only.
- [ ] 5. `templates/hooks/credential-leak-guard.sh` (`PreToolUse`/`Bash`: env scans for
      token/secret, `~/.ssh`, `~/.aws`, `curl`/`wget` exfil) and `templates/hooks/large-file-guard.sh`
      (`PostToolUse`/`Write`, size threshold). Both wired in both settings, both self-tested. Adapted
      from davepoon/buildwithclaude `plugins/hooks-safety` — rewrite to this repo's conventions, don't
      paste.
- [ ] 6. Apply the `GIT` prefix in `block-dangerous-commands.sh` to `push`, `reset --hard`, `clean`,
      `branch -D` and `stash clear`, so `git -C sub …` blocks like the bare form; extend
      `block-dangerous-commands.test.sh` with a `-C` case per pattern.
- [ ] 7. Retire `link-local-memory.sh`: both hook copies, `worktree.sh`'s `link_local_memory()`, its
      `worktree.test.sh` group, the `SessionStart` wire in both settings, `dw-init`'s legacy-only offer
      and `dw-start`'s sentence. Keep the `AGENTS.md`-first fallback in `lint-on-edit` and
      `typecheck-on-stop`. Add `scripts/tests/block-non-pnpm.test.sh` while the hook layer is open.
- [ ] 8. `docs/agents/tooling.md`: the new hooks, the two declaration bullets and the resolution
      order; `docs/agents/worktrees.md` where it names the retired hook. Bump the owning plugin
      versions + `.claude-plugin/marketplace.json` (`pnpm validate:manifests` pins the pair).

## Anchors

- `templates/hooks/block-dangerous-commands.sh:27-45` — `WRAPPER`/`BOUNDARY`/`GIT`; the new hooks
  must see through `sudo`/`rtk` the same way, and task 6 lives here.
- `templates/hooks/lint-on-edit.sh` — the `- **Lint command**:` bullet resolution both new bullets
  copy, including `none` as a standalone declaration.
- `scripts/tests/block-env-access.test.sh` — the self-test shape every new test follows:
  `jq -n --arg` payloads, blocked/allowed helpers, SKIP without jq, target = template.
- `scripts/tests/hooks-in-sync.test.sh` — template↔installed byte identity and +x; add each
  template first, then `cp` and `chmod +x`.
- `skills/dw-git/SKILL.md:58-68` — the commit Defaults being trimmed; `:83-90` — the backtick note.
- `AGENTS.md` `## Git conventions` — the trailer rule the new bullet must express machine-readably.
- `scripts/runtime/worktree.sh` `link_local_memory()` + `scripts/tests/worktree.test.sh` — task 7's
  other half; `docs/decisions/0007-agent-memory-in-tracked-agents-md.md` is why it is retirable
  (`CLAUDE.local.md` is already gone from this repo — verified).
- buildwithclaude.com/hook/conventional-commits — `-m` extraction and the pass-through list.

## Notes

Full grill/plan record: `/Users/dominik.wozniak/.claude/plans/zastanawiam-sie-nad-nowym-shimmying-gosling.md`.

The commit hook polices this repo's own commits the moment it is installed — including the commit
that installs it. Land task 1's wiring only once the message convention is confirmed working, or
expect the first commit to bounce. Same for task 4: `guard-plugin-canon` will refuse edits under
`plugins/`, which is correct but will surprise the session that wires it.

Task 5's two hooks are the ones with the weakest case (`block-env-access.sh` + the CI trufflehog
scan already cover much of the credential ground). If the change starts to drag, they are the first
thing to drop back to the backlog — say so rather than half-doing them.
