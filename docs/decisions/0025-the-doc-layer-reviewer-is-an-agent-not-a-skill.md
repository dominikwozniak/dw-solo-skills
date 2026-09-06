---
decision: 0025
status: active # active | superseded
date: 2026-09-06
---

# 0025 — The doc-layer reviewer ships as an agent, and `agents/` is canon like `skills/`

## Context

Nothing in this lane reads a sentence in the doc layer and asks whether it is still true:
`dw-doctor` checks the layer exists, `check-agents-docs.mjs` counts words. Answering it means
reading `AGENTS.md`, every routed topic file, `CONTEXT.md` and `docs/decisions/`, then searching the
tree for every name they mention — tens of thousands of tokens whose only useful residue is a short
table. `dw-check` states the loop grows no reviewer of its own, so this could not join the spine.

## Decision

It ships as a subagent, `agents/dw-docs-drift.md`, with `agents/` a canon directory alongside
`skills/` and the same symlink-and-single-owner rule enforced by `validate-manifests.sh`. Read-only
is carried by `tools: Read, Grep, Glob` rather than by a clause in the prompt. The owning
`plugin.json` lists the agent **by file path in an array**: the directory string that works for
`skills` is `agents: Invalid input`, a type error that stops the plugin loading.

## Trade-off

An agent buys its own context window and pays for it in reach. There is no `/` form — a caller
types `@dw-solo-extras:dw-docs-drift` or describes the task — and no `disable-model-invocation`, so
the `description` is the only control over when it fires. It sits outside every measurement this
repo has: `eval:routing` does not score it and the skill corpus does not count it, which is why the
one description that routes it is unmeasured where twelve skills are not.

A thin skill wrapping the agent would restore the `/` form and the eval. It was rejected: it buys a
keystroke and adds a second description competing with the agent's own for the same prompts.

## Revisit when

A second agent lands and the two descriptions start pulling the same prompt in different
directions — that is when the unmeasured routing stops being one file's problem and needs an eval
tier of its own.
