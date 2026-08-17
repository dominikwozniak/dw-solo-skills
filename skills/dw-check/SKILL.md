---
name: dw-check
description: >-
  A fast, optional quality gate over the change in progress: the diff goes to an outside reviewer
  by default, or to a quick two-axis self-review — correct? fits this repo? — when it is trivial or
  none is installed. Findings at real file:line, verified, then fixed in-session after approval.
  Repeatable mid-build; writes no artifact. Use when the work so far deserves a look, or when
  someone says "review this", "check this", "quick QA". Prefer this over a multi-auditor review
  pipeline.
argument-hint: "bare delegates the pass · codex forces it on a trivial diff · a path or topic narrows the focus"
---

# dw-check — a fast look, then fixes

**This is the review step, and it is repeatable mid-build.** Run it twice while the diff is small;
`dw-land`'s closing verdict stays a thin last look and never grows a reviewer of its own.

## What it reads

The diff against the default branch — both the branch and **the ref of it** resolved the way `dw-git`
does, never `origin/` by reflex; `<base>` below is that ref. Plus the change's `CHANGE.md` for the
goal, found by branch the same way `dw-next` finds it. `$ARGUMENTS` is read two ways, and this is the
one skill in the catalog that mixes them: the single word **`codex`** forces the delegated pass past
the triviality floor (step 2), and anything else — including whatever follows that word — narrows the
focus to a path or a topic.

It writes **no `.ai/` artifact** — approved fixes land as code commits, and a gate you re-run
freely doesn't need a report file rotting between runs.

## Workflow

### 1. Establish the diff

`git diff <base>...HEAD` plus `git log --oneline <base>..HEAD`, narrowed by the
focus part of `$ARGUMENTS` when given — `codex` is a mode, never a path. Read the `CHANGE.md` goal so
findings are judged against what the change is trying to do, not against taste.

### 2. Delegate by default, above a floor

**Bare delegates.** The second model is what this gate adds over reading your own diff again, and
gating that on a word you have to remember is how it went unused — so hand the diff to `codex:rescue`
whenever the codex plugin is installed, without asking first.

Two things send the diff to step 3 unassisted, and each costs **one line saying so**, never a silent
skip:

- **A trivial diff** — 2 files or fewer **and** under 50 lines touched, from
  `git diff --shortstat <base>...HEAD` (insertions plus deletions). A typo or a copy edit is not
  worth the round trip; anything above the floor is.
- **No reviewer installed** — self-review, plus the fix in that same line:
  `/plugin marketplace add openai/codex-plugin-cc`, then `/plugin install codex@openai-codex`. Where
  the plugin is there but not ready, `/codex:setup` is the fix instead — it checks the CLI and auth.
  Any other installed reviewer that takes a diff and returns findings folds in the same way, and
  **this skill never depends on one being there.**

**`codex` overrides the floor, and only the floor** — it forces the pass on a two-line diff, and it
cannot conjure a plugin that isn't installed.

Two paths into the plugin, and they are not interchangeable:

- **`codex:rescue`** — model-invocable, so **this skill can run it itself**: the `codex:rescue`
  command forwards to the `codex:codex-rescue` subagent via the `Agent` tool. No round trip through
  the user. This is what bare uses.
- **`/codex:review --wait`** — the purpose-built reviewer, and the richer report. It is
  `disable-model-invocation: true`, so **no skill can run it** — name it for the user to type when the
  diff deserves the better tool, and wait for the findings to land in the conversation. Its moment is
  a change that already has an open PR — `dw-land` opens one before the merge decision, and that
  window is what the richer pass wants.

Either way the findings fold into step 3's report. `codex:rescue` returns Codex's output verbatim by
its own contract, which pulls against that: **quote it verbatim, then verify each finding against the
file before it counts.** A delegated finding is still a finding that has to point at a real
`file:line` — an outside reviewer earns no exemption from step 3, and its line numbers are the first
thing to check.

### 3. Two axes, judged separately

Whether delegated or self-reviewed, weigh two things and **report them side by side, never merged
into one score** — a fit problem must not hide behind "it's correct":

- **Correct?** Does the diff do what the goal says? Edge cases, error paths, the empty input, the
  call that fails. Anything actually broken.
- **Does it fit?** Compare against the neighbouring code, not best practice in the abstract. A
  pattern used once elsewhere in this repo beats a better pattern used nowhere in it.

Every finding points at a real `file:line` you opened — if you can't ground it, don't report it.
"No findings on either axis" is a normal, useful answer; say it plainly and stop.

### 4. Present, wait, then fix

List the findings with a severity-ordered recommendation and **stop — nothing is fixed without
approval.** On approval, fix the accepted findings in-session and commit the way `dw-git` does —
related fixes together, unrelated ones apart. Then offer to run again: the second look is the
point of a gate this cheap.

**Next:** `dw-next` for the next task, or `dw-land` when the boxes are all ticked.
