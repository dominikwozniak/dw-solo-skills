---
created: 2026-08-14
source: commit-pattern-hook
---

# Three more guardrail hooks surfaced by the buildwithclaude survey

One change if ever built — same templates/settings wiring, one bump. Candidates: a PreToolUse
Edit/Write block on `plugins/**` ("edit the canon in `skills/…`" — the AGENTS.md absolute rule,
today prose-only); `credential-leak-guard` (secret hunting/exfiltration, beyond what
`block-env-access.sh` sees); `large-file-guard` (PostToolUse Write size warning). Source:
davepoon/buildwithclaude, `plugins/hooks-safety`.
