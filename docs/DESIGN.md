# Design notes

Why the skills are shaped this way. The [README](../README.md) is the short version; this is the
_why_ behind the shape.

The skill set is currently being rebuilt from scratch, so this document names **roles** rather than
skills — "the closing pass", "the resume step". Each constraint below is binding on whatever skill
ends up filling that role; substitute the real names as they land.

## The failure modes these skills target

| Failure mode                              | Design answer                                                   |
| ----------------------------------------- | --------------------------------------------------------------- |
| Context dies on `/clear`                  | The change persists as a tracked `.ai/` file, not in context    |
| Agent runs on a wrong assumption          | A bounded interview surfaces decisions before code              |
| "Done" is claimed but never proven        | The closing pass checks ticked boxes against what actually runs |
| One skill grows into a do-everything blob | One skill, one job — they compose through `.ai/`, not chains    |
| The process outweighs the change          | One file and one pass, not three artifacts and five audits      |
| A private repo accumulates and forgets    | The closing pass deletes the doc but promotes the durable parts |

## Persistence lives in the skill, not a wrapper

**The change doc is on disk, not in the model's head.** Each `SKILL.md` writes its own `.ai/` path as
part of its procedure — there's no `.claude/commands/` glue layer translating intent into a file
location. The doc lands automatically and travels with the installed plugin, so it survives a
`/clear`, a new session, or a week away. A workflow whose state lives only in context is one you
can't reliably resume.

## `.ai/` is tracked, one folder per change, no central index

**Artifacts are real work documents, committed with the code — not scratch.**

- **No shared index file.** A central registry becomes a merge-conflict magnet once tracked. Discovery
  is by directory name + per-file frontmatter, so two branches never fight over one file.
- **One folder per change** (`.ai/work/<slug>/`) — parallel branches and worktrees don't collide.
- **Branch-matched resume.** A change doc records its branch; the resume step globs the work dirs,
  matches the current branch, and reports the first unticked box. Deterministic — no scrollback
  archaeology.
- **Branch reads use `git rev-parse --abbrev-ref HEAD`**, never `git branch --show-current`, which
  returns an empty string on a detached HEAD and silently turns a branch match into a no-match.

## Persistent but disposable — and what gets promoted out

**The change doc is tracked so a gap costs nothing, and deleted at merge so the repo doesn't rot.**
These two ideas are usually conflated; splitting them is the point of the closing pass's second
phase.

What is genuinely durable is **promoted out** to four targets before the doc is deleted:

| Target                      | What goes there             | Why that one                                        |
| --------------------------- | --------------------------- | --------------------------------------------------- |
| `docs/decisions/`           | hard-to-reverse decisions   | needs the reasoning, not just the outcome           |
| `CONTEXT.md`                | domain terms, glossary only | a term you'd have to re-derive every session        |
| `## Gotchas` in `CLAUDE.md` | traps that cost real time   | **auto-loaded** — the next session reads it unasked |
| `.ai/BACKLOG.md`            | ordinary follow-ups         | clears none of the above bars, still real           |

Without that closing step a private repo accumulates stale specs _and_ loses the decisions worth
keeping — the one failure a thin lane would otherwise introduce.

The backlog is the fourth target because the other three each have a high bar, and an ordinary
follow-up clears none of them. It stays a flat, unvalidated list on purpose: the moment it grows a
status column it is the validated plan this lane exists to avoid.

## One gate, not a skill boundary

A team-weight workflow splits quality across several read-only auditors and a separate writer, because
an auditor that can also patch is tempted to under-report what it couldn't fix. Here you read every
finding before anything happens, so the honesty is enforced by you instead: the closing pass
**reports first and mutates only after an explicit approval**, with the gate between its two phases
doing the work the skill boundary did.

Two more things this lane drops, and why that's safe:

- **The validated status table.** A plan's SHA column and immutable step ids exist so a second reader
  can trust the record. A checklist has no invariants that can break silently, which is why nothing
  here validates `.ai/work/` — see `scripts/validate-artifacts.sh`.
- **Handoffs.** There is no one to hand off to. `.ai/handoffs/` is deliberately never created.

## Technology-agnostic by construction

**No stack knowledge is hardcoded — every command is read from your project.** A skill finds the
commands it needs (test, lint, run) in this order:

1. a declared `## Commands` block in `CLAUDE.md` / `AGENTS.md`,
2. then manifests and scripts (`package.json`, `Gemfile` + `bin/`, `Makefile`, …),
3. then the code itself.

Stack is detected by which manifest is present, never branched on by name. With no declared commands a
skill auto-detects and **states its assumption, asking when ambiguous** — it never guesses silently.

Tier 1 is populated, not hoped for: the scaffolding step seeds `## Commands` in **tracked**
`CLAUDE.md` from the commands it actually found. Tracked matters — a copy that lives only in the gitignored
`CLAUDE.local.md` is invisible on a fresh clone and to any agent that reads `AGENTS.md`. That file
keeps its own copy anyway, because the lint and typecheck hooks grep it for those names, so the two
must be updated together.

Being gitignored has one more consequence, and it is why the `link-local-memory` hook exists: a
`git worktree` checkout receives only **tracked** files, so `CLAUDE.local.md` is simply absent there.
Without it a git skill loses the repo's `## Git conventions` — commit format, trailer policy, the
signing rule — and falls back to generic defaults. The visible symptom is a worktree commit carrying a trailer
the main tree forbids. The hook closes it by symlinking the main tree's copy in at `SessionStart`,
detecting the worktree via `--git-dir` vs `--git-common-dir` (a path compare would misfire: in the
main tree `--git-common-dir` returns a relative `.git`).

## Thin harness, fat skills

**The intelligence lives in the markdown, not in glue code.** A skill's weight tracks its procedure,
not a line budget; bulky detail loads on demand from `references/`. The harness stays thin, so every
model upgrade improves the skills for free. This is the direct application of **"Fat Skills"**
(Garry Tan) — see [Inspiration](#inspiration--further-reading).

The same budget applies to a skill's `description`. Every installed skill's description sits in the
context window of every session, whether or not the skill fires — so it carries routing signal only:
what the skill does, how it differs from its nearest sibling, and the phrases that should trigger it.
Procedure detail belongs in the body, which is paid for once, on invoke. A description that names a
skill from the _other_ repo is pure noise here, since it isn't installed.

## The symlink canon — one file, one plugin

**A skill or a shipped script exists once, and the plugin reaches it through git-tracked symlinks.**
The canon is `skills/<name>/` and `scripts/runtime/<script>.sh`; `plugins/dw-solo/skills/<name>` and
`plugins/dw-solo/scripts/<script>.sh` are mode-120000 symlinks back to it.

This works because `claude plugin install` **dereferences** symlinks — the plugin gets its own real
copy in the plugin cache. So a skill body invokes a shipped script through the unchanged
`${CLAUDE_PLUGIN_ROOT}/scripts/<script>.sh` and the path resolves to a real file.

With a single plugin the indirection buys little today. It is kept because the rule it enforces —
**never edit through a `plugins/…` path** — is absolute, and because `templates/` needs the same
treatment: `plugins/dw-solo/templates -> ../../templates`, read as
`${CLAUDE_PLUGIN_ROOT}/templates/…`. `scripts/tests/hooks-in-sync.test.sh` pins this repo's own
`.claude/hooks/` to that canon, so the hooks you run are the hooks you ship.

## Composable, not chained

**Skills stay separate and connect through artifacts — never a forced sequence.** Two light links
connect them: the shared `CHANGE.md`, and a `**Next:**` pointer at the end of each body. The pointer
is a recommendation, not a rail — and `validate-docs.sh` checks it names a skill that actually exists
in this repo, because a stale pointer at a team-lane skill is a dead end.

## Why this is a separate repo

This lane started inside [`dw-skills`](https://github.com/dominikwozniak/dw-skills), sharing that
repo's `templates/` canon, runtime scripts and CI. The concrete reason it moved out: **the shared
`templates/` payload was team-shaped and this lane paid for it at runtime.** The template
`CLAUDE.local.md` shipped the team loop, so the scaffolding step had to replace a whole section after
copying; the `.ai/` README documented `runs/`/`verify/`/`handoffs/`, so it was told not to copy that
one and to hand-write one inline; the gitignore markers read `dw-bootstrap managed block`. Three
work-arounds-in-prose that a separate `templates/` deletes outright.

The costs, stated plainly rather than discovered later:

- **`templates/hooks/` and `slugify.sh` are vendored copies.** Byte-identical today; a fix must be
  applied in both repos, and nothing across the boundary can detect drift. `hooks-in-sync.test.sh`
  only pins this repo's `.claude/hooks/` to its own canon.
- **Skills that exist in both lanes will be forks**, simplified for one reader, and are _meant_ to
  diverge — a solo git skill drops ticket prefixes and the PR flow, a solo health check drops the
  team checks. Don't re-sync them.
- **Two marketplace sources** if you ever want both lanes on one machine.

**Install one lane per repo, not both.** Two lanes in one project means two skills competing for
"start a feature", and no description wording fixes that reliably. Claude Code scopes plugins per
project, which is the right place to make the choice once — the scaffolding step sets that switch
with `claude plugin disable`, and the health check asserts it held.

## Loops vs persistence — why these skills don't auto-run

**This catalog chooses persistence plus a human gate over an autonomous loop.** A loop that takes a
wrong turn doesn't waste one step; it compounds, multiplying both the error rate and the token burn
for as long as it runs unwatched. The value here — a change doc that survives `/clear`, a verdict tied
to real `file:line`s, a "done" that was actually run — needs none of that. **The HARD STOP is the
feature, not a gap waiting to be automated away.**

This matters more in a solo repo, not less: there is no reviewer downstream to catch what a runaway
loop got wrong.

## Inspiration & further reading

- **Fat Skills** — Garry Tan, on skills that carry their own process instead of being thin wrappers:
  <https://x.com/garrytan/status/2042925773300908103>.
- **Anthropic — Agent Skills** — the official concept these build on:
  <https://docs.claude.com/en/docs/agents-and-tools/agent-skills>.
