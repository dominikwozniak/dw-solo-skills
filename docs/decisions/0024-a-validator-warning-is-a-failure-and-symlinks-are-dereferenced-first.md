---
decision: 0024
status: active # active | superseded
date: 2026-09-05
---

# 0024 — A validator warning is a failure, and the tree it reads is dereferenced first

## Context

`claude plugin validate` reads a plugin's components without following symlinks, and every
component this repo ships is one. Run against `plugins/<p>/.claude-plugin/plugin.json` it opened
none of the twelve skills, printed "6 entries here are symlinks and were not read", and exited 0.
`validate-manifests.sh` read only that exit code, so the gate reported green on the corpus the repo
exists to hold — for as long as the gate had existed. The validator's own message names the way
out: "validate the real paths separately."

## Decision

Each `plugin.json` is validated through a `cp -RL` copy rather than in place, and a warning fails
the run alongside an error. Warnings are the reason to run the validator at all — a skill with no
description and a misspelled manifest field both exit 0 — so a gate that reads the exit code alone
cannot report what it found.

## Trade-off

CI is now bound to an external tool's warning vocabulary. A warning class Anthropic adds later
turns this repo red without a commit of ours, and the fix will be a judgement call each time:
satisfy it, or carve it out. That was accepted over the alternative of an allow-list keyed to
warning text, which decays silently in the other direction — a carve-out written for the symlink
warning would have gone on suppressing the real ones after dereferencing removed its cause.

The copy also costs a full plugin tree per manifest per run, `templates/` included. It is bounded
and local, and buys the only reading of the skills that CI gets.

## Revisit when

A warning arrives that this repo cannot satisfy and should not have to — the first time the honest
answer is a carve-out rather than a fix. At that point the choice is a keyed allow-list with an
expiry, not a return to gating on the exit code.
