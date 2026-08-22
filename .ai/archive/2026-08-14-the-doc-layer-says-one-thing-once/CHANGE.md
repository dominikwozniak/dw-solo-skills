---
change: the-doc-layer-says-one-thing-once
branch: the-doc-layer-says-one-thing-once
created: 2026-08-14
status: landed # shaping | building | landed
landed: 2026-08-14
---

# Change — every fact in the doc layer is true and lives in exactly one file, and a fresh scaffold gets room to grow

## Goal

The always-loaded and generated docs stop lying and stop repeating themselves. Afterwards: no claim
in `AGENTS.md`, `README.md`, `CONTEXT.md`, `docs/agents/*.md` or `templates/*` is false against disk;
no self-measuring number (`117/120 lines`, `7088 B`, `51 warnings`, `6 guardrail hooks`) is hardcoded
in prose anywhere; the fork list, the vendored list, the layout block and the loop prose each have one
home and a link from wherever else needs them; `docs/agents/tooling.md` no longer restates decision
`0009`; and `templates/AGENTS.md` is a skeleton with **real headroom** under the 120-line budget instead of
15 lines of it — every section reduced to a one-line hint, with only what a hook greps, what
`check-agents-docs.mjs` enforces and what `dw-init` substitutes left standing. **Amended at land
time**: this read "~55–65 lines" and that floor is unreachable while keeping those three things —
ten headings with their blanks, the six-row router table, the ten placeholder-bearing bullets and the
hook-grep contract paragraph are ~80 lines before any hint is written. The measurable claim is now
the headroom, which came out at 34 lines. `pnpm validate:docs`, `validate:artifacts`,
`validate:manifests`, `format` and `lint` all stay green, and `AGENTS.md` stays inside the budget it
declares.

**This is a large change, deliberately.** Three layers (root docs, the routed topic files, the
payload) would each ship on their own, and the user chose one pass over three so the whole doc corpus
is judged against one standard in one context. The task list is progress tracking for `dw-next`, not
a split: it all lands together.

## Decisions

- **One change, not three** — the user's call, reaffirmed when the split was offered with slugs. The
  value is a single consistent standard across all three layers; splitting would let the second and
  third drift from the first.
- **Fix drift and cut noise; keep every rule.** No file is added, none removed, and no
  `docs/agents/` topic is split or merged — a router row is the only thing making the topic layer
  reachable, and restructuring it is a different change.
- **`templates/` is in scope**, despite shipping verbatim into other repos. It is where the worst
  crowding is.
- **`README.md` keeps the sell** — hero, badges, the "how it works" pitch, "Why two repos". It has a
  human audience that earns rationale. Only text duplicating `AGENTS.md` or `CONTEXT.md` is cut, and
  replaced with a link.
- **`templates/AGENTS.md` becomes a skeleton, not a worked example.** Keep what a hook greps, what
  `check-agents-docs.mjs` enforces, and each heading with a one-line hint. The target repo writes its
  own prose.
- **The 120-line budget is not reopened** — that is `docs/decisions/0008`. The template gets smaller;
  the ceiling stays.
- **Self-measuring numbers are deleted, not corrected.** `scripts/validate-artifacts.sh:15` already
  refuses to record one and says why: two copies of a drifting number drift apart. Prose gets the
  rule; the checker reports the number.

## Tasks

- [x] 1. `AGENTS.md` drift, net-neutral on lines. Layout block: name the `.mjs` checkers
      (`scripts/check-skill-corpus.mjs`, `templates/check-agents-docs.mjs`) that the `<script>.sh`
      glob hides, and the two payload files it omits (`gitignore-block.txt`, `worktreeinclude.txt`).
      Correct the `validate:artifacts` parenthetical — it runs three passes, not just the self-tests.
      Pay for the added lines by cutting the positioning prose at `:9–12` to its one rule, since the
      file sits at 118 of 120 lines.
- [x] 2. `CONTEXT.md` back to the definitions-only promise its own line 3 makes. Fix `:13` — traps go
      to the `## Gotchas` of the matching routed topic file, never a root `## Gotchas`, which does
      not exist and which `AGENTS.md:5` forbids. Delete the term-less "three governors are distinct"
      editorial bullet, which restates the three entries above it.
- [x] 3. One home for the duplicated enumerations. The fork list is in both `CONTEXT.md:48` and
      `docs/agents/skills-and-plugins.md:41` and they already disagree on `dw-handoff`; the vendored
      list is in `CONTEXT.md:46`, `README.md:133` and `skills-and-plugins.md`. Keep the definition in
      `CONTEXT.md` and the enumeration in the topic file, link the other way, and settle
      `dw-handoff` by reading the two skills.
- [x] 4. `README.md`: `:133` says 6 guardrail hooks, `templates/hooks/` holds 8. `:158` sends a
      contributor to `AGENTS.md` for an add-a-skill checklist that lives in
      `docs/agents/skills-and-plugins.md:47`. Drop the duplicated layout block (`:145–154`) and the
      duplicated loop prose (`:58`, `:68–70`) in favour of links.
- [x] 5. Delete every hardcoded self-measurement: `docs/agents/tooling.md:80` ("51 warnings"), `:83`
      ("117/120 lines") and `docs/agents/README.md:25` ("117/120 lines and 7088/10240 B") — all three
      already stale at 118/7318. State the rule, let the checker report the number.
- [x] 6. `docs/agents/tooling.md` (227 lines / 19.3 KB, the largest doc) down to what only it can say.
      Cut the ratchet rationale that is a third copy of `docs/decisions/0009` and a fourth of
      `scripts/validate-artifacts.sh:12–17`; cut the CI-cache experiment narrative to its one
      actionable sentence; cut the three-occurrence `paths:` story to its one rule, since both
      workflows carry the explanation inline already.
- [x] 7. `docs/agents/change-artifacts.md` down to the ~8 lines only it holds (the no-index rationale,
      the sentinel rule, the squash-merge consequence). Cut the claim protocol, the promotion-target
      list and the branch-read rule — owned by `dw-shape`/`dw-next`/`dw-land`, `CONTEXT.md` and
      `AGENTS.md:112` respectively.
- [x] 8. `docs/agents/skills-and-plugins.md`: qualify `:25–27`, which states as absolute that no skill
      can reach an explicit-invoke one by prose while four shipped `**Next:**` pointers do exactly
      that — a `**Next:**` is a suggestion to the user, not delegation. Cut the two war-story gotchas
      (`:96–105`, `:128–134`) to their generalisable lines, and drop step 7's fifth copy of the
      ratchet argument while keeping its command.
- [x] 9. `templates/AGENTS.md` from 105 lines to ~55–65. Keep the budget header, every heading, the
      Task Router rows, the four hook-grepped bullets and the `{{...}}` placeholders; cut the worked
      prose under `## Always` / `## Ask First` / `## Never` / `## Git conventions` to one-line hints.
      Fix the loop at `:66`, which still omits `dw-grill` and `dw-land`, and add the hook-critical
      detail `AGENTS.md:92` has and the template lacks: `none` must stand alone on the line.
- [x] 10. The other payload docs. `templates/decisions-README.md:9` says the bar "isn't restated here"
      and then `:11–13` restates it — its live twin `docs/decisions/README.md:9–14` names this exact
      problem. `templates/work-README.md:43` still sends traps to `## Gotchas` in `CLAUDE.md`, and
      `:53–55` contradicts its own sibling `templates/backlog-README.md:12–14` on entry length.

## Anchors

- `AGENTS.md:16–29` — the layout block, and `:53` the `validate:artifacts` parenthetical. At 118 of
  the 120 lines it declares at `:3`, so task 1 must not grow it.
- `templates/check-agents-docs.mjs:70,124,162,175` — what "green" means: a declared budget line, a
  `## Task Router` row per topic file, and every routed path real. Run against this repo's own root by
  `scripts/validate-docs.sh` check 5.
- `scripts/tests/check-agents-docs.test.sh:295,311` — renders `templates/AGENTS.md` against seeded
  `.ai/README.md`, `.ai/backlog/README.md`, `.ai/archive/README.md`, `docs/decisions/README.md` and
  `CONTEXT.md`. Task 9 must keep every router row whose path `dw-init` creates.
- `scripts/validate-artifacts.sh:12–17` — the precedent task 5 follows: it refuses to record a warning
  count and states the reason in place.
- `docs/agents/git-history.md` (31 lines) — no duplication, no history, three traps with fixes. The
  shape tasks 6–8 are aiming at.
- `docs/decisions/0009-skill-corpus-ratchet.md` — what `tooling.md` should point at instead of
  restating, and `0008` for the budget task 9 must not reopen.

## Notes

**Left out of this change, each decided explicitly at shape time:**

- `scripts/lint.sh` ignores the file path `lint-on-edit` appends — it always runs `agnix .` over the
  whole tree, so `AGENTS.md:89`'s "must accept one" is unsatisfied and `.husky/pre-commit` documents
  the opposite. A code bug, not a doc bug; a docs change must not change lint behaviour.
- `.ai/archive/design-rationale.md` (16 KB) — self-declared frozen, no router row, no pointer from
  anywhere, and the only non-slug entry in `.ai/archive/`.
- Nothing compares a `templates/*-README.md` to its live `.ai/` twin. `templates/archive-README.md`
  and `.ai/archive/README.md` are byte-identical by hand; only `templates/hooks/` has a sync test.
- `.ai/README.md` does not exist in this repo, so `templates/work-README.md` is never exercised here —
  only `check-agents-docs.test.sh` opens it, and only to seed a dummy.
- The stale `.ai/work/the-guardrail-hook-wave/CHANGE.md` on local `main`: `0/8` ticked and
  `branch: unclaimed`, duplicating the `8/8` copy already in `.ai/archive/`. It exists only in four
  unpushed local commits (`28b3e4b`..`8da3082`) made before the `#31` squash-merge; `origin/main` is
  clean, so pushing `main` as it stands would resurrect it.

**While building:**

- Task 1: only one `.mjs` checker was actually hidden. `templates/check-agents-docs.mjs` was already
  named on the `templates/` layout line, so the shape's "name the two" was one edit, not two. The
  line budget was bought differently than shaped: the `scripts/` glob absorbed `.mjs` in place
  (`scripts/<script>.{sh,mjs}`, dropping `lint.sh` from its examples) rather than growing a line, so
  the positioning prose only had to give up one line instead of two. 119/120 lines before and after,
  7283 B.

- Task 2: the deleted "three governors are distinct" bullet was checked term by term before it went,
  since a summary bullet can be the only home of a fact. It was not: "picks no number at all" is
  already in **Ratchet** (`:66`), and the Cap/Budget halves in `:17` and `:61`. Nothing lost.

- Task 3: `dw-handoff` is **not a fork** — settled from its origin commit `bd3c286`, which records
  that the team lane dropped handoffs deliberately and this skill answers a different question. It
  was written here; it shares a name with a team-lane skill and nothing else. So `CONTEXT.md`'s
  omission was right and the topic file's fork-list entry was wrong, which is the opposite of the way
  the shape guessed.
- Task 3, two facts neither doc had: `templates/hooks/` holds **9** scripts, not the 6 both copies
  claimed nor the 8 the shape counted (8 is `.claude/hooks/` — `typecheck-on-stop.sh` ships as a
  template but is pruned here, since the Typecheck command is `none`). And only **5** are vendored:
  the wave's four (`credential-leak-guard`, `enforce-commit-hygiene`, `guard-plugin-canon`,
  `large-file-guard`) were authored here from a survey, per `40da922`, so their canon is local. The
  vendored five have also been fixed here in five commits since `19811ac`, so "byte-identical today"
  was an over-claim and now reads "assume diverged".
- Task 3 took `README.md:133` with it, since that line is the vendored enumeration and the
  `6 guardrail hooks` number in one sentence. Task 4 covers the rest of `README.md`.

- Task 4 kept one sentence the task listed for deletion. Of `:68–70`, only the spine half duplicated
  `AGENTS.md`; the parallel-changes recipe (shape several, then a worktree + session each) is nowhere
  in `AGENTS.md` or `CONTEXT.md` — it lives in `dw-start`'s body — so cutting it would have removed a
  fact rather than a copy, against the decision that only duplicating text goes. `README.md` 163 →
  157 lines. The `11 skills` / `3 plugins` badges were checked against disk and are correct, so they
  stay: they are the sell, and unlike a line count they change only when a skill is added.

- Task 5 found two more of the same kind and took them: the `~1752 tokens, limit is 1500` inside the
  quoted agnix warning (a measurement wearing an example's clothes), and the `120 lines / 10 KB`
  restated twice in `docs/agents/README.md`. That last one is a _chosen_ number rather than a measured
  one, so it is not what the task was aimed at — but it is a second copy of a line the checker parses
  out of `AGENTS.md`, sitting two lines above a new sentence promising no figures are kept in prose.
  A grep for the four patterns across `AGENTS.md`, `CONTEXT.md`, `README.md`, `docs/` and `templates/`
  now returns nothing. The `11 skills` badge and the `32 KB` Codex limit stay — one is verified against
  disk, the other is an external constant.

- Task 6: 227 → 215 lines. All three named cuts made, plus one word: `:34` called this repo's
  `.claude/hooks/` "vendored copies" of `templates/hooks/`, which collides head-on with the glossary
  term settled in task 3 (`Vendored` = canon in `dw-skills`). The relationship it meant is
  canon-and-copy _inside_ this repo, so it now says that.
- Task 6, deliberately not cut: the declared-bullet resolution chain at `:56–75` overlaps
  `CONTEXT.md`'s **Declared bullet** entry and `AGENTS.md:89–92`. Judged cross-reference rather than a
  second home — the glossary defines the term, the root says why the four live there, and only this
  file has the mechanics (which probe each script falls back to, why `CLAUDE.md` is off the chain, why
  `none` is tested before backtick extraction). Named here because the next reader will see the
  overlap and should know it was looked at.

- Task 7: 34 → 19 lines. Two things the task listed as cuttable were folded rather than dropped,
  because each was the load-bearing half of a design this file does own. The branch-matched resume
  mechanic is _how_ discovery works without an index, so it moved into the no-index bullet instead of
  going with the rest of the claim protocol. And the sentinel keeps one line saying why it exists —
  with no index it is the only thing distinguishing an unopened change — while who flips it and when
  goes to the skills.
- Task 7, left alone on purpose: the one-change-one-shippable-scope bullet, and the no-index rationale
  that `README.md:106` also carries. The first was not listed for cutting and is defined nowhere else;
  the second is duplicated only by the README's pitch version, which the "README keeps the sell"
  decision protects.

- Task 8: **three** shipped `**Next:**` pointers name an explicit-invoke skill, not four —
  `dw-shape` → `dw-start`, `dw-land` → `dw-ship`, `dw-doctor` → `dw-init`. Nothing points at
  `dw-handoff`. The fix names no count, so the correction is only recorded here.
- Task 8 also fixed the same false absolute in `README.md:56` ("can't be reached by other skills'
  prose"), which the task list did not mention. The distinction that resolves both: a skill cannot
  **delegate** to an invisible one, but naming it is the one route in, and that is what a `**Next:**`
  line is.
- Task 8's cuts (~11 lines) run against task 3's addition (~16), so this file ends at 139 lines,
  slightly _up_ from the 134 it started at. That is the intended trade — it is now the one home for two
  enumerations that were living in three files.

- Task 10 found a fourth copy of the same bug and a version obligation. `templates/archive-README.md`
  **and** its hand-kept twin `.ai/archive/README.md` both sent the durable layer to `## Gotchas` in
  `CLAUDE.md`; both are fixed identically and `cmp` confirms they are still byte-identical, which is
  the only thing keeping them in step (nothing tests it — see the shape's Notes). And tasks 9 + 10 edit
  `templates/`, which is payload, so `dw-solo-setup` is bumped `0.1.19` → `0.1.20` in
  `marketplace.json` and its `plugin.json` together. `validate-manifests.sh` checks the two are
  _equal_, never that either moved, so nothing would have caught the omission.
- Gate run at the end of task 10, all green: `format`, `validate:docs`, `validate:artifacts` (including
  the 59-case `check-agents-docs.test.sh`), `validate:manifests`, `eval:routing`, and
  `bash scripts/lint.sh` at 0 errors. `pnpm lint` itself dies with `Command "eslint" not found` — the
  rtk-proxy hijack `tooling.md` documents, not a repo failure.

**`dw-check` via `/codex:review`, after task 10 — two findings, both confirmed and fixed:**

- The Git conventions compression in task 9 dropped `git fetch origin &&` from the rebase command, so
  the payload taught a rebase onto a stale tracking ref. The bullet wraps to two lines again; the
  template is 86 lines.
- Four payload files stated the trap destination flatly where `dw-land:108–109` states an **ordering**:
  an existing root `## Gotchas` stays the home where a repo already keeps one, and only otherwise the
  routed topic file. Codex found one instance (`work-README.md:44`); the same claim was in
  `work-README.md:36`, `decisions-README.md:15` and `archive-README.md:12` with its twin
  `.ai/archive/README.md:12`. All hedged, twins still `cmp`-identical. **`CONTEXT.md:13` deliberately
  keeps the absolute form** — this repo has no root `## Gotchas` and `AGENTS.md:5` forbids one.
- Worth keeping for its own sake: this is exactly the gotcha task 8 edited — _when a sibling skill
  hedges a claim you are about to state flatly, the hedge is load-bearing_ — walked into inside the same
  change, by the same hand that had just rewritten it. The entry is not paranoid enough; a reviewer
  caught it and the author did not.
- `dw-solo-setup` → `0.1.21` for the second round of payload edits.

**RESOLVED — the `## Goal` was amended at land time; the verdict re-ran clean against it.** What
follows is why, kept because the floor is the reusable part.

**Task 9 landed at 86 lines, against a shaped ~55–65.** Every substantive instruction in
task 9 is done: worked prose under `## Always` / `## Ask First` / `## Never` / `## Git conventions` is
now one-line hints, the loop gained `dw-grill` and `dw-land`, `none` gained "standing alone on the
line", and all ten placeholders plus every heading, router row and hook-grepped bullet survive (the
59-case `check-agents-docs.test.sh` passes, including the render case). 105 → 86 lines, 5.5 → 4.6 KB;
headroom went from 15 lines to 34.

~55–65 is not reachable while keeping what the same task requires kept. The floor is structural: ten
headings with their blank lines (~20), the six-row router table (8), the ten placeholder-bearing
bullets, and five prose blocks that are contracts rather than examples — the hook-grep paragraph above
all, which tells the author that the Lint command must accept an appended file path and that `none`
must stand alone. Cutting to 65 means dropping one of those, and each is protected either by the
checker, by a hook, or by this task's own "keep" list. The number needs amending or the constraint
does. The user chose to amend the number, on the grounds that the objective was headroom and that
buying twenty more lines would come out of the same pocket as the `git fetch` the reviewer caught.

**Prior context:** `.ai/backlog/templates-ship-the-docs-agents-contract.md` is coupled to task 9 —
cutting the template's prose removes the last place a scaffolded repo meets the `docs/agents/`
contract before hitting it as a red gate. Its candidate fix adds a `templates/agents-docs-README.md`,
which the "no file added" decision above excludes. Left parked, and worth revisiting right after this
lands.
