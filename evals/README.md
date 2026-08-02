# Routing evals

Two tiers answering one question: **has a skill's `description` drifted into a neighbour's territory
badly enough that the loop will misroute?**

| Tier               | Cost                | Determinism | Where it runs          |
| ------------------ | ------------------- | ----------- | ---------------------- |
| `evals/routing.ts` | free                | total       | CI + the pre-push gate |
| `evals/trigger.ts` | subscription tokens | none        | by hand, never in CI   |

Tier 2 is a **lexical proxy**, not the router. It scores prompts against the corpus of
`name: description` pairs with TF-IDF and cosine. The real router is a model reading those same lines
with far more context and is allowed to disagree — that is what tier 3 is for. What tier 2 buys is a
check that runs on every push for zero tokens and catches the failure mode that matters: two
descriptions competing for the same words.

## Running it

```bash
pnpm eval:routing                           # what CI and the pre-push gate run (--min-rank1 67)
pnpm validate:evals                         # every model-invocable skill has a case file, and back
node evals/routing.ts                       # report only, no floor enforced
node evals/routing.ts dw-shape dw-grill     # only these skills
node evals/routing.ts --top 5               # show more of each ranking, and more collision pairs
```

No build step and no dependencies — Node strips the types natively. Exit codes: `0` pass, `1` a gate
failed, `2` bad usage or a malformed case file.

Both live in `.github/workflows/evals-routing.yaml` and in the pre-push gate in `AGENTS.md`. The
workflow installs nothing: tier 2 has no dependencies and `jq` for the validator is already on the
runner.

## Case files

One `evals/cases/<skill>.json` per **model-invocable** skill. The four with
`disable-model-invocation: true` get none: routing is never the model's decision there. Their
descriptions stay in the corpus regardless, because they still compete for the same words.

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
2. **A description pair at or above 0.75 cosine** (warn from 0.50). Whole-corpus, always scanned in
   full even when you narrow to one skill — a collision is a property of the descriptions, and
   scanning only the pairs you named would hide the one you did not.
3. **`--min-rank1 <percent>`** — the ratchet. Absent, rank-1 is reported and never enforced.

**Rank-1 is computed only among skills the model can actually be offered.** An explicit-invoke skill
scoring higher is reported on its own `shadowed` column as overlap, not counted as a failure —
failing a prompt over a loss that cannot happen would make the number meaningless. `dw-git` alone is
shadowed on three of five prompts by `dw-ship` and `dw-start`, which own "PR" and "branch".

## Measured baseline — 2026-08-02

Corpus of 11 skills, 4 of them explicit-invoke. **rank-1 20/30 = 67%**, yields 21/21, 9 shadowed.

| skill       | rank-1 | yields | shadowed |
| ----------- | ------ | ------ | -------- |
| `dw-grill`  | 4/4    | 3/3    | 0        |
| `dw-land`   | 4/4    | 3/3    | 1        |
| `dw-doctor` | 3/4    | 3/3    | 1        |
| `dw-shape`  | 3/5    | 3/3    | 2        |
| `dw-check`  | 2/4    | 3/3    | 1        |
| `dw-git`    | 2/5    | 3/3    | 3        |
| `dw-next`   | 2/4    | 3/3    | 1        |

Closest description pairs, of 55 scanned: `dw-ship ↔ dw-start` 0.206, `dw-land ↔ dw-ship` 0.199,
`dw-handoff ↔ dw-next` 0.166. Nothing is near the thresholds, so treat the collision check as a
tripwire and watch the top number creep rather than waiting for it to fire.

67% is not a target, it is where the descriptions are today. The two standing weaknesses behind it:

- **`dw-git` has no synonyms.** "save what I have with a sensible message" and "park these edits
  somewhere" score _exactly zero_ against a description that lists the operations by their git names
  and never names how anyone asks for them. Restoring the sentence that
  `44c06c7` removed recovers a different prompt outright — "bring my branch up to date with main"
  goes from rank 3 to rank 1, because that sentence contained the phrase "sync with main".
- **`dw-shape`'s vocabulary is contested three ways** — by `dw-start` ("Open a **shaped** change"
  stems to the same term), by `dw-next` (which owns "disk" and "task") and by `dw-land` (which owns
  "decisions").

Both are description decisions, deliberately left alone: the eval's job is to show them, not to
quietly rewrite the skills it measures.

### The threshold worth knowing about

Broadening `dw-check` on purpose to eat `dw-land`'s vocabulary — verdict, diff, blast radius,
promote, decisions, merge — is correctly rejected, but note _which_ gate does it:

| signal               | before | after |
| -------------------- | ------ | ----- |
| rank-1               | 67%    | 57%   |
| negatives stolen     | 0      | 3     |
| `dw-check ↔ dw-land` | 0.071  | 0.686 |

The collision leaps almost tenfold and still lands under the 0.75 error threshold — it only warns.
**The negative-prompt gate is what actually fails the run.** So keep negatives in every case file;
the cosine error threshold alone would have let this through.

## Caveats

- The stemmer is a suffix stripper, not a linguist's. `shape`/`shaping`/`shaped` conflate;
  `decide`/`decision` never meet. Both the corpus and the query go through the same function, so
  relative ranking holds even where the stem is wrong.
- `log(N/df)` is deliberate: a term every description carries — the shared "Use when someone says"
  phrasing — lands on exactly zero and drops out, with no boilerplate list to maintain by hand.
- Only `name` and `description` are scored, because a listing of those two is the whole surface the
  routing decision is made from. Not `argument-hint`, not the body.
