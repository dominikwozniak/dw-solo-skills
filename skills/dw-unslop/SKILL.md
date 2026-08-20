---
name: dw-unslop
description: >-
  Cut the AI tells out of text a human will read — a PR body, a commit body, a release note — without
  flattening it into something voiceless. Refuses agent-facing artifacts by name. Explicit-invoke only.
argument-hint: "bare takes the change's PR and commit bodies · a path or pasted text narrows it"
disable-model-invocation: true
---

# dw-unslop — the last pass before a human reads it

The only skill here that edits wording. Everything else in the lane writes for an agent, where density
is the point; this one runs over the few things a person actually reads, where the patterns that mark
text as machine-written spend the reader's attention before the content gets any.

Two failures, not one. The obvious one is slop — puffery, hedging, the vocabulary. The other is
over-correction: prose sanded down until it has no opinion and no rhythm, which reads as generated just
as fast. Step 3 is there for the second one.

## What it reads and writes

Reads whatever `$ARGUMENTS` names: empty takes the open change's PR body and the commit bodies on its
branch, a path takes that file, pasted text takes itself. Writes the rewritten text — into a tracked
file only after you have seen the diff — and **no `.ai/` artifact of its own**.

**It refuses, by name:** any `SKILL.md`, `AGENTS.md` / `CLAUDE.md`, `docs/agents/*`,
`docs/decisions/*`, `CONTEXT.md`, `CHANGE.md`, `HANDOFF.md`, `.ai/backlog/*`, and any `## Gotchas`
block. Agents read those on every invocation, so a sentence trimmed out of one is an instruction some
later session no longer gets. Name the file, give the reason in one line, stop — never counter-offer a
lighter touch on the same file.

## Workflow

### 1. Scan

Read the text against `references/patterns.md`: 31 numbered rules in seven groups, each written as an
edit rather than a flag. Note which numbers fire — step 4 reports them.

### 2. Rewrite

Preserve the meaning and match the register the text was aiming at. A PR body is not an essay: the fix
for puffery there is the fact the puffery stood in for, not livelier puffery. Where a rule fires but
the rewrite would change what the sentence **claims**, leave it and say so. The claim is the author's.

### 3. Don't flatten it

Cutting patterns is half the job. Sterile is its own tell, so the pass has to put something back:

- **Keep the opinion.** A sentence that judges beats a sentence that lists. "The generator is not worth
  two skills" carries more than "there are trade-offs here."
- **Vary the rhythm.** One short sentence. Then one that takes its time, because the thought it is
  carrying actually needs the room. Uniform sentence length is the most reliable machine tell there is.
- **Keep a specific detail.** A number, a filename, a `file:line`. Specificity is what slop cannot fake.
- **Let some structure stay uneven.** Perfect parallelism looks generated — three bullets over material
  that has four things in it is rule 10 firing.

**This step is what stops the skill becoming a length optimiser.** An agent told to tighten prose
optimises for length, because length is the property it can see. `docs/agents/README.md` records where
that ends up: a line target dropped `git fetch origin &&` from a rebase command, teaching a rebase onto
a stale ref, and no check could see the bill. Shorter is not the goal. Less slop is.

### 4. Report what fired

Show the rewritten text and name the rules by number, one line each. On a tracked file, **stop for
approval before writing** — the diff is the part worth reading, and a wording pass applied unseen is
how a claim quietly changes owner.

## The two tests

The catalog is patterns to recognise. These two are the algorithm, and they catch the sentences no list
will — apply them first, because both are deletions and a deleted sentence needs no rewrite:

- **The restatement test.** Try to restate the sentence as a concrete instruction, a fact or a number.
  If you cannot, it names a feeling rather than a thing, so cut it. "The database stays close at hand"
  fails; "`.toSQL()` returns the exact string sent to the database" passes.
- **The portability test.** If the sentence would read identically in another project's docs, it says
  nothing about this one. Cut it. This is the test that kills the well-formed paragraph a reader nods
  along to and learns nothing from.

## References

- `references/patterns.md` — the numbered catalog, kept at its upstream numbers so "rule 16" means the
  same thing in a review here and in the plugin it came from. Two rules are deliberately softened
  there, each with the reason on its own line.

**Next:** `dw-land`, which owns the PR body, or `dw-git` for a commit body about to be written.
