---
created: 2026-08-10
source: two-gates-against-scope-shedding
---

# Re-triage this repo's own `.ai/` state against the bar it now ships — two `.ai/` hygiene fixes, one pass

Both are housekeeping over tracked `.ai/`, no version bump and no payload, so they ship together:

- The live backlog entries predate the absorption bar. Some are plausibly commits in a change that
  already touched the file — apply the new bar and drop or fold what doesn't clear it.
- `.ai/work/skill-and-docs-drift/` is a backlog entry `git mv`'d into `work/` and never reshaped: no
  `change:`, `branch:` or `status:` frontmatter, no task checkboxes. `dw-next` can't find it by
  branch and `dw-start` can't claim it.
