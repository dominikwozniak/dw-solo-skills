---
created: 2026-08-01
---

# Three fixes to the `dw-solo-setup` payload, plus tests for the two scripts they open

Bundled because every one of them ships: one `dw-solo-setup` bump instead of three chances to forget
it — `validate-manifests.sh` cannot see a missing bump (`## Gotchas`).

- `typecheck-on-stop.sh` needs a way to say "this repo has no typecheck". It skips only
  `{{TYPECHECK_COMMAND}}`, so the honest value this repo already writes,
  `**Typecheck command**: none`, would be `eval`ed as a command (`:32`). **Vendored from
  `dw-skills`** — apply the fix in both repos.
- `doctor.sh` gains one WARN-tier (never FAIL) check for `codex` on PATH plus the `openai-codex`
  plugin dir, fix `/codex:setup`, depth capped there — never probe auth. Codex is the only companion
  the skills route to (`dw-check:45-61`, `dw-ship:52`); local accelerators like `ctx7` and `rtk` stay
  out, since no skill names them and `doctor.sh` runs on a consumer's machine.
- `templates/CLAUDE.local.md:61` offers `CONTEXT.md` inside parenthetical prose, so a scaffolded repo
  can end up with a glossary nothing points at. **Count the readers before doing this one**: the
  premise was three skills reading that file, and the `routing-eval-explain-flag` branch removes the
  instruction from `dw-grill` and `dw-next` and deletes this very entry on its own branch. If nothing
  reads the glossary once that lands, the bullet goes with it.
- While both scripts are open, give them the self-tests they have never had: `doctor.sh` is 261 lines
  and the only script that runs on someone else's machine. Taken off `shell-test-sweep`.

Detail: `.ai/archive/language-discipline-in-grill-and-next`.
