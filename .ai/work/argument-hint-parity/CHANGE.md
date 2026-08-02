---
change: argument-hint-parity
branch: argument-hint-parity
created: 2026-08-02
status: building # shaping | building | landed
---

# Change — make the README Arguments column provable, and fix the three cells that already drifted

## Goal

`docs/SKILL-ANATOMY.md:50-51` states the contract — the hint is canon, the README **Arguments** cell
mirrors it — and then admits nothing enforces it. Three commits after that sentence landed, three
cells no longer mirror anything: `dw-init` and `dw-handoff` advertise a `bare` mode their hints never
mention, and `dw-start`'s hint leads with the slug and separates with `", or"`, breaking the very
convention it sits two bullets below. Known when `pnpm validate:docs` passes on all 11 skills and
fails on a hand-broken cell.

## Decisions

- **Keep the prose hints; don't adopt codex's `[--flag|--flag]` syntax** — no `dw-*` skill has a
  single `--` flag and every mode is a bare word, so bracket syntax would advertise a parser that
  doesn't exist. The mechanism is already identical: Claude Code reads `argument-hint` out of
  `SKILL.md` frontmatter with the same loader it uses for `commands/*.md`.
- **Fix the hints, not the cells, for `dw-init` and `dw-handoff`** — both have a real bare mode
  (`dw-init` detects the stack from disk, `dw-handoff` saves where you are). The cells were right and
  the hints incomplete, so the fix also makes every hint lead with bare, as the convention says.
- **`dw-git`, `dw-grill` and `dw-shape` keep their question-form hints** — they're the free-text
  skills, with no bare mode and no mode words, so "state bare first" can't apply to them. The doc is
  what's wrong here; extend the free-text bullet rather than rewrite three hints into a lie.
- **Token-subset parity, not string equality** — the cell is a condensation of the hint
  (`AGENTS.md:60-63`), so the two can never be equal. Requiring every backticked token in the cell to
  appear in the hint catches all three live drifts and passes the other eight with no false positive.
- **Skill links are exempt from the token check** — a cell may point at another skill
  (`` → `dw-shape` ``), so tokens matching `dw-[a-z-]+` are links, not arguments.
- **No test file** — `validate-docs.sh` is CI-only, never shipped; `scripts/tests/` covers the hooks
  and `scripts/runtime/` only, and `pnpm validate:docs` over the real tree is the test.
- **This answers a parked question, not a new one** —
  `.ai/archive/skill-arguments-reference/CHANGE.md` deferred the validator because "a presence check
  can't catch the drift that matters". True, and a subset check can; the trigger it named ("revisit
  if the column actually rots") has fired.

## Tasks

- [x] 1. Rewrite the three hints so each leads with bare, `·`-separated. `dw-start` →
      `bare lists the unclaimed changes · <slug> opens that one · a description shapes it first`,
      which also documents the third input path at `skills/dw-start/SKILL.md:31-34` that today exists
      only in the body. `dw-init` → `bare detects the stack from disk · any project context to seed`.
      `dw-handoff` → `bare saves where you are · or name what the next session should focus on`.
- [ ] 2. `README.md` task-router — `dw-start`'s Arguments cell becomes
      `` `bare` lists unclaimed · `<slug>` · a description → `dw-shape` ``. The `dw-init` and
      `dw-handoff` cells stay as they are; task 1 is what makes them true.
- [ ] 3. `docs/SKILL-ANATOMY.md` — name `dw-git` in the free-text bullet and sanction the question
      form for free-text-only skills, then replace "no validator catches the drift" with the rule
      check 5 enforces.
- [ ] 4. `scripts/validate-docs.sh` — check 5, reusing check 3's row lookup: the README row is the
      line that starts with `|` and contains `skills/<name>/SKILL.md`; the Arguments cell is its 4th
      pipe field; the cell is `—` iff the skill has no `argument-hint`; every backticked token that
      isn't `dw-[a-z-]+` must be a substring of the hint. Update the header comment from four checks
      to five.
- [ ] 5. Patch-bump each plugin that owns an edited skill body, in `plugin.json` **and**
      `.claude-plugin/marketplace.json`: `dw-solo` 0.4.6 → 0.4.7 (`dw-start`), `dw-solo-setup`
      0.1.4 → 0.1.5 (`dw-init`), `dw-solo-extras` 0.1.1 → 0.1.2 (`dw-handoff`).

## Anchors

- `scripts/validate-docs.sh:77` — `grep "skills/$name/SKILL.md" "$README"`, check 3's row lookup.
  Check 5 copies it and adds a leading-`|` guard so a prose mention can't match as a table row.
- `scripts/validate-docs.sh:5-10` — the four-check header comment that becomes five.
- `docs/SKILL-ANATOMY.md:36-51` — the four hint conventions. `:44-45` is the free-text bullet to
  extend, `:50-51` the honor-system sentence to replace.
- `README.md:72-100` — the four task-router tables; Arguments is the 4th pipe field in each.
- `skills/dw-start/SKILL.md:31-34` — the three input paths, one documented nowhere else.
- `.ai/archive/skill-arguments-reference/CHANGE.md` — the change that wrote the column and parked
  this validator.

## Notes

Verified against the Claude Code 2.1.220 binary before shaping, rather than against docs:

- `argument-hint` is read by the same skill loader that reads `commands/*.md`, and the field's own
  description is "Placeholder text shown after the slash command name" — so `/dw-next` already gets
  exactly what `/codex:review` gets. Nothing about the mechanism needs changing.
- There is an undocumented sibling key, `arguments`, which the schema marks as an internal typed
  variant of `argument-hint` and which parses into positional `argumentNames`. Deliberately unused
  here: internal and unadvertised.
- The token-subset rule was checked by hand against all 11 skills. It fails exactly `dw-init`,
  `dw-handoff` and `dw-start`, and passes the other eight.

Found while building:

- `dw-start`'s new hint line is 104 characters, over `.prettierrc.json`'s `printWidth: 100`, and
  both prettier and agnix pass anyway — prettier does not fold a long YAML scalar. Leave it; a
  future session should not "fix" the wrap.
- **Task 2 is smaller than shaped.** Its stated job was to stop the `dw-start` cell drifting, but
  task 1 already did that: the cell's two tokens, `bare` and `<slug>`, both appear in the new hint,
  so check 5 would pass it as it stands. What is left is only adding the third input path
  (`` · a description → `dw-shape` ``) — completeness, not a drift fix.
