---
decision: 0007
status: active # active | superseded
date: 2026-08-12
supersedes: 0003
---

# 0007 — The scaffold's agent memory is tracked `AGENTS.md`, and the worktree link class empties

## Context

`dw-init` scaffolded a gitignored `CLAUDE.local.md` and made it the source of truth for two things
the lane cannot work without: the `## Git conventions` block `dw-git` reads, and the
`- **Lint command**:` / `- **Typecheck command**:` bullets the guardrail hooks grep. Being gitignored
is what broke it. A fresh clone has neither, a `git worktree` checkout has neither, and every gap
fails silently rather than loudly — which is why decision 0003 had to invent a **link** carry class
for exactly one file, and why this repo's own `## Gotchas` records that `CLAUDE.local.md` cannot even
be edited from a worktree: the harness refuses the write as leaving the tree, and nothing commits it
either.

The alternative was already running in another repo. `grateful-me-app-v2` keeps one tracked
`AGENTS.md` under a declared budget, a `CLAUDE.md` symlink onto it, a Task Router into
`docs/agents/`, and a checker over the lot — and its own ADR (0001 there) had to reject a second
always-loaded memory channel to keep the corpus from forking.

## Decision

The scaffold writes one always-loaded, **tracked** `AGENTS.md` with `CLAUDE.md` symlinked at it. No
`CLAUDE.local.md` is written, and `link-local-memory` leaves the always-offered hook set — it is
offered only when a repo already has the file. `.gitignore` still names it, so a stray one is never
committed.

Two consequences follow, and both are the point rather than side effects. **Decision 0003's link
class has no member**: agent memory was its only one, and `git worktree add` delivers a tracked file
unaided. `worktree.sh`'s link step and the `link-local-memory` hook both survive as compatibility
paths for repos scaffolded earlier, guarded so that absence is a silent no-op. And the hooks resolve
their command from `AGENTS.md` **first**, `CLAUDE.local.md` second, so no already-scaffolded repo
changes behaviour.

**What this supersedes in 0003, and what it does not.** Only the **link** class. 0003's other three —
**copy** via `.worktreeinclude` with its hardcoded refusals, **regenerate** reported rather than
carried, and **absent** as the correct default — are unchanged, still implemented in `worktree.sh`,
and still the operative rule; the folder has no "partially superseded" status to say so with, which is
what this paragraph is for. Read 0003 for those three.

## Trade-off

**Personal and project memory stop being separable.** `CLAUDE.local.md` was the place for how you
like to be talked to, what you are learning, which MCP servers you happen to have running — none of
which a tracked file should carry. That content moves to the global `~/.claude/CLAUDE.md`, one level
up from any repo, where it cannot be per-project. The lane accepts that because it is a one-reader
lane: the second reader is the only party the split was protecting, and there isn't one.

**The root file is now budgeted, which means it can reject a true addition.** A gitignored scratch
file grows for free; `AGENTS.md` is capped at 120 lines / 10 KB and a real rule arriving at line 121
has to be routed into `docs/agents/` instead of just written down. That is the cost of the file being
worth loading in full every session.

The rejected option was a **tracked `CLAUDE.local.md`** holding only those two blocks. It would have
been read at the exact path every skill and hook already looked for, and needed no chain, no
supersession and no checker. It was rejected because a committed file named `local` is a lie the next
reader has to decode, and because two always-loaded files fork the corpus no matter how thin the
second one starts.

## Revisit when

Any one of: a second person gets commit access to a repo this scaffolds, at which point personal and
project memory genuinely need separating again; a scaffolded `AGENTS.md` passes ~115 of its 120 lines
with the git conventions and command bullets as what is squeezing it; or Claude Code grows a
per-repo personal-memory path that is neither gitignored nor tracked, which would give the retired
file a home that survives a clone.
