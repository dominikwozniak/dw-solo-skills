---
created: 2026-08-01
---

# Give `typecheck-on-stop.sh` a way to say "this repo has no typecheck"

It `eval`s the `**Typecheck command**` value from `CLAUDE.local.md`, and the only value it skips
is the `{{TYPECHECK_COMMAND}}` placeholder — which the same template's closing section calls a
mistake. This repo already writes the honest value, `**Typecheck command**: none`, which a consumer
with the hook wired would `eval` as a command (`typecheck-on-stop.sh:32`).
