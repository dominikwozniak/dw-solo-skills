---
created: 2026-08-14
source: commit-pattern-hook
---

# The commit hook checks the subject only — the trailer, the backtick-in-`-m`, and `git add -A` are still on faith

Three extensions of `enforce-commit-pattern.sh`, one change, one version bump: validate the trailer
policy from `## Git conventions`, block a backtick inside a `-m` string (command substitution
silently drops the span — the hazard `dw-git` documents), block `git add -A` / `git add .`. Held
back so the base hook proves itself in the field first.
