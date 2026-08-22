# Promotion — the five targets, in order, and what each one deletes

Phase 3 of `dw-land`, after the user's go and never before it. The five bullets below run in the
order they appear, and the commit at the end carries all of them.

**Promotion replaces; it does not append.** For each target below, read what is already there before
writing, and delete what this change supersedes in the same edit. A durable layer that only ever grows
stops being read, which costs you the promotion step entirely — and where a cap, a ceiling or a
baseline exists, appending is what makes the build fail.

- **Promote the decisions.** Anything from Decisions or Notes that a future session would need and
  couldn't re-derive from the code becomes `docs/decisions/<NNNN>-<slug>.md`, numbered next from the
  highest on disk. The sibling `decision-record.md` holds the bar, the shape, the ceiling and the
  supersession protocol — **read it rather than writing from memory**, and name its three tests out
  loud per candidate before any record exists. Most changes produce **zero** records, and that's the
  correct number. When a record here replaces an older one, flip that one in the same pass; nothing
  else in the loop does it. This is the one target where replacing is a link rather than a deletion.
- **Promote the vocabulary.** Any new domain term this change introduced or sharpened goes into
  `CONTEXT.md` as a glossary line. Terms only — no implementation detail. Create the file if it
  doesn't exist. **If the change sharpened a term already defined there, rewrite that line** — two
  definitions of one word is worse than none, and a term the change retired comes out.
- **Promote the gotchas.** A trap that cost real time, or repeated, becomes one entry — the local
  trap, and what to do instead. Same bar as decision records: **not every surprise.** A gotchas list
  that logs every small confusion teaches you to stop reading it.

  **Where it goes, in this order.** An existing `## Gotchas` section — in `AGENTS.md` or `CLAUDE.md`,
  wherever the repo already keeps one — stays the home; newest first. Otherwise the home is the
  **routed topic file** whose subject covers the trap: find the `## Task Router` row that matches and
  append there. **No matching row means creating both halves in the same commit** — the topic file
  under `docs/agents/` and its router row — because a topic file nothing routes to is a file nothing
  reads, and the shipped `agents:check` fails on one.

  Never the root file by default: it is loaded in full every session, so traps accumulating there push
  a real rule out. A routed file is read when its subject comes up — exactly when its traps matter.
  Four things before you write:
  - **Ask first whether a mechanism would catch it.** A trap a hook, a validator, a self-test or a lint
    rule could refuse outright does not belong in prose — prose is for what no mechanism can enforce,
    and a rule enforced on trust is one a tired session skips. Where a mechanism would work the
    promotion is one `.ai/backlog/<date>-<slug>.md` naming it and **no `## Gotchas` entry**; a trap written up
    as prose is a trap you have decided to keep hitting. Where none fits, write the entry.
  - **Delete what this trap replaces.** A gotcha the change made untrue — the tool is gone, the hook
    is fixed, the flag now defaults the other way — comes out in this edit. Leaving it beside its
    replacement is how the list stops being trustworthy: the reader can no longer tell which half is
    current.
  - **Look for the cousin.** If an existing entry has the same root cause, make this a sub-bullet of
    it rather than another sibling. Where the repo caps the list, a merge is the only way to add to a
    full one, and appending fails the build.
  - **Shrink before you add, where the corpus is ratcheted.** A baseline beside the topic files means
    the layer may shrink freely and grows only through a commit that re-records it. So the entry is
    paid for: cut what it made untrue, or re-record on purpose in this commit and let the number
    move where you can see it. A silent increase is the one option that isn't there.

- **Promote the follow-ups.** Every follow-up named in the verdict, plus anything deliberately left
  out, becomes one file `.ai/backlog/<YYYY-MM-DD>-<slug>.md` — name from
  `bash "${CLAUDE_PLUGIN_ROOT}/scripts/slugify.sh" dated "<the follow-up>"`, carrying
  `source: <this change's bare slug>`. `.ai/backlog/README.md` states the entry shape and both bars —
  **will you ever?** and **should it have been done now?** — so they are not restated here; judge
  against those. Where the repo has no such README, create the dir and say so: `dw-init` owns the
  payload it comes from, and the bars are not reproducible from here. If
  an entry already carries this bare slug (`undate` each name), merge into it or re-slug with a more
  specific description — **never overwrite it silently**; the existing entry is queued work. Zero is a normal
  answer, and a folder already too long is what `dw-prune` is for — say its name rather than triaging
  the queue from here.
  **Then clear what this change closed**: an entry whose work the diff just did, or which the change
  made moot, is `git rm`'d in this same commit — and one that survives with fewer bullets than it had
  gets rewritten to what is left. A queue holding finished work reads as a backlog you have stopped
  believing.
- **Archive the scaffolding.** `git rm` a leftover `HANDOFF.md` first — it described the middle of a
  task, and post-merge it is noise — then `git mv .ai/work/<shaped date>-<slug>/`
  `.ai/archive/<landed date>-<slug>/`: the destination takes **today's** date, not the one the work
  folder carried, so the name records when the change landed — only the bare slug travels. In the
  moved `CHANGE.md`, flip `status:` to `landed` with `landed: YYYY-MM-DD`, the same date as the
  folder, plus `pr: "#<n>"` where the
  branch already has one (`gh pr view --json number`) — otherwise step 4 fills it, since on the usual
  path the PR does not exist yet. `.ai/archive/README.md` states the convention; create it from that
  one line if the repo predates the scaffold. If that destination already exists — same day, same slug —
  stop and pick a suffixed one (`<date>-<slug>-2`): `git mv` into an existing directory silently nests
  the folder inside it. If something in the doc still feels too valuable to bury, that is the signal it belonged
  in a record, a gotcha or the backlog — promote it first, then archive.
- **Commit** the promotion and the archive move together, the way `dw-git` does — **on the branch you
  are on.** In a worktree that means the feature branch: the promotion rides the PR, the squash-merge
  carries it to the default branch, and post-merge `main` is already clean.
- **A fix absorbed here can touch a versioned artifact, and the bump is an earlier commit.** Where CI
  checks each commit against its parent, that bump does not cover this one — grow the version again in
  this commit. The local check can pass while CI fails; they use different bases.
