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

**A trap that cost real time goes in the `## Gotchas` of the topic file whose subject covers it** —
newest first, one entry saying the trap and what to do instead. Not the root, which is loaded in full
every session, so a growing list of traps there pushes a real rule out. Ask first whether a hook, a
validator or a lint rule would refuse the trap outright; a rule enforced on trust is one a tired
session skips.

**Not here.** What a word _means_ goes in `CONTEXT.md`. Why the code is shaped this way goes in
`docs/decisions/`. A follow-up worth keeping but not worth doing now goes in `.ai/backlog/`.
