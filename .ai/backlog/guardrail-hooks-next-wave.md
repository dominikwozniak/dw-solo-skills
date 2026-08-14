---
created: 2026-08-14
source: commit-pattern-hook
---

# Three more guardrail hooks, surfaced while shaping the commit-hygiene one

One change if ever built: same `templates/hooks/` + settings wiring, one gate run, one bump.
Candidates, from the buildwithclaude survey (davepoon/buildwithclaude, `plugins/hooks-safety`):
a PreToolUse Edit/Write block on `plugins/**` ("edit the canon in `skills/…`" — the AGENTS.md
absolute rule, today prose-only); `credential-leak-guard` (secret hunting and exfiltration beyond
what `block-env-access.sh` sees); `large-file-guard` (PostToolUse Write size warning).
