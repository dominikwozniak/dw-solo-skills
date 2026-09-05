---
created: 2026-09-05
source: add-a-references-explorer-subagent (grateful-me-app-v2)
why-not-now: five calls are open — who invokes it, whether it blocks or reports, what it reads, how it tells a missing record from noise, and whether it prototypes as a local `.claude/agents/` file here before promotion; `dw-grill` settles them first
effort: one sitting after the grill — one agent file, an `agents` key in plugin.json, a version bump, one eval fixture
---

# A `dw-docs-drift` reviewer: did the diff deliver what `AGENTS.md` promised?

`dw-land` promotes decisions, vocabulary and gotchas, and `dw-init` scaffolds the files they land
in. Nothing checks whether what those files **say** is still true. `dw-doctor` checks the layer
exists; `check-agents-docs.mjs` counts bytes and words. Neither reads a sentence.

Home is `dw-solo-extras` — `dw-solo`'s `dw-check` states it never grows a reviewer of its own —
and this repo's own lane artefacts make it dogfoodable here before it ships.

## Where this came from

`/claude-code-setup:claude-automation-recommender` (plugin `claude-code-setup@claude-plugins-official`)
run over `grateful-me-app-v2`. It found the setup already dense — hooks, permissions, nine locked
skills, an eight-step gate — and **zero subagents in any repo**, which is why both of its agent
recommendations are worth the effort. The sibling one, `references-explorer`, is built and merged
(that repo's PR #80); this is the second. Re-running the skill is the cheapest way to re-derive the
rest of its output: it also proposed a `SessionStart` hook printing the active `CHANGE.md` and a
`Stop` hook running the cached check, both left report-open.

## Three drift classes, one real case each

Every case below is from `grateful-me-app-v2`, found by a human or by accident, never by a gate.

1. **A doc asserts something the code does not have.** `docs/agents/ui.md:39` named `CARD_BOX` in
   `src/utils/styles.ts` from commit `85bfaa6` (2026-08-30). The symbol first existed in `dbf78d8`
   (2026-09-05) — **22 commits and six days** during which the routed topic file told every agent
   to use a helper that was not there. Nothing failed.
2. **A state marker outlives its state.** `references/conflicts.md` carried the row
   `state | … | zustand + react-native-mmkv [built]` while `zustand` sat installed with **zero
   imports for a month**. Caught by an ad-hoc `code-simplifier` audit, not by the lane.
3. **A promise the diff should have written and did not.** The `share-as-image` row listed one
   `deps` package; sharing needs two. Found on the first run of `references-explorer`, which is the
   evidence this shape of agent works — it reported the row, it did not edit it.

Class 3 is the original motivation, but 1 and 2 are the ones that rot silently, and they are the
same question asked backwards: **does every assertion in the doc layer still hold against the tree,
and does every change to the tree leave the doc layer true?**

## What it must do

Read the diff, the branch's `CHANGE.md`, and the repo's doc layer. Report at real `file:line`:
an assertion that no longer holds, a decision that cleared the bar and was never recorded, a term
the glossary lacks, a gotcha that cost time and is written nowhere. Never edit — the caller fixes,
the way `references-explorer` reports a stale row and leaves it alone.

The bar for "should have been a record" is `dw-land`'s `references/decision-record.md`: hard to
reverse, surprising, a real trade-off, **all three named out loud per candidate**. Without that
gate it will invent forty findings against forty existing records.

## Portability — this is not a grateful-me tool

The targets are exactly what `dw-init` scaffolds: `docs/decisions/`, `CONTEXT.md`, `AGENTS.md`
with its Task Router and budget, `docs/agents/` and its README, `.ai/`. `dw-doctor` is the
precedent for discovering them and degrading when a repo has fewer — the agent must do the same,
never hardcode a layout. Anything a consumer repo adds on top (grateful-me's
`references/conflicts.md`, its `built:` markers) has to be reachable through the Task Router, not
through a name the agent knows.

Open question that follows: does a consumer repo need to declare its doc contract somewhere the
agent can read, or is the Task Router enough? If it needs a declaration, that is a `dw-init`
template change and a second scope.

## The five open calls, for the grill

1. Who invokes it — `dw-land` automatically, or a person? Auto makes `dw-land` grow the reviewer
   `dw-check` refuses to grow.
2. Blocking gate or report? A blocking gate on prose teaches you to skip it.
3. What does it read — file names only, or the diff body? Decides whether it is cheap.
4. How does it separate a missing record from noise? See the bar above.
5. Local `.claude/agents/` prototype here first, then promote to the plugin? An agent does not
   register in the session that writes it, so a plugin agent pays a version bump per iteration
   where a local one pays a restart.
