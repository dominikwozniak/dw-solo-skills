---
name: dw-check
description: >-
  A fast, optional quality gate over the change in progress: delegate to an outside reviewer when
  asked for one, else a quick two-axis self-review — correct? fits this repo? — findings at
  real file:line, fixed in-session after approval. Repeatable mid-build; writes no artifact. Use
  when the work so far deserves a look, or when someone says "review this", "check this", "quick
  QA". Prefer this over a multi-auditor review pipeline.
argument-hint: "bare checks the change's diff · codex delegates the pass · a path or topic narrows the focus"
---

# dw-check — a fast look, then fixes

The solo QA gate is optional and cheap on purpose: at this cadence a review you can afford to run
twice mid-build beats a thorough one you only dare run at the end. It finds problems while the diff
is still small; the closing pass stays a thin last look, not a bottleneck this skill duplicates.

## What it reads

The diff against the default branch — read that branch from `## Git conventions`, don't assume
`main`, and prefer `origin/<default-branch>` when it exists (a stale local default makes the
merge-base older than the branch point, so the diff swallows commits you didn't write). Plus the
change's `CHANGE.md` for the goal, found by branch the same way `dw-next` finds it. `$ARGUMENTS` is
read two ways, and this is the one skill in the catalog that mixes them: the single word **`codex`**
switches mode (step 2), and anything else — including whatever follows that word — narrows the focus
to a path or a topic.

It writes **no `.ai/` artifact** — approved fixes land as code commits, and a gate you re-run
freely doesn't need a report file rotting between runs.

## Workflow

### 1. Establish the diff

`git diff <default-branch>...HEAD` plus `git log --oneline <default-branch>..HEAD`, narrowed by the
focus part of `$ARGUMENTS` when given — `codex` is a mode, never a path. Read the `CHANGE.md` goal so
findings are judged against what the change is trying to do, not against taste.

### 2. Delegate only when asked for it

**Bare does not delegate, and does not nag.** Go straight to step 3. The `argument-hint` already
advertises the option at the moment of typing, so a bare run that lobbies for a second opinion just
taxes the cheap path.

**On `codex`**, hand the same diff to the `openai-codex` plugin. Two paths, and they are not
interchangeable:

- **`codex:rescue`** — model-invocable, so **this skill can run it itself**: the `codex:rescue`
  command forwards to the `codex:codex-rescue` subagent via the `Agent` tool. No round trip through
  the user. This is the default for `codex`.
- **`/codex:review --wait`** — the purpose-built reviewer, and the richer report. It is
  `disable-model-invocation: true`, so **no skill can run it** — ask the user to type it by name when
  the diff deserves the better tool, and wait for the findings to land in the conversation.

Either way the findings fold into step 3's report. `codex:rescue` returns Codex's output verbatim by
its own contract, which pulls against that: **quote it verbatim, then verify each finding against the
file before it counts.** A delegated finding is still a finding that has to point at a real
`file:line` — an outside reviewer earns no exemption from step 3, and its line numbers are the first
thing to check.

If codex is installed but not ready, `/codex:setup` is the fix — it checks the CLI and auth. Any other
installed reviewer that takes a diff and returns findings folds in the same way. When nothing of the
kind is installed, say so in one line and self-review; this skill never depends on one being there.

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
