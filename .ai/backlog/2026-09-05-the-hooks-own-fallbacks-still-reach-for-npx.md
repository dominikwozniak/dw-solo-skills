---
created: 2026-09-05
why-not-now: needs a call on non-pnpm consumers, whose lint and typecheck probes exist precisely because they have no pnpm
effort: S
source: hooks-audit-fixes
---

# The pnpm guard now refuses `npx`, but two hooks still emit it as their own last-resort probe

`lint-on-edit.sh:85` prints `npx eslint --fix --max-warnings 0` and `typecheck-on-commit.sh:77` prints
`npx tsc --noEmit` when nothing is declared and `pnpm exec` is unavailable. Neither goes through the
Bash tool, so `block-non-pnpm.sh` never sees them and nothing is broken today — but the repo now
declares one rule and ships hooks that quietly hold the other.

`pnpm dlx` is not a drop-in here: the probes want the project's own installed eslint/tsc, which is what
`pnpm exec` already covers on the line above. The open question is what the fallback should do in a
repo with neither — drop the probe, or keep `npx` and say in the file why this one place is exempt.
