---
decision: 0012
status: active # active | superseded
date: 2026-08-17
---

# 0012 — Bare `dw-check` delegates to an outside reviewer; a triviality floor is the only way out

## Context

Delegation was opt-in: you typed `codex` or you got the self-review. The reasoning, recorded in
`.ai/archive/2026-08-05-shape-splits-changes/`, was that the `argument-hint` advertises the option at the moment
of typing, so a bare run lobbying for a second opinion just taxes the cheap path.

That is true about nagging and wrong about defaults. The cross-model pass is the only thing this gate
adds over re-reading your own diff — the two axes are a reading discipline you already have — and an
option you have to remember is an option that goes unused. The failure mode was never a noisy prompt;
it was the pass silently not happening.

## Decision

Bare `dw-check` hands the diff to `codex:rescue` whenever the codex plugin is installed, without
asking. Two degradations, each of which **says so in a line** rather than skipping quietly: a trivial
diff self-reviews, and a missing plugin self-reviews with the install named. `codex` demotes from a
mode switch to an override of the triviality floor, and of nothing else — it cannot conjure a plugin
that is not there.

## Trade-off

The cheap bare path is gone, and it was worth something: a gate whose selling point is being cheap
enough to run twice now spends a subagent round trip on every non-trivial run, in every repo that
installs the plugin. The floor bounds that; it does not remove it.

The floor is also an **arbitrary threshold**, in a repo that otherwise refuses to pick one — the
corpus ratchet exists specifically so no number has to be chosen, and this change chooses two. Some
diff will sit just the wrong side of them.

And the behaviour ships. Consumers get it at `dw-solo` 0.4.22, so reversing it is another version and
a second behaviour flip for anyone already installed.

The rejected option was keeping delegation opt-in and nagging on a bare run. That is precisely what
the previous shape removed on purpose, and re-adding it trades an unused feature for an ignored
prompt — the same pass still fails to happen, with more words. [`0011`](0011-bare-dw-next-builds-rather-than-reports.md)
made the sibling call for `dw-next` on the same reasoning: a step whose default withholds its own
value is ceremony, not safety.

## Revisit when

You cancel or discard a bare run's delegated pass twice as not worth the wait — or the floor starts
arguing with itself, which shows up as typing `codex` on sub-floor diffs, or sitting through a
delegated pass on a diff barely above it.
