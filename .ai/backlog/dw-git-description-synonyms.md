---
created: 2026-08-02
---

# Decide whether `dw-git`'s description gets its synonym sentence back

`skill-routing-evals` measured it and deliberately did not act on it: `dw-git` holds 2 of its 5
positives, and two score **exactly zero** — "save what I have with a sensible message" and "park these
edits somewhere" share no term with a description that lists git operations by their git names.

`44c06c7` removed the sentence "Use for any git intent — committing, pushing, opening a PR, rebasing,
branching, stashing — or when someone says …" in favour of "Use for any git intent, however it's
phrased." Restoring it moves "bring my branch up to date with main" from rank 3 to rank 1, because
that sentence carried the phrase "sync with main".

The real question is not the eval score — it is whether a description should carry paraphrases at all,
or whether that is padding the router does not need. Opus routed the contested `dw-shape` prompt
correctly without any such help, so the lexical tier may simply be understating what the model does.
Worth one `node evals/trigger.ts --go --trials 3 dw-git` run to find out before editing anything.

Raising `--min-rank1` above 67 depends on this.
