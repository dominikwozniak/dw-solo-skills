---
change: a-ticked-box-names-the-evidence-that-checks-it
branch: a-ticked-box-names-the-evidence-that-checks-it
created: 2026-09-10
status: landed # shaping | building | landed
landed: 2026-09-10
---

# Change — a ticked box names the evidence that checks it

## Decisions

- **A tick asserts a check that ran, not work that happened. (rejected: hard to reverse)** — surprising and a real trade-off both hold, but the change is confined to this repo's canon: four skill files and a glossary line, none of them payload, so `dw-init` copies none of it and reversing it is the same edit as making it. The nomination claimed target projects vendor the template; they do not.

## Tasks

<!-- Convention: `- [ ]` pending, `- [x]` done — `dw-next` flips the box in the task's own commit.
A task that stopped being necessary keeps its box and gains `**skip:** <reason>`; every later
invocation reads that as not remaining. Never rename a task title. -->

- [x] 1. The task line in `skills/dw-shape/references/CHANGE.md` gains the `proof:` clause, and the tick-convention comment above it gains the sentence that a box is ticked only once its named proof exists — proof: `sed -n '43,49p' plugins/dw-solo/skills/dw-shape/references/CHANGE.md` shows both through the shipped symlink
- [x] 2. `skills/dw-shape/SKILL.md:89-92` — a task with no nameable check is badly cut, one sentence in step 3 — proof: `grep -n 'proof' plugins/dw-solo/skills/dw-shape/SKILL.md` returns the new line
- [x] 3. `skills/dw-next/SKILL.md:78` — the box flips after the named check ran, not after the code was written, and what ran goes in the commit body — proof: `sed -n '76,84p' plugins/dw-solo/skills/dw-next/SKILL.md`
- [x] 4. `skills/dw-next/SKILL.md:60`, **Test the way the project does** — the `0013` bar in one sentence — proof: the sentence read back beside `docs/decisions/0013`'s own wording, no third variant introduced
- [x] 5. `skills/dw-next/SKILL.md` step 3 — `attack-the-premise` as one bullet: two fixes on one premise refused by the same gate means write the premise down and list the cases before the third fix — proof: `grep -n 'premise' plugins/dw-solo/skills/dw-next/SKILL.md`
- [x] 6. `skills/dw-land/SKILL.md:34` and `:75` — the rung ladder reads the boxes and grades a proofless box as `said so`; the mechanism requirement gains `build-the-lever`'s falsifiable half (cited a mechanism, no hook, validator or self-test in the diff, then you did not do it) — proof: `sed -n '32,36p;73,78p' plugins/dw-solo/skills/dw-land/SKILL.md`
- [x] 7. `node scripts/check-skill-corpus.mjs --update-baseline`, and bump `dw-solo` 0.9.2 → 0.9.3 in `plugins/dw-solo/.claude-plugin/plugin.json` and `.claude-plugin/marketplace.json`, all in one commit — proof: `pnpm validate:artifacts` and `pnpm validate:versions` both green

## Notes

- A proof only the push can run keeps its box open and still hands off: without that carve-out named in `dw-next`, a CI-only check could never be ticked and `dw-land` could never be reached.
- The falsifiability clause went to `dw-land:75`, the phase-2 Gotchas bullet, not phase 3 as the plan said; phase 3 opens the PR.
- `CONTEXT.md`'s **Task** bullet was rewritten rather than joined by a second one, since the term gained half its meaning here.
- `dw-shape`'s `## References` line was updated in task 2 so the pointer to the template still names what it holds.
