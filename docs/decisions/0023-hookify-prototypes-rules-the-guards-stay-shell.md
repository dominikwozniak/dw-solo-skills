---
decision: 0023
status: active # active | superseded
date: 2026-09-05
---

# 0023 — hookify prototypes soft rules; the guardrails stay shell, tracked and self-tested

## Context

An audit of every hook surface in this repo asked whether the installed `hookify` plugin should carry
any of the guardrails. It is the obvious candidate: rules are a few lines of frontmatter instead of a
regex in bash, and it reaches two events this repo wires nothing on — `Stop` and `UserPromptSubmit`.

Three facts decided it. Its rules live in `.claude/hookify.*.local.md`, globbed relative to the working
directory and untracked by its own convention, so a rule is a fact about one machine — the exact
property `hooks-in-sync.test.sh` and the `templates/` payload exist to deny. Every one of its four hook
scripts ends in `sys.exit(0)` inside a `finally`, so a rule can deny a permission or print a message
but can never be the refusal an `exit 2` guard is. And its two shipped examples restate
`block-dangerous-commands.sh` and `block-env-access.sh`, which buys two refusal messages for one
command and two places to fix a pattern.

## Decision

The guardrails stay what they are: shell under `templates/hooks/`, copied byte-identical into
`.claude/hooks/`, wired in tracked `settings.json`, and pinned by a self-test that can fail. hookify is
used only where this repo wires nothing at all — `Stop` and `UserPromptSubmit` — and only for messages
that advise. Its examples stay disabled.

A rule that proves itself there is promoted: rewritten as a guard under `templates/hooks/` with a case
in `scripts/tests/`, where it ships to every scaffolded repo instead of sitting on one laptop. The
`.gitignore` entry that keeps the rules untracked is the reminder that nothing in that directory is
shipped, reviewed, or covered.

## Trade-off

Two events keep a second, weaker mechanism, and a reader now has to know which of two systems a given
message came from. That is a real cost and it is bounded by scope: nothing in hookify refuses anything,
so the worst a stale rule does is advise wrongly.

The rejected option was to adopt hookify for the soft, advisory checks that do not deserve a self-test
and let it grow from there. It fails on the same property that makes it attractive — a rule nobody
tracks is a rule nobody reviews, and the boundary between "advisory" and "guardrail" is exactly the
kind of line that moves one rule at a time.

Writing rules for it carries one trap worth stating once, because its own documentation gets it wrong:
the `event: stop` shorthand with a bare `pattern:` never fires. The shorthand binds the pattern to the
`content` field, which does not exist on a Stop payload, so the condition fails and the rule is silent.
Use `field: transcript` or `field: reason` with explicit `conditions:`.

## Revisit when

hookify's rules can be tracked and exercised by a test — or a rule written for `Stop` earns promotion
twice, which would say the boundary drawn here is in the wrong place.
