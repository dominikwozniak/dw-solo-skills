---
created: 2026-08-01
---

# Fix `block-env-access.sh` so a commit message naming a dotenv file isn't blocked

The quoted-prose escape only survives `-m "…"`, not a heredoc. **Vendored from `dw-skills`** —
apply the fix in both repos, and extend `scripts/tests/block-env-access.test.sh` with the heredoc
case.
