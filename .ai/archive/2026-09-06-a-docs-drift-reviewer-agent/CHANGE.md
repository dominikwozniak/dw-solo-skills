---
change: a-docs-drift-reviewer-agent
branch: worktree-majestic-conjuring-scott
created: 2026-09-06
landed: 2026-09-06
status: landed
pr: https://github.com/dominikwozniak/dw-solo-skills/pull/61
---

# Change — a `dw-docs-drift` subagent reads the doc layer and reports what no longer exists

## Tasks

<!-- Convention: `- [ ]` pending, `- [x]` done — `dw-next` flips the box in the task's own commit.
A task that stopped being necessary keeps its box and gains `**skip:** <reason>`; every later
invocation reads that as not remaining. Never rename a task title. -->

- [x] 1. Write the prototype `.claude/agents/dw-docs-drift.md` — `description` that routes on
      "docs drift / stale docs / are the docs still true", discovery via the Task Router with
      `dw-doctor`-style degradation, the three-state bar, a report table of `file:line` · referent ·
      state · evidence, and an explicit never-edit clause.
- [x] 2. Run it against this repo, iterate the prompt until every finding survives being opened by
      hand; record what it found and what it wrongly flagged in `## Notes`.
- [x] 3. Promote to the canon: `agents/dw-docs-drift.md`, the symlink
      `plugins/dw-solo-extras/agents/dw-docs-drift.md`, an `"agents": "./agents"` key in that
      plugin's `plugin.json`, and `0.2.0 → 0.3.0` in both `plugin.json` and
      `.claude-plugin/marketplace.json`. Delete the local prototype.
- [x] 4. Document it: a README row, the `agents/` line in the root `AGENTS.md` layout block, and an
      `## Adding an agent` section in `docs/agents/skills-and-plugins.md` naming what no validator
      covers.
- [x] 5. One backlog entry for the surviving follow-ups: a declared doc contract in
      `templates/AGENTS.md`, CI coverage for `agents/`, and the recommender's two unbuilt hooks.
- [x] 6. Run the full `scripts` block of `package.json` — `eval:routing` included, since nothing
      here adds a skill but the docs checks read README and `AGENTS.md`.
- [x] 7. Teach `validate-manifests.sh` the `agents/` canon: every `plugins/<p>/agents/<name>.md` is
      a symlink resolving to `agents/<name>.md`, and every canon agent is shipped by exactly one
      plugin — the same two directions it already enforces for `skills/`. Runs after task 3.

## Notes

- **Unverified at close, and deliberately.** The goal asked for a run against a repo with no Task
  Router, degrading rather than failing. Nothing here can show it: the agent deregistered the moment
  it moved out of `.claude/agents/`, and no CI step runs an agent. Carried as a line in the PR body,
  to be checked on the first run in a consumer repo against 0.3.0.
- First run against this repo: one true finding (`git-uncommitted`, a fixture retired with `dw-git`,
  still named as live), zero false positives. The bar held on its first outing.
- The bar also refused a real drift of another class — two count claims in `docs/agents/tooling.md`,
  both wrong, neither a named referent. Fixed by hand instead; widening the bar to catch a count is
  what invents forty findings.
- Task 5 shipped two items, not three. `.ai/backlog/README.md` sends work that nothing blocks and
  that costs less than its own description into the open change instead — the `agents/` validator
  was both, so it became task 7.
- `validate-versions.sh` built a plugin's shipped surface from `skills/*` alone, so an edited agent
  would have reached consumers with no version bump and nothing would have failed.
- The worktree git guard refuses `git add`, `git commit`, `git diff`, `git log` and `git status`
  here — rtk rewrites them and the guard cannot then prove the target. `git mv`, `git rev-parse`,
  `git rev-list` and `git cat-file` pass. Every commit in this change was pasted by hand.
