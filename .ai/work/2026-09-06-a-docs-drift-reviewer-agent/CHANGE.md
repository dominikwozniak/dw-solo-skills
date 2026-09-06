---
change: a-docs-drift-reviewer-agent
branch: worktree-majestic-conjuring-scott
created: 2026-09-06
status: building
---

# Change — a `dw-docs-drift` subagent reads the doc layer and reports what no longer exists

## Goal

Ship `dw-docs-drift` in `dw-solo-extras`: a subagent that walks a repo's doc layer, takes every
named referent in it — a path, a symbol, a command, a package, a config key, a version — and
reports each as alive, dead or absent at a real `file:line`. It never edits. Proven when a run
against this repo returns findings that hold up when opened by hand, and a run against a repo
without a Task Router degrades to what it can reach instead of failing.

## Decisions

- Subagent, not a skill — the sweep costs tens of thousands of tokens of grep and file reads; a
  subagent keeps them in its own context window and returns a table.
- Home is `dw-solo-extras`, invoked by a person on demand — `dw-check` states it never grows a
  reviewer of its own, and an off-loop tool must not make `dw-land` grow one either.
- No diff, no `CHANGE.md` on the input — it audits the doc layer against the tree at rest. All three
  real cases from `grateful-me-app-v2` surfaced long after the diff that broke them: a topic file
  named `CARD_BOX` six days before the symbol existed, a `[built]` marker stood over `zustand` with
  zero imports for a month, and a `deps` row listed one package where sharing needs two.
- Reports, never gates — a tool outside the loop has nothing to block, and a blocking gate on prose
  teaches you to skip it.
- Only named referents are checkable, in three states: exists and is used · exists but dead ·
  absent. Advice, rationale and style are out of scope and the agent stays silent on them. Without
  this bar it invents forty findings against forty correct records.
- Discovery is the `## Task Router` in `AGENTS.md` plus what `dw-init` scaffolds (`CONTEXT.md`,
  `docs/decisions/`, `docs/agents/`, `.ai/`), degrading like `dw-doctor` when a repo has fewer. No
  layout is hardcoded and `dw-init` does not change.
- Drift class 3 — "a decision cleared the bar and was never recorded" — is dropped, not deferred:
  `dw-land` phase 2 already sweeps for exactly that with the diff in hand and the bar beside it.
- Prototype at `.claude/agents/dw-docs-drift.md` first, promote inside this same change. A plugin
  agent costs a reinstall per iteration; a local one costs a session restart.
- The three surviving follow-ups land as **one** backlog entry, not three — the lane sits at its
  cap of 8 and this change frees exactly one slot.

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

## Anchors

- `skills/dw-check/SKILL.md:5` — states the loop's quality pass grows no reviewer of its own; the
  reason this lives off-loop.
- `skills/dw-land/SKILL.md:20` — `dw-land`'s verdict is never delegated, and its phase 2 owns the
  missing-record sweep this agent drops.
- `skills/dw-doctor/SKILL.md` — the discovery-and-degrade pattern to copy: read what the repo
  declares, report the gap, never assume a layout.
- `docs/agents/skills-and-plugins.md:36` — the `## Adding a skill` checklist task 4 mirrors for
  agents, and the source of the symlink and version-bump rules task 3 follows.
- `scripts/validate-manifests.sh:147` — the canon/symlink rule covers `skills/` and
  `scripts/runtime/` only; an `agents/` directory is unvalidated, which is why task 5 files it.
- `plugins/dw-solo-extras/.claude-plugin/plugin.json` — version `0.2.0`, no `agents` key yet.
- `scripts/validate-artifacts.sh:64` — `BACKLOG_CAP=8`, the constraint behind one bundled entry.

## References

- `skills/dw-land/references/decision-record.md` — the bar for a decision record; named so it is
  visibly **not** copied into the agent.
- `byarcadia-app/grateful-me-app-v2` PR #80 — `references-explorer`, the sibling subagent this one
  is shaped after; it reported a stale row and left it alone.
- `/claude-code-setup:claude-automation-recommender` — the run over `grateful-me-app-v2` that
  proposed both agents and the two hooks task 5 files.
- `evals/cases/` — one file per model-invocable skill; nothing there measures an agent.

## Notes

- The sibling enforces read-only through `tools: Read, Grep, Glob` rather than a prompt clause;
  copied, so the never-edit rule cannot be talked out of.
- The loudest noise source in this repo is its own payload: every path in `templates/` is a shape
  for another repo, not a claim about this tree. The bar names that class explicitly.
- A project agent registers only when a session **starts** — task 2 needs a restart before the
  first run, and that cost is the reason the prototype is local.
- **`agents` takes an array of file paths, never the `skills` key's directory string.** Probed
  against `claude plugin validate --strict`: the array passes, `"agents": "./agents"` returns
  `agents: Invalid input` and a type error on a recognised field stops the plugin loading. So each
  new agent is listed by name — unlike a skill, which the directory string covers for free.
- `claude plugin validate <plugin>` reads components without following symlinks, so it never sees
  this repo's canon. Validate the real path too: `claude plugin validate agents --strict` passes.
- A plugin subagent registers under a **scoped** name — `dw-solo-extras:dw-docs-drift` in a
  consumer repo, not the bare name. Task 4's docs say the scoped form.
- Plugin subagents ignore `hooks`, `mcpServers` and `permissionMode` in frontmatter. This one uses
  none of them, so promotion changes nothing about how it behaves.
- First run: one true finding (`git-uncommitted`, a fixture retired with `dw-git`, still named at
  `docs/agents/skills-and-plugins.md:148`), zero false positives. The bar held.
- The bar also correctly refused a real drift of another class: `docs/agents/tooling.md` says three
  `validate-*` workflows where `.github/workflows/` has four. A count is not a named referent, and
  widening the bar to catch it is what invents forty findings. Left for a human.
- **An agent `description` written as a plain YAML scalar breaks on a colon.** Claude Code loaded
  the file and ran it; `agnix` refused it as unparseable frontmatter, and `claude plugin validate`
  passed it too. Use a `>-` block, as every skill here does. Only the repo's own linter saw it.
- `validate-versions.sh` built a plugin's shipped surface from `skills/*` alone, so an edited agent
  would reach consumers with no version bump and nothing would fail. Closed alongside task 7.
- Absorbed, all three found by the agent's own first run: the retired `git-uncommitted` fixture,
  nine hooks called "a ninth" where `templates/hooks/` ships ten, and three path-filtered
  `validate-*` workflows where `.github/workflows/` has four.
- Task 5 shipped two items, not three. `.ai/backlog/README.md` sends work that nothing blocks and
  that costs less than its own description into the open change instead — the `agents/` validator
  is both, so it became task 7. The bundle is tighter for it: two `templates/` items, one bump.
- The worktree git guard refuses `git add`, `git commit`, `git log` and `git status` here (rtk
  rewrites them and the guard cannot then prove the target). Every commit in this change needs a
  `!` line from the user.
