---
name: dw-check
description: >-
  A second opinion on the diff so far, mid-build: what is wrong with it, and does it fit this
  repo? One quick pass reads the diff here, and an outside reviewer — codex — is offered afterwards
  as confirmation rather than run by default; every mistake either one names is verified at a real
  file:line before it counts, then fixed in-session on your approval.
argument-hint: "bare reviews the diff here · codex adds the outside pass without asking · a path or topic narrows the focus"
---

# dw-check — a fast look, then fixes

**The review step, repeatable mid-build.** Run it while the diff is small.

## What it reads

The diff against the default branch — the ref `bash "${CLAUDE_PLUGIN_ROOT}/scripts/base-ref.sh"` prints — plus
the branch's `CHANGE.md` goal, so findings are judged against what the change is trying to do, not
against taste. The argument is read two ways: the single word `codex` adds the outside pass without
asking first, and anything else narrows the focus to a path or a topic. It writes no `.ai/`
artifact — approved fixes land as code commits.

## Workflow

### 1. Establish the diff

`git diff <base>...HEAD` plus `git log --oneline <base>..HEAD`, narrowed by the focus when given.

### 2. Read the diff yourself — two axes, judged separately, never merged into one score

Every run, whatever else follows, and **with this skill's own prose in the main thread** — never
`/code-review`, `/simplify` or `/security-review`, never a subagent, never an effort level. The
filter below is what bounds it.

- **Correct?** — does the diff do what the goal says: edge cases, error paths, the empty input.
- **Does it fit?** — compared against the neighbouring code, not best practice in the abstract.

Every finding points at a real `file:line` you opened — if you can't ground it, don't report it.
"No findings on either axis" is a normal, useful answer; say it plainly and stop. Then filter, and
name what you dismissed, one line each:

- All nits means the diff is probably fine — lead with that conclusion, nits after it.
- "I would have done it differently" is not a finding until it names a concrete problem with this.
- More than five things to act on means the filter is too loose — except correctness and security,
  which earn more scrutiny before dismissal, not less.

### 3. Present, wait — and offer the outside pass in the same breath

List the findings with a severity-ordered recommendation and **stop — nothing is fixed and nothing
is delegated without approval.** Above the triviality floor — more than 2 files **or** 50-plus lines from
`git diff --shortstat` — that same stop carries one more line: `codex:rescue` can re-read this,
worth it? Below the floor, don't ask. `codex` in the argument skips the ask, and no plugin installed
drops it; neither costs a line of explanation, because the verdict is already in.

### 4. The second opinion, then the fixes

Only on your yes, or on `codex`: hand the diff to `codex:rescue`, passing no model and no effort —
the codex config decides both. **Verify every finding it names against the file before it counts** —
line numbers are the first thing to check — then quote what survives verbatim, say what didn't
ground, and fold the rest into step 2's list. `/codex:review --wait` is the richer pass you type
yourself; name it when the diff deserves more than a re-read.

Then, on approval, fix in-session and commit per `## Git conventions` — related fixes together,
unrelated apart. Then offer to run again; the second look is the point of a gate this cheap.

**Next:** `dw-next` for the next task, `dw-land` when nothing is pending, or `dw-grain` where
`dw-solo-extras` is installed.

$ARGUMENTS
