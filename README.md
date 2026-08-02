<p align="center">
  <img src="docs/assets/dw-solo-skills-hero-v2.png" alt="dw-solo-skills — a persistent workflow from idea to merge" width="100%">
</p>

<p align="center"><strong>A persistent workflow for Claude Code, sized for repos only you read.</strong></p>

<p align="center">
  <img alt="License: MIT" src="https://img.shields.io/badge/license-MIT-111111?style=flat-square">
  <img alt="11 skills" src="https://img.shields.io/badge/skills-11-111111?style=flat-square">
  <img alt="3 plugins" src="https://img.shields.io/badge/plugins-3-111111?style=flat-square">
  <img alt="Claude Code plugin" src="https://img.shields.io/badge/Claude_Code-plugin-111111?style=flat-square">
</p>

This is the **thin lane**. If several people read your specs and reviews, you want the fuller
workflow instead: [**dw-skills**](https://github.com/dominikwozniak/dw-skills) — `dw-spec → dw-plan →
dw-build` with five auditors, a validated status table, and slice graphs. Same conventions, more
ceremony. Pick one per repo; see [Why two repos](#-why-two-repos) below.

## ◆ What this lane is for

Every skill written here has to earn its place against one failure mode of agentic coding, at the
smallest weight that still works:

- **Context dies on /clear** — the change lives in a tracked file under `.ai/work/`, not in the
  session, and is read back from disk rather than reconstructed from scrollback.
- **The agent runs on a wrong assumption** — a fuzzy idea gets interrogated into decisions before
  anything is written.
- **The process outweighs the change** — one artifact instead of spec + plan + notes, one gated pass
  instead of five auditors and a separate writer.
- **A private repo rots** — the change doc is archived at merge (`.ai/archive/`), and what's durable
  is **promoted** first: decisions to `docs/decisions/`, terms to `CONTEXT.md`, traps to `## Gotchas`
  in `CLAUDE.md`, follow-ups to `.ai/backlog/`. Without that step you accumulate stale specs and lose
  the decisions worth keeping.
- **Commits drift from your conventions** — the repo's own `## Git conventions` are applied instead
  of generic defaults.

The _why_ behind each design choice is in [`docs/DESIGN.md`](docs/DESIGN.md).

## ▸ Quick start

```
claude plugin marketplace add dominikwozniak/dw-solo-skills
claude plugin install dw-solo
claude plugin install dw-solo-setup
claude plugin install dw-solo-extras   # optional — off-loop skills
```

Then, in a project of your own: `/dw-init` scaffolds it, `/dw-shape` opens the first change.

## ◇ Task router — which skill for which task

A task may match several rows — read all that apply. `⭑` = explicit-invoke only: say its name (it
never auto-fires). The phrases that trigger each skill live in its own `description`, not here.

**Explicit-only skills**: `dw-start`, `dw-ship`, `dw-init` and `dw-handoff`. Marked `⭑` in the
router; they never auto-fire — say the name. Being invisible to the model, they also can't be reached
by other skills' prose.

**The loop** — the mandatory spine is shape → next → ship; everything marked `?` is opt-in.

<p align="center">
  <img
    src="docs/assets/dw-solo-skills-workflow.svg"
    alt="Workflow: optional dw-grill, dw-shape, optional dw-start, iterative dw-next, optional dw-check, dw-land, then dw-ship"
    width="100%"
  >
</p>

A small serial change never leaves the default branch: shape → next → ship (`dw-ship` runs the
closing pass itself when the change doc is still there). Parallel changes: shape several on the
default branch, then one worktree + session each via `dw-start` or `claude -w <slug>`.

| Skill                                      | Task                                                       | Arguments                                                      | What you get                                                |
| ------------------------------------------ | ---------------------------------------------------------- | -------------------------------------------------------------- | ----------------------------------------------------------- |
| [`dw-grill`](skills/dw-grill/SKILL.md)     | Interview a fuzzy idea into decisions — max five questions | the idea to grill                                              | shared understanding (writes nothing)                       |
| [`dw-shape`](skills/dw-shape/SKILL.md)     | Synthesize it into one goal + decisions + task checklist   | the change to shape                                            | `.ai/work/<slug>/CHANGE.md`                                 |
| [`dw-start`](skills/dw-start/SKILL.md) `⭑` | Open a shaped change: worktree + branch + claim            | `bare` lists unclaimed · `<slug>` · a description → `dw-shape` | `.claude/worktrees/<slug>` on branch `<slug>`               |
| [`dw-next`](skills/dw-next/SKILL.md)       | Resume point _and_ build step (`go` builds and commits)    | `bare` · `go` · `all`                                          | code + ticked box + commit                                  |
| [`dw-check`](skills/dw-check/SKILL.md)     | Fast optional QA gate — delegate, or two-axis self-review  | `bare` · a path or topic                                       | findings at `file:line`, fixed in-session                   |
| [`dw-land`](skills/dw-land/SKILL.md)       | One thin verdict, then promote what's durable and archive  | `bare` · `close`                                               | `docs/decisions/` · `CONTEXT.md` · backlog · `.ai/archive/` |
| [`dw-ship`](skills/dw-ship/SKILL.md) `⭑`   | Push — or PR → squash-merge — then tear the worktree down  | `bare` · `pr`                                                  | merged default branch, clean tree                           |

**Anytime**

| Skill                              | Task                                                     | Arguments                              | What you get                       |
| ---------------------------------- | -------------------------------------------------------- | -------------------------------------- | ---------------------------------- |
| [`dw-git`](skills/dw-git/SKILL.md) | All git ops — commit / push / PR / sync / branch / stash | which git op — commit, push, open PR … | commits / PR per `CLAUDE.local.md` |

**Off-loop** — the `dw-solo-extras` plugin; reached for when a session ends before the task does.

| Skill                                          | Task                                                           | Arguments                     | What you get                 |
| ---------------------------------------------- | -------------------------------------------------------------- | ----------------------------- | ---------------------------- |
| [`dw-handoff`](skills/dw-handoff/SKILL.md) `⭑` | Compact the session mid-task — where you are, what's ruled out | `bare` · next session's focus | `.ai/work/<slug>/HANDOFF.md` |

**Setup** — the `dw-solo-setup` plugin; run once per repo.

| Skill                                    | Task                                                  | Arguments                        | What you get                             |
| ---------------------------------------- | ----------------------------------------------------- | -------------------------------- | ---------------------------------------- |
| [`dw-init`](skills/dw-init/SKILL.md) `⭑` | Scaffold a solo repo: `.ai/`, hooks, settings, memory | `bare` · project context to seed | tracked scaffold (+ optional pre-commit) |
| [`dw-doctor`](skills/dw-doctor/SKILL.md) | Diagnose tools, hooks, `.ai/` sanity (read-only)      | —                                | health report + copy-paste fixes         |

## ⚙ How it works — the design in one screen

Full rationale in [`docs/DESIGN.md`](docs/DESIGN.md).

- **Persistence in the skill, not a wrapper.** Each `SKILL.md` writes its own `.ai/` path as part of
  its procedure, so the change doc lands automatically and travels with the installed plugin — no
  `.claude/commands/` glue layer.
- **`.ai/` is tracked, one folder per change, no central index.** A registry becomes a merge-conflict
  magnet once tracked; discovery is by directory name + frontmatter, matched to the git branch.
- **Persistent, then archived.** The change doc is tracked so a `/clear` changes nothing, and moved
  to `.ai/archive/` at merge so `work/` doesn't accumulate stale specs — a squash merge would
  otherwise erase its worked state from history. What's genuinely durable is still promoted out.
- **One gate, not a skill boundary.** The fuller workflow separates read-only auditors from the one
  writer so an auditor can't under-report what it couldn't fix. Here you read every finding yourself,
  so a single pass reports first and mutates only after explicit approval.
- **Thin harness, fat skills.** The process lives in the markdown, not in glue code — so every model
  upgrade improves the skills for free. (Inspired by
  ["Fat Skills"](https://x.com/garrytan/status/2042925773300908103).)
- **Technology-agnostic.** Test/lint/run commands are read from your project (`## Commands` in
  `CLAUDE.md` → manifests → the code), never hardcoded.

## ◈ Why two repos

This lane started inside [`dw-skills`](https://github.com/dominikwozniak/dw-skills) alongside the
team lane. It moved out because the shared `templates/` payload was shaped for the team scaffolder —
the `CLAUDE.local.md` shipped the team loop, the `.ai/` README documented directories this lane
doesn't have — and every scaffolding run patched those files after copying. Here the templates are
this lane's own, copied as-is.

The cost, stated plainly: `templates/hooks/` (6 guardrail hooks — the team repo's Ruby lint hook is
deliberately dropped in this Node-only lane) and `scripts/runtime/slugify.sh` are **vendored
copies** of the same files in `dw-skills`. A fix must be applied in both — nothing across the repo
boundary can detect drift.

**Install one lane per repo, not both.** `dw-git`, `dw-doctor` and `dw-init` exist in both lanes as
deliberately diverging forks, so two lanes in one project means two skills competing for the same
task. Claude Code scopes plugins per project, which is where the choice is made once: in a solo repo
enable this lane's two plugins and disable the team lane's.

## ▤ Project structure

```
skills/<name>/SKILL.md          canonical skill (edit here)
plugins/dw-solo/                the loop plugin — git-tracked symlinks → ../../../skills/<name>
plugins/dw-solo-setup/          the setup plugin — dw-init, dw-doctor, the templates symlink
scripts/runtime/                shipped scripts (slugify, worktree), symlinked into the owning plugin
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
