---
decision: 0010
status: active # active | superseded
date: 2026-08-14
---

# 0010 — A policy a hook enforces is a declared bullet, never inferred from the prose that states it

## Context

`AGENTS.md` already stated this repo's commit conventions in `## Git conventions`: Conventional
Commits, lowercase and imperative, a `Co-Authored-By` trailer naming the model, no generated-with
footer. Every one of those was enforced on trust — a session read the prose and complied, or didn't,
and nothing noticed. Moving them under a script needed the hook to know what the rule _is_, and there
were only two ways to arrange that.

The obvious one is to parse what is already written. `## Git conventions` is a section with a stable
heading, the trailer rule is a bullet in it, and a hook could grep the section and derive both the
subject shape and the trailer key without anyone writing a second line. That is one source of truth,
which is the shape this repo reaches for everywhere else — the pre-push gate is `package.json`'s
`scripts` block precisely because the prose copies drifted, and decision 0006 exists to delete second
copies.

## Decision

**The hook reads a declared bullet under `## Solo lane`, and never the prose.**
`- **Commit pattern**:` holds an ERE; `- **Commit trailer**:` holds a trailer key. They resolve the
way `- **Lint command**:` and `- **Typecheck command**:` already do — `AGENTS.md` first, a legacy
`CLAUDE.local.md` second, then a default baked into the script — and a standalone `none` disables the
check.

The prose stays, and now says less: `skills/dw-git/SKILL.md` points at the bullets instead of
restating the subject shape and the trailer, keeping only what a pattern cannot express (mood, case,
length, the ticket prefix).

Defaults are asymmetric on purpose. An absent `Commit pattern` means Conventional Commits, because a
project that installs the hook wants _some_ shape and that is the overwhelmingly common one. An absent
`Commit trailer` means `none`, because a requirement nobody declared must not start failing commits in
a repo that never asked for one — the hook ships to every repo `dw-init` scaffolds, and a guardrail
whose first act is to refuse ordinary work gets unwired that day.

## Consequences

**This is a second place the rule is written, and that is the cost.** `## Git conventions` describes
the commit style to a reader; the bullet states it to a parser. They can disagree, and nothing detects
it — the same class of drift decision 0006 was written to kill. What buys it back is that the parser's
copy is _executable_: a divergence between the bullet and reality surfaces as a refused commit within
minutes, where a divergence between two prose copies surfaces never. The prose was also trimmed rather
than left whole, so the overlap is a pointer, not a duplicate.

**A machine-readable rule must be a rule a machine can read.** Prose can say "lowercase, imperative,
no trailing period, ≤72 chars, and use a ticket prefix on ticket branches"; an ERE cannot express mood
and would be unreadable expressing the rest. So the split is deliberate and permanent: the bullet
carries what a regex can decide, `dw-git` carries the judgment. That boundary is also where the two can
contradict each other — a `[TICKET-123] ` prefix and a `^(feat|fix|…)`-anchored pattern cannot both be
satisfied, and `dw-git` now says to name the contradiction rather than fight the hook.

**Adding a fifth policy is now a known shape, not a design question**, which is the main thing this
buys: a bullet, the shared resolution helper, a `none` sentinel, a default in the script, and a case in
the self-test. `docs/agents/tooling.md` documents the order once for all four.

The rejected option — inferring from `## Git conventions` — was not rejected because it is unworkable.
It was rejected because the inference is _silent when it fails_. A section renamed, a bullet reworded,
a trailer written as a sentence instead of a list item, and the hook derives a rule nobody wrote and
enforces it, or derives nothing and enforces nothing. Neither failure announces itself, and both are
worse than the duplication.
