# Context — glossary

Terms this repo uses in a specific way. Definitions only, no implementation detail — that lives in
[`docs/DESIGN.md`](docs/DESIGN.md).

- **Lane** — how much process a change gets. This repo is the **thin lane** (one reader). The
  team-weight lane is [`dw-skills`](https://github.com/dominikwozniak/dw-skills). One lane per repo.
- **Canon** — the single real copy of a file. `skills/<name>/` and `scripts/runtime/<s>.sh` are canon;
  everything under `plugins/` is a git-tracked symlink back to it. Never edit through `plugins/…`.
- **Change** — one unit of work, held in `.ai/work/<slug>/CHANGE.md`. Persistent (tracked, survives a
  `/clear`) but disposable (deleted by `dw-land` at merge).
- **Promotion** — moving the durable residue out of a `CHANGE.md` before it is deleted: decisions to
  `docs/decisions/`, terms here, traps to `## Gotchas` in `CLAUDE.md`, follow-ups to `.ai/BACKLOG.md`.
- **Task** — one ticked box in a `CHANGE.md`: a thin vertical slice, independently committable, leaving
  the project green. Not a layer ("add all the migrations" is not a task).
- **Anchor** — a `path/to/file.rb:42` reference in a `CHANGE.md`. Orientation for a fresh session, never
  an edit script; re-verified when the work resumes.
- **Vendored** — a byte-identical copy of a file whose canon lives in `dw-skills`
  (`templates/hooks/*`, `scripts/runtime/slugify.sh`). Fixes must be applied in both repos.
- **Fork** — a skill copied from `dw-skills` and deliberately simplified for one reader (`dw-git`,
  `dw-doctor`, `dw-setup-precommit`). Expected to diverge; not re-synced.
- **Explicit-invoke** — a skill with `disable-model-invocation: true`; it fires only when named.
- **HARD STOP** — a point in a skill where it must stop and wait for a human answer rather than
  proceed on an assumption.
