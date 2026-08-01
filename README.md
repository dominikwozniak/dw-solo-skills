<p align="center"><strong>A persistent workflow for Claude Code, sized for repos only you read.</strong></p>

<p align="center">
  <img alt="License: MIT" src="https://img.shields.io/badge/license-MIT-111111?style=flat-square">
  <img alt="0 skills" src="https://img.shields.io/badge/skills-0-111111?style=flat-square">
  <img alt="1 plugin" src="https://img.shields.io/badge/plugins-1-111111?style=flat-square">
  <img alt="Claude Code plugin" src="https://img.shields.io/badge/Claude_Code-plugin-111111?style=flat-square">
</p>

> **Status: rebuilding.** The skill set this repo shipped was inherited wholesale from the team lane
> and has been removed. What remains is the harness — plugin manifests, the symlink canon, the
> validators, the CI, and the `templates/` payload — so the first new skill is a `SKILL.md` and a
> symlink, and nothing else. The sections below describe the lane the skills are being designed for.

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
- **A private repo rots** — the change doc is deleted at merge, but what's durable is **promoted**
  first: decisions to `docs/decisions/`, terms to `CONTEXT.md`, traps to `## Gotchas` in `CLAUDE.md`,
  follow-ups to `.ai/BACKLOG.md`. Without that step you accumulate stale specs and lose the decisions
  worth keeping.
- **Commits drift from your conventions** — the repo's own `## Git conventions` are applied instead
  of generic defaults.

The _why_ behind each design choice is in [`docs/DESIGN.md`](docs/DESIGN.md).

## ▸ Quick start

```
claude plugin marketplace add git@github.com:dominikwozniak/dw-solo-skills.git
claude plugin install dw-solo
```

The plugin installs and validates, but ships no skills yet.

## ◇ Task router — which skill for which task

A task may match several rows — read all that apply. `⭑` = explicit-invoke only: say its name (it
never auto-fires). The phrases that trigger each skill live in its own `description`, not here.

**The loop** — shape → build → land → ship; grill first when the idea is fuzzy.

| Skill                                  | Task                                                       | What you get                          |
| -------------------------------------- | ---------------------------------------------------------- | ------------------------------------- |
| [`dw-grill`](skills/dw-grill/SKILL.md) | Interview a fuzzy idea into decisions — max five questions | shared understanding (writes nothing) |

**Anytime**

| Skill                              | Task                                                     | What you get                       |
| ---------------------------------- | -------------------------------------------------------- | ---------------------------------- |
| [`dw-git`](skills/dw-git/SKILL.md) | All git ops — commit / push / PR / sync / branch / stash | commits / PR per `CLAUDE.local.md` |

## ⚙ How it works — the design in one screen

Full rationale in [`docs/DESIGN.md`](docs/DESIGN.md).

- **Persistence in the skill, not a wrapper.** Each `SKILL.md` writes its own `.ai/` path as part of
  its procedure, so the change doc lands automatically and travels with the installed plugin — no
  `.claude/commands/` glue layer.
- **`.ai/` is tracked, one folder per change, no central index.** A registry becomes a merge-conflict
  magnet once tracked; discovery is by directory name + frontmatter, matched to the git branch.
- **Persistent but disposable.** The change doc is tracked so a `/clear` changes nothing, and deleted
  at merge so the repo doesn't accumulate stale specs. What's genuinely durable is promoted out.
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

The cost, stated plainly: `templates/hooks/` (7 guardrail hooks) and `scripts/runtime/slugify.sh` are
**vendored copies** of the same files in `dw-skills`. They're byte-identical today, and a fix must be
applied in both — nothing across the repo boundary can detect drift.

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
