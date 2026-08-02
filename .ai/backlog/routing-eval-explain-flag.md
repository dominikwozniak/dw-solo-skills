---
created: 2026-08-02
---

# `node evals/routing.ts --explain "<prompt>"`

Two of `dw-git`'s prompts score `no signal`, and the runner says only that nothing discriminated. It
does not say which terms it produced or which were dropped as out-of-vocabulary — the one thing you
need to fix the case file or the description. A flag printing the stems, their idf, and the top
matches would also make the stemmer directly testable, which it currently is not.
