---
decision: 0008
status: active # active | superseded
date: 2026-08-13
supersedes: 0006
---

# 0008 — The always-loaded root is held by a declared budget and a Task Router, not by a cap on how many traps it may hold

## Context

[`0006`](0006-delete-the-second-copy-and-cap-the-pile.md) capped `## Gotchas` in `AGENTS.md` at 12
entries, and it worked as designed: the pile stopped growing. What it could not do is distinguish
_the file is too big_ from _this file holds too many traps_. Only the root was ever capped, because
the root was the only place a trap could go, so every trap competed for the same twelve slots
regardless of subject — and the way to stay under the number was to merge two unrelated traps into
one entry with sub-bullets. The entry about worktrees ended up holding six.

Meanwhile the real cost was never the trap count. It was that 288 lines of boundaries, procedure and
traps loaded in full at the start of every session, whatever the task touched.

## Decision

**The root declares its own budget — `Budget: **120 lines / 10 KB**` in its header prose — and a
`## Task Router` names the topic file for each subject.** Procedure and traps live in
`docs/agents/<topic>.md`, loaded on demand. Over budget is never resolved by trimming a rule: a topic
moves out and earns a router row, in the same commit.

**Gotchas move to the topic file their router row names, and are no longer counted.** A trap about
prettier belongs beside the other tooling traps, where it is read only by someone already fighting
tooling. The growth discipline that the cap enforced mechanically is now stated in
[`docs/agents/README.md`](../agents/README.md) and held by hand: retire what stopped being true,
merge genuine cousins.

**The check is the checker we already ship.** `scripts/validate-docs.sh` runs
`templates/check-agents-docs.mjs` — the file `dw-init` scaffolds into consumer repos — against this
repo's own root, rather than reimplementing the budget and router-coverage checks in bash.

**What `0006` decided that still stands**, restated here because the contract has no partial
supersession and flipping that record must not read as reopening it: a validator whose only job is
comparing two hand-kept copies is still deleted along with the copy, and `.ai/backlog/` is still
capped by entry count at 8 in `validate-artifacts.sh`. Only the gotcha cap is replaced.

## Trade-off

**`0006` rejected exactly this, and the rejection was right about the thing it was judging.** It
turned down `.ai/work/eager-doc-size-budget/` on two grounds: a size limit cannot see duplication,
and that proposal wanted a `PostToolUse` hook, a self-test, a payload copy, a settings wire and a
version bump to enforce a number the repo had concluded it would never declare. Both objections are
answered by _what changed underneath_ rather than by argument. The enforcement costs nothing new —
`check-agents-docs.mjs` already ships for the scaffolder's sake, and one call from a script already
in the gate is the whole wiring, no hook and no bump. And the budget is not a bare size limit: it is
paired with a router, so being over it has a defined resolution — move the topic, add the row —
instead of the "say less" the earlier proposal offered.

The first objection stands unanswered and is the price. **A budget still cannot see duplication:**
the root can sit at 117 lines and say something a topic file already says in full, and nothing will
complain. `0006`'s single-source rule is what covers that, which is why it is restated above rather
than retired.

**The second price is that trap growth is now unbounded per topic.** Six topic files each free to
grow is how a corpus rots quietly, and the honest failure mode is a `docs/agents/tooling.md` nobody
finishes reading. The bet is that a file loaded only by someone already working on its subject can
afford length in a way the always-loaded root never could.

## Revisit when

A topic file gets long enough that its own `## Gotchas` needs skimming rather than reading — then the
cap was right and belongs back, scoped per file rather than to the root. Or when the root has been
compressed twice to stay under 120 lines without a topic moving out: that means the budget is being
paid in shortened rules, which is precisely what it exists to prevent.
