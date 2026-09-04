# `docs/agents/` — the routed topic layer

Three tiers, and the difference between them is **when they load**:

| tier          | file(s)                                    | loads                               |
| ------------- | ------------------------------------------ | ----------------------------------- |
| always-loaded | root `AGENTS.md` (`CLAUDE.md` symlinks it) | every session, in full              |
| topic rules   | `docs/agents/*.md`                         | on demand, via the root Task Router |
| change state  | `.ai/`, `docs/decisions/`                  | never eagerly; the skills own them  |

**The root holds only what applies to every task regardless of what you touch** — plus the two blocks
the tooling reads directly, `## Solo lane` and `## Git conventions`, which live there and nowhere
else. Anything scoped to one subject belongs in a topic file. The root is budgeted because it is paid
for on every session; a topic file is read when its subject comes up, which is where prose belongs.

**A topic file and its Task Router row land in the same commit.** A file nothing routes to is a file
nothing reads, and `agents:check` fails both halves: a topic file with no row, and a row pointing at a
path that does not exist. Over budget is never a licence to trim a rule — move the topic out and route
it.

**A trap that cost real time goes in the `## Gotchas` of the topic file whose subject covers it, as
one undated bullet of at most two lines** — do or never X, one clause of why, a pointer. Newest
first, by position: the top of the list _is_ the newest, so a date buys nothing and costs the shape.
An entry stamped with the day it was learned reads as a log, and a log is appended to rather than
rewritten. What happened, when, and what it measured belongs in the commit and the archived change
doc. Not the root either, which loads in full every session, so traps there push a real rule out.

**Ask first whether a hook, a validator or a lint rule would refuse the trap outright** — a rule
enforced on trust is one a tired session skips. When that mechanism arrives, **delete the prose it
replaced and leave its name**; when an argument is settled in `docs/decisions/`, replace the argument
here with a pointer to the record. Writing the new rule _beside_ the prose it made redundant is how a
corpus doubles without anyone deciding it should.

**Two numbers hold this layer, and both are yours to delete.** `agents:check` measures every
`docs/agents/*.md` except this one against the budget declared below, and separately refuses a silent
increase in the corpus as a whole against `corpus.baseline.json`, which `dw-init` seeded. Growth stays
legal and costs one `--update-baseline` in the same commit, so no threshold is chosen and none can be
set too high. Delete the baseline file to switch the ratchet off. Delete the line below to switch the
cap off — and with it the one shape rule a number cannot express, the ban on a dated bullet.

Topic budget: **90 lines / 4.5 KB**, per file, this one excluded.

**Not here.** What a word _means_ goes in `CONTEXT.md`, on the same terms: one bullet, at most two
lines, no rationale. Why the code is shaped this way goes in `docs/decisions/`. A follow-up worth
keeping but not worth doing now goes in `.ai/backlog/`.
