---
decision: 0006
status: active # active | superseded
date: 2026-08-12
---

# 0006 — A check whose only job is comparing two hand-kept copies is deleted with the copy, and the durable layer is capped by count

## Context

This repo had reached 9804 words of documentation across seven files, 11 812 words of skill bodies,
21 `## Gotchas` entries and 12 backlog files — and a validator layer whose job was largely to notice
when one hand-kept copy of a rule drifted from another. `validate-docs.sh` check 5 compared each
README Arguments cell to the skill's own `argument-hint`; check 6 compared the pre-push gate across
three markdown files. `check-decisions.sh` was 489 lines of script, self-test and dogfood pass over
229 lines of records. `validate-evals.sh` guarded a one-file-per-skill contract that a checklist line
states as well.

Every one of those grew for a good local reason: something drifted, so a check was added. Nothing was
ever the place a copy or a stale entry came out, so both piles only grew.

## Decision

Two halves of one stance.

**A validator that exists to compare two copies is deleted along with the second copy.** Where a fact
has an environment-owned home — `package.json` scripts for the gate, `argument-hint` for a skill's
arguments — that home is the single source and no markdown restates it. Where it does not, the fact is
stated once in the file that is actually read at the moment it applies (the decision-record contract
lives in `skills/dw-land/references/decision-record.md`, which `dw-land` reads while writing a record;
the two READMEs point at it).

**The durable layer is capped by entry count, enforced in `validate-artifacts.sh`**: `## Gotchas` ≤ 12
entries, `.ai/backlog/` ≤ 8 files. Counting entries, not bytes. `dw-land` phase 3 is the counterpart —
promotion now reads its target and deletes what the change supersedes, so a full list can still take a
new trap by merging it into the cousin it belongs with.

## Trade-off

**Silent breakage comes back, and that is the price.** A malformed decision record, a case file with
no skill, a README cell that stops matching its hint — each will now sit unnoticed until someone reads
the file. The bet is that one reader who wrote the thing last week notices faster than 489 lines of
parser justify, and that three of the last six PRs being about the contract rather than the work is
the real cost signal. In a repo with a second reader this is the wrong call: enforcement is how you
buy trust you cannot get by asking.

The caps have a sharper edge. A cap is a forcing function only if the merge-or-retire work actually
happens; if it does not, the honest failure is a build that stays red, and the dishonest one is a trap
deleted to make room. `dw-land` states the three ways out in order — bundle, absorb, retire — so the
lazy fourth option is at least named as the wrong one. The number itself (12 and 8) is arbitrary and
chosen to be _reachable today_: it bites immediately rather than after another year of growth.

Rejected alternative: `.ai/work/eager-doc-size-budget/` proposed a `PostToolUse` hook enforcing a
declared per-file line and byte budget. A size limit cannot see duplication — you can sit under budget
and still say a thing twice — and it wanted a hook, a self-test, a payload copy, a settings wire and a
version bump to enforce a number that change's own decisions concluded this repo would never declare.
Archived `status: rejected` with the reasoning.

## Revisit when

A second person reads this repo's PRs — then the enforcement half is wrong and should come back before
the trust does. Or when a cap has been raised twice without a merge attempt in between: that means it
is being treated as a quota rather than a forcing function, and a number nobody defends is worse than
no number.
