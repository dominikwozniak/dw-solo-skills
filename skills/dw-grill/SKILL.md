---
name: dw-grill
description: >-
  Interview the user to sharpen a vague, half-formed idea into decisions before any of it gets
  built — one question at a time, at most five, hardest-first, each with a recommended answer, so
  the thinking is finished first.
argument-hint: "What should I grill you about?"
---

# dw-grill — interview the idea before it becomes work

**Conversational, and it writes nothing.** The deliverable is a shared understanding that
`dw-shape` turns into a durable artifact. Read `CONTEXT.md` first where the project has one, and
ask in its terms.

## Workflow

1. **Separate facts from decisions.** Facts — anything discoverable in the repo or environment —
   are looked up, never asked. Only decisions (trade-offs, scope boundaries, product choices, which
   of two shapes) become questions.
2. **Spend the budget well — at most five questions**, hardest-first by what a wrong answer would
   cost: scope → security/privacy → UX → technical detail. Four good questions beat five with a
   filler. Don't ask what the repo already answers (style, test framework, layout, naming, which
   installed library) — assume the sensible default and say which one you assumed.
3. **One question per message**, answerable as two to five mutually exclusive options or in five
   words, always with the option you'd pick and why. Short active sentences, one word with one
   meaning. Then **wait** — never answer your own question and move on.
4. **Resolve the tree, not the list.** After each answer, re-derive what is still genuinely open:
   an answer often closes two later questions, or opens one that matters more than anything left.
5. **Close explicitly** when the remaining unknowns wouldn't change what gets built. Play back in a
   few lines: what we're building, what we decided, every resource the conversation pointed at, and
   — explicit and separate — what we deliberately left out. `dw-shape` gives each named left-out
   item its fate, and an item you don't name never gets one.

**Do not start implementing, and write nothing** — agreement is the whole job here.

**Next:** `dw-shape` to turn this understanding into a `CHANGE.md` with a task list.

$ARGUMENTS
