<p align="center"><strong>shape → build → land — a persistent workflow for Claude Code, sized for repos only you read.</strong></p>

<p align="center">
  <img alt="License: MIT" src="https://img.shields.io/badge/license-MIT-111111?style=flat-square">
  <img alt="8 skills" src="https://img.shields.io/badge/skills-8-111111?style=flat-square">
  <img alt="1 plugin" src="https://img.shields.io/badge/plugins-1-111111?style=flat-square">
  <img alt="Claude Code plugin" src="https://img.shields.io/badge/Claude_Code-plugin-111111?style=flat-square">
</p>

One `CHANGE.md` per change, tracked in git, so work survives a `/clear` or a week-long gap. One
quality pass instead of five audits. Every skill reads your project's own commands — nothing about a
stack is baked in.

This is the **thin lane**. If several people read your specs and reviews, you want the fuller
workflow instead: [**dw-skills**](https://github.com/dominikwozniak/dw-skills) — `dw-spec → dw-plan →
dw-build` with five auditors, a validated status table, and slice graphs. Same conventions, more
ceremony. Pick one per repo; see [Why two repos](#-why-two-repos) below.

## ◆ Why these skills exist

Each kills one failure mode of agentic coding, at the smallest weight that still works:

- **Context dies on /clear** — the change lives in a tracked `.ai/work/<slug>/CHANGE.md`, not in the
  session. `dw-next` bare reads it back from disk.
- **The agent runs on a wrong assumption** — `dw-grill` interviews a fuzzy idea into decisions,
  one question at a time, before anything is written.
- **The process outweighs the change** — one file instead of spec + plan + notes, one gated pass
  instead of five auditors and a separate writer.
- **A private repo rots** — `dw-land` deletes the change doc at merge but **promotes** what's
  durable first: decisions to `docs/decisions/`, terms to `CONTEXT.md`, traps to `## Gotchas` in
  `CLAUDE.md`, follow-ups to `.ai/BACKLOG.md`. Without that step you accumulate stale specs and lose
  the decisions worth keeping.
- **Commits drift from your conventions** — `dw-git` reads `## Git conventions` from
  `CLAUDE.local.md` and applies them instead of generic defaults.

The _why_ behind each design choice is in [`docs/DESIGN.md`](docs/DESIGN.md).

## ▸ Quick start

```
claude plugin marketplace add git@github.com:dominikwozniak/dw-solo-skills.git
claude plugin install dw-solo
```

Then `/dw-init` once per repo, and `/dw-shape` to open the first change. `/dw-next` bare is also the
resume path after a `/clear`.

## ↻ The loop

```
  (GRILL)       SHAPE           BUILD                 LAND                    SHIP
  /dw-grill →   /dw-shape   →   /dw-next     →        /dw-land         →      (merge — your call)
  fuzzy idea    one CHANGE.md   ↺ /dw-next (bare =    verdict, then promote
                + task list       resume from disk)   decisions & drop the doc
  └────── .ai/work/<slug>/CHANGE.md (deleted at merge) ──────┘  └→ docs/decisions/ · CONTEXT.md · ## Gotchas · .ai/BACKLOG.md (kept)
```

One artifact home: **`.ai/work/<slug>/CHANGE.md`** — the goal, the decisions actually taken, a task
checklist, and anchors in real files. Tracked in git, so it survives a `/clear`; deleted by `dw-land`
at merge, after the durable parts are promoted out.

**Shipping is intentionally outside this toolkit.** The loop hands you a change that's been read and
proven; merging it is your call.

The arrows are a _recommendation, not a rail_. Every skill is invoked on its own when you need it.

## ◇ Task router — which skill for which task

`⭑` = explicit-invoke only: say its name (it never auto-fires). The phrases that trigger each skill
live in its own `description`, not here.

**The loop**

| Skill                                  | Task                                                       | What you get                                        |
| -------------------------------------- | ---------------------------------------------------------- | --------------------------------------------------- |
| [`dw-grill`](skills/dw-grill/SKILL.md) | Interview a fuzzy idea into decisions — max five questions | shared understanding (writes nothing)               |
| [`dw-shape`](skills/dw-shape/SKILL.md) | Synthesize it into one goal + decisions + task checklist   | `.ai/work/<slug>/CHANGE.md`                         |
| [`dw-next`](skills/dw-next/SKILL.md)   | Resume point _and_ build step (`go` builds and commits)    | code + ticked box + commit                          |
| [`dw-land`](skills/dw-land/SKILL.md)   | One verdict: correct · fits · blast radius · proven        | `docs/decisions/` · `CONTEXT.md` · `.ai/BACKLOG.md` |

**Setup & anytime**

| Skill                                                          | Task                                                        | What you get                     |
| -------------------------------------------------------------- | ----------------------------------------------------------- | -------------------------------- |
| [`dw-init`](skills/dw-init/SKILL.md) `⭑`                       | Scaffold a repo for this loop: `.ai/work/`, hooks, settings | tracked `.ai/` + `.claude/`      |
| [`dw-doctor`](skills/dw-doctor/SKILL.md)                       | Diagnose tools, hooks, `.ai/` sanity (read-only)            | health report + fixes            |
| [`dw-git`](skills/dw-git/SKILL.md)                             | All git ops — commit / push / sync / branch / stash         | commits per `CLAUDE.local.md`    |
| [`dw-setup-precommit`](skills/dw-setup-precommit/SKILL.md) `⭑` | Wire husky + lint-staged for a pnpm node/ts/js repo         | `.husky/` + `.lintstagedrc.json` |

**Explicit-only skills** (`dw-init`, `dw-setup-precommit`) are invoked by name and never
auto-trigger — they scaffold a repo and install shared tooling, so the model shouldn't reach for them
unbidden. Everything else can be model-invoked when the task fits.

## ⚙ How it works — the design in one screen

Full rationale in [`docs/DESIGN.md`](docs/DESIGN.md).

- **Persistence in the skill, not a wrapper.** Each `SKILL.md` writes its own `.ai/` path as part of
  its procedure, so the change doc lands automatically and travels with the installed plugin — no
  `.claude/commands/` glue layer.
- **`.ai/` is tracked, one folder per change, no central index.** A registry becomes a merge-conflict
  magnet once tracked; discovery is by directory name + frontmatter, matched to the git branch.
- **Persistent but disposable.** `CHANGE.md` is tracked so a `/clear` changes nothing, and deleted at
  merge so the repo doesn't accumulate stale specs. What's genuinely durable is promoted out.
- **One gate, not a skill boundary.** The fuller workflow separates read-only auditors from the one
  writer so an auditor can't under-report what it couldn't fix. Here you read every finding yourself,
  so `dw-land` reports first and mutates only after explicit approval.
- **Thin harness, fat skills.** The process lives in the markdown, not in glue code — so every model
  upgrade improves the skills for free. (Inspired by
  ["Fat Skills"](https://x.com/garrytan/status/2042925773300908103).)
- **Technology-agnostic.** Test/lint/run commands are read from your project (`## Commands` in
  `CLAUDE.md` → manifests → the code), never hardcoded.

## ◈ Why two repos

This lane started inside [`dw-skills`](https://github.com/dominikwozniak/dw-skills) alongside the
team lane. It moved out because the shared `templates/` payload was shaped for the team scaffolder —
the `CLAUDE.local.md` shipped the team loop, the `.ai/` README documented directories this lane
doesn't have — and every `dw-init` run patched those files after copying. Here the templates are
this lane's own, copied as-is.

The cost, stated plainly: `templates/hooks/` (7 guardrail hooks) and `scripts/runtime/slugify.sh` are
**vendored copies** of the same files in `dw-skills`. They're byte-identical today, and a fix must be
applied in both — nothing across the repo boundary can detect drift. `dw-git`, `dw-doctor` and
`dw-setup-precommit` are forks, deliberately simplified for one reader, and will diverge on purpose.

## ▤ Project structure

```
skills/<name>/SKILL.md          canonical skill (edit here)
plugins/dw-solo/                plugin.json + git-tracked symlinks → ../../../skills/<name>
scripts/runtime/                shipped scripts, symlinked into the plugin
templates/                      payload copied INTO a target project (hooks, settings, CLAUDE.local.md)
.claude-plugin/marketplace.json makes the repo installable
docs/DESIGN.md                  design rationale (the "why")
docs/SKILL-ANATOMY.md           the shape every SKILL.md follows
```

## ◆ Contributing

Layout, conventions, the add-a-skill checklist, and CI all live in [`AGENTS.md`](AGENTS.md)
(`CLAUDE.md` is a symlink to it).

## ▪ License

MIT
