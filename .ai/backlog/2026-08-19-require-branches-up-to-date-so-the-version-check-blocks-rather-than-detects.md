---
created: 2026-08-19
source: the-version-bump-check-gets-a-base-ref
---

# `validate-versions.sh` detects a parallel same-number bump but cannot block one, without strict branch protection

Two PRs that fork at the same version and both bump to the same number both pass against `origin/main`,
and GitHub re-runs the second only under "Require branches to be up to date before merging" or a merge
queue. The push-to-main run bases on `HEAD~1` so the second merge lands **red on main** instead of
shipping silently — detection, not prevention. Turning either setting on is a repository-settings
decision, not a file in this repo. Detail: `.ai/archive/2026-08-19-the-version-bump-check-gets-a-base-ref`.
