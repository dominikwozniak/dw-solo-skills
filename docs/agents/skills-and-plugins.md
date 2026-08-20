# Skills and plugins — the canon, the symlinks, and how to add one

The root's layout rule — **always edit `skills/<name>/SKILL.md`, never a `plugins/…` path** — is
absolute. This file is why it works and what it costs.

## Why the indirection works

Every canon skill is shipped by exactly one plugin, and `validate-manifests.sh` enforces that ownership
in both directions. `scripts/tests/hooks-in-sync.test.sh` pins this repo's `.claude/hooks/` to the
`templates/hooks/` canon it ships, so the hooks you run are the hooks you ship.

`claude plugin install` **dereferences** symlinks — the plugin gets a real copy in the plugin cache — so
a skill body invokes a shipped script as `${CLAUDE_PLUGIN_ROOT}/scripts/<script>.sh` and the path
resolves. `templates/` gets the same treatment (`plugins/dw-solo-setup/templates -> ../../templates`,
read as `${CLAUDE_PLUGIN_ROOT}/templates/…`, since only the scaffolder consumes the payload).

A script used by only **one** skill needs no canon: bundle it in `skills/<name>/scripts/` and invoke it
via `<this-skill-dir>/…`.

## Explicit-only skills

A skill is marked `disable-model-invocation: true` for either of two reasons: it **acts outward** — on
branch topology, on the remote, or on a fresh repo's tooling — or **only you can see its moment has
come**, where a model left to guess fires it at the wrong time or not at all.

The cost is deliberate: an explicit-only skill is invisible to the model, so **no other skill can
delegate to it** — anything the loop must hand work off to stays model-invocable. _Naming_ one stays
legal, and several shipped pointers do it: a `**Next:**` line is a suggestion the reader acts on by
typing the name, which is the one route into an invisible skill. Which skills these are is the `⭑` list
in `README.md`, kept in sync by `validate-docs.sh`.

## Adding a skill

1. `skills/<name>/SKILL.md` — kebab-case `name` matching the directory (the validators' regex is
   `dw-[a-z-]+`: lowercase letters and hyphens only, no digits), a `description` that is routing signal
   only, `disable-model-invocation: true` if explicit-invoke only. For the shape, copy a near neighbour
   and keep its section order — the skills on disk are the anatomy.
2. `ln -s ../../../skills/<name> plugins/<plugin>/skills/<name>` in the **owning** plugin and `git add`
   the symlink — exactly one plugin per skill.
3. Bump the owning plugin's patch version in **both** `.claude-plugin/marketplace.json` and its
   `plugin.json`, kept identical. One bump covers a train of skills landing together.
4. Name the skill everywhere the docs list skills: the README **task-router** row, the **loop diagram**
   in README plus the root's `## The loop` if it joins the core loop (honor-system — no validator reads
   the diagram), and — if explicit-invoke — the `⭑` marker plus the explicit-only list in README.
5. End the body with a `**Next:**` line naming a skill that exists **in this repo**; a pointer at a
   team-lane skill is a dead end and `validate:docs` fails it. A cycle of new skills lands its
   `**Next:**` lines in one wiring commit at the end, since `validate:docs` only checks pointers that
   exist.
6. **Exactly one `evals/cases/<name>.json` per model-invocable skill, and none for an explicit-invoke
   one** — at least 3 positives and 2 negatives, each negative naming the `owner` that should win
   instead. Nothing validates that count any more, so it is yours to hold: a missing file is a skill
   measured by nothing, an orphan file is a case file measuring nothing, and a file for a
   `disable-model-invocation: true` skill reads as coverage while measuring a decision the model never
   makes. Shape and conventions: [`evals/README.md`](../../evals/README.md).
7. **Re-record the corpus baseline in the same commit**:
   `node scripts/check-skill-corpus.mjs --update-baseline`. A new skill is corpus growth, which pass 3 of
   `validate:artifacts` refuses until told — same when an existing `SKILL.md` legitimately gets longer,
   and when it gets shorter the slack is free growth for the next append. Why:
   [`0009`](../decisions/0009-skill-corpus-ratchet.md).
8. Run the gate (the `scripts` block of `package.json`), `eval:routing` included: a new description
   shifts every term's idf, so adding a skill can knock an _existing_ one off rank-1 and fail CI's floor
   without your own case file scoring badly at all.

Steps 2–5 and 7 are CI-enforced, bar the loop diagram; **step 6 is not** — `evals/routing.ts` skips a
case file that is absent and demands one positive and no negatives at all, so its counts are yours to
hold. `validate-manifests.sh` checks the two versions are _equal_ and `validate-versions.sh` checks the
number _grew_ — step 3 needs both to pass. The validators name the exact missing entry — run them rather
than re-deriving this checklist by hand.

## Adding a shipped (plugin-level) script

1. Put the real file once at `scripts/runtime/<script>.sh` and `chmod +x` it.
2. `ln -s ../../../scripts/runtime/<script>.sh plugins/<plugin>/scripts/<script>.sh` in every plugin
   whose skills invoke it, and `git add` the symlink (must be mode 120000).
3. Add the basename to `RUNTIME_SCRIPTS` in `scripts/validate-manifests.sh`, plus a
   `scripts/tests/<script>.test.sh` where it has logic worth pinning (anchor it to the repo root via
   `git rev-parse --show-toplevel`).

## Gotchas

- **The idf risk is a reason to run the eval, never a reason to leave a `description` wrong.** Editing
  one shifts every term's idf and can knock an unrelated skill off rank-1 (step 8), and that risk once
  kept a **known-false** sentence in place: `dw-shape` advertised "one per independently shippable scope"
  after its body had stopped meaning it, in the one field the model routes on, until a second rewrite made
  the contradiction open. Measured since, across two `description` edits and a whole new skill, rank-1
  went 67% → 68% and never fell. Run `pnpm eval:routing` and read the number; it is the cheapest check in
  the repo.
- **A skill body is read in two repos, and only one of them has this repo's tooling.** The canon is
  authored here, where `validate-artifacts.sh` caps `.ai/backlog/` and a full gate runs in CI — none of
  which ships, and `templates/backlog-README.md` omits the cap paragraph on purpose so a consumer sets its
  own number. Prose asserting that tooling is **false on arrival**: write repo-specific mechanisms as
  conditions ("where the repo caps the list"), and check the assertion against what the plugin ships
  rather than the repo you are standing in. The tell that catches it early: **when a sibling skill hedges
  a claim you are about to state flatly, the hedge is load-bearing.**
  - **An _ordering_ is a hedge, and it is the shape that gets missed.** `dw-land` says an existing root
    `## Gotchas` stays the home "in this order", falling back to the routed topic file — and four payload
    files were rewritten to name the topic file flat. A numbered fallback reads like procedure rather than
    a caveat, so it survives a search for hedge words and still breaks when flattened. Before restating a
    rule a skill owns, check whether the skill states one destination or a sequence of them.
- **The skill you are running is not the skill you are editing.** Claude Code serves
  `~/.claude/plugins/cache/dw-solo-skills/dw-solo/<version>/`, which only changes on reinstall, so a
  session can review, invoke and reason about a body several versions behind the canon it is editing with
  nothing announcing the gap — it cost a whole review pass here, `dw-check` running from 0.4.0 while the
  canon said something materially different. So **never debug a skill by its behaviour in the session that
  edits it** (invoke the canon's text by hand instead), and treat every canon skill edit as **unexercised**
  until a post-reinstall run, because no test asserts skill body content by design.
- **`${CLAUDE_PLUGIN_ROOT}` is substituted into skill _bodies_, not exported into the shell those bodies
  run.** A body's `bash "${CLAUDE_PLUGIN_ROOT}/scripts/x.sh"` resolves because the text is expanded before
  the call, but a **bundled script** reading `$CLAUDE_PLUGIN_ROOT` at runtime gets an empty string — it is
  not in the environment at all (the only `CLAUDE_*` vars in a live session are `CLAUDE_CODE_*`,
  `CLAUDE_PID` and friends). Under `set -u` that is a hard error; without it, a silently wrong path. A
  bundled script needing a sibling shipped script must resolve from its own `$0` and cover three layouts,
  because `skills/<name>/` and `plugins/<p>/skills/<name>/` sit at different depths from
  `scripts/runtime/`.
- **The two version checks answer different questions, and only one of them can see history.**
  `validate-manifests.sh` compares `marketplace.json` against the owning `plugin.json` inside one tree, so
  it catches a mismatch and nothing else; it cannot tell a bump from a number that never moved.
  `validate-versions.sh` (`pnpm validate:versions`) supplies the missing half against a base ref: it
  derives each plugin's shipped surface from the symlink graph and fails when a path under it changed
  without a **strictly higher** version. Bump the owning plugin in both manifests whenever the diff touches
  the payload; the failure names the plugin, both numbers and one changed path.
  - **It reads two refs for two jobs, and swapping them silently disables half of it.** Changed paths come
    from the merge base — what this branch did. The version comparison is against the base **tip**, because
    a branch that went 0.4.5 → 0.4.6 really did grow relative to where it forked, so a merge-base
    comparison passes the parallel-bump case every time. That is the failure that hit twice on 2026-08-02;
    `scripts/tests/validate-versions.test.sh` pins it as `number-already-taken-on-main-fails`, and it is
    the one case a merge-base mutation breaks.
  - **A base ref it cannot resolve is a SKIP, exit 0.** The validator never fetches, so a local
    `pnpm validate:versions` is only as current as your last `git fetch` — CI is the authoritative run.
    Its workflow is the one validate-* job with **no `paths:` filter**, deliberately: the check's subject
    is which paths changed, so filtering it by path would skip exactly the commit shape it exists to catch.
- **A constraint written as an intro sentence does not act like a constraint.** Review delegation belongs
  to `dw-check`, and both it and `dw-land` say so in their opening prose — which did not stop the closing
  verdict from getting its own reviewer built three lines below one of those sentences, then reverted. If a
  boundary between two skills is load-bearing, put it in the step itself, not in the paragraph that sets
  the tone.
