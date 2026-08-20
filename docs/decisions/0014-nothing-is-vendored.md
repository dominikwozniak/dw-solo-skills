---
decision: 0014
status: active # active | superseded
date: 2026-08-20
supersedes: 0001
---

# 0014 — Nothing is vendored; `dw-skills` is gone from the live docs

## Context

[`0001`](0001-separate-repo-from-dw-skills.md) split this lane out of `dw-skills` and accepted one
cost: `templates/hooks/*.sh` and `scripts/runtime/slugify.sh` stay byte-identical copies, so every hook
fix must be applied in both repos with nothing able to detect drift. Its `## Revisit when` named the
trigger — one hook fix missed in one repo and shipped broken. That happened: all five shared templates
have diverged, and the sibling's `block-non-pnpm.sh` still strips one leading `sudo ` by parameter
expansion, the exact hole this repo closed with a wrapper regex.

## Decision

The other repo is unmaintained and nothing here points at it. `templates/hooks/` and
`scripts/runtime/` are this repo's canon outright, not copies of anything. Every live mention is
removed — the README's "Why two repos" section and its thin-lane pointer, the `AGENTS.md` clause,
`CONTEXT.md`'s `Lane` sentence and its `Fork` term, the "fix in both" section in
`docs/agents/skills-and-plugins.md`, and the comments in `validate-manifests.sh`, `dw-init/SKILL.md`
and `credential-leak-guard.sh`. `Vendored` keeps its name and means one thing only: a consumer repo's
copy of a shipped template, which `dw-doctor` compares.

## Trade-off

`0001` predicted the fix would be publishing `templates/` as a versioned package — a third repo, a
release flow, version pinning. That is no longer worth doing for a dependency with one consumer, so the
trade dissolves rather than being paid.

What is given up is real. The README no longer explains why this repo exists, and `0001` is now the
only account of it; a reader has to reach `docs/decisions/` to find it. The "install one lane per repo,
not both" warning also goes, so someone who already has both installed loses the sentence that told
them the two `dw-git`/`dw-doctor`/`dw-init` pairs compete.

## Revisit when

A second consumer of `templates/` appears — another repo of your own, or someone forking this one and
asking for the hooks alone. One consumer is what makes a package not worth its release flow.
