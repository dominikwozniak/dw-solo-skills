---
name: dw-grill
description: >-
  Interview the user to sharpen a vague, half-formed or ambiguous idea into decided requirements
  before any of it gets built — a round asks every question whose prerequisites are settled, hardest
  first, each with a recommended answer, then plays back what is decided and what is still open, so
  the thinking is finished first.
argument-hint: "bare grills the idea already in the conversation · a topic or question narrows it"
---

# dw-grill — interview the idea before it becomes work

**Conversational, and it writes nothing.** The deliverable is a shared understanding that
`dw-shape` turns into a durable artifact. Read `CONTEXT.md` first where the project has one, and
ask in its terms.

## Workflow

1. **Size the idea before question one.** An idea answering to several **separate goals** — different
   consumers, different data, one piece could be dropped without rewriting the others — is too big to
   grill as one: name the pieces, propose which to grill first, and **wait**. Grilling the whole
   yields a long session and a plan for none of it. Independent shippability is **not** the test —
   `dw-shape` settled that, and a grill that splits on it hands over a split that skill will refuse.
2. **Separate facts from decisions.** Facts — anything discoverable in the repo or environment —
   are looked up, never asked. **A choice this project already settled is a fact** — asking it back
   spends a slot and invites reversing it by accident. Where `docs/decisions/` exists, read what it
   settled about the subject before question one, delegating to `dw-decisions` where that agent is
   installed; quote it rather than reopening it. Only genuinely undecided things (trade-offs, scope
   boundaries, product choices, which of two shapes) become questions.
3. **A round is the whole frontier.** The frontier is every decision whose prerequisites are already
   settled — the questions answerable now without guessing at an answer you have not heard. Ask all
   of them in one message, numbered, hardest-first by what a wrong answer would cost: scope →
   security/privacy → UX → technical detail. A question whose answer depends on another still open
   in this round belongs to the **next** round, and that is what makes asking them together cost
   nothing. Two filters replace a size limit: don't ask what the repo already answers (style, test
   framework, layout, naming, which installed library), and don't spend a question on a decision
   with one sensible default — assume it and say so in the same message, "assuming X unless you say
   otherwise", so a wrong default costs one correction. A frontier that opens huge is a sizing
   failure at step 1, not a licence: name the pieces and go back.
4. **Each question stands alone**, answerable as two to five mutually exclusive options or in five
   words, always with the option you'd pick and why. Short active sentences, one word with one
   meaning. Then **wait** for the round's answers — never answer your own question and move on. A
   disambiguation of a question just asked belongs to that question and opens no new one.
5. **Resolve the tree, not the list.** After each round's answers, re-derive what is still genuinely
   open: an answer often closes two later questions, or opens one that matters more than anything
   left. Settled decisions push the frontier outward, so recompute it before the next round.
6. **Play back after every round**, whatever its size. Before the next one: what is decided, and what
   is still open — each with the default you would assume and what a wrong default costs. Offer three
   ways forward: another round · shape now with those defaults · the idea is too big to grill as
   one, here are the pieces. Then **wait**; a hedged reply is not a choice.
7. **Close when the frontier is empty** — every branch of the tree visited, nothing left silently
   assumed; an unknown that would not change what gets built is closed by saying so rather than by
   asking it. Play back in a few lines: what we're building, what we decided, every resource the conversation pointed at, and
   — each explicit and separate — what we **assumed** without asking, what we **deferred** and why,
   and what we deliberately **left out**. `dw-shape` gives each named item its fate — an assumed or
   deferred item becomes a decision marked as such, a left-out item goes under `## Out of scope` or
   into the change — and an item you don't name never gets one.

**Do not start implementing, and write nothing** — agreement is the whole job here.

**Next:** `dw-shape` to turn this understanding into a `CHANGE.md` with a task list.

$ARGUMENTS
