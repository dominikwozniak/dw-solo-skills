---
change: absorb-follow-ups-by-default
branch: absorb-follow-ups-by-default
created: 2026-08-23
status: landed
landed: 2026-08-23
---

# Change — the loop absorbs session-sized follow-ups instead of manufacturing backlog and doc churn

## Goal

A session-sized follow-up gets **done before close**, not filed: `dw-next` fixes discoveries in
place, `dw-land` refuses a backlog file for anything that passes "should it have been done now?".
What genuinely defers is two-tier — a report/PR-body line by default, an expensive backlog entry
(`why-not-now` + `effort`) only above that. Most lands promote **nothing** to
decisions/CONTEXT/gotchas. References named at grill/shape survive into `CHANGE.md` and `dw-next`
proves it read them.

## Decisions

- Do-it-now is a hard rule, not a bar to weigh — deferring reversible session-sized work is the
  failure mode (consensus across `.inspirations/`: pstack, gstack, addyosmani).
- Two-tier deferral: report-open (no file) is the default; a `.ai/backlog/` file costs
  `why-not-now:` + `effort:` frontmatter — the cost pushes small items into do-it-now.
- No drive-by edits in `dw-next` — nothing outside the current task; an absorbed fix is its own
  commit, never a smuggled hunk.
- Promotion bar raised at `dw-land`: only what the verdict explicitly names; ADR needs all three of
  hard-to-reverse + surprising + real trade-off; zero promotion is the normal outcome.
- `## References` is a first-class `CHANGE.md` section — external pointers (paths, URLs, folders)
  from grill/shape land there; `dw-next`'s opening report names which it read.
- Anti-slop in grateful-me stays; the ceremony around adding a rule was the cost, and absorb-now
  removes it. Meta-vs-product brake, residue ratchet, backlog pruning: deliberately out.

## Tasks

- [x] 1. `skills/dw-next/SKILL.md` — step 3 absorb rule (reversible + related + session-sized →
      fix now, own commit), no-drive-by rule, and deferral routed through the two tiers.
- [x] 2. `skills/dw-next/SKILL.md` — step 1 report lists the `## References` entries and which
      were read before building.
- [x] 3. `skills/dw-land/SKILL.md` — the verdict's "ready with follow-ups" splits report-open
      items (report + PR body only) from backlog candidates.
- [x] 4. `skills/dw-land/references/promote.md` — invert the follow-up default: test
      "should it have been done now?" first, do it before closing when it passes; a file only for
      work exceeding the session, with `why-not-now:` + `effort:`; zero files stays normal.
- [x] 5. `skills/dw-land/references/promote.md` — raise the decisions/CONTEXT/gotchas bar: only
      what the verdict named, three-part ADR test, most lands promote nothing.
- [x] 6. `skills/dw-shape/SKILL.md` + `references/CHANGE.md` — add `## References` (one line:
      path/URL + why), mandatory for every resource the conversation pointed at; skippable when none.
- [x] 7. `templates/backlog-README.md` — the two-tier rule and the expensive entry format, so
      `dw-init` ships it.
- [x] 8. Housekeeping — bump dw-solo (and dw-solo-setup if templates count as its payload) in both
      manifests, re-record the corpus baseline, run the full `scripts` gate incl. `eval:routing`.

## Anchors

- `skills/dw-next/SKILL.md:63-68` — the "one small file in `.ai/backlog/`" sentence the absorb rule replaces.
- `skills/dw-land/references/promote.md:53-67` — the "every follow-up becomes one file" block to invert.
- `skills/dw-shape/references/CHANGE.md:33-38` — `## Anchors`; `## References` sits beside it, same one-line style.
- `templates/backlog-README.md:18-23` — the two-bars paragraph the two-tier rule extends.
- `docs/agents/skills-and-plugins.md:88-99` — a skill body ships to repos without this repo's tooling; write mechanisms as conditions.

## References

- `.inspirations/` survey (this conversation): pstack `cursor-plugins/pstack/skills/poteto-mode/playbooks/autonomous-run.md:9` (do not park reversible work), gstack `ETHOS.md:40-57` (defer-to-follow-up is an anti-pattern), mattpocock `skills/engineering/domain-modeling/SKILL.md:60-72` (three-part ADR bar, zero-promotion norm), pstack `skills/no-comments/SKILL.md:22` (report-open tier).
- Evidence pattern: grateful-me-app-v2 PRs #37→#38→#39 (parked lint rule became two extra PRs), backlog at 11 entries.

## Notes

- The three-part ADR bar already existed verbatim in `decision-record.md`; task 5 became the verdict-scoping rule instead.
- Task 7 also updated the live `.ai/backlog/README.md` twin in the same commit — the absorb rule, applied to itself.
- Gotcha-to-mechanism promotion now routes through the same two tiers (session-sized mechanism → build before closing).
