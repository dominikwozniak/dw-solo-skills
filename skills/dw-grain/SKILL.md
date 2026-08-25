---
name: dw-grain
description: >-
  Audit code just written for excess the gate cannot see: a helper reinvented beside its canonical
  home, a wrapper with one caller, config for a case that never occurs, a shape the neighbouring
  files build differently, code this change stranded. One table, and every row is a deletion or a
  reuse. Explicit-invoke only.
argument-hint: "bare audits everything new since the merge-base · a path, a ref range or a PR number narrows it"
disable-model-invocation: true
---

# dw-grain — working code is not the same as code worth keeping

Everything else that runs over a finished change asks whether the code is right. Lint, the formatter,
the type checker, the tests, the review pass: all of them pass code that never needed to be written.
An agent building against a checklist reaches for a new helper faster than for the one already in the
tree, because writing is cheaper than searching — and the result compiles, passes and reads fine.

Every category below has exactly one remedy: delete it, or call what is already there. That is
structural rather than a stated preference. A category allowed to propose an abstraction would spend
the pass inventing the thing the pass exists to find, and anything asked for improvements returns
improvements. None of them can, so the table cannot grow the codebase.

## What it reads and writes

**Reads wide, judges narrow.** As input: the whole of every file the change touched, not the hunks;
their neighbours in the same directory; the canonical home the project keeps for helpers of that kind;
and whatever the repo declares about itself — a root `AGENTS.md` or `CLAUDE.md`, the topic files its
router points at, a `CONTEXT.md` glossary, a decision record covering this code. As **judgeable**:
only what the change wrote. Every row has to be fixable by changing the new code, which is what keeps
a wide read from becoming a tour of the repo's older sins.

Scope comes from git, never from a change doc. Bare takes the merge-base against the default branch —
both the branch and the ref of it resolved the way `dw-git` does — and reads the files
`git diff --name-only <base>...HEAD` names. `$ARGUMENTS` narrows or replaces that: a path takes that
subtree, a ref range takes that range, a PR number takes that PR's files. It reads **no `.ai/`
artifact at all** — no lane, no `CHANGE.md`, no goal — so it runs in a repo that has never seen this
loop, over a directory, or over a branch that merged months ago.

Phase one writes nothing. Phase two writes the deletions you named, as code commits, and **no `.ai/`
artifact** — a table you act on in the same session needs no file to rot between runs.

## Workflow

### 1. Resolve the scope, then read past it

Open each file in scope whole, and open its neighbours: the audit turns on what already exists, and a
hunk cannot tell you that. Before judging anything, find where this project keeps the kind of thing
the change added — the utility module, the service layer, the shared types — because "reinvented" is
unprovable without it.

### 2. Five categories, each with its remedy fixed

- **Reinvented** — a helper that already exists, written again somewhere else. Search on the new
  code's **job**, not its name: the name is what makes the duplicate invisible. Remedy: **reuse** —
  delete the new one, call the existing one.
- **Pass-through** — a wrapper, adapter or indirection with one caller that adds nothing of its own
  beyond forwarding. Remedy: **delete** it and inline it at that call site.
- **Speculative** — a flag, option, parameter or mode carrying a case that never occurs: every call
  site passes the same value. Remedy: **delete** the parameter and the branch it feeds.
- **Drift** — the change builds something the neighbouring files already build another way: a
  different error shape, a second name for one concept, the same kind of logic in a different layer.
  Remedy: **reuse** the neighbours' shape. The direction is fixed and does not depend on which is
  better — the neighbours win, because one inconsistency is paid by every later reader.
- **Stranded** — what the change made unreachable and left behind: the branch nothing takes now, the
  import nothing uses, the export with no consumer, a comment describing behaviour that is gone.
  Remedy: **delete**.

All five run over every file in scope, and the pass is not finished until they have. A category you
never applied returns the same empty table as a category that found nothing, and nothing downstream
can tell those two apart.

### 3. The gate a row passes before it is written

- **Quote it, or it does not exist.** Every row carries `file:line` plus the verbatim text that
  motivated it. Reinvented and drift carry **two** quotes — the new code, and the canonical or
  neighbouring code it should have used. A "this already exists" claim with nothing quoted on the
  other side is the exact false positive this gate is built for. Cannot produce both? **Drop the
  row.** Not soften it, not report it as possible — this lane has no appendix to hide a weak row in.
- **The repo's own conventions suppress.** A shape the project has declared for itself is not a row,
  however it reads: a pattern its root agent file prescribes, a term its glossary defines, a
  duplication a decision record already settled as deliberate. Read those in step 1 so the
  suppression happens before the table, not after you have argued for the row.
- **Whatever a tool already enforces is not a row.** Formatting, import order, lint rules, type
  errors: the project's own commands catch those, and they belong in somebody else's commit.
- **Correctness belongs to `dw-check`, and the remedy column is what enforces that.** A row saying
  the code is _wrong_ — a missed edge case, an absent guard, an error path that throws — is that
  skill's, and filing it here produces a table nobody can act on. The test is mechanical: if the fix
  is anything other than deleting code or calling code that already exists, it is not a row. Same
  verdict for "I would have built it differently" with no existing thing to point at, which is a
  proposal rather than a finding.

### 4. One table, then stop

```
## dw-grain — <N> rows over <scope>

| # | Category     | Location      | What is there                                        | Remedy                                      |
| - | ------------ | ------------- | ---------------------------------------------------- | ------------------------------------------- |
| 1 | reinvented   | src/f.ts:41   | `parseWindow()` re-derives what `lib/time.ts:88` returns | call `lib/time.ts:88`; delete 41-63     |
| 2 | pass-through | src/bar.ts:12 | `wrapClient()` forwards to `Client`, one caller      | delete; inline at `src/baz.ts:30`           |

Suppressed: <n> — one line each, naming the convention or record that blessed it.
```

Order by the size of the deletion, the only thing a table like this can honestly rank by. Then
**stop — nothing is fixed without being named.** "No rows" is a common and correct answer: say it
plainly, because a pass that always finds something is a pass that invents something.

### 5. Fix the rows you were given, and only those

The rows you were not given were declined, not deferred — do not carry them into the commit or
re-raise them after. Commit the way `dw-git` does: independent deletions apart, related ones together.
Then run the project's tests, which matters more here than the edit size suggests — every remedy in
this table is a deletion or a re-pointed call, the one shape of edit that compiles cleanly and fails
at runtime. Offer to run the pass again afterwards, since a deletion often strands the next thing.

**Next:** `dw-check` if something looked wrong rather than merely surplus, or `dw-land` once the diff
is what you mean to ship.
