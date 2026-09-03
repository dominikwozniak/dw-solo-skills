---
name: dw-check
description: >-
  A fast, optional quality gate over the change in progress: the diff goes to an outside reviewer,
  or to a quick two-axis self-review — correct? fits this repo? — when the diff is trivial or no
  reviewer is installed, with findings at real file:line, verified, then fixed in-session after
  approval.
argument-hint: "bare delegates the pass · codex forces it on a trivial diff · a path or topic narrows the focus"
---

# dw-check — a fast look, then fixes

**The review step, repeatable mid-build.** Run it while the diff is small; `dw-land`'s closing
verdict stays a thin last look and never grows a reviewer of its own.

## What it reads

The diff against the default branch — the ref `bash "${CLAUDE_PLUGIN_ROOT}/scripts/base-ref.sh"` prints — plus
the branch's `CHANGE.md` goal, so findings are judged against what the change is trying to do, not
against taste. `$ARGUMENTS` is read two ways: the single word `codex` forces the delegated pass
past the triviality floor, and anything else narrows the focus to a path or a topic. It writes no
`.ai/` artifact — approved fixes land as code commits.

## Workflow

### 1. Establish the diff

`git diff <base>...HEAD` plus `git log --oneline <base>..HEAD`, narrowed by the focus when given.

### 2. Delegate by default, above a floor

Bare hands the diff to `codex:rescue` whenever the codex plugin is installed, without asking — the
second model is what this gate adds. Two things send it to step 3 unassisted, each costing one
line saying so, never a silent skip:

- **A trivial diff** — 2 files or fewer **and** under 50 lines from `git diff --shortstat`.
  `codex` overrides this floor, and only this floor.
- **No reviewer installed** — self-review, naming the fix in the same line:
  `/plugin marketplace add openai/codex-plugin-cc`, then `/plugin install codex@openai-codex` —
  or `/codex:setup` when it's installed but not ready.

`/codex:review --wait` is the richer, user-typed pass — name it when the diff deserves the better
tool, ideally once `dw-land` has opened the PR. Either way, quote delegated findings verbatim,
then **verify each against the file before it counts** — line numbers are the first thing to check.

### 3. Two axes, judged separately — never merged into one score

- **Correct?** — does the diff do what the goal says: edge cases, error paths, the empty input.
- **Does it fit?** — compared against the neighbouring code, not best practice in the abstract.

Every finding points at a real `file:line` you opened — if you can't ground it, don't report it.
"No findings on either axis" is a normal, useful answer; say it plainly and stop. Then filter, and
name what you dismissed, one line each:

- All nits means the diff is probably fine — lead with that conclusion, nits after it.
- "I would have done it differently" is not a finding until it names a concrete problem with this.
- More than five things to act on means the filter is too loose — except correctness and security,
  which earn more scrutiny before dismissal, not less.

### 4. Present, wait, then fix

List the findings with a severity-ordered recommendation and **stop — nothing is fixed without
approval.** On approval, fix in-session and commit per `## Git conventions` — related fixes together,
unrelated apart. Then offer to run again; the second look is the point of a gate this cheap.

**Next:** `dw-next` for the next task, `dw-land` when nothing is pending, or `dw-grain` where
`dw-solo-extras` is installed.

$ARGUMENTS
