---
created: 2026-08-05
source: shape-splits-changes
---

# `dw-ship`'s "you skipped `dw-check`" nudge only exists on the PR path

`skills/dw-ship/SKILL.md:51-52` offers a second pair of eyes inside `### 3. The PR path`. `### 2. Pick
the path` means there is also a direct-push path, and it carries no such line — so shipping without a
PR reaches the irreversible step having never mentioned a review. Fix in `dw-ship`, not in `dw-land`:
the closing pass is deliberately not a review pipeline (`dw-land:14-15`).
