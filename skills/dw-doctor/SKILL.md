---
name: dw-doctor
description: >-
  Read-only environment diagnostic for a solo-lane repo: check whether the tools the hooks and
  skills assume are installed and whether the repo's guardrails will actually fire, then report
  each gap with a copy-paste fix. Mutates nothing. Use when setting up or inheriting a repo, or
  when someone asks "check my setup", "why aren't my hooks running", "diagnose the repo".
---

# dw-doctor — read-only environment diagnostic

Confirm the machine actually has what this repo's hooks and skills assume, and that the wiring
resolves — before a missing tool silently degrades things. The sharpest case: every
`.claude/hooks/*.sh` opens with `command -v jq >/dev/null || exit 0`, so on a box without `jq` the
dangerous-command block, `.env` protection, pnpm enforcement, and lint/typecheck-on-edit hooks
**all quietly no-op** and nobody notices. Same failure class for a missing `pnpm`, a
`settings.json` pointing at a hook that isn't executable, or a typecheck hook with no `tsc` to
call.

**Read-only:** it probes (`command -v`, `--version`) and reads files, then reports. It never
installs a tool, never edits a file, never runs the fixes it suggests — applying them is your call.

## What it reads

It diagnoses the **current git repo** (resolved via `git rev-parse --show-toplevel`), not the
skill's own location. Checks are conditional on what the repo declares, so nothing about a stack is
assumed:

- `package.json` — `engines.node`, the pnpm pin (`devEngines.packageManager` first, then the older
  `packageManager`), declared deps, and `scripts.typecheck` (drives the JS/TS checks).
- `tsconfig.json`, `.nvmrc` — presence informs the `tsc` / node checks.
- `.claude/settings.json` — parsed for every wired hook command; each referenced `*.sh` is checked
  for existence + the executable bit.
- `.ai/work/` — the scaffold this lane runs on; its absence points at `dw-init`, and a `.ai/runs/`
  directory is flagged as the other lane's repo rather than half-checked.
- `docs/decisions/` and `CONTEXT.md` — the promotion targets `dw-land` writes into. Presence only:
  the record contract is prose `dw-land` reads while writing one, not something this skill parses.
- **`AGENTS.md` — the one always-loaded file, and the block worth the most here.** Present? Does it
  declare a `Budget:` line, is that line parseable, and is the file inside it? Is there a
  `## Task Router` with rows, and does every `docs/agents/*.md` have one? Did a `{{PLACEHOLDER}}`
  survive the render? Is `CLAUDE.md` the **symlink** to it rather than a second copy that will
  diverge? And is `scripts/check-agents-docs.mjs` there to enforce any of it.
- **The `- **Lint command**:` / `- **Typecheck command**:` bullets**, resolved in the hooks' own
  order — `AGENTS.md`, then a legacy `CLAUDE.local.md` — and **extracted the way the hooks extract
  them**, first backticked span else the rest of the line. Reporting a command the hook would not
  actually run is the one failure mode a diagnostic cannot afford. A value of `none` reports OK: it
  is what tells the hook to skip.
- `CLAUDE.local.md` — informational only. Nothing writes it any more; where one exists it is a
  legacy fallback, not a gap.
- `.claude-plugin/marketplace.json` — only if present (a marketplace repo); a light
  plugin/version-sync glance.
- Tool presence on `PATH` via `command -v`: `git`, `jq`, `gh`, `codex`, `node`, `pnpm`, and the
  project-local `agnix` / `prettier` / `tsc` binaries. `codex` is WARN-tier and **never** FAIL — the
  loop works without it, only `dw-check`'s outside reviewer and `dw-ship`'s rescue route degrade —
  and the check stops at "installed": probing auth would mean a network call from a read-only
  diagnostic.

## Workflow

### 1. Run the bundled script

From anywhere inside the target repo, run the script shipped with this skill:

```
bash "<this-skill-dir>/scripts/doctor.sh"
```

`<this-skill-dir>` is the directory holding this `SKILL.md` (e.g. `skills/dw-doctor` in source, or
the installed plugin's `skills/dw-doctor`). The script resolves the repo itself, so the working
directory only needs to be somewhere inside the repo you want diagnosed.

### 2. Relay the report

The script prints grouped `OK` / `WARN` / `FAIL` lines with a one-line fix on each non-OK.
Summarize it for the user and **lead with any `FAIL`** — especially `jq` or `git`, since those gate
everything else. Surface the install commands it prints (e.g. `brew install jq`,
`corepack enable`, `pnpm install`) verbatim so they can copy-paste, but do not run them yourself.

### 3. Stop

Report and hand off. Fixing the environment is the user's action; `dw-doctor` only diagnoses. If
the report shows `.ai/runs/`, the repo runs the team lane from the other marketplace — say so
plainly instead of pointing anywhere in this one.

## Guardrails

- **Stack-adaptive.** JS/TS checks run only when `package.json` exists; `tsc` only when the repo asks
  for typechecking. The marketplace check fires only when `marketplace.json` is present.
- **Never guesses.** It reports observed state and the consequence of each gap; it doesn't infer
  intent or "fix" anything for you.

**Next:** `dw-init` if the scaffold is incomplete, else `dw-shape` for a new change or `dw-next` to
pick the active one back up.
