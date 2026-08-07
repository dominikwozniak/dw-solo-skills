---
created: 2026-08-01
---

# Fix `block-env-access.sh` so a commit message naming a dotenv file isn't blocked

The quoted-prose escape only survives `-m "…"`, not a heredoc. The `tr '\n' ' '` fold at `:50` is not
the fix and the comment at `:44-47` should not be read as one — it covers the multi-line `-m "…"`
case, where `sed` strips quotes per line; a heredoc carries no quoting to strip. Measured 2026-08-07:
both bare and quoted delimiters exit 2, both `-m` forms exit 0. **Vendored from `dw-skills`** — apply
the fix in both repos, and extend `scripts/tests/block-env-access.test.sh` with the heredoc case.
