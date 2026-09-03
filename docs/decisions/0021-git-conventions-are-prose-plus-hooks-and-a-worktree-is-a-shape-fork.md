---
decision: 0021
status: active
date: 2026-09-03
---

# 0021 — git conventions are prose plus hooks, and a worktree is a fork of `dw-shape`

## Context

Two skills were held to one question: does the skill add anything a prompt every session already
loads does not? `dw-git` restated the `## Git conventions` block and then told the model to read it;
the half a regex can decide — subject pattern, trailer, `git add -A`, a live backtick, force-push —
is refused by `enforce-commit-hygiene.sh` and `block-dangerous-commands.sh` whether or not any skill
runs. Nine skills delegated to it by the phrase "the way `dw-git` does", which a session could only
honour by loading a second skill, and none did. Its one mechanism, which ref of the default branch a
review diff is taken against, was six lines of bash three skills borrowed by prose. `dw-start` was
2.4 KB of glue around `worktree.sh create` — pick, create, enter, install, shape, hand to `dw-next` —
and contested `dw-shape`'s vocabulary in the routing eval on every re-measure.

## Decision

There is no git skill. The conventions live in `## Git conventions`, loaded every session, and that
block now carries the judgement `0010` assigned to `dw-git`; the procedures the rules imply live in
the routed git topic file here and inline in the shipped template; the hooks enforce the declared
half. The base-ref resolution is `scripts/runtime/base-ref.sh`, a shipped script beside
`slugify.sh`, called by `dw-check`, `dw-land` and `dw-grain`.

There is no worktree skill. `dw-shape`'s branch decision has a third fork, taken only when the user
says the word "worktree": `worktree.sh create`, enter, run the declared `Bootstrap command`, shape
there. Worktrees stay opt-in — this lane is one reader and usually one session, and every worktree
pays an install plus the six traps `docs/agents/worktrees.md` records. `worktree.sh` stays whole:
`${CLAUDE_PLUGIN_ROOT}` resolves only inside a skill body, so a rule in `AGENTS.md` cannot reach a
plugin script, and `remove` is what `dw-ship` needs a session later, where `ExitWorktree` cannot.

## Trade-off

**A repo without a `## Git conventions` block gets Claude's own git defaults**, not this lane's. The
block ships in the scaffold, so a `dw-init` repo has it; an un-scaffolded repo used to get `dw-git`'s
defaults for free and now gets nothing. Accepted: those defaults were Conventional Commits and
staging by name, which is what the model does unprompted.

**Commit discipline lost its behaviour measurement.** `dw-git`'s two behaviour cases — staged by name
under pressure, a stash that names what it holds — were the most trace-assertable in the tier and
scored 4/4 and 4/4. The tier keys a case to a skill, so they went with it, and the fixture with them.
Measuring the conventions block itself would need the runner to accept a case with no skill; nothing
asks for that today.

**A model-invocable skill now creates worktrees.** Explicit-only was reserved for skills that act on
branch topology. `dw-shape` already created branches; the fork adds a worktree behind the same gate
`EnterWorktree` itself uses — the literal word from the user, never inferred.

The rejected option was the other half of the idea: retire `worktree.sh create` too and lean on
`EnterWorktree`, which honours `.worktreeinclude` natively. Rejected for now because `create`
carries an origin-collision check, an env-file report and the husky-inactive warning the native tool
lacks, and all three are tested; it stays `0003`'s revisit trigger.

## Revisit when

Claude Code grows a hook on worktree creation, or `EnterWorktree` reports what a fresh checkout still
needs — then `worktree.sh create` is duplication and goes, as `0003` predicted. Or the conventions
block squeezes a root `AGENTS.md` past its budget with nothing else left to move out. Or a second
lane wants git behaviour that differs per invocation rather than per repo, which is the one thing a
skill can express and a block cannot.
