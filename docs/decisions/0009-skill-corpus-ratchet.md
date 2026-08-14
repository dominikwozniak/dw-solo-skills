---
decision: 0009
status: active # active | superseded
date: 2026-08-14
---

# 0009 — the skill corpus is governed by a ratchet against its own past, not by a threshold

## Context

`skills/*/SKILL.md` went from 11 116 words to 13 243 in three days. The 11 116 was recorded on purpose
by `de-ratchet-the-solo-lane` and then stopped being anybody's job. Nothing measured it, and the one
mechanical check that looks at skill size is decoration: agnix `AS-012` fires at 500 body lines while
the largest skill is 228, and **agnix warnings do not gate at all** — `scripts/lint.sh` exits 0 with
51 of them, one of which (`CLAUDE.md` over agnix's token limit) has been true and ignored the whole
time `validate:docs` called the same file green in a different unit.

This invokes the revisit condition the rejected `eager-doc-size-budget` change left behind —
"evidence that an eager file grew past the point of being read" — while rejecting that change's
mechanism, which was a hook.

## Decision

`scripts/skill-corpus.baseline.json` records what the corpus **is**; pass 3 of
`scripts/validate-artifacts.sh` fails when it is larger, naming the skills that account for the delta.
Growth stays legal and costs one `--update-baseline` in the same commit.

No number is chosen, so no number can be set too high. That is the whole argument, and it is what
makes this different from `0008`'s budget: a budget is a ceiling somebody picked, a ratchet is a
comparison against yesterday.

The unit is **words**, because prettier reflows Markdown at 100 columns — lines and bytes move on a
pure reformat and words do not. Demonstrated rather than assumed: unwrapping one `SKILL.md` and
letting prettier reflow it moved 80 lines → 66 → 68 and one byte, with the word count fixed at 699.
ASCII whitespace only, so the count equals `cat skills/*/SKILL.md | wc -w` under the `LC_ALL=C` the
gate exports; JavaScript's `\s` would count an NBSP as a separator and report a phantom +1 the
documented command cannot see.

Repo tooling, never shipped — no hook, no `templates/` payload, no plugin version bump. That is
`0008`'s cost test, and it is met because the checker is not payload.

## Trade-off

**Every commit that adds or grows a skill now touches two files.** The baseline is a second edit on a
path that used to need one, and a squash-merge carries a re-record that a reader has to accept or
contest. That is the friction, and it is the mechanism rather than a side effect: it forces the choice
an append skips.

**The ratchet is blind to compensating change.** It governs the corpus total, so one skill growing 200
words passes if another shrinks 200. `perSkill` is recorded and reported but not enforced per file.
A per-skill ratchet would close that and would also fire on every ordinary edit that moves prose
between two skills — which is a refactor, not growth.

**Rejected: lowering `AS-012`.** Not a preference — it cannot be done. `agnix schema` exposes no
numeric knob (`rules.<category>` is a boolean, `disabled_rules` a list of IDs, `[[overrides]]` only
_disables_ rules for a glob, `severity` sets a reporting floor); the rule is per file while the growth
was spread across 11 of them; and warnings do not gate anyway. A threshold can be turned off, never
turned down.

**Rejected: a tolerance band.** A percentage would put the taste number straight back in.

## Revisit when

Any one of these:

- **A re-record passes unread three times running** — if the baseline bump becomes a line nobody
  contests, the ratchet has become a rubber stamp and deleting it is cheaper than running it. This is
  the same failure `de-ratchet-the-solo-lane` removed 489 lines of enforcement over.
- **A compensating swap hides real growth** — one skill gains more than ~200 words while the total
  holds. Then the ratchet belongs per file, and the `perSkill` map it already records is the input.
- **agnix gains a configurable size threshold.** Then this checker is duplicate machinery and the
  platform should own it.
