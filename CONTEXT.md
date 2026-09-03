# Context — glossary

Terms this repo uses in a specific way. Definitions only, no implementation detail — the rules live
in [`AGENTS.md`](AGENTS.md) and the procedures in the skills themselves.

- **Lane** — how much process a change gets. This repo is the **thin lane**: one reader, and only the
  ceremony a solo change pays for.
- **Canon** — the single real copy of a file. `skills/<name>/` and `scripts/runtime/<s>.sh` are canon;
  everything under `plugins/` is a git-tracked symlink back to it. Never edit through `plugins/…`.
- **Change** — one unit of work, held in `.ai/work/<date>-<slug>/CHANGE.md`. Persistent (tracked,
  survives a `/clear`), archived at merge (`.ai/archive/<date>-<slug>/`, `status: landed`).
- **Entry name** — `<YYYY-MM-DD>-<slug>`, from `slugify.sh dated`, for every entry in the three `.ai/`
  lanes. Each lane stamps **its own** date (noted, shaped, landed), so only the **bare slug** is
  comparable across them — `slugify.sh undate` strips a prefix, and `docs/decisions/` is exempt because
  its `NNNN-` numbering already sorts.
- **Promotion** — moving the durable residue out of a `CHANGE.md`, **as it happens**: `dw-next`
  writes a decision or term in the task's own commit, and `dw-land` sweeps what is left at close —
  traps to the `## Gotchas` of the routed topic file, stale pointers rewritten, follow-ups to
  `.ai/backlog/` (one file per idea). It **replaces rather than appends**: each target is read
  first, and what the change supersedes is deleted in the same edit. Decisions are the exception —
  there the replacement is a `superseded-by:` link and the old record stays.
- **Cap** — the limit `validate-artifacts.sh` enforces on `.ai/backlog/`, the one durable list that
  would otherwise only grow; that script holds the number. A count of **entries**, never of bytes or
  lines, and a forcing function rather than a quota — the way past a full list is to bundle an entry
  with a cousin that ships alongside it, absorb one into the open change, or retire one that failed
  the month bar. Set by [`0006`](docs/decisions/0006-delete-the-second-copy-and-cap-the-pile.md),
  which also capped `## Gotchas` until
  [`0008`](docs/decisions/0008-root-budget-replaces-the-gotcha-cap.md) replaced that half with the
  root's **Budget**. One of four limits the lane uses, and the four are not interchangeable: a **Cap**
  counts entries, a **Budget** and a **Ceiling** are declared sizes, and a **Ratchet** declares no
  size at all.
- **Ceiling** — a declared per-file size over a durable folder, enforced by the shipped
  `check-agents-docs.mjs` where that folder's README declares one, and **opt-in**: no declaration means
  no check and no mention. It gates size and never shape, the distinction
  [`0015`](docs/decisions/0015-the-shipped-checker-gates-size-never-shape.md) rests on. A **Budget** is
  the same kind of number over a single always-loaded file; a Ceiling applies per file across a folder.
- **Ratchet** — a limit that chooses no number: a tracked baseline records what a corpus **is**, the
  corpus may shrink freely, and it grows only through a commit that re-records the baseline. Growth
  stays legal and stops being silent. Used over `skills/*/SKILL.md` here by
  [`0009`](docs/decisions/0009-skill-corpus-ratchet.md), and over a consumer repo's `docs/agents/` by
  the shipped checker. The right tool where the form is open and any ceiling would be a guess.
- **Completion gate** — the closing verdict's rule that a `## Goal` result the diff doesn't deliver
  makes a change **not ready**, never _ready with follow-ups_. Ticked boxes don't satisfy it; only
  the diff does, or a `## Goal` the user amends. One carve-out: a result that is **pending on the
  push** — unobservable at land time rather than undelivered, "CI is green" being the only real case —
  closes **ready to merge** with that line attached. The name is loose about the trigger: on a feature
  branch it is `dw-land` **opening the PR** that starts the run, not the push before it, and only on
  the default branch does the push itself trigger anything. Either way `dw-ship` reads the result
  before merging. The bar is that the evidence cannot exist yet, never that gathering it is
  inconvenient.
- **Base ref** — which ref of the default branch a diff is taken against, local or `origin/`. Never
  `origin/` by reflex: whichever of the two contains the other wins, and local is the default, because
  a local branch that is _ahead_ (an unpushed `chore: shape …` commit) makes `origin/` pull commits the
  branch didn't write into the diff. Resolved once, in `dw-git`, for the review diffs `dw-check` and
  `dw-land` take. `validate-versions.sh` is the other consumer and resolves its own: it needs **two**
  refs, the merge base for which paths changed and the base _tip_ for whether the version grew.
- **Triviality floor** — the diff size below which `dw-check` self-reviews instead of handing the diff
  to an outside reviewer. The `codex` argument overrides it, and overrides nothing else; a missing
  reviewer is not something it can override. The numbers live in the skill, not here. Set by
  [`0012`](docs/decisions/0012-bare-dw-check-delegates-by-default.md).
- **Absorption bar** — the second test a backlog entry must clear, and a **default rather than a
  judgement**: nothing blocks it and doing it costs less than describing it → the change that found
  it, now. Only genuinely blocked work — waiting on a decision, a dependency, a change not yet made —
  earns an entry. Joins the month bar (_will you ever?_), which tests only whether the idea is worth
  queueing at all. `dw-prune` applies it late, to a queue that grew anyway.
- **Archive** — `.ai/archive/<date>-<slug>/`: landed change docs kept as history, not guidance. Nothing
  reads them to decide anything. An entry is a **receipt** rather than the working doc — frontmatter,
  the H1, the task list as it was left, and only the notes no durable target took. Two statuses end
  up here and there is no third: `landed`, and **`rejected` ≡ cancelled** — one status for an idea
  turned down and for work abandoned mid-build, since both leave the same thing behind (a
  `## Why rejected`) and nothing downstream tells them apart.
- **Task** — one ticked box in a `CHANGE.md`: a thin vertical slice, independently committable, leaving
  the project green. Not a layer ("add all the migrations" is not a task).
- **Anchor** — a `path/to/file.rb:42` reference in a `CHANGE.md`. Orientation for a fresh session, never
  an edit script; re-verified when the work resumes.
- **Payload** — `templates/`: files `dw-init` copies **verbatim into a target project**, never read
  from the plugin at runtime. Not canon; a payload file may have a hand-written twin here.
- **Shipped surface** — every path one plugin's install would carry: `plugins/<p>/**` plus the canon
  behind each of its symlinks — the skills, the runtime scripts, and `templates/` where it links one.
  Wider than payload, and never `.claude-plugin/marketplace.json`, which is where half a bump lands.
  A change touching a plugin's surface must bump that plugin; `validate-versions.sh` derives the map
  from the symlink graph rather than a list.
- **Vendored** — a consumer repo's copy of a shipped template, written there by `dw-init`. It can fall
  behind what this repo ships; `dw-doctor` is what detects that.
- **Carry class** — which treatment an untracked file gets when a worktree is created: **copy** (local
  config, via `.worktreeinclude`), **regenerate** (`node_modules/`, `.husky/_/` — reported, never
  carried) or **absent** (caches). A fourth, **link**, held only personal agent memory; it is gone,
  not merely empty — the machinery implementing it (`link-local-memory.sh` and `worktree.sh`'s link
  step) is deleted, because that memory is tracked and the checkout delivers it. Set by
  [`0003`](docs/decisions/0003-worktree-carry-classes.md), the link class retired by
  [`0007`](docs/decisions/0007-agent-memory-in-tracked-agents-md.md) and its code removed with the
  hook wave.
- **Budget** — the line-and-byte ceiling a root `AGENTS.md` declares **about itself**, in its own prose
  (`Budget: **120 lines / 10 KB**`), enforced by the `check-agents-docs.mjs` the payload ships. Chosen
  editorial discipline, not a harness ceiling: nothing truncates there, and it is ~3× stricter than
  Codex's 32 KB `project_doc_max_bytes`. Over budget, a topic moves out to a **routed topic file** —
  trimming a rule is not the way past it.
- **Self-measuring number** — a figure in prose that measures this repo against itself: a line count,
  a byte size, a warning tally, a count of files in a directory. Deleted rather than corrected — the
  prose states the rule and the checker reports the number, because two copies of a moving measure
  drift apart. Distinct from a **Budget** or a **Cap**, which are numbers somebody chose.
- **Declared bullet** — a `- **<Name>**: <value>` line under `## Solo lane` that a hook **greps**
  rather than infers, so the rule the writer reads and the rule the enforcer applies are one line.
  Four exist: **Lint command**, **Typecheck command**, **Commit pattern**, **Commit trailer**. All
  resolve alike — `AGENTS.md`, then a legacy `CLAUDE.local.md`, then a default in the script — with the
  value the line's first backticked span, and a standalone `none` disabling the check. Set by
  [`0010`](docs/decisions/0010-policies-the-hooks-enforce-are-declared-bullets.md).
- **Task Router** — the table in a root `AGENTS.md` mapping a kind of task to the doc to read. It is
  the only thing that makes the topic layer reachable, so the checker holds it to both directions:
  every `docs/agents/*.md` needs a row, and every path a row's `read` column names must exist.
- **Routed topic file** — `docs/agents/<topic>.md`: prose lifted out of the root file, reached only
  through its router row. Where a gotcha lands in a scaffolded repo, and created together with its row
  in one commit — a topic file nothing routes to is a file nothing reads.
- **Reference file** — `skills/<name>/references/<file>.md`: a block lifted out of a `SKILL.md`
  because it runs on only some invocations, reached by a pointer the body keeps. The skill-level twin
  of a routed topic file, and what a hot skill sheds instead of being trimmed; `validate-docs.sh`
  check 6 refuses a pointer with no file behind it.
- **Reference** — a `## References` line in a `CHANGE.md`: a pointer at something outside the change
  — a URL, a design doc, a sibling repo — carried from grill or shape time so the build does not
  rediscover it. Not the **reference file** above, and not a scaffolded project's own `references/`
  folder; the word keeps all three senses on purpose (`docs/decisions/0017`).
- **Explicit-invoke** — a skill with `disable-model-invocation: true`; it fires only when named.
- **Case file** — one per skill per tier, and the two tiers ask different things.
  `evals/cases/<skill>.json` holds routing prompts: **positives** that should route here and
  near-miss **negatives** that should not, each naming the `owner` that should win instead — one per
  model-invocable skill, none for an explicit-invoke one. `evals/behaviour/<skill>.json` holds
  **expectations**: what the skill must be seen to do once it is running — or, where the promise is
  that nothing happens, what must never appear in the trace at all — graded from that trace. An
  explicit-invoke skill gets one of those, reached by slash.
- **Shadowed** — a positive prompt where an explicit-invoke skill scores higher than the skill under
  test. Reported as overlap, never counted as a routing failure: the model is never offered it.
- **Blank** — a prompt no description discriminates on, so every skill scores zero. A blank negative
  fails the run outright; a blank positive is counted in its own column under a `--max-blank` ratchet,
  because one of them is a description missing words and another is a trade this repo took knowingly.
- **Fixture** — `evals/fixtures/<name>/`, a throwaway repo the behaviour eval builds and destroys per
  run: `base/` committed on `main`, `branch/` committed on the feature branch so `main...HEAD` has a
  diff, `dirty/` left uncommitted.
- **HARD STOP** — a point in a skill where it must stop and wait for a human answer rather than
  proceed on an assumption.
- **Fact-token diff** — the check that a doc rewrite kept its content: every backticked span, path,
  flag, number and error string in the old text, checked for presence in the new. Reads a rewrite too
  heavy for the word-stream window `docs/agents/README.md` prescribes beside it.
- **Rung** — one of five levels a safety claim in a closing verdict can reach, weakest first: you said
  so · you pointed at the line · you showed the bad case cannot happen · you ran it · you reproduced it
  in the artifact a user gets rather than the tree you edited. `dw-land` names the one each claim
  stopped at; the bottom rung here means a **post-reinstall** run, so it is out of reach until merge.
- **`VERIFY.md`** — the tracked file recording how to drive a project by hand: **Launch**, **Doctor**
  (one read-only check that an instance is worth driving) and **Drive** (commands paired with the
  result each should produce). Scaffolded by `dw-init`, never per-change — that is the `.ai/verify/`
  the lane deliberately has no use for. A project with nothing to launch keeps the headings as written,
  and that is a finished file rather than a stub; this repo is one, so it has none.
