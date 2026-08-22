---
decision: 0013
status: active # active | superseded
date: 2026-08-19
---

# 0013 — A validator whose subject is git history gets a self-test; the disk validators still don't

## Context

This repo does not test its own CI validators. `validate-docs.sh` and `validate-manifests.sh` have no
`scripts/tests/` file, stated as deliberate in `.ai/archive/2026-08-02-skill-routing-evals/`: what they assert is
visible by looking, and `scripts/tests/` is for the shipped runtime scripts and the guardrail hooks.
`de-ratchet-the-solo-lane` went further and deleted `check-decisions.sh` outright — 489 lines of
enforcement over 229 lines of records, in a repo with one reader who does not need a parser to notice a
malformed record they just wrote.

`validate-versions.sh` is 184 lines and its self-test is 242. That is the same ratio, and the same
instinct should apply.

It doesn't, because the two validators differ in kind rather than degree. A disk validator's inputs are
the files in front of you: you can read `validate-manifests.sh`, look at `plugins/`, and confirm the
answer. This one's input is **two refs and the relationship between them** — the interesting case needs
a base tip that has moved since the branch forked, a state that does not exist in any working tree and
cannot be inspected by reading. `717f1e5` is the standing local proof that a validator passes silently
while broken.

## Decision

The distinction is **what the validator's subject is**, not how long it is. A validator over the tree on
disk gets no self-test. A validator over git history — two refs, a merge base, a state you cannot check
out — gets one, and the test builds a real throwaway repository rather than mocking git.

The bar the test has to clear is that its cases are **non-vacuous**: each was confirmed by mutating the
checker back to the broken behaviour and watching exactly that case fail. `number-already-taken-on-main-fails`
is the one that carries the design — swapping the version lookup from the base tip to the merge base
breaks it and nothing else.

## Trade-off

242 lines of fixture is now the largest test in the repo for one of the smallest scripts, and it is
exactly the shape `de-ratchet-the-solo-lane` deleted. If the distinction drawn here turns out to be a
rationalisation, this is 242 lines of the thing that change removed, growing back.

It also creates a second precedent to keep straight. "We don't test validators" was one sentence; "we
don't test validators unless their subject is history" is a sentence plus a judgement call, and the next
validator will have to be argued about rather than assumed.

The rejected option was a `## Gotchas` entry describing the two-ref asymmetry and trusting the reader.
That is what the previous state of this repo already had for the unbumped-payload failure — a documented
trap, faithfully recorded — and it was relied on by three separate landed changes and silently missed by
a fourth. A trap a careful reader must remember is the failure mode this change exists to end; replacing
it with a differently-worded trap would have been the same bet twice.

## Revisit when

A disk validator here acquires a self-test, which would mean the line drawn is not the one being used —
or this test starts failing for reasons unrelated to the checker (git version drift, fixture rot), which
would mean it is testing the fixture rather than the logic.
