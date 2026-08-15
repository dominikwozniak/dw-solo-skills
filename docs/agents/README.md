# Agent docs — how this corpus works

Three tiers, three owners:

| tier                 | file(s)                                              | loads                                     |
| -------------------- | ---------------------------------------------------- | ----------------------------------------- |
| boundaries + routing | root `AGENTS.md` (`CLAUDE.md` is a symlink to it)    | every session, in full                    |
| topic rules          | `docs/agents/*.md`                                   | on demand, via the root Task Router       |
| change state + why   | `.ai/` (working memory), `docs/decisions/` (records) | never eagerly; the `dw-*` skills own them |

## What goes where

- **Root `AGENTS.md`**: only what applies to _every task regardless of what you touch_ — the
  boundary this repo keeps against `dw-skills`, the layout rule, the loop, the Commands block, the
  Task Router, and the two blocks the tooling reads directly: `## Solo lane` (whose
  `- **Lint command**:` line the `lint-on-edit` hook greps) and `## Git conventions` (which `dw-git`
  applies). It declares its own hard budget in its header prose, and `pnpm validate:docs` enforces
  exactly what that line says — so the number lives there and is not restated here. If a rule is
  topic-scoped it goes into a topic file and earns a router row instead. The budget caps only this
  one file; `docs/agents/*.md` are unbudgeted, which is where prose belongs.

  **What kind of number that is: chosen editorial discipline, not a harness ceiling.** Nothing
  truncates where it is set. The nearest real limit is Codex's `project_doc_max_bytes`, 32 KB, and the
  byte half is deliberately several times stricter than that — the point is a file a human rereads in
  one sitting, not a file a tool can ingest. The line half is the one that has ever bound, with far
  less headroom than the byte half, so every squeeze to date has been a line squeeze.
  `pnpm validate:docs` prints where the file currently stands; no copy of those figures is kept in
  prose, because two copies of a moving number drift apart. Treat a breach as the prompt to move a
  topic out, never as a licence to compress a rule into a shorter, vaguer one.

- **`docs/agents/<topic>.md`**: everything scoped to one topic — procedure, mechanics, and the
  traps that topic has actually sprung. One file per concept, sized to the concept; a 15-line file
  is fine. Each topic has exactly one authoritative file; related files cross-reference it, never
  duplicate it.
- **`docs/decisions/<NNNN>-<slug>.md`**: why the code is shaped this way. One numbered file per
  decision, append-only; `dw-land` writes them at close. The bar for writing one at all is in
  `docs/decisions/README.md`.

## Gotchas live here, not in the root

Every topic file carries its own `## Gotchas` — traps this repo has actually sprung, newest first.
That is a deliberate reversal: the root used to hold all of them under a hard count cap, and the cap
kept forcing unrelated traps to be merged into one entry to stay under the number. Scoped to a topic
file the pressure is gone, because the file is only loaded by someone already working on that topic.

The cost the cap was paying for is real, though, so keep it in mind without a validator: an entry
that stopped being true is deleted, and two entries with one root cause are one entry with
sub-bullets. Growth is fine; sprawl of stale traps is not.

## Gotchas

- **A header written to explain a fix is where a fact gets re-copied, because there it reads as
  context rather than duplication.** The commit after the one that made every fact live in exactly
  one file added a script header restating a caveat `.agnix.toml` and `.husky/pre-commit` already
  carried — three homes, written by the hand that had just finished deduplicating the doc layer.
  When a comment explains _why a fix was needed_, the background belongs to whatever file already
  owns it: name that file and stop. What the header may state is what its own file does.
- **Moving prose between files conserves entries while losing content, and counting proves
  nothing.** Splitting the root into this directory moved twelve gotcha entries and seventeen
  sub-bullets — every one of them accounted for, and four separate pieces of content gone anyway,
  each lost inside a paragraph that survived: an instruction dropped from a section that kept the
  fact it explains, a trap's "why" dropped from its "what". Reading the diff did not surface them
  either, because every hunk looked like a faithful move. What surfaced them was diffing the old
  file against the new corpus as a **word stream** — slide an 8-gram window over the old text and
  report windows absent from the union of the new files, then judge each miss. Do that before
  believing any large doc move.
  - **A line target buys itself out of the content, and the format gate cannot see the bill.**
    Compressing `templates/AGENTS.md` toward a shaped line count dropped `git fetch origin &&` from a
    rebase command — a payload teaching a rebase onto a stale ref, caught by a reviewer and not by any
    check. Prose has no compiler, so shrinking it is not refactoring: it silently trades tokens that
    matter for tokens that don't. Where a line count and a correct instruction conflict, the count is
    the thing to renegotiate — and a floor worth keeping is worth writing into the goal.
- **`CLAUDE.md` is a symlink to `AGENTS.md`, not a synced copy — and the symlink bites twice.**
  Claude Code's `Edit` tool **refuses to write through a symlink**, so an edit aimed at `CLAUDE.md`
  fails in a way that reads as a permissions problem rather than as "you named the wrong file". And
  a change doc that treats the two as separate files schedules the same edit twice, then reports the
  second one as already done. There is one file: `AGENTS.md`. Everything — the Task Router, the
  Commands block, the two hook-read bullets — lives in it.

## Editing the Task Router

- The left column is keyword bait: task verbs, file names, script names — the words an agent would
  grep for. Not abstract categories.
- One line per row. If a row needs a paragraph, the paragraph belongs in the target file.
- A new `docs/agents/*.md` file gets its router row **in the same commit** — `pnpm validate:docs`
  fails otherwise, and a topic file nothing routes to is a file nothing reads.
- Paths are read out of the **last** cell only. The task column describes the task, so a backticked
  name there is a concept, not a file to open.

## Keep it current — same-commit triggers

Update the corpus in the same commit when you: change or add a command; add or remove a skill (the
README task-router row); add a topic file (a router row here); learn a gotcha the hard way (append
it to its topic file, never to the root); make an architecture decision and record it in
`docs/decisions/`.

## What `pnpm validate:docs` enforces

Two scripts, one command. `scripts/validate-docs.sh` guards the docs ↔ skills contract — dead skill
links, undocumented skills, explicit-invoke (`⭑`) consistency, stale `**Next:**` pointers. It then
runs `templates/check-agents-docs.mjs`, the same checker this repo _ships_ into scaffolded projects,
against this repo's own root: the declared budget, unrendered `{{PLACEHOLDER}}` tokens, router
coverage and reachability, `pnpm <script>` mentions that match `package.json`, and `CLAUDE.md` still
being a symlink.

Running the shipped payload against ourselves is the point, and it is the same bargain
`scripts/tests/hooks-in-sync.test.sh` strikes for the hooks: the checker consumers get is the
checker that has to pass here first.

## Deliberately not used (and why)

- **`@import` in `CLAUDE.md`** — imports load eagerly at launch; they organize content but save no
  context. The router exists precisely because `docs/agents/*.md` are _not_ auto-loaded.
- **`.claude/rules/`** — would fork the corpus into a Claude-only channel beside the tool-agnostic
  `AGENTS.md` layout.
- **A second always-loaded memory file** — one root, or the corpus forks and the stale half wins
  wherever it was read last. Personal notes (how you like to be talked to, what you are learning)
  belong in `~/.claude/CLAUDE.md`, which is not this repo's problem.
