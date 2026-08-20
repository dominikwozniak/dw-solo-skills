# patterns — the numbered catalog

Every entry is an **edit**: the pattern, then what it becomes. A rule that only flags something is a
rule you have to think about twice.

The numbers are the ones this catalog arrived with (Lauren Tan's `unslop`, in the `pstack` Cursor
plugin), and they stay fixed so "rule 16" means the same thing in a review here as it does there. Add
new rules at 32 and up; never renumber to close a gap.

**Two rules are softened rather than adopted** — 13 and 26. Both are marked, with the reason on the
line, because a softened rule you cannot see the reasoning for gets re-tightened by the next reader.

## Content

1. **Puffery.** "pivotal moment", "a testament to", "the evolving landscape", "sets the stage for".
   Cut it and state what happened.
2. **Name-dropping.** Listing tools, companies or sources without saying what any of them did. Pick
   one and say what it does.
3. **Superficial `-ing` phrases.** A trailing "…highlighting the need for", "…ensuring consistency",
   "…reflecting the shift toward". Delete the clause, or replace it with the mechanism it gestures at.
4. **Promotional language.** "groundbreaking", "seamless", "robust", "powerful", "elegant". Say what it
   does instead. "Robust error handling" is either a list of the errors handled or nothing.
5. **Vague attributions.** "Experts suggest", "it is widely accepted that", "best practice says".
   Name the source, or drop the sentence and make the claim yourself.
6. **Formulaic tension.** "Despite the trade-offs, X remains…". Replace with the specific trade-off and
   the specific call.

## Language

7. **AI vocabulary.** additionally, crucial, delve, enhance, garner, interplay, intricate, landscape
   (abstract), pivotal, showcase, tapestry, testament, underscore, vibrant. Use the plain word.
8. **Fancy ways to say "is".** "serves as", "stands as", "boasts", "features". Say "is" or "has".
9. **"Not just X, but Y."** State Y. If X needed saying, it is its own sentence.
10. **Forced rule of three.** Three bullets over material that has two things or four. Use the real
    number — an invented third item is always the weakest one.
11. **Synonym cycling.** Calling one thing a skill, a capability, a module and a unit in one paragraph.
    Pick the word the glossary uses and repeat it. Repetition is not a style problem; a second name for
    one thing costs a translation on every read.
12. **False ranges.** "from configuration to deployment" where the two ends are not on a scale. List
    the things.

## Style

13. **Em dashes standing in for a period.** _Softened._ Upstream bans the em dash outright. Here the
    tell is an em dash doing a full stop's job — two independent clauses stapled together — and the fix
    is the full stop. An em dash carrying a genuine aside is not a tell, and this repo's prose uses it
    that way throughout; a rule that fires on the house voice gets ignored wholesale, which costs the
    other thirty.
14. **Colons as mid-sentence connectors.** Fine before a list or an example. Not as a hinge between two
    clauses that would read better as one sentence or two.
15. **Boldface overuse.** Bolding every proper noun, path or acronym. Bold the thing a skimmer needs to
    land on, then stop.
16. **Inline-header lists.** The tell is a bold label plus colon that restates the line:
    `**Performance:** Performance improved…`. Convert those to prose. A bold lead-in that ends in a
    **period**, names the item, and is followed by genuinely new detail is the opposite — it is the form
    most of this corpus is written in, and the form every rule on this page uses. Do not "fix" it.
17. **Title case headings.** Sentence case.
18. **Decorative emojis.** Out of headings and bullets. A status glyph carrying meaning (`⭑` in the
    README's task router) is not decoration.
19. **Curly quotes and typographic apostrophes.** Straight ones.

## Communication artifacts

20. **Chatbot phrases.** "I hope this helps", "Let me know if", "Of course!", "Found it!". Delete.
21. **Cutoff and uncertainty disclaimers.** "While specific details are limited…". Go find the detail,
    or make the claim without the apology.
22. **Sycophantic tone.** "Great question", "You're absolutely right". Answer.

## Filler

23. **Filler phrases.** "in order to" → "to". "due to the fact that" → "because". "it is important to
    note that" → delete, keep the note.
24. **Excessive hedging.** "it could potentially be argued that this might" → "this may", or state it.
    One hedge per claim is honest; three is a refusal to have a position.
25. **Generic conclusions.** "The future looks bright", "this sets us up well". State the next step or
    end the text. A closing paragraph that adds nothing is the easiest whole-paragraph delete there is.

## Jargon

26. **Abstract metaphor nouns.** _Softened._ Upstream bans a list that includes `ratchet`, `surface`,
    `scaffolding`, `harness` and `primitive` — the exact vocabulary this repo is built on, defined in
    `CONTEXT.md` and load-bearing in `docs/decisions/0009-skill-corpus-ratchet.md`. Adopting it whole
    would declare war on the house voice, and banning a defined term is the drift the glossary exists
    to stop. So: a metaphor noun is a tell only when a shorter concrete word exists **and** the repo
    has not already defined the metaphor as a term. Undefined and replaceable, it goes — "substrate" →
    "base", "wedge in" → "add", "vector" → "way", "gold-plating" → "more than the job needs", "north
    star" → the actual goal. Defined here, it stays, and using it is the correct call.

## Plain speech

27. **Say what it does, not how it feels.** "the database stays close at hand", "types that follow your
    schema" — both name a feeling. Name the mechanism or a number instead: "a column rename fails the
    build". This is where the two tests in the skill body come from, and it is the rule with the highest
    hit rate on a first draft.
28. **Shorten or split dense sentences.** If a reader has to backtrack to parse it, break it in two or
    drop a clause. One idea per sentence — with the carve-out that a sentence carrying a genuine
    subordinate thought is not dense, it is just long.
29. **Active voice.** Catch "is/are/was/were + past participle" and name the actor: "queries are
    validated" → "the compiler validates queries". Passive is fine where the actor is genuinely unknown
    or genuinely does not matter, which is rarer than a draft assumes.
30. **Cut the adverb or find a stronger verb.** "runs quickly" → "is fast", or the number.
    "significantly improves" → the measured delta. An adverb propping up a weak verb means the verb is
    the wrong one.
31. **Prefer the plain word.** "utilize" → "use", "leverage" → "use", "facilitate" → "help",
    "numerous" → "many", "in the event that" → "if". The longer synonym is almost never clearer.
