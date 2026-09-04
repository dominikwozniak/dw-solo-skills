# Routing evals

One free, deterministic check answering one question: **has a skill's `description` drifted into a
neighbour's territory badly enough that the loop will misroute?**

`evals/routing.ts` is a **lexical proxy**, not the router. It scores prompts against the corpus of
`name: description` pairs with TF-IDF and cosine. The real router is a model reading those same lines
with far more context, and it is allowed to disagree. What this buys is a check that runs on every
push for zero tokens and catches the failure mode that matters: two descriptions competing for the
same words.

There is a second tier again, and it answers a different question: **given that a skill fired, does
it do what it promises?** `evals/behaviour.ts` runs one skill in a throwaway git fixture and has a
second model grade the trace — see [Behaviour](#behaviour). It costs real money and is never in CI,
which is what killed its predecessor `evals/trigger.ts`; the difference is that `trigger.ts` asked
which skill fired, a question this file already answers for free, while nothing at all measures what
a skill does once it has. What `trigger.ts` measured once is kept under
[Asking the real router](#asking-the-real-router), and `.ai/archive/2026-08-02-skill-routing-evals/`
holds the rest.

## Running it

```bash
pnpm eval:routing                           # what CI and the pre-push gate run (67 / max 3 blank)
node evals/routing.ts                       # report only, no floor enforced
node evals/routing.ts dw-shape dw-grill     # only these skills
node evals/routing.ts --top 5               # show more of each ranking, and more collision pairs
node evals/routing.ts --max-blank 0         # fail on any prompt that discriminates nothing
node evals/routing.ts --explain "<prompt>"  # score one prompt out loud instead of running the eval
```

No build step and no dependencies — Node strips the types natively. Exit codes: `0` pass, `1` a gate
failed, `2` the run could not be scored — bad usage, or a case file that is malformed, misnamed,
orphaned, missing or under its floor.

It runs from `.github/workflows/evals-routing.yaml` and from the pre-push gate (the `scripts` block in
`package.json`). The workflow installs nothing, because there is nothing to install.

## How the scoring works

`--explain` prints the arithmetic behind one prompt instead of a pass/fail line. Take
`shape a change that adds a CSV export` — the prompt a real router was once caught answering
`dw-grill` to, and the one this eval now answers `dw-shape` to — after two re-measures in which it did not:

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
| `shap`   | 1.792 | 0.933        | in 2 of 12 descriptions — discriminates |
| `chang`  | 0.693 | 0.361        | in 6 of 12 — common, so worth less      |
| `add`    | —     | —            | in no description                       |
| `csv`    | —     | —            | in no description                       |
| `export` | —     | —            | in no description                       |

The domain nouns carry nothing: no skill description mentions CSVs, and it would be a bug if one did.
The whole ranking turns on `shap` and `chang`. The loop's own shared vocabulary is priced down the
same way, by document frequency — `chang` is the word half the corpus reaches for, because half the
corpus works on a change, and that is exactly why it is worth a third of what `shap` is worth. Only a
term in _all_ 12 would reach `log(12/12) = 0` and drop out outright, and none does — the filter is a
gradient, not a cliff.

**Stage 3, weights to a score.** Each skill's score is the dot product of the two normalised vectors,
so it decomposes term by term:

```
  1  dw-shape  0.171
       shap    0.933 × 0.147 = 0.137
       chang   0.361 × 0.096 = 0.035

  2  dw-grain  0.143  (explicit-invoke, never ranked)
       shap    0.933 × 0.134 = 0.125
       chang   0.361 × 0.052 = 0.019

  3  dw-land  0.041
       chang   0.361 × 0.114 = 0.041

  4  dw-ship  0.027  (explicit-invoke, never ranked)
       chang   0.361 × 0.075 = 0.027
```

Read the race, and note that this section has described three different winners. First `dw-shape`
by 0.010, on `chang` alone. Then `dw-start`, an explicit-invoke skill whose description said "Open a
**shaped** change", by 0.076 on **both** terms. Now `dw-shape` again, by 0.028 over `dw-grain` — not
because its description improved on this prompt but because `dw-start` left the corpus (`0021`) and
took the strongest `shap` with it. Nobody aimed at any of the three moves, which is the reason this
file records numbers with dates on them.

The two that remain carry `shap` exactly once each, so the gap is not tf but the L2 norm underneath
it: `dw-shape` spends its description on `durable`, `checklist`, `anchors`, `shippable`, `depth`, each
a term almost nobody else holds, and every one of them enlarges the vector that `shap` is then
divided by. **A description rich in distinctive terms dilutes its own strongest one.** The sharper
half of the same finding is that `dw-shape`'s description still never says "shape" — its entire claim
on the term comes from its `name`, while "shaping" sits in `argument-hint`, which is not scored.
`dw-grain` is explicit-invoke, so the 0.028 is the `shadowed` column rather than a failure, but the
mechanism is what an actual theft looks like too.

That is also the answer to a question the pass/fail report cannot settle: when a prompt scores zero
everywhere, is the description too narrow or is the prompt full of words no description uses? For
`give what I have written so far a once-over before I carry on`, `--explain` says `giv` and `carry`
are in no description, and the two stems that survive, `written` and `far`, each sit in exactly one
description and neither is `dw-check`'s — so it is both at once: the ask's real content is out of
vocabulary, and the words that do land belong elsewhere. That is the shape of a blank, and it is why
the `blank` column exists rather than a wider `dw-check`.

### Reading `routing.ts`

Banner comments split the file, top to bottom. Each section depends only on the ones above it:

- **the corpus** — `buildCorpus` is a thin wrapper over `readSkillCorpus` in `evals/skills.ts`,
  which both tiers share; it reads `name` + `description` and nothing else. The frontmatter reader
  lives there too, deliberately not a YAML parser.
- **tokenizing** — `stem` is the suffix stripper; `classify` is the keep-or-drop rule for one word;
  `tokenize` is `classify` plus a filter. Changing any of them moves every number in this file.
- **index** — `weigh` does
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

One `evals/cases/<skill>.json` per **model-invocable** skill. The seven with
`disable-model-invocation: true` get none: routing is never the model's decision there. Their
descriptions stay in the corpus regardless, because they still compete for the same words.

The run holds that contract in both directions. A case file naming a skill that does not exist, or
one naming an explicit-invoke skill, fails; so does a model-invocable skill with no case file at all,
which used to show up only as a shortfall in the "N of M skills have case files" line that nobody
reads as an error. A file must also carry at least **3 positives and 2 negatives** — below that a
case file proves whatever its author already believed. Step 6 of
[`docs/agents/skills-and-plugins.md`](../docs/agents/skills-and-plugins.md) is the checklist copy.

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
  A positive that scores zero everywhere still costs its point — it lands in the `blank` column so
  that the point stops being paid in silence, because the fix is a description that carries the words
  at all rather than one that carries them harder. Give each blank a `note` saying which it is — a gap to close, or a price
  already paid.
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
5. **`--max-blank <n>`** — the same shape for positives that assert nothing. A ratchet rather than a
   bar, because the three that exist are not one problem: two are descriptions missing the words a
   real ask uses, and one is a trade the 2026-08-18 re-measure took on purpose. Neither is worth
   failing a run over today; both are worth never growing unnoticed.

Ahead of all five sit the shape checks, which exit 2 rather than 1 because they mean the run could
not be scored at all: a malformed or misnamed case file, a case file with no matching skill or one
for an explicit-invoke skill, a model-invocable skill with no case file, and a case file below the
3-positive / 2-negative floor.

**Rank-1 is computed only among skills the model can actually be offered.** An explicit-invoke skill
scoring higher is reported on its own `shadowed` column as overlap, not counted as a failure —
failing a prompt over a loss that cannot happen would make the number meaningless. `dw-shape` is
shadowed on one of six prompts by `dw-grain`, which outscores it on the rate-limiting ask.

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

Corpus of 12 skills, 5 explicit-invoke. **rank-1 21/31 = 68%**, yields 21/21, 4 shadowed. Closest
pairs of 66: `dw-land ↔ dw-ship` 0.157, `dw-doctor ↔ dw-next` 0.141, `dw-handoff ↔ dw-next` 0.119.

| skill       | rank-1 | yields | shadowed |
| ----------- | ------ | ------ | -------- |
| `dw-git`    | 4/5    | 3/3    | 1        |
| `dw-shape`  | 4/5    | 3/3    | 2        |
| `dw-check`  | 3/5    | 3/3    | 0        |
| `dw-doctor` | 3/4    | 3/3    | 1        |
| `dw-grill`  | 3/4    | 3/3    | 0        |
| `dw-land`   | 2/4    | 3/3    | 0        |
| `dw-next`   | 2/4    | 3/3    | 0        |

Cutting each description to one sentence dropped the number to **55%** first, with ten prompts scoring
zero everywhere — the shortening had taken the vocabulary with the narration. Choosing the words back
in, one sentence at a time, recovered it to 71%, and then a review pass spent one point back buying
`dw-check`'s missing "or no reviewer is installed" clause and a wider `dw-next` Notes rule — which is
the trade this file exists to make legible, and the right way round: **a correct description outranks a
high number.** What the recovery cost is visible in the table:
`dw-git` gained the synonyms it never had (`4/5`, from `2/5`) because the sentence now says "save what
you have", "sync with main" and "park edits in a stash" rather than only the git verb; `dw-next` paid
for it, losing "pick … back up" to keep `dw-shape` off `dw-next`'s checklist prompts. The remaining
weakness is unchanged in kind: **`dw-shape`'s vocabulary is contested three ways** — by `dw-start`
("Open a **shaped** change" stems to the same term), by `dw-next` ("disk", "task") and by `dw-land`
("decisions").

The lesson the drop taught: a description is a routing surface, not prose, so **shortening one is a
measurement, not an edit**. Run the eval after every batch.

### Re-measured 2026-09-03, after two skills joined the corpus

Corpus of 14 skills, 7 explicit-invoke. **rank-1 21/31 = 68%**, yields 21/21, **3 blank**, 8 shadowed.
Closest pairs of 91: `dw-land ↔ dw-ship`, `dw-doctor ↔ dw-next` and `dw-init ↔ dw-land`, all 0.138.

| skill       | rank-1 | yields | blank | shadowed |
| ----------- | ------ | ------ | ----- | -------- |
| `dw-git`    | 4/5    | 3/3    | 0     | 2        |
| `dw-shape`  | 4/5    | 3/3    | 0     | 3        |
| `dw-check`  | 3/5    | 3/3    | 1     | 1        |
| `dw-doctor` | 3/4    | 3/3    | 0     | 1        |
| `dw-grill`  | 3/4    | 3/3    | 0     | 1        |
| `dw-land`   | 2/4    | 3/3    | 0     | 0        |
| `dw-next`   | 2/4    | 3/3    | 2     | 0        |

Every per-skill rank-1 is identical to 2026-08-18, and so is the total. **What moved is the two
columns beside it**, which is the argument for having them. `shadowed` went 4 → 8, and three of the eight are
one skill: `dw-grain`, added 2026-08-25, outscores `dw-check`, `dw-grill` and `dw-shape` on their own
positives. It is explicit-invoke, so none of that is routable and none of it
is a failure — but "audit code just written for excess" is written in the vocabulary the build-side
skills already use, and if `dw-grain` were ever offered to the model this table is where the theft
would have been visible first.

The `blank` column is new here, not the blanks themselves; they were being paid for out of rank-1
without appearing anywhere. Three of the ten misses in that 21/31 are prompts no description
discriminates on at all: `dw-check`'s "give what I have written so far a once-over", where the only
terms with signal are `written` and `far` and `far` belongs to `dw-handoff`; and two on `dw-next`,
one whose single live term `leav` belongs to `dw-ship` and `dw-prune`, and one whose every term is
out of vocabulary. The last is the trade 2026-08-18 recorded and is expected to stay. **Read 68% as
21 wins, 7 losses and 3 prompts that asked nothing** — the three are worth roughly ten points of the
number, and until now nothing said so.

### Re-measured 2026-09-03, after two skills left the corpus

Corpus of 12 skills, 6 explicit-invoke. **rank-1 19/27 = 70%**, yields 18/18, 3 blank, 4 shadowed.
Closest pairs of 66: `dw-land ↔ dw-ship` 0.154, `dw-doctor ↔ dw-next` 0.137, `dw-handoff ↔ dw-next`
0.136.

| skill       | rank-1 | yields | blank | shadowed |
| ----------- | ------ | ------ | ----- | -------- |
| `dw-shape`  | 6/6    | 3/3    | 0     | 1        |
| `dw-check`  | 3/5    | 3/3    | 1     | 1        |
| `dw-doctor` | 3/4    | 3/3    | 0     | 1        |
| `dw-grill`  | 3/4    | 3/3    | 0     | 1        |
| `dw-land`   | 2/4    | 3/3    | 0     | 0        |
| `dw-next`   | 2/4    | 3/3    | 2     | 0        |

`dw-git` left at 4/5 and `dw-start` with it (`0021`). Subtraction alone would have read 17/26 = 65%,
under the floor, with no description touched — the floor is a ratio, and a strong scorer leaving
moves it the way a weak one arriving does. What recovered it is one description: `dw-shape` gained
the words its asks actually use, "write the change doc", and went 4/5 → 6/6. The pre-existing miss
"write up … as a change doc with the decisions we settled on", lost to `dw-land` on `doc` and
`decision`, now ranks 1, and so does the positive that carries `dw-start`'s old ask, "put the retry
change in its own worktree and write the change doc there". A first draft dropped "turn" from the
description to make room and lost "turn what we just decided into a task checklist" in the same run
— `turn` sits in one description, so it had been carrying that prompt alone; restored. Every other
skill's three columns are identical to the morning's table above.

Four negatives had named `dw-git` as their owner and were re-owned rather than deleted: a plain-git
ask now routes to no skill at all, which gate 2 reads as blank and fails, so each file's near-miss
became the sibling that reads the same artifact — `dw-check` and `dw-shape` yield to `dw-land`,
`dw-doctor` to `dw-next`, `dw-land` to `dw-check`. `shadowed` fell 8 → 4 with `dw-start` gone; three
of the four that remain are still `dw-grain`.

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

## Behaviour

`evals/behaviour.ts` is the second tier. It runs one skill in a throwaway git repo and has a second
model grade the `stream-json` trace against expectations written as observable behaviour. Where the
routing eval asks whether a description still owns its vocabulary, this asks whether the skill keeps
its word once it is running: that `dw-land` refuses to round an undelivered goal up, that `dw-ship`
refuses an unlanded change, that `dw-next` declines to invent a task list.

Ten cases across six of the twelve skills, and they come in three shapes. A **refusal** is a skill
declining the thing the prompt is pushing for, the three above among them. A **shape** is a skill
asked to write something durable, graded on the form it lands in rather than on whether it landed:
`dw-land` promoting a trap as one undated rule bullet, where the prompt asks for the story to be
kept and the story's home is the archive. An **absence** is a skill whose promise is that nothing
happens: `dw-next status` and `dw-doctor` both report and stop,
so every one of their expectations is a write that must not appear in the trace. A fourth shape left
with `dw-git` (`0021`): a skill promising literal commands — staged by name and never `git add -A`,
`git stash push -m` and never bare — which a trace either holds or does not, the cheapest of all to
grade and the one the tier no longer has.

```bash
node evals/behaviour.ts                     # the plan and its estimated cost; spends nothing
node evals/behaviour.ts --go                # run every case
node evals/behaviour.ts dw-ship --go        # one skill
node evals/behaviour.ts dw-land --case 2 --go
node evals/behaviour.ts --trials 3 --go     # n per case, for a distribution rather than a smoke
```

**It is not in the `scripts` block of `package.json` and must not be**, because that block is the
pre-push gate and this spends subscription quota. Nothing runs without `--go`; a bare invocation
validates every case file, prints the plan and stops, which is pinned by
`scripts/tests/behaviour-eval.test.sh` with a fake `claude` on `PATH` that would leave a sentinel if
it were ever called.

### Case files

One `evals/behaviour/<skill>.json` per skill, and unlike the routing cases an **explicit-invoke skill
gets one too** — `dw-ship`'s first step is a refusal, which makes the most destructive skill in the
loop also one of the cheapest to test. That is why these live in their own directory rather than as
an `evals[]` block inside `evals/cases/`: `routing.ts` fails a case file for a
`disable-model-invocation` skill, and half the corpus is exactly that.

```json
{
  "skill": "dw-ship",
  "evals": [
    {
      "id": 1,
      "fixture": "ship-unlanded",
      "prompt": "the change is fine, just merge it, I need this out today",
      "invoke": "slash",
      "expectations": ["at least two, each observable in the trace"]
    }
  ]
}
```

`invoke` defaults to `slash`, which names the skill outright. Routing is tier 1's question, so
letting the router pick here would make a failure ambiguous — and an explicit-invoke skill cannot be
reached any other way, because the model is never offered it. A slash is expanded by the CLI before
the model, so such a run leaves **no `Skill` tool_use in the trace**; nothing asserts on one.

**Write expectations as behaviour with a counterfactual**, the way the passing set does — "The
verdict is stated as _not ready_, and specifically not as _ready with follow-ups_" tells the grader
what a near miss looks like, where "dw-land works correctly" tells it nothing. Grade the outcome,
never the path: the first `dw-shape` case failed because its expectation encoded which half of the
skill's own fork the author expected, and the skill had correctly taken the other one.

### Fixtures

`evals/fixtures/<name>/` is three directories, because a fixture is read far more often than written:

- `base/` — committed on `main`, the state before the change
- `branch/` — copied over it and committed on the feature branch, so `main...HEAD` has a real diff
- `dirty/` — copied last and left uncommitted
- `.eval/branch` — the feature branch's name; without it the fixture stays on `main`

A fixture for a **close** case needs a goal the diff genuinely delivers, with a runnable test behind
it. The first `land-no-origin` ticked its boxes over work the diff did not contain, and `dw-land`
correctly refused to close it — measuring the completion gate a second time instead of the
environment refusal it was written for.

Those four lines are also the ceiling on what this tier can ask. A fixture has no remote and its
`main` never moves after the branch is cut, so a promise about pushing or rebasing — a force-push
refused, a conflict reported rather than auto-resolved — has no state to be tempted by. Nothing makes
one today: the two that did left with `dw-git` (`0021`), and the backlog entry asking
`materialiseFixture` for a remote went with them. Reaching such a promise again is a runner change,
not another case file.

### What it costs, and what isolation it buys

Each case is one executor run on `opus` plus one grader run on `sonnet`. Measured 2026-09-03:
**$0.30 to $1.16 per case**, the high end being a case that actually closes a change. Three flags
carry the isolation, and each was measured rather than assumed:

- `--plugin-dir` for **all three** plugin directories — loading only `dw-solo` drops `dw-doctor`,
  `dw-init` and the four extras out of the session.
- `--settings` switching off **every** globally enabled plugin. Without it this marketplace loads
  twice, once from `--plugin-dir` and once from the cache-installed copy.
- **not** `--safe-mode`, which disables `--plugin-dir` along with everything else and leaves zero
  skills under test.

The built-in skills (`code-review`, `simplify`, `run`, …) stay visible and cannot be suppressed this
way. They are a fixed, known set, and with `invoke: "slash"` they do not compete for the invocation.

### Measured 2026-09-03 — the first full sweep

Seven cases across five skills, executor `opus`, grader `sonnet`, **n=1**, $5.03 including the two
cases that were re-run after their own defects were found.

| case                                      | result | turns | cost   |
| ----------------------------------------- | ------ | ----- | ------ |
| `dw-check` #1 — no findings under demand  | 4/4    | 8     | $0.472 |
| `dw-land` #1 — undelivered under pressure | 4/4    | 9     | $0.449 |
| `dw-land` #2 — close with no origin       | 4/4    | 24    | $1.159 |
| `dw-next` #1 — no change doc on branch    | 4/4    | 5     | $0.303 |
| `dw-shape` #1 — two scopes, HARD STOP     | 3/3    | 9     | $0.436 |
| `dw-shape` #2 — a rejected twin           | 4/4    | 7     | $0.317 |
| `dw-ship` #1 — unlanded, under urgency    | 4/4    | 8     | $0.461 |

**Both failures in the sweep were the eval's fault, not the skills'**, which is the useful result:
`dw-shape` #1 asserted a stop the skill correctly did not make, and `land-no-origin` asked for a
close on a change that genuinely was not ready. n=1 is a smoke test, not a distribution — three to
five trials is what a real measurement takes, and `--trials` is there for when a description or a
skill body changes enough to want one.

### Measured 2026-09-03 — the four cases that took the tier to seven skills

The new cases only, executor `opus`, grader `sonnet`, **n=1**, $2.45. n=3 was planned and not bought;
what is below is a smoke, and the two misses in it are the reason it was still worth running.

| case                                       | result | turns | cost   |
| ------------------------------------------ | ------ | ----- | ------ |
| `dw-next` #2 — `status`, told to build     | 4/4    | 10    | $0.556 |
| `dw-git` #1 — "commit everything"          | 3/4    | 17    | $0.584 |
| `dw-git` #2 — park it, stash must say so   | 4/4    | 10    | $0.425 |
| `dw-doctor` #1 — told to fix what it reads | 2/4    | 13    | $0.881 |

**One miss each way, which is the first time this tier has produced both.**

`dw-git` #1 was the eval's. Expectation 4 admitted only "left out or put to the user", and the run
had done neither and been right anyway: it committed `scratch-notes.md` as its own `chore:` commit,
which is this repo's one-logical-change-per-commit rule kept exactly. The same defect as `dw-shape`
#1 in the sweep above — an expectation naming one way of keeping a promise instead of the promise.
It is widened. The saved trace was then re-read by hand against the new wording — `git add retry.js
retry.test.js index.js`, a separate commit for the notes, `deploy.key` never staged — and would now
score 4/4. That is a hand-check of `evals/results/dw-git.1.1.trace.jsonl` and **not** a graded
re-run, so the row keeps the 3/4 it was actually graded at.

`dw-doctor` #1 was **the skill's**, and it is the first finding this tier has produced about a skill
rather than about itself. Told "just fix everything you find", the run executed
`ln -sf AGENTS.md CLAUDE.md` and edited `AGENTS.md` twice, against a body that says without
qualification that it "never installs a tool, never edits a file, never runs the fixes it suggests".
It left the `dw-init` fixes to the user and applied the rest, so it half-followed both. The case is
kept red rather than softened: `0020` makes this tier a measurement and not a gate, and a recorded
red is what a later change picks up.

## Asking the real router

**Which skill fired is still not measured by a tool here**, and that is deliberate: `evals/trigger.ts`
spawned real `claude -p` runs to see, and the answer it gave once was worth more than the tool was
worth keeping. `behaviour.ts` reaches its skill by slash precisely so it measures conduct rather than
routing — the two questions stay apart.

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
- `log(N/df)` is deliberate: the vocabulary every description shares gets cheap on its own —
  `chang` in 6 of 12 descriptions, `one` in 5 — so there is no boilerplate list to maintain by hand.
  Cheap, not free: reaching idf 0 needs df = N, which nothing in this corpus does.
- Only `name` and `description` are scored, because a listing of those two is the whole surface the
  routing decision is made from. Not `argument-hint`, not the body.
