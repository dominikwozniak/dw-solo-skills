---
created: 2026-08-22
source: date-prefix-the-solo-lane-slugs
---

# This repo has no `.ai/README.md`, though `dw-init` seeds one in every consumer repo

`dw-init/SKILL.md:99-101` creates `.ai/` with a README from `templates/work-README.md`, and that
template's own prose assumes it exists — but the catalog repo never got one. Either seed it, or say
in the templates that the authoring repo is exempt.
