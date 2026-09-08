---
name: dw-grill
description: >-
  Interview the user to sharpen a vague, half-formed or ambiguous idea into decided requirements
  before any of it gets built — one question at a time, in rounds of five, hardest-first, each with a
  recommended answer, and a playback between rounds of what is decided and what is still open, so
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
   are looked up, never asked. **A choice this project already settled is a fact**, so asking it
   back costs a slot and invites reversing it by accident: where `docs/decisions/` exists, ask
   `dw-decisions` what is already settled about the subject rather than reading the folder, and
   quote what it returns instead of re-opening it. Only genuinely undecided things (trade-offs,
   scope boundaries, product choices, which of two shapes) become questions.
3. **Spend the round well — five questions a round**, hardest-first by what a wrong answer would
   cost: scope → security/privacy → UX → technical detail. Four good questions beat five with a
   filler. Don't ask what the repo already answers (style, test framework, layout, naming, which
   installed library), and don't spend a slot on a decision with one sensible default: assume it and
   say so in the same message — "assuming X unless you say otherwise" — so a wrong default costs one
   correction, not a question.
4. **One question per message**, answerable as two to five mutually exclusive options or in five
   words, always with the option you'd pick and why. Short active sentences, one word with one
   meaning. Then **wait** — never answer your own question and move on. A disambiguation of the
   question just asked belongs to that question and takes no slot.
5. **Resolve the tree, not the list.** After each answer, re-derive what is still genuinely open:
   an answer often closes two later questions, or opens one that matters more than anything left.
6. **Pause at five.** Before a sixth question, play back in a few lines: what is decided, and what is
   still open — each with the default you would assume and what a wrong default costs. Offer three
   ways forward: another round · shape now with those defaults · the idea is too big to grill as
   one, here are the pieces. Then **wait**; a hedged reply is not a choice.
7. **Close explicitly** when the remaining unknowns wouldn't change what gets built. Play back in a
   few lines: what we're building, what we decided, every resource the conversation pointed at, and
   — each explicit and separate — what we **assumed** without asking, what we **deferred** and why,
   and what we deliberately **left out**. `dw-shape` gives each named item its fate — an assumed or
   deferred item becomes a decision marked as such, a left-out item goes under `## Out of scope` or
   into the change — and an item you don't name never gets one.

**Do not start implementing, and write nothing** — agreement is the whole job here.

**Next:** `dw-shape` to turn this understanding into a `CHANGE.md` with a task list.

$ARGUMENTS
