---
created: 2026-08-12
source: block-env-heredoc-escape
---

# Carry the heredoc fix across to `dw-skills`, where the same hook is vendored

`templates/hooks/block-env-access.sh` and its self-test were byte-identical in both repos until this
change; the team lane still blocks a heredoc commit message naming a dotenv file. Nothing across the
repo boundary detects the drift. Hunk and reasoning: `.ai/archive/block-env-heredoc-escape/`.
