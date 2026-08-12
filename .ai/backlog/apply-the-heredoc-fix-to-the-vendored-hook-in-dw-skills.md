---
created: 2026-08-12
source: block-env-heredoc-escape
---

# Carry the vendored-hook fixes across to `dw-skills`, where the same three hooks live

Bundled because it is one pass over one directory in one other repo: `templates/hooks/*.sh` was
byte-identical across both lanes until these changes, and nothing across the repo boundary detects the
drift. Both fixes are backward-compatible for the team lane, so nothing there blocks on them.

- `block-env-access.sh` — the team lane still blocks a heredoc commit message naming a dotenv file.
  Hunk and reasoning: `.ai/archive/block-env-heredoc-escape/`.
- `lint-on-edit.sh` and `typecheck-on-stop.sh` — the `AGENTS.md`-first resolution chain, and `none`
  as a sentinel that stops it rather than being `eval`ed. `typecheck-on-stop.sh` also carried the BSD
  `\s` bug and had no self-test. Hunks: `.ai/archive/setup-lives-in-tracked-agents-md/`.
