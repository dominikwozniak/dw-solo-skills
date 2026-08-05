---
change: language-discipline-in-grill-and-next
branch: unclaimed
created: 2026-08-05
status: shaping # shaping | building | landed
---

# Change — a language discipline for the loop: plain register when it asks, established terms when it names

## Goal

`dw-grill` asks its questions in a deliberately plain register, and both `dw-grill` and `dw-next` read
`CONTEXT.md` before coining or naming anything. Observable after a reinstall: `/dw-grill` on a fuzzy
idea returns visibly shorter, flatter questions, and `/dw-next go` in a project that has a glossary
names things with terms already in it — and says so when it coins a new one.

## Decisions

- **The register rule covers `dw-grill`'s questions only, never the artifacts** — ASD-STE100 buys a
  register, not conformance (its ~900-word dictionary is licensed and uncheckable), and that trade
  only pays where a misread sentence causes a wrong answer. `CHANGE.md`, `docs/decisions/` and
  `## Gotchas` stay dense; that density is load-bearing.
- **Name the standard, then gloss it** — the acronym is the compact handle for the model; the gloss is
  what a human reader gets instead of a licensed spec to go look up.
- **Per-skill lines, not one auto-loaded pointer** — `dw-solo` and `dw-solo-setup` install separately,
  so anything riding on `dw-init`'s output is absent for a loop-only install. Upstream reaches the same
  answer explicitly: _"a one-line habit any skill can do"_ (`domain-modeling/SKILL.md:8`).
- **Drop the phrase "ubiquitous language"** — it appears nowhere in this repo and is not in `CONTEXT.md`
  itself, so importing it would add an undefined term to the repo whose thesis is that terms get
  defined. This lane says _glossary_ / `CONTEXT.md`.
- **`dw-check` stays out** — a vocabulary lens would widen it toward the linting role `docs/DESIGN.md`
  keeps it out of.
- **One change, not two** — the count test yields 2, but the goal is single and the whole diff is ~6
  added lines; two change docs and two bumps for that is the ceremony this lane exists to avoid. The
  shared file was explicitly _not_ the reason — `dw-shape:94-96` disallows that as a merging argument.

## Tasks

- [ ] 1. `dw-grill` `### 3` — add the register rule after the "five words" paragraph, before
      `Then **wait.**`: **"Write the question in ASD-STE100 Simplified Technical English"** plus the
      gloss (short active sentences, one word with one meaning, no undefined term) and the reason
      (a question misread is a question answered wrong).
- [ ] 2. `dw-grill` `## What it reads` — add a second paragraph: read `CONTEXT.md` before the first
      question, because this is where words get coined and a second name for a thing that has one is
      the drift the glossary exists to stop.
- [ ] 3. `dw-next` — declare the read in `## What it reads and writes`, and add a
      **"Use the project's words."** bullet directly after **"Follow the anchors."** in `### 3`,
      closing with the pointer that `dw-land` promotes a genuinely new term at the end.
- [ ] 4. Bump `dw-solo` `0.4.8 → 0.4.9` in both manifests (identical values), then run the full gate.

## Anchors

- `skills/dw-grill/SKILL.md:57-66` — `### 3`; the rule goes between `:64` and `:66`. It extends the
  step's existing compression discipline rather than opening a new axis.
- `skills/dw-grill/SKILL.md:21-24` — `## What it reads`, currently conversation + repo only.
- `skills/dw-next/SKILL.md:21-26` — `## What it reads and writes`; names `CHANGE.md` + `HANDOFF.md`.
- `skills/dw-next/SKILL.md:87` — **"Follow the anchors."**, the bullet the new one pairs with: that one
  matches local _patterns_, this one matches local _vocabulary_. Placement in `### 3` is the point —
  it fires at naming time, not as bookkeeping.
- `skills/dw-shape/SKILL.md:66-67` — the sentence to mirror, so the new reads land as one existing
  habit rather than a new rule.
- `skills/dw-land/SKILL.md:73` — "Promote the vocabulary", the write half of the loop `dw-next` joins.
- `.claude-plugin/marketplace.json:13` · `plugins/dw-solo/.claude-plugin/plugin.json:3` — the paired
  versions. `validate-manifests.sh` checks they are _equal_, never that either moved.

## Notes

- **Unexercised until reinstall.** No test asserts skill body content, by design, and the shaping
  session ran the cached `0.4.8` copy — do not verify by invoking `dw-grill` or `dw-next` in the
  session that edits them.
- `eval:routing` should come back unchanged: no `description` and no `argument-hint` is touched, so no
  term's idf shifts and the README **Arguments** column stays correct.
- Edit the canon at `skills/<name>/SKILL.md`. Any `plugins/*/skills/` path appearing in `git diff`
  means an edit went through a symlink.
- Neighbouring backlog entry **offered, not folded in**: `.ai/backlog/echoing-eval-positives.md` also
  concerns `dw-grill`, but it is `evals/cases/` plus the `--min-rank1` pin — no file overlap, and it
  would need a paid eval re-run.
- Backlog candidates surfaced during `dw-grill`, for `dw-land` to park: the `@CONTEXT.md` auto-import
  (or a third `dw-init`-managed `CLAUDE.md` section), and turning `templates/CLAUDE.local.md:61`'s
  `**Domain**` placeholder into a real `CONTEXT.md` pointer.
