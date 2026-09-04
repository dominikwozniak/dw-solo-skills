# Agent docs — how this corpus works

Three tiers, three owners:

| tier                 | file(s)                                              | loads                                     |
| -------------------- | ---------------------------------------------------- | ----------------------------------------- |
| boundaries + routing | root `AGENTS.md` (`CLAUDE.md` is a symlink to it)    | every session, in full                    |
| topic rules          | `docs/agents/*.md`                                   | on demand, via the root Task Router       |
| change state + why   | `.ai/` (working memory), `docs/decisions/` (records) | never eagerly; the `dw-*` skills own them |

## What goes where

- **Root `AGENTS.md`**: only what applies to _every task regardless of what you touch_ — the layout
  rule, the loop, the Commands block, the Task Router,
  and the two blocks the tooling reads directly: `## Solo lane` (whose `- **Lint command**:` line the
  `lint-on-edit` hook greps) and `## Git conventions` (which every commit, push and PR follows). A topic-scoped rule goes
  into a topic file and earns a router row instead. It declares its own hard budget in its header prose
  and `pnpm validate:docs` enforces exactly what that line says, so the number lives there and is not
  restated here. The budget caps only that one file; `docs/agents/*.md` are unbudgeted, which is where
  prose belongs — unbudgeted but **ratcheted**: `corpus.baseline.json` records what the corpus is, so it
  may shrink freely and grows only through a commit that re-records it with `--update-baseline`. No
  number is chosen for a topic file, so none can be set too high, and no growth is silent.

  **What kind of number that is: chosen editorial discipline, not a harness ceiling.** Nothing truncates
  where it is set — the nearest real limit is Codex's `project_doc_max_bytes`, 32 KB, and the byte half is
  deliberately several times stricter, because the point is a file a human rereads in one sitting rather
  than one a tool can ingest. The line half is the one that has ever bound, so every squeeze has been a
  line squeeze. `pnpm validate:docs` prints where the file stands; no copy of those figures is kept in
  prose, because two copies of a moving number drift apart. Treat a breach as the prompt to move a topic
  out, never as a licence to compress a rule into a shorter, vaguer one.

- **`docs/agents/<topic>.md`**: everything scoped to one topic — procedure, mechanics, and the traps that
  topic has actually sprung. One file per concept, sized to the concept; a 15-line file is fine. Each
  topic has exactly one authoritative file; related files cross-reference it, never duplicate it.
- **`docs/decisions/<NNNN>-<slug>.md`**: why the code is shaped this way. One numbered file per decision,
  append-only; `dw-land` writes them at close. The bar for writing one at all is in
  `docs/decisions/README.md`.

## Gotchas live here, not in the root

Every topic file carries its own `## Gotchas`, newest first — a deliberate reversal of the root's old
hard count cap, which kept forcing unrelated traps to be merged into one entry to stay under the number.
Scoped to a topic file the pressure is gone, because only someone already working on that topic loads it.

The cost the cap was paying for is real. Total growth is now the ratchet's job — it cannot be silent. What
stays editorial is the part no counter can see: an entry that stopped being true is deleted, and two
entries with one root cause are one entry with sub-bullets. Growth is fine; sprawl of stale traps is not.

## Gotchas

- **A header written to explain a fix is where a fact gets re-copied, because there it reads as context
  rather than duplication.** The commit after the one that made every fact live in exactly one file added
  a script header restating a caveat `.agnix.toml` and `.husky/pre-commit` already carried — three homes,
  written by the hand that had just finished deduplicating the doc layer. When a comment explains _why a
  fix was needed_, the background belongs to whatever file already owns it: name that file and stop. What
  a header may state is what its own file does.
- **Moving prose between files conserves entries while losing content, and counting proves nothing.**
  Splitting the root into this directory moved twelve gotcha entries and seventeen sub-bullets, every one
  accounted for, and four separate pieces of content went missing anyway — each lost inside a paragraph
  that survived, an instruction dropped from a section that kept the fact it explains, a trap's "why"
  dropped from its "what". Reading the diff did not surface them, because every hunk looked like a faithful
  move. What did: diffing the old file against the new corpus as a **word stream** — slide an 8-gram window
  over the old text, report windows absent from the union of the new files, then judge each miss. Do that
  before believing any large doc move.
  - **A rewrite dense enough to reword every sentence drowns that window in noise**, so pair it with a
    **fact-token diff**: every backticked span, path, flag, number and error string in the old text,
    checked for presence in the new. It is the check that survives a rewrite the 8-gram window cannot read.
  - **Both checks read words, so neither sees a relative cross-reference that lost its referent.**
    `dw-shape`'s split execution said "run the ladder above once per scope"; the block moved to a
    reference file while the ladder stayed in the body, so "above" pointed at nothing — word-perfect
    move, fact-token clean, and wrong. No grep can judge it either: seventeen legitimate _above_ /
    _below_ uses sit in the same corpus. Re-read the moved text **in its new home** and make every
    _above_, _below_, _the section before_ and bare "this step" either resolve there or name what it
    meant.
  - **A line target buys itself out of the content, and the format gate cannot see the bill.** Compressing
    `templates/AGENTS.md` toward a shaped line count dropped `git fetch origin &&` from a rebase command,
    teaching a rebase onto a stale ref — caught by a reviewer, by no check. Prose has no compiler, so
    shrinking it is not refactoring: it silently trades tokens that matter for tokens that don't. Where a
    count and a correct instruction conflict, the count is what to renegotiate, and a floor worth keeping
    is worth writing into the goal.
- **`CLAUDE.md` is a symlink to `AGENTS.md`, not a synced copy — and the symlink bites twice.** Claude
  Code's `Edit` tool **refuses to write through a symlink**, so an edit aimed at `CLAUDE.md` fails in a way
  that reads as a permissions problem rather than as "you named the wrong file". And a change doc that
  treats the two as separate files schedules the same edit twice, then reports the second as already done.
  There is one file: `AGENTS.md`, and everything lives in it — the Task Router, the Commands block, the two
  hook-read bullets.

## Editing the Task Router

- The left column is keyword bait: task verbs, file names, script names — the words an agent would grep
  for. Not abstract categories.
- One line per row. If a row needs a paragraph, the paragraph belongs in the target file.
- A new `docs/agents/*.md` file gets its router row **in the same commit** — `pnpm validate:docs` fails
  otherwise, and a topic file nothing routes to is a file nothing reads.
- Paths are read out of the **last** cell only. The task column describes the task, so a backticked name
  there is a concept, not a file to open.

## Keep it current — same-commit triggers

Update the corpus in the same commit when you: change or add a command; add or remove a skill (the README
task-router row); add a topic file (a router row here); learn a gotcha the hard way (append it to its topic
file, never to the root); make an architecture decision and record it in `docs/decisions/`.

## What `pnpm validate:docs` enforces

Two scripts, one command. `scripts/validate-docs.sh` guards the docs ↔ skills contract — dead skill links,
undocumented skills, explicit-invoke (`⭑`) consistency, stale `**Next:**` pointers. It then runs
`templates/check-agents-docs.mjs`, the same checker this repo _ships_ into scaffolded projects, against
this repo's own root: the declared budget, unrendered `{{PLACEHOLDER}}` tokens, router coverage and
reachability, `pnpm <script>` mentions that match `package.json`, and `CLAUDE.md` still being a symlink.

Running the shipped payload against ourselves is the point, and the same bargain
`scripts/tests/hooks-in-sync.test.sh` strikes for the hooks: the checker consumers get is the checker that
has to pass here first.

## Deliberately not used (and why)

- **`@import` in `CLAUDE.md`** — imports load eagerly at launch; they organize content but save no
  context. The router exists precisely because `docs/agents/*.md` are _not_ auto-loaded.
- **`.claude/rules/`** — would fork the corpus into a Claude-only channel beside the tool-agnostic
  `AGENTS.md` layout.
- **A second always-loaded memory file** — one root, or the corpus forks and the stale half wins wherever
  it was read last. Personal notes (how you like to be talked to, what you are learning) belong in
  `~/.claude/CLAUDE.md`, which is not this repo's problem.
