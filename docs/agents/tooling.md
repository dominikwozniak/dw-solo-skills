# Tooling — pnpm, Node, lint, format, and the guardrail hooks

The commands themselves are in the root's `## Commands`; the gate is the `scripts` block of
`package.json`. This file is how that tooling misbehaves, and what the misbehaviour looks like when
it is not what it appears to be.

## The pins

`devEngines.packageManager` states the pnpm version and `devEngines.runtime` the Node one — there is
no `packageManager` field and no `.nvmrc`. `engines.pnpm` is the floor that turns an old bootstrap
into a loud `ERR_PNPM_UNSUPPORTED_ENGINE` rather than a half-applied config. CI reads both fields
through one inputless `pnpm/setup@v2` step, which installs pnpm, installs Node and runs the install —
so a workflow needs no `with:` block.

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
