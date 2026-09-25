---
change: a-change-finishes-its-goal-and-grows-nothing-unasked
branch: a-change-finishes-its-goal-and-grows-nothing-unasked
created: 2026-09-25
status: building
---

# Change — a change finishes its goal, and nothing it leaves behind grows unasked

## Goal

- Asked for one piece of a flow, `dw-shape` writes a `## Goal` that reaches the first result a user
  sees, says so at the read-back, and offers no backlog entry as the fate of a left-out item.
- No loop skill measures work by a session: in-goal work joins the change (a new task when it is
  big), out-of-goal work is a `## Notes` line the land report carries, and `dw-next` never writes to
  `.ai/backlog/`.
- On a plain go, `dw-land` creates no backlog entry, decision record, gotcha or term — each exists
  only on the user's yes to it by name at the verdict. A trap's mechanism is built in the change only
  when it adds a case to an existing check, hook or lint config; otherwise a report line names it.
- `dw-land`'s report ends with a `You get:` line and a balance line,
  `Backlog +N/−M (now K) · decisions +N · docs +N/−M`; the archive receipt is the frontmatter, the H1
  and that `You get:` line, plus `## Why rejected` on a rejection.
- Every payload file `dw-init` ships says the same: none tells a consumer to file a follow-up, or to
  build a check, without these bars.
- `dw-shape` #4, `dw-land` #3 (rewritten) and `dw-land` #4 grade every expectation passed at n=1 on
  this branch.

## Decisions

- **One change.** Every piece answers the one goal and the user asked for one; split, it would be
  the fragmentation it exists to stop.
- **The goal measures the work, not the session.** "small enough for a fresh session",
  "session-sized" and "exceeds the session" go; a task stays a vertical slice, one commit, green.
  `absorb-follow-ups-by-default` made the session the bar, and Grateful Me is what it produced.
- **Internal-only work is its own change only when the user asks.** A check, lint rule, test harness
  or refactor otherwise rides in the product change that found it, or is a report line — the
  meta-vs-product brake that `absorb-follow-ups-by-default` deliberately left out.
- **A request for a piece of a flow is extended to the first result a user sees**, said at the
  read-back and narrowed back on one word — the read-back is already the one stop, so none is added.
- **Nothing durable is created without the user's yes to it by name** — a backlog entry, a decision
  record, a gotcha, a `CONTEXT.md` term. A plain go creates none; rewriting or deleting an existing
  one needs no yes. `dw-next` nominates a term the way it nominates a decision. A planning sitting on
  the default branch and split siblings after the HARD STOP are the user's yes already, and stay. Why:
  the verdict already stopped for a go, and the queue grew through it.
- **A check is cheap only when it adds a case to an existing check, hook or lint config**, in this
  change. A new script, hook or harness never is — here a new validator carries a self-test (`0013`)
  — so the trap stays prose (on a yes) plus one report line naming the mechanism, never a backlog
  entry. "build or backlog" is what produced checks about checks.
- **The balance line is chat-only**; the PR body stays what its template makes it.
- **The archive receipt is the frontmatter (with `pr:`), the H1 and the `You get:` line**; a
  rejection keeps `## Why rejected`. The task list, Notes and turned-down decision lines go — the
  worked state lives in the PR that `pr:` names, and `dw-shape`'s rejected-twin read and `dw-ship`'s
  residue check read only what stays. (nominated) — supersedes `0026`.
- Trimming keeps turned-down decision lines (inherited: 0026) — "Trimming an archive receipt keeps
  `## Decisions`' `(rejected:)` and `(unsettled:)` lines, nothing else." The line above replaces it
  once `dw-land` writes the superseding record.
- The behaviour tier is proof by a recorded run, never by the gate — `0020`'s `## Decision`, my
  extract (no `rule:`): "It is a **measurement**, not a gate: `--go` before anything runs, never in
  the `scripts` block of `package.json`, never in CI."
- The canon says `You get:` (assumed) — skill bodies are English; the agent says it in the user's
  language.
- Existing entries stay as they are (assumed) — the 8 backlog entries and 62 receipts; the rules
  change for new work, and `dw-prune` exists for the queue.
- The cap stays at 8 and repo-only (assumed).
- `dw-land close` creates nothing new (assumed) — its candidates become report lines.
- The backlog entry's frontmatter is unchanged (assumed).
- Each of the three cases runs once red on the current rules and once green on the finished branch
  (assumed) — a case that passes before the rules change proves nothing; $0.30–$1.47 a case measured.

## Out of scope

- Grateful Me — no file there; this session hands over a prompt for its `docs/agents/README.md:62`
  and `docs/agents/solo-lane.md:28-30`, which repeat "build that" and "follow-up → backlog".
- Pruning the backlog or trimming old receipts — the rules change for new work.
- Shipping the backlog cap — the named yes does what the cap forces, without a number.
- `dw-grill`'s depth — a separate goal, the interview rather than the close; the next grill.
- A `dw-next` behaviour case — `dw-shape` and `dw-land` are the named proof.

## Tasks

<!-- Convention: `- [ ]` pending, `- [x]` done — `dw-next` flips the box in the task's own commit.
A box is ticked only once the proof it names exists: the check ran, not the code got written.
A task that stopped being necessary keeps its box and gains `**skip:** <reason>`; every later
invocation reads that as not remaining. Never rename a task title. -->

- [x] 1. The three behaviour cases, red first: `dw-shape` #4 on a new fixture (an endpoint asked
      for, a page that would use it), `dw-land` #4 on a new fixture (a delivered goal whose Notes hold
      a cheap in-goal fix, an out-of-goal idea and a trap only a new hook would refuse; a plain go),
      `dw-land` #3's expectations rewritten for a named-trap yes and a short receipt — proof:
      `node evals/behaviour.ts` lists all three, then `--go` on each at this commit, results in Notes.
- [x] 2. The goal, not the session, sizes the work — `dw-shape` step 3 and read-back, the
      piece-of-a-flow extension, the internal-only rule, `dw-next`'s absorb bullet, `CONTEXT.md`
      Change and Task — proof: `grep -rn -E "session-sized|exceeds the session|small enough for a fresh session" skills/dw-shape skills/dw-next`
      prints nothing; `pnpm validate:docs`.
- [x] 3. The backlog grows only on a named yes — `dw-next`, `dw-shape`'s read-back, `dw-land`'s
      verdict, Follow-ups and description, `dw-ship`, `dw-handoff`, `dw-init`, the backlog and work
      README pairs, `templates/AGENTS.md`, `templates/agents-docs-README.md:50-51`, `README.md`,
      `CONTEXT.md` — proof: the task 2 grep over `skills templates .ai/backlog/README.md` prints
      nothing; each twin `diff` shows only its repo paragraph; `pnpm validate:docs`, `pnpm eval:routing`.
- [x] 4. Decisions, gotchas and terms grow only on a named yes, and a trap's mechanism is built here
      or not at all — `dw-land` phase 2, `dw-next`'s term line, the `CHANGE.md` template markers,
      `templates/agents-docs-README.md:34-35`, `README.md:28-33`, `CONTEXT.md` Nomination and
      Promotion — proof: `grep -n "build or" skills/dw-land/SKILL.md` prints nothing; `pnpm validate:docs`.
- [x] 5. The close ends with what the user got — `dw-land`'s report and archive trim, `dw-shape`,
      the template, the archive and work README pairs, `docs/agents/change-artifacts.md`,
      `CONTEXT.md` Archive, `README.md:118-120` — proof: the archive README twin `diff` shows only
      its repo paragraph; `pnpm validate:docs`; a reader holds step 4 and the archive step to goal line 4.
- [ ] 6. Versions and the gate — `dw-solo`, `dw-solo-setup` and `dw-solo-extras` bumped in both
      manifests, the corpus baseline re-recorded in whichever commit grew it — proof: every check in
      `package.json`'s `scripts` block passes, `pnpm validate:versions` and `pnpm eval:routing` among them.
- [ ] 7. The three cases green on the finished branch, recorded under a new `### Measured` heading in
      `evals/README.md` — proof: `node evals/behaviour.ts dw-shape --case 4 --go` and `dw-land --case 3`
      / `--case 4` grade every expectation passed.

## Anchors

- `skills/dw-shape/SKILL.md:84-87` — split siblings become backlog entries; stays, as the user's yes.
- `skills/dw-shape/SKILL.md:91-92` — "small enough for a fresh session".
- `skills/dw-shape/SKILL.md:101-106` — the read-back's three fates, one of them a backlog entry.
- `skills/dw-shape/SKILL.md:81-82` — "the receipt is `CHANGE.md` alone".
- `skills/dw-next/SKILL.md:55-58` — the session-sized absorb bullet and its backlog tier.
- `skills/dw-next/SKILL.md:70-73` — decisions nominated, terms written at once.
- `skills/dw-land/SKILL.md:4-7` — the description's "file the leftovers"; routing reads it.
- `skills/dw-land/SKILL.md:44-47` — the verdict's three-way sort, backlog "exceeds the session".
- `skills/dw-land/SKILL.md:55-71` — the decision gate; a turned-down line "rides into the archive".
- `skills/dw-land/SKILL.md:72-80` — vocabulary and gotchas; "build or backlog that".
- `skills/dw-land/SKILL.md:83-94` — follow-ups, then the archive trim.
- `skills/dw-land/SKILL.md:111-121` — the report, and the `close` mode.
- `skills/dw-ship/SKILL.md:76-79` — "the backlog is where it starts".
- `skills/dw-handoff/SKILL.md:14-16` — "follow-ups in the backlog".
- `skills/dw-init/SKILL.md:225-228` — "entries arrive later, from `dw-land`".
- `skills/dw-shape/references/CHANGE.md:28-32` — the markers; the turned-down two "survive into the archive".
- `templates/backlog-README.md` — twin of `.ai/backlog/README.md`, which adds the cap paragraph.
- `templates/work-README.md:10-11,46,62-63` — byte-identical twin `.ai/README.md`.
- `templates/archive-README.md:7-13` — twin of `.ai/archive/README.md`, which adds "rejected covers cancelled".
- `templates/agents-docs-README.md:34-35,50-51` — "Ask first whether a hook…", no threshold; follow-ups → backlog.
- `templates/AGENTS.md:47` — the Task Router row sending a follow-up to the backlog.
- `docs/agents/change-artifacts.md:11` — "the archived entry is the receipt alone".
- `CONTEXT.md:11,13,21,71,76,83` — Change, Nomination, Promotion, Absorption bar, Archive, Task.
- `README.md:28-33,69-70,118-120` — promotion sweeps follow-ups to the backlog; the archive keeps worked state.
- `evals/behaviour/dw-land.json` case 3 — expects the full narrative to survive in the archive.
- `evals/fixtures/land-gotcha-shape/`, `evals/fixtures/shape-large-change/` — the fixture patterns to copy.
- `.claude-plugin/marketplace.json:13,21,29` — `dw-solo` 0.9.5, `dw-solo-setup` 0.4.7, `dw-solo-extras` 0.4.1.

## References

- `~/workspace/private/byarcadia-app/grateful-me-app-v2` — the evidence, measured 2026-09-25 on its
  `.ai/archive`, `.ai/backlog` and `git log`: 119 changes in ~7 weeks; 143 entries created, 125
  closed, 18 open, all 18 sourced from an earlier change; median PR 259 lines; since 08-21, 33% of
  lines in `src/` and 15% in `.ai/`. Read-only for this change.
- `.ai/archive/2026-08-23-absorb-follow-ups-by-default/CHANGE.md` — made "session-sized" the bar and
  left the meta-vs-product brake out; the rules task 2 deletes.
- `.ai/archive/2026-08-18-backlog-discipline-one-change-bias-and-dw-prune/CHANGE.md` — the
  absorption bar and `dw-prune`, the attempt before that.
- `docs/decisions/0026-a-turned-down-decision-survives-the-archive-trim.md` — superseded by task 5's nomination.
- `docs/decisions/0020-the-behaviour-tier-returns-as-measurement.md`,
  `docs/decisions/0013-a-validator-over-git-history-gets-a-self-test.md` — the tier's status; why a new check is never cheap here.
- `evals/README.md` `## Behaviour` — case and fixture shape, cost, where a run's table goes; tasks 1 and 7.
- `docs/agents/skills-and-plugins.md` — bumps, the corpus re-record, and why the eval (canon via
  `--plugin-dir`) and not this session's cached skill is what exercises the edit.

## Notes

- Red on the current rules (n=1, $3.59): `dw-shape` #4 1/4 — the goal stopped at the endpoint and
  the page's button got "backlog entry (the likely next change)" as its fate; `dw-land` #3 2/4 — the
  gotcha pointed at a new `.ai/backlog/…-zero-tests-guard.md`; `dw-land` #4 2/5 — no balance, full receipt.
- `dw-land` #4 refused the `Intl` trap with a case in the existing test file, a cheap check under
  this change's rule; its expectation 3 was widened after the run to admit that path.
- `land-gotcha-shape`'s `docs/agents/README.md:28-29,42-43` is a vendored copy of
  `templates/agents-docs-README.md`; task 4 moves it with the template so #3 measures the new payload.
- Task 4 missed two spots saying dw-land keeps "what is worth keeping" — the H1 and `reject` mode; fixed on their own commit after task 5.
