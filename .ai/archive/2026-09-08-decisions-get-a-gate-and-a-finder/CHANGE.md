---
change: decisions-get-a-gate-and-a-finder
branch: decisions-get-a-gate-and-a-finder
created: 2026-09-08
status: landed # shaping | building | landed
landed: 2026-09-08
pr: https://github.com/dominikwozniak/dw-solo-skills/pull/63
---

# Change — a decision record is written only where the bar is read, and found without scanning the folder

## Decisions

- **The agent carries the method, never the bar**
  (rejected: hard to reverse — the bar-passing protocol is two prose blocks,
  `agents/dw-decisions.md:23-34` and `skills/dw-land/SKILL.md:56-59`, and reversing it is pasting
  four lines of `references/decision-record.md` into the prompt. The agent-and-`tools:` half of it
  is already decided by `0025`.)

## Tasks

- [x] 1. `agents/dw-decisions.md` — the contract for three modes (`ask`, `judge`, `audit`),
      `tools: Read, Grep, Glob`, `model: sonnet`; symlink at `plugins/dw-solo-extras/agents/`,
      listed by path in the `agents` array, extras version bumped.
- [x] 2. Sharpen both agent descriptions so `dw-docs-drift` keeps referent-existence prompts and
      `dw-decisions` keeps decision prompts — `0025`'s revisit trigger fires the moment a second
      agent lands.
- [x] 3. `skills/dw-land/references/decision-record.md` — `touches:` and `rule:` in the frontmatter
      shape, with what each is for and the note that neither is machine-checked.
- [x] 4. `templates/decisions-README.md` — the two fields for a consumer repo, still no index and
      still no second copy of the bar.
- [x] 5. `skills/dw-next/SKILL.md` — the promote bullet becomes a nominate bullet, plus the narrow
      `touches:` grep for a file the change doc did not anchor.
- [x] 6. `skills/dw-land/SKILL.md` — the gate: judge every nomination, call the agent when there is
      one and it is installed, and stop claiming the promotion already happened at `:49`.
- [x] 7. `skills/dw-land/SKILL.md` — the receipt keeps a rejected nomination with its failing leg;
      `:71` currently deletes the section it lives in.
- [x] 8. `skills/dw-shape/SKILL.md` (and `dw-grill`'s read step) — grep `touches:` over the anchors'
      paths and carry the matching `rule:` into `## Decisions`; the agent's `ask` mode for an open
      question.
- [x] 9. Green: `pnpm validate:manifests`, `validate:docs`, `validate:artifacts`,
      `validate:versions`, `eval:routing`, `format`; both plugin versions bumped.

## Notes

- Built by the rule this change introduces: the bar-carrying call was nominated in `## Decisions`,
  not promoted mid-build. Cheapest way to test the mechanism is to use it — and the gate then
  rejected it.
- `templates/` ships in `dw-solo-setup`, so touching `templates/decisions-README.md` obliged a setup
  bump too — three plugins moved in this change, not two.
- `main` moved mid-session (another session pushed `dw-solo-setup 0.4.2`). The branch was rebased
  onto `origin/main` before the bumps, or the merge would have reverted that number.
- The agent is not installed from this branch, so it was exercised by handing its own file to a
  subagent as instructions. That tests the contract, not the registration — `@dw-solo-extras:dw-decisions`
  is unproven until the plugin is reinstalled.
- Two review rounds, eleven findings then seven. Two of the second round's were created by the
  first round's fixes: giving the agent two new verdicts without giving `dw-land` anywhere to file
  them.
