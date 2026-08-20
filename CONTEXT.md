# Context — glossary

Terms this repo uses in a specific way. Definitions only, no implementation detail — the rules live
in [`AGENTS.md`](AGENTS.md) and the procedures in the skills themselves.

- **Lane** — how much process a change gets. This repo is the **thin lane**: one reader, and only the
  ceremony a solo change pays for.
- **Canon** — the single real copy of a file. `skills/<name>/` and `scripts/runtime/<s>.sh` are canon;
  everything under `plugins/` is a git-tracked symlink back to it. Never edit through `plugins/…`.
- **Change** — one unit of work, held in `.ai/work/<slug>/CHANGE.md`. Persistent (tracked, survives a
  `/clear`), archived at merge (`.ai/archive/<slug>/`, `status: landed`).
- **Promotion** — moving the durable residue out of a `CHANGE.md` before it is archived: decisions to
  `docs/decisions/`, terms here, traps to the `## Gotchas` of the routed topic file that covers them,
  follow-ups to `.ai/backlog/` (one file per idea). It **replaces rather than appends**: each target
  is read first, and what the change supersedes is deleted in the same edit. Decisions are the
  exception — there the replacement is a `superseded-by:` link and the old record stays.
- **Cap** — the ceiling `validate-artifacts.sh` enforces on `.ai/backlog/`, the one durable list that
  would otherwise only grow; that script holds the number. A count of entries, never of bytes, and a
  forcing function rather than a quota — the way past a full list is to bundle an entry with a cousin
  that ships alongside it, absorb one into the open change, or retire one that failed the month bar.
  Set by [`0006`](docs/decisions/0006-delete-the-second-copy-and-cap-the-pile.md), which also capped
  `## Gotchas` until [`0008`](docs/decisions/0008-root-budget-replaces-the-gotcha-cap.md) replaced
  that half with the root's **Budget**.
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
- **Archive** — `.ai/archive/<slug>/`: landed change docs kept as history, not guidance. Nothing
  reads them to decide anything; backlog entries may point at one for its findings. Two statuses end
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
- **Claim** — flipping a change doc's `branch: unclaimed` sentinel to a real branch name, committed
  immediately. Done by `dw-start` (after creating the worktree) or offered by `dw-next` (when its
  branch-grep misses). A change shaped on the default branch is unclaimed until then.
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
- **Ratchet** — a governor that records what a measure currently **is** and refuses only an increase,
  so no threshold is ever chosen. Over the skill corpus:
  `scripts/skill-corpus.baseline.json` plus pass 3 of `validate:artifacts`, set by
  [`0009`](docs/decisions/0009-skill-corpus-ratchet.md). Growth stays legal at the price of a
  re-record in the same commit.
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
- **Explicit-invoke** — a skill with `disable-model-invocation: true`; it fires only when named.
- **Case file** — `evals/cases/<skill>.json`: prompts that should route to a skill (**positives**) and
  near-miss prompts that should not (**negatives**, each naming the `owner` that should win instead).
  One per model-invocable skill, none for an explicit-invoke one.
- **Shadowed** — a positive prompt where an explicit-invoke skill scores higher than the skill under
  test. Reported as overlap, never counted as a routing failure: the model is never offered it.
- **HARD STOP** — a point in a skill where it must stop and wait for a human answer rather than
  proceed on an assumption.
- **Fact-token diff** — the check that a doc rewrite kept its content: every backticked span, path,
  flag, number and error string in the old text, checked for presence in the new. Reads a rewrite too
  heavy for the word-stream window `docs/agents/README.md` prescribes beside it.
