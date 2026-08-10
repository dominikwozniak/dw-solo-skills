---
created: 2026-08-10
source: check-decisions-in-ci
---

# `CONTRIBUTING.md`'s pre-push command and gate table are two gates behind CI

`:21` omits `pnpm validate:evals` and `pnpm eval:routing`, and `:24` says "CI runs those five" when
it runs seven plus `trufflehog`. `AGENTS.md:109` has the correct list; nothing checks the two agree.
Noticed while editing the table row in `.ai/archive/check-decisions-in-ci/`.
