# Routing evals

One free, deterministic check answering one question: **has a skill's `description` drifted into a
neighbour's territory badly enough that the loop will misroute?**

`evals/routing.ts` is a **lexical proxy**, not the router. It scores prompts against the corpus of
`name: description` pairs with TF-IDF and cosine. The real router is a model reading those same lines
with far more context, and it is allowed to disagree. What this buys is a check that runs on every
push for zero tokens and catches the failure mode that matters: two descriptions competing for the
same words.

There used to be a second tier — `evals/trigger.ts`, which spawned real `claude -p` runs against a
throwaway fixture and reported which skill actually fired. It was deleted along with its
`scripts/validate-evals.sh` sibling: it spent subscription quota, never ran in CI (there is no login
to inherit there), refused to do anything without `--go`, and answered a question no change had asked
for months. What it measured once is recorded under [Asking the real router](#asking-the-real-router),
and `.ai/archive/skill-routing-evals/` keeps the rest.

## Running it

```bash
pnpm eval:routing                           # what CI and the pre-push gate run (--min-rank1 67)
node evals/routing.ts                       # report only, no floor enforced
node evals/routing.ts dw-shape dw-grill     # only these skills
node evals/routing.ts --top 5               # show more of each ranking, and more collision pairs
node evals/routing.ts --explain "<prompt>"  # score one prompt out loud instead of running the eval
```

No build step and no dependencies — Node strips the types natively. Exit codes: `0` pass, `1` a gate
failed, `2` bad usage or a malformed case file.

It runs from `.github/workflows/evals-routing.yaml` and from the pre-push gate (the `scripts` block in
`package.json`). The workflow installs nothing, because there is nothing to install.

## How the scoring works

`--explain` prints the arithmetic behind one prompt instead of a pass/fail line. Take
`shape a change that adds a CSV export` — the prompt a real router was once caught answering
`dw-grill` to, and the one this eval answers `dw-start` to:

```bash
node evals/routing.ts --explain "shape a change that adds a CSV export" --top 4
```

**Stage 1, words to stems.** Each word is lowercased, split on non-alphanumerics and put through the
suffix stripper. `shape → shap`, `change → chang`, `adds → add`. `that` is a stopword; `a` is dropped
for being shorter than two characters, before the stopword list is ever consulted. Five stems survive.

**Stage 2, stems to weights.** Surviving is not the same as counting. Only two of the five appear in
any description at all:

| term     | idf   | query weight | why                                     |
| -------- | ----- | ------------ | --------------------------------------- |
| `shap`   | 1.299 | 0.906        | in 3 of 11 descriptions — discriminates |
| `chang`  | 0.606 | 0.423        | in 6 of 11 — common, so worth less      |
| `add`    | —     | —            | in no description                       |
| `csv`    | —     | —            | in no description                       |
| `export` | —     | —            | in no description                       |

The domain nouns carry nothing: no skill description mentions CSVs, and it would be a bug if one did.
The whole ranking turns on `shap` and `chang`. The shared boilerplate is priced down the same way, by
document frequency: `use` is in 7 of 11 descriptions and `say` in 5, so both are cheap. Only a term in
_all_ 11 would reach `log(11/11) = 0` and drop out outright, and none does — the filter is a gradient,
not a cliff.

**Stage 3, weights to a score.** Each skill's score is the dot product of the two normalised vectors,
so it decomposes term by term:

```
  1  dw-start  0.198  (explicit-invoke, never ranked)
       shap    0.906 × 0.150 = 0.136
       chang   0.423 × 0.147 = 0.062

  2  dw-shape  0.188
       shap    0.906 × 0.170 = 0.154
       chang   0.423 × 0.079 = 0.034

  3  dw-grill  0.083
       shap    0.906 × 0.092 = 0.083

  4  dw-land  0.051
       chang   0.423 × 0.121 = 0.051
```

Read the two-horse race: `dw-shape` owns `shap` more strongly (0.170 against 0.150) and loses anyway,
because `dw-start` also carries `chang` about twice as prominently (0.147 against 0.079). The margin
is 0.010 — a hundredth of a point, decided by the one word neither skill is really about.
`dw-start` is explicit-invoke, so this is the `shadowed` column rather than a failure — but the
mechanism is what an actual theft looks like too.

That is also the answer to a question the pass/fail report cannot settle: when a prompt scores zero
everywhere, is the description too narrow or is the prompt full of words no description uses? For
`save what I have with a sensible message`, `--explain` says `sav`, `sens` and `messag` are each in no
description — so it is the first, and `dw-git` is the skill to widen.

### Reading `routing.ts`

Banner comments split the file, top to bottom. Each section depends only on the ones above it:

- **frontmatter** — `parseFrontmatter`, four keys out of a `SKILL.md`. Deliberately not a YAML parser.
- **tokenizing** — `stem` is the suffix stripper; `classify` is the keep-or-drop rule for one word;
  `tokenize` is `classify` plus a filter. Changing any of them moves every number in this file.
- **corpus and index** — `buildCorpus` reads `name` + `description` and nothing else; `weigh` does
  sublinear tf × idf, L2-normalised; `buildIndex` turns the corpus into one vector per skill.
- **scoring** — `cosine` is a dot product because both sides are already normalised; `rank` scores a
  prompt against every skill; `findCollisions` scores every description pair against every other.
- **case files** — `loadCases`, which also rejects a malformed or misnamed one.
- **reporting** — `report` walks the positives and negatives, `summarise` prints the table,
  `reportCollisions` the pairs. This is where the gates are decided.
- **explain** — `explain`, the `--explain` output. It calls the functions above and does no arithmetic
  of its own beyond multiplying the two weights it prints.
- **entry point** — `main` parses flags and picks between the eval and `explain`.

## Case files

One `evals/cases/<skill>.json` per **model-invocable** skill. The four with
`disable-model-invocation: true` get none: routing is never the model's decision there. Their
descriptions stay in the corpus regardless, because they still compete for the same words.

That contract used to have its own validator. It is now one line of the add-a-skill checklist in
`AGENTS.md` — a missing case file means a skill measured by nothing, and an orphan one means a case
file measuring nothing, both visible on the run's own summary table.

```json
{
  "skill": "dw-shape",
  "note": "why this file looks the way it does — optional",
  "positives": [{ "prompt": "...", "note": "optional" }],
  "negatives": [{ "prompt": "...", "owner": "dw-grill", "note": "optional" }]
}
```

- **positives** — asks that should route here. **Paraphrase how you would really say it.** Copying
  the trigger phrases out of the `description` scores the eval against itself and proves nothing.
- **negatives** — asks that should route elsewhere; `owner` names where. The assertion is only that
  this skill does not outrank the owner, never that the owner takes first place outright — that is
  the owner's own case file to make.

Write negatives as **near misses**. `dw-check` against `dw-land` is the same verdict-over-a-diff at
two different moments; `dw-doctor` against `dw-check` is the word "check" pointing at an environment
or at a diff. Distant pairs pass without telling anyone anything.

## What gates

1. **A negative that steals** — the case file's own skill ranks at or above the named owner. Always
   an error. In practice this is the gate that fires first.
2. **A negative where neither side scores** — a separate error, not a theft. `0 ≥ 0` is true, so
   without its own case the run would fail this as the skill outranking the owner and point you at a
   description that is not the problem. Rewrite the prompt until one side moves.
3. **A description pair at or above 0.75 cosine** (warn from 0.50). Whole-corpus, always scanned in
   full even when you narrow to one skill — a collision is a property of the descriptions, and
   scanning only the pairs you named would hide the one you did not.
4. **`--min-rank1 <percent>`** — the ratchet. Absent, rank-1 is reported and never enforced.

**Rank-1 is computed only among skills the model can actually be offered.** An explicit-invoke skill
scoring higher is reported on its own `shadowed` column as overlap, not counted as a failure —
failing a prompt over a loss that cannot happen would make the number meaningless. `dw-git` alone is
shadowed on two of five prompts by `dw-ship` and `dw-start`, which own "PR" and "branch".

## Measured baseline — 2026-08-17

Corpus of 11 skills, 4 of them explicit-invoke. **rank-1 21/31 = 68%**, yields 21/21, 7 shadowed.

| skill       | rank-1 | yields | shadowed |
| ----------- | ------ | ------ | -------- |
| `dw-grill`  | 4/4    | 3/3    | 0        |
| `dw-land`   | 4/4    | 3/3    | 0        |
| `dw-doctor` | 3/4    | 3/3    | 1        |
| `dw-shape`  | 3/5    | 3/3    | 2        |
| `dw-check`  | 3/5    | 3/3    | 1        |
| `dw-git`    | 2/5    | 3/3    | 2        |
| `dw-next`   | 2/4    | 3/3    | 1        |

Closest description pairs, of 55 scanned: `dw-land ↔ dw-ship` 0.227, `dw-ship ↔ dw-start` 0.145,
`dw-next ↔ dw-start` 0.138. Nothing is near the thresholds, so treat the collision check as a
tripwire and watch the top number creep rather than waiting for it to fire.

68% was not a target, just where the descriptions were.

### Re-measured 2026-08-18, after the descriptions went to one sentence each

Corpus of 12 skills, 5 explicit-invoke. **rank-1 22/31 = 71%**, yields 21/21, 4 shadowed. Closest
pairs of 66: `dw-land ↔ dw-ship` 0.157, `dw-doctor ↔ dw-next` 0.140, `dw-handoff ↔ dw-next` 0.119.

| skill       | rank-1 | yields | shadowed |
| ----------- | ------ | ------ | -------- |
| `dw-git`    | 4/5    | 3/3    | 1        |
| `dw-shape`  | 4/5    | 3/3    | 2        |
| `dw-check`  | 3/5    | 3/3    | 0        |
| `dw-doctor` | 3/4    | 3/3    | 1        |
| `dw-grill`  | 3/4    | 3/3    | 0        |
| `dw-land`   | 3/4    | 3/3    | 0        |
| `dw-next`   | 2/4    | 3/3    | 0        |

Cutting each description to one sentence dropped the number to **55%** first, with ten prompts scoring
zero everywhere — the shortening had taken the vocabulary with the narration. Choosing the words back
in, one sentence at a time, recovered it and then some. What that cost is visible in the table:
`dw-git` gained the synonyms it never had (`4/5`, from `2/5`) because the sentence now says "save what
you have", "sync with main" and "park edits in a stash" rather than only the git verb; `dw-next` paid
for it, losing "pick … back up" to keep `dw-shape` off `dw-next`'s checklist prompts. The remaining
weakness is unchanged in kind: **`dw-shape`'s vocabulary is contested three ways** — by `dw-start`
("Open a **shaped** change" stems to the same term), by `dw-next` ("disk", "task") and by `dw-land`
("decisions").

The lesson the drop taught: a description is a routing surface, not prose, so **shortening one is a
measurement, not an edit**. Run the eval after every batch.

### The threshold worth knowing about

Broadening `dw-check` on purpose to eat `dw-land`'s vocabulary — verdict, diff, blast radius,
promote, decisions, merge — is correctly rejected, but note _which_ gate does it:

| signal               | before | after |
| -------------------- | ------ | ----- |
| rank-1               | 67%    | 57%   |
| negatives failing    | 0      | 3     |
| `dw-check ↔ dw-land` | 0.071  | 0.686 |

The collision leaps almost tenfold and still lands under the 0.75 error threshold — it only warns.
**The negative-prompt gate is what actually fails the run.** So keep negatives in every case file;
the cosine error threshold alone would have let this through.

The row says "failing" rather than "stolen" because gate 2 was added after this run was recorded:
broadening a description raises the document frequency of the terms it absorbs, which lowers their
idf, so some of those three negatives now collapse to zero on both sides and are reported as
asserting nothing rather than as thefts. Three negatives break either way — only the label moved.

## Asking the real router

**There is no tool here for this any more**, and that is deliberate: `evals/trigger.ts` spawned real
`claude -p` runs to see which skill actually fired, and the answer it gave once was worth more than
the tool was worth keeping.

Recorded 2026-08-02. The reconnaissance behind these evals saw `dw-grill` fire 3/3 on `shape a change
that adds a CSV export` — a prompt containing `dw-shape`'s own trigger verb. Under identical
conditions with only the model changed:

| model   | first `Skill` call | turns | cost    |
| ------- | ------------------ | ----- | ------- |
| `haiku` | **`dw-grill`** ✗   | 3     | $0.0247 |
| `opus`  | **`dw-shape`** ✓   | 7     | $0.2722 |

**The grill/shape collision is a haiku artifact, not a live misroute.** The loop runs opus, and opus
routes it correctly. n=1 per cell — enough to kill the lead, not enough to be a distribution. This
eval also declined to reproduce the lead, but for its own reason: it puts `dw-start` first, not
`dw-grill`. Two measurements disagreeing with the same reconnaissance in two different ways is the
expected shape, not a bug in either.

To ask the question again, ask it by hand: run `claude -p` in a scratch project with the three plugin
directories loaded and every globally enabled plugin switched off, and read the first `Skill` call out
of the stream. Those two conditions were the whole subtlety of the deleted tool — without them the
cache-installed copy of this marketplace loads alongside and every skill appears twice.

## Caveats

- The stemmer is a suffix stripper, not a linguist's. `shape`/`shaping`/`shaped` conflate;
  `decide`/`decision` never meet. Both the corpus and the query go through the same function, so
  relative ranking holds even where the stem is wrong.
- `log(N/df)` is deliberate: the shared "Use when someone says" phrasing gets cheap on its own —
  `use` in 7 of 11 descriptions, `say` in 5 — so there is no boilerplate list to maintain by hand.
  Cheap, not free: reaching idf 0 needs df = N, which nothing in this corpus does.
- Only `name` and `description` are scored, because a listing of those two is the whole surface the
  routing decision is made from. Not `argument-hint`, not the body.
