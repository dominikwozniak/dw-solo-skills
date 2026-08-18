# Skills and plugins — the canon, the symlinks, and how to add one

The root's layout rule — **always edit `skills/<name>/SKILL.md`, never a `plugins/…` path** — is
absolute. This file is why it works and what it costs.

## Why the indirection works

Every canon skill is shipped by exactly one plugin. `validate-manifests.sh` enforces that ownership
in both directions, and `scripts/tests/hooks-in-sync.test.sh` pins this repo's own `.claude/hooks/`
to the `templates/hooks/` canon it ships — so the hooks you run are the hooks you ship.

`claude plugin install` **dereferences** symlinks: the plugin gets a real copy in the plugin cache.
So a skill body invokes a shipped script as `${CLAUDE_PLUGIN_ROOT}/scripts/<script>.sh` and the path
resolves. `templates/` gets the same treatment (`plugins/dw-solo-setup/templates -> ../../templates`,
read as `${CLAUDE_PLUGIN_ROOT}/templates/…`, since only the scaffolder consumes the payload).

A script used by only **one** skill needs no canon: bundle it in `skills/<name>/scripts/` and invoke
it via `<this-skill-dir>/…`.

## Explicit-only skills

A skill is marked `disable-model-invocation: true` for either of two reasons: it **acts outward** —
on branch topology, on the remote, or on a fresh repo's tooling — so the model never reaches for it
unbidden, or **only you can see its moment has come**, where a model left to guess fires it at the
wrong time or not at all. The cost is deliberate: an explicit-only skill is invisible to the model, so
**no other skill can delegate to it** — anything the loop must be able to hand work off to stays
model-invocable. _Naming_ one is a different act and stays legal: a `**Next:**` line is a suggestion
the reader acts on by typing the name, which is the one route into an invisible skill, and several of
the shipped pointers do exactly that. Which skills those currently are is the `⭑` list in `README.md`,
kept in sync by `validate-docs.sh`.

## Vendored from `dw-skills` — fix in both

This is the enumeration; `CONTEXT.md` defines the two terms. These are **copies**, not references,
and nothing can detect drift across the repo boundary — **a fix here does not reach that repo, so
apply it twice**:

- The hooks this lane forked with: `block-dangerous-commands.sh`, `block-env-access.sh`,
  `block-non-pnpm.sh`, `lint-on-edit.sh`, `typecheck-on-stop.sh`. Several have been fixed here since,
  so assume diverged rather than identical. The team repo also ships a Ruby lint hook this Node-only
  lane deliberately drops; don't "re-sync" it back.
- `scripts/runtime/slugify.sh`.

Everything else under `templates/hooks/` — `credential-leak-guard.sh`, `enforce-commit-hygiene.sh`,
`guard-plugin-canon.sh`, `large-file-guard.sh` — was written here in the guardrail hook wave and has
no upstream at all. `scripts/tests/hooks-in-sync.test.sh` pins the templates to _this_ repo's
`.claude/hooks/` and to nothing in `dw-skills`.

A skill copied from `dw-skills` is a **fork**, simplified for one reader — expected to diverge, never
re-synced. Current forks: `dw-grill`, `dw-shape`, `dw-next`, `dw-land`, `dw-git`, `dw-doctor` and
`dw-init` (which also absorbed the team lane's standalone pre-commit skill). `dw-start`, `dw-check`,
`dw-ship`, `dw-handoff`, `dw-prune` and `scripts/runtime/worktree.sh` are this lane's own — they have
no upstream.
`dw-handoff` is the one to watch: it shares a name with a team-lane skill and nothing else, having
been written here after the team lane dropped handoffs on purpose, and it writes one overwritten
`HANDOFF.md` inside the change folder rather than a dated record under `.ai/handoffs/`.

## Adding a skill

1. `skills/<name>/SKILL.md` — kebab-case `name` matching the directory (the validators' regex is
   `dw-[a-z-]+` — lowercase letters and hyphens only, no digits), a `description` that is routing
   signal only, `disable-model-invocation: true` if explicit-invoke only. For the shape, copy a near
   neighbour and keep its section order — the skills on disk are the anatomy.
2. `ln -s ../../../skills/<name> plugins/<plugin>/skills/<name>` in the **owning** plugin and
   `git add` the symlink — exactly one plugin per skill.
3. Bump the owning plugin's patch version in **both** `.claude-plugin/marketplace.json` and its
   `plugin.json` — keep the two identical. One bump covers a train of skills landing together.
4. Name the skill everywhere the docs list skills: the README **task-router** row, the **loop
   diagram** in README + the root's `## The loop` if it joins the core loop (honor-system — no
   validator reads the diagram), and — if explicit-invoke — the `⭑` marker plus the explicit-only
   list in README.
5. End the body with a `**Next:**` line naming a skill that exists **in this repo** — a pointer at a
   team-lane skill is a dead end here, and `validate:docs` fails it. A cycle of new skills lands its
   `**Next:**` lines in one wiring commit at the end; `validate:docs` only checks pointers that
   exist.
6. **Exactly one `evals/cases/<name>.json` per model-invocable skill, and none for an explicit-invoke
   one** — at least 3 positives and 2 negatives, each negative naming the `owner` that should win
   instead. Nothing validates that count any more, so it is yours to hold: a missing file is a skill
   measured by nothing, an orphan file is a case file measuring nothing, and a file for a
   `disable-model-invocation: true` skill reads as coverage while measuring a decision the model never
   makes. Shape and conventions: [`evals/README.md`](../../evals/README.md).
7. **Re-record the corpus baseline in the same commit**: `node scripts/check-skill-corpus.mjs
--update-baseline`. A new skill is corpus growth, which pass 3 of `validate:artifacts` refuses
   until told. Same when an existing `SKILL.md` legitimately gets longer — and when it gets shorter,
   or the slack is free growth for the next append. Why it works this way:
   [`0009`](../decisions/0009-skill-corpus-ratchet.md).
8. Run the gate (the `scripts` block of `package.json`) — `eval:routing` included, because a new
   description shifts every term's idf, so adding a skill can knock an _existing_ one off rank-1 and
   fail CI's floor without your own case file scoring badly at all.

Steps 2–7 are CI-enforced (bar the loop diagram, and CI checks the versions are _equal_, not that
they changed). The validators name the exact missing entry — run them rather than re-deriving the
checklist by hand.

## Adding a shipped (plugin-level) script

1. Put the real file once at `scripts/runtime/<script>.sh` and `chmod +x` it.
2. `ln -s ../../../scripts/runtime/<script>.sh plugins/<plugin>/scripts/<script>.sh` in every plugin
   whose skills invoke it, and `git add` the symlink (must be mode 120000).
3. Add the basename to `RUNTIME_SCRIPTS` in `scripts/validate-manifests.sh`, plus a
   `scripts/tests/<script>.test.sh` where it has logic worth pinning (anchor it to the repo root via
   `git rev-parse --show-toplevel`).

## Gotchas

- **A skill body is read in two repos, and only one of them has this repo's tooling.** The canon is
  authored here, where `validate-artifacts.sh` caps `.ai/backlog/` and a full gate runs in CI — none of
  which ships; `templates/backlog-README.md` even omits the cap paragraph on purpose, so a consumer sets
  its own number. So prose asserting that tooling is **false on arrival**. Write repo-specific
  mechanisms as conditions ("where the repo caps the list"), and check the assertion against what the
  plugin actually ships rather than against the repo you are standing in. The tell that catches it
  early: **when a sibling skill hedges a claim you are about to state flatly, the hedge is load-bearing,
  not throat-clearing.**
  - **An _ordering_ is a hedge, and it is the shape that gets missed.** `dw-land` says an existing root
    `## Gotchas` stays the home "in this order", falling back to the routed topic file — and four
    payload files were rewritten to name the topic file flat, in the same change that rewrote the entry
    above. A numbered fallback reads like procedure rather than a caveat, so it survives a search for
    hedge words and still breaks when you flatten it. Before restating any rule a skill owns, check
    whether the skill states one destination or a sequence of them.
- **The skill you are running is not the skill you are editing.** Claude Code serves
  `~/.claude/plugins/cache/dw-solo-skills/dw-solo/<version>/`, which only changes on reinstall — so a
  session can review, invoke and reason about a body several versions behind the canon it is editing,
  with nothing announcing the gap. It cost a whole review pass here: `dw-check` ran from 0.4.0 while
  the canon said something materially different, and the discrepancy read as a missing feature. Two
  consequences: **never debug a skill by its behaviour in the session that edits it** — invoke the
  canon's text by hand instead — and treat every canon skill edit as **unexercised** until a
  post-reinstall run, because no test asserts skill body content by design.
- **`${CLAUDE_PLUGIN_ROOT}` is substituted into skill _bodies_, not exported into the shell those
  bodies run.** A skill body's `bash "${CLAUDE_PLUGIN_ROOT}/scripts/x.sh"` resolves because the text
  is expanded before the call — but a **bundled script** reading `$CLAUDE_PLUGIN_ROOT` at runtime
  gets an empty string, because it is not in the environment at all (confirmed by dumping `env` in a
  live session; the only `CLAUDE_*` vars there are `CLAUDE_CODE_*`, `CLAUDE_PID` and friends). Under
  `set -u` that is a hard error; without it, a silently wrong path. A bundled script that needs a
  sibling shipped script must resolve from its own `$0`, and must cover three layouts, because
  `skills/<name>/` and `plugins/<p>/skills/<name>/` sit at different depths from `scripts/runtime/`.
- **`validate-manifests.sh` checks the two versions are _equal_, not that either moved.** Change a
  shipped file — anything under `templates/` or `scripts/runtime/` — and CI stays green with no bump,
  while every installed consumer keeps the old copy. Nothing else catches it: the add-a-skill
  checklist only fires when a skill is added, and `dw-ship` never mentions versions at all. Bump the
  owning plugin by hand, in `marketplace.json` and its `plugin.json` together, whenever the diff
  touches the payload.
- **A constraint written as an intro sentence does not act like a constraint.** Review delegation
  belongs to `dw-check`, and both it and `dw-land` say so in their opening prose — which did not stop
  the closing verdict from getting its own reviewer built three lines below one of those sentences,
  then reverted. If a boundary between two skills is load-bearing, put it in the step itself, not in the
  paragraph that sets the tone.
