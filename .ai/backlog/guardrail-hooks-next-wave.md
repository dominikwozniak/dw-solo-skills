---
created: 2026-08-14
source: commit-pattern-hook
---

# The guardrail hooks' next wave — everything the commit-pattern change deliberately left on faith

One change if ever built: same `templates/hooks/` + settings wiring, one gate run, one bump.

- Commit-hook layers: validate the trailer policy from `## Git conventions`; block a backtick
  inside `-m` (command substitution silently drops the span — the hazard `dw-git` documents);
  block `git add -A` / `git add .`.
- New hooks from the buildwithclaude survey (davepoon/buildwithclaude, `plugins/hooks-safety`):
  a PreToolUse Edit/Write block on `plugins/**` ("edit the canon in `skills/…`" — the AGENTS.md
  absolute rule, today prose-only); `credential-leak-guard` (secret hunting/exfiltration beyond
  `block-env-access.sh`); `large-file-guard` (PostToolUse Write size warning).
