# Context — glossary

Terms this repo uses in a specific way. Definitions only, no implementation detail — that lives in
[`docs/DESIGN.md`](docs/DESIGN.md).

- **Lane** — how much process a change gets. This repo is the **thin lane** (one reader). The
  team-weight lane is [`dw-skills`](https://github.com/dominikwozniak/dw-skills). One lane per repo.
- **Canon** — the single real copy of a file. `skills/<name>/` and `scripts/runtime/<s>.sh` are canon;
  everything under `plugins/` is a git-tracked symlink back to it. Never edit through `plugins/…`.
- **Change** — one unit of work, held in `.ai/work/<slug>/CHANGE.md`. Persistent (tracked, survives a
  `/clear`), archived at merge (`.ai/archive/<slug>/`, `status: landed`).
- **Promotion** — moving the durable residue out of a `CHANGE.md` before it is archived: decisions to
  `docs/decisions/`, terms here, traps to `## Gotchas` in `CLAUDE.md`, follow-ups to `.ai/backlog/`
  (one file per idea).
- **Archive** — `.ai/archive/<slug>/`: landed change docs kept as history, not guidance. Nothing
  reads them to decide anything; backlog entries may point at one for its findings.
- **Task** — one ticked box in a `CHANGE.md`: a thin vertical slice, independently committable, leaving
  the project green. Not a layer ("add all the migrations" is not a task).
- **Anchor** — a `path/to/file.rb:42` reference in a `CHANGE.md`. Orientation for a fresh session, never
  an edit script; re-verified when the work resumes.
- **Vendored** — a byte-identical copy of a file whose canon lives in `dw-skills`
  (`templates/hooks/*`, `scripts/runtime/slugify.sh`). Fixes must be applied in both repos.
- **Fork** — a skill copied from `dw-skills` and deliberately simplified for one reader. Expected to
  diverge; not re-synced. Current forks: `dw-grill`, `dw-shape`, `dw-next`, `dw-land`, `dw-git`,
  `dw-doctor`, `dw-init`.
- **Claim** — flipping a change doc's `branch: unclaimed` sentinel to a real branch name, committed
  immediately. Done by `dw-start` (after creating the worktree) or offered by `dw-next` (when its
  branch-grep misses). A change shaped on the default branch is unclaimed until then.
- **Carry class** — which treatment an untracked file gets when a worktree is created: **copy** (local
  config, via `.worktreeinclude`), **link** (`CLAUDE.local.md`), **regenerate** (`node_modules/`,
  `.husky/_/` — reported, never carried) or **absent** (caches). Set by [`0003`](docs/decisions/0003-worktree-carry-classes.md).
- **Explicit-invoke** — a skill with `disable-model-invocation: true`; it fires only when named.
- **Case file** — `evals/cases/<skill>.json`: prompts that should route to a skill (**positives**) and
  near-miss prompts that should not (**negatives**, each naming the `owner` that should win instead).
  One per model-invocable skill, none for an explicit-invoke one.
- **Shadowed** — a positive prompt where an explicit-invoke skill scores higher than the skill under
  test. Reported as overlap, never counted as a routing failure: the model is never offered it.
- **HARD STOP** — a point in a skill where it must stop and wait for a human answer rather than
  proceed on an assumption.
