---
created: 2026-08-02
---

# Carry the `lint-on-edit.sh` fix over to `dw-skills`

Fixed here in `skill-routing-evals`: `sed -E` with `\s` silently fails on BSD sed, so the resolved
lint command was a single space, and `eval " \"$file_path\""` **executed the edited file** — exit 0
and no output when the file carried the executable bit. **Vendored from `dw-skills`** — that repo
still has the broken extractor. Take `scripts/tests/lint-on-edit.test.sh` across with it; the
`never_executed` sentinel is what actually pins the bug.
