---
name: dw-grill
description: >-
  Interview the user to sharpen a fuzzy idea into decisions before anything gets written — one
  question at a time, at most five, hardest-first, each with a recommended answer. Writes nothing;
  the shared understanding it reaches is the input to `dw-shape`. Use when an idea is still vague,
  when a request could be read two ways, or when someone says "grill me", "interview me", "poke
  holes in this", "help me think this through". Prefer this over guessing at intent.
argument-hint: "What should I grill you about?"
---

# dw-grill — interview the idea before it becomes work

The cheapest bug to fix is one you talked yourself out of. This skill exists because the model's
instinct on a fuzzy request is to pick a plausible reading and build it — and a wrong reading found
after the code is written costs a rewrite.

It is deliberately conversational and writes nothing. What it produces is a **shared understanding**,
which `dw-shape` then turns into a durable artifact.

## What it reads

The conversation, plus whatever it can verify in the repo. The subject may arrive as `$ARGUMENTS`;
otherwise it's whatever is being discussed. It writes no files.

## Workflow

### 1. Separate facts from decisions

Split everything you don't know into two piles, because they are answered differently:

- **Facts** — anything discoverable in the environment: which library version is installed, whether
  a route already exists, what the schema column is called, how the neighbouring module does it.
  **Look these up. Never ask.** Asking the user to read their own repo to you is the failure mode
  this rule exists to prevent.
- **Decisions** — trade-offs, scope boundaries, product choices, "which of these two shapes".
  These are the user's, and only these become questions.

### 2. Spend the question budget well

**At most five questions.** That cap is the point: it forces you to decide what is worth asking
instead of interrogating. Order them hardest-first, by what a wrong answer would cost:

1. **scope** — what's in, what's out, what this replaces vs extends
2. **security / privacy** — anything touching auth, personal data, secrets, money
3. **UX** — what the user of the thing sees and does
4. **technical detail** — last, because it is usually the cheapest to change later

Drop anything below the cap that isn't load-bearing. Four good questions beat five with a filler.

**Don't ask about these — assume a sensible default and say which one you assumed:** code style and
formatting, test framework, directory layout, naming conventions, logging, error-message wording,
which of two equivalent libraries already in the project to use. All of those are either in the repo
already or cheap to change. If a "default" turns out to be load-bearing, it was a scope question in
disguise — promote it.

### 3. Ask one at a time, with your recommendation

**One question per message.** Asking several at once is bewildering and reliably produces answers to
the first and silence on the rest.

Each question should be answerable as **two to five mutually exclusive options**, or in five words.
Always state which option you'd pick and why — a recommendation to react to is far easier than a
blank prompt, and disagreement is more informative than invention.

Then **wait.** Don't answer your own question and move on.

### 4. Resolve the tree, not the list

Answers open and close branches. After each one, re-derive what is still genuinely open: an answer
often makes two later questions moot, and sometimes reveals a question that matters more than
anything left on your list. Follow the branch the answer opened before returning to your original
order.

### 5. Close explicitly

Stop when the remaining unknowns wouldn't change what gets built. Say so, and play back the shared
understanding in a few lines: what we're building, what we decided, what we deliberately left out.

Keep that last list explicit and separate — `dw-shape` is what turns it into something durable, either
as a Decision in `CHANGE.md` or as a line in `.ai/BACKLOG.md`. **This skill still writes nothing**: a
playback the next step can act on is the deliverable, and an interviewer that also files things is one
you can't run to think out loud.

**Do not start implementing.** Getting agreement is the whole job here — writing it down is
`dw-shape`'s, and building it is `dw-next`'s.
