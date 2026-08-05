---
change: shape-splits-changes
branch: shape-splits-changes
created: 2026-08-02
status: building # shaping | building | landed
---

# Change — teach dw-shape to write N changes when the request carries N shippable scopes

## Goal

`dw-shape` writes exactly one `CHANGE.md`, always. The only splitting language in the catalog is a
single bullet (`skills/dw-shape/SKILL.md:81-84`) that opens with "still one file", caps the split at
two, and says nothing about what happens if you say yes. Give it a real branch: a test for when a
request is N changes rather than one, and the procedure for writing N unclaimed change docs. Known
when a deliberately two-scope request produces two named slugs and a question, instead of one doc
carrying two goals.

What this pays back is visible in the repo's own history: 3 of the 5 change docs written so far carry
four or more unrelated scopes, and `.ai/archive/worktreeinclude-support/CHANGE.md:133-139` records
"Absorbed into this change" for two problems found mid-build that should have been their own.

## Decisions

- **The test is independent shippability** — "could each piece land on its own and leave the repo
  green?" `CONTEXT.md:17` already applies exactly that test to a task, so this is the same test one
  level up: the lane gains a rule, not a new vocabulary.
- **Rejected: disjoint anchors as the test** — nearly every change here touches `README.md` and
  `marketplace.json`, so a shared-file test would almost never fire, and when it did it would be a
  false negative. File overlap is an ordering fact, not a merging one.
- **Rejected: a task-count threshold** — `pnpm-v11-migration` had 3 tasks and one scope,
  `skill-arguments-reference` had 2. Task count doesn't track scope count.
- **Ordering is a sentence in `## Notes`, never a field** — `docs/DESIGN.md:85-88` forbids growing
  `.ai/` a status column ("the moment it grows a status column it is the validated plan this lane
  exists to avoid"). `.ai/archive/skill-arguments-reference/CHANGE.md:54-56` is the hand-written
  precedent for what that sentence reads like.
- **`dw-shape` splits, `dw-grill` doesn't** — grill writes nothing, and its close already routes what
  was left out to a Decision or the backlog. Naming the split in both places would put the judgement
  where it can't act on it.
- **N, not two** — the existing cap is arbitrary; the test yields however many it yields.
- **Tasks 4-5 are a deliberate scope override, not an oversight.** They were flagged as a separate
  scope — zero file overlap with tasks 1-3, and this change's own Goal cites "Absorbed into this
  change" as the failure it exists to prevent — and folded in anyway on an explicit call. Recorded so
  the close reads it as a decision. The irony is the point, not a mistake to fix retroactively.
- **A mode word, not a flag** — `docs/SKILL-ANATOMY.md:42` states the convention ("one word, no
  flags, no punctuation"), so `codex`, never `--codex`.
- **Delegation fires only on that word; bare stays silent.** Today `dw-check:39-43` asks the user to
  type `/codex:review` on _every_ run, gated on nothing. The `argument-hint` is the advertisement —
  it's shown as you type — so bare doesn't need to nag.
- **Name the path the agent can actually run.** `/codex:review` is `disable-model-invocation: true`
  (`commands/review.md:4`), `codex:rescue` is not. Naming only the unrunnable one is what produced
  the nagging.

## Tasks

- [x] 1. `skills/dw-shape/SKILL.md` — rewrite the **Large** bullet (`:81-84`) to hand off to the test
      instead of pre-answering it, and add the split test as a block closing step 2: the shippability
      question; name the N slugs and what each owns, then ask; on yes write N ×
      `.ai/work/<slug>/CHANGE.md`, each complete on its own terms and all `branch: unclaimed`, never
      a stub pointing at a sibling; shared anchors become one ordering sentence in the `## Notes` of
      whichever lands second; on no it stays one change, with the reason recorded as a Decision.
- [x] 2. `docs/DESIGN.md` — one bullet beside "One folder per change" (`:42`): one change is one
      independently shippable scope, applied at shape time, and shared anchors are an ordering note
      rather than a dependency field.
- [x] 3. Patch-bump `dw-solo` in `plugins/dw-solo/.claude-plugin/plugin.json` and
      `.claude-plugin/marketplace.json` — 0.4.7 → 0.4.8 if `argument-hint-parity` landed first, else
      0.4.6 → 0.4.7.
- [x] 4. `skills/dw-check/SKILL.md` + `README.md:79` — gate `### 2.` (`:37-47`) on a `codex` mode
      word instead of asking every run; name both paths and which is which (`codex:rescue` the agent
      runs itself, `/codex:review --wait` the user types); keep the `/codex:setup` pointer and the
      "any other reviewer folds in the same way" clause; bake in verbatim-then-verify. `argument-hint`
      gains `codex`, README Arguments cell in the same commit (check 5).
- [x] 5. `skills/dw-land/SKILL.md` + `README.md:80` — the same `codex` word wired into the verdict
      step (`:43`) as one sentence, added to `## Modes` (`:104-116`), `argument-hint` and README cell
      together.

## Anchors

- `skills/dw-shape/SKILL.md:73-84` — the sizing ladder. The **Large** bullet at `:81-84` is what
  changes, and the new block closes `### 2.`.
- `skills/dw-shape/SKILL.md:101-103` — the existing "read it back and wait for confirmation" gate the
  split question reuses instead of duplicating.
- `CONTEXT.md:10` and `CONTEXT.md:17` — the definitions of Change and Task; the test is Task's own
  wording raised one level.
- `docs/DESIGN.md:42` — "One folder per change", where the granularity rule joins.
- `docs/DESIGN.md:85-88` — the no-status-column constraint that keeps ordering in prose.
- `.ai/archive/skill-arguments-reference/CHANGE.md:54-56` — a hand-written ordering note; the shape
  task 1 makes routine.
- `.ai/archive/worktreeinclude-support/CHANGE.md:133-139` — two absorbed scopes, the failure this
  change exists to prevent.

## Notes

- **Land after `argument-hint-parity`.** Both bump `dw-solo`'s patch version in
  `plugins/dw-solo/.claude-plugin/plugin.json` and `.claude-plugin/marketplace.json` — the only
  overlap between them, and `pnpm validate:manifests` fails if those two files disagree. Rebase this
  one's bump onto whatever landed.
- These two changes were split by the test this change installs, applied by hand in the `dw-grill`
  session that shaped them — the procedure didn't exist yet.
- **`argument-hint-parity` has landed** (`6a79cba`, archived), so task 3's conditional is settled:
  `dw-solo` is at **0.4.7** in both files → bump to **0.4.8**. No rebase of the bump needed.
- **Task 1 grew two edits the task line didn't name**, both forced by the same file contradicting
  itself. The intro asserted "It writes **one** `CHANGE.md`" three lines above a procedure for
  writing N (H1 kept — "one file, then build" is about no-spec-no-plan, not a count); and step 4 said
  "write `CHANGE.md`" / "commit the file" singular. One sentence each.
- **The split's branch rule needed a case the task line didn't cover.** "All N `unclaimed`" conflicts
  with Output location rule 1 (a feature branch is shaping+claiming in one step) and rule 2 (no two
  changes on one claimed branch). Resolved: on the default branch all N are `unclaimed`; on a claimed
  branch the one being built records the branch verbatim and siblings go out `unclaimed`.
- **Deliberately left stale:** the `description` and `README.md:76` still say "one … `CHANGE.md`".
  Editing a description shifts every term's idf and can knock an unrelated skill off rank-1 in
  `pnpm eval:routing` — a cost out of proportion to the wording. `dw-land` should park it if it still
  reads wrong at close.
- Referents inside the new block are stated, not cited: the skill installs into arbitrary repos, so
  `CONTEXT.md:17` and `docs/DESIGN.md:85-88` (this repo's anchors) became "the same test step 3
  applies to a task" and "`.ai/` doesn't get a status column".
- **`dw-check` found two real gaps where the split meets the pre-existing procedure**, both now
  closed. Step 4's backlog path is singular by construction (`git mv` **the file**, keep **its**
  slug) — a split seeded by one `.ai/backlog/` entry had no rule for which of the N receives the
  move; it seeds one, siblings are written fresh. And the slug-collision check tests against disk,
  which can't see a sibling being derived in the same breath. Both are consequences of writing N
  where the skill assumed 1; anything else added later that writes N should be read against these
  two spots first.
- Wording that misfired on the first pass: "don't ask twice" read as cancelling step 4's read-back
  rather than the split question. Restated as "ask it once, here". Worth remembering that a HARD STOP
  which defers to a later gate has to name which question it's suppressing.
- The 0.4.8 bump covers the review fixes too — it hasn't shipped, so no second bump.
- **A third pass (codex) found the seams the first two didn't look at.** Both of my passes checked the
  new block against itself and against step 4. What they missed was its interaction with the **sizing
  ladder** and with the **pre-workflow `Output location` items** — and all three remaining defects
  lived exactly there. Worth generalising: when a block is added to a step, the thing to review is
  every _other_ step that block now changes the meaning of, not the block.
  - The ladder never re-ran per scope, so mandating "goal, decisions, tasks and anchors" on each of
    the N contradicted the Small rule's "skip Decisions and Anchors entirely" — the split was forcing
    the exact ceremony step 2 exists to prevent. Now sized per scope.
  - A split on a branch that **already** carries a change double-claimed it: opening a new change
    there is permitted for genuinely separate work, and the claimed-branch rule then handed the branch
    to one of the N. Now all N go out `unclaimed` in that case.
  - "step 2" was ambiguous the whole time — `Output location` has an item 2 and `## Workflow` has a
    `### 2.`. Anything referring to a step across those two sections has to say which.
