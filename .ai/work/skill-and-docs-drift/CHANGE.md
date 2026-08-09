---
created: 2026-08-02
---

# Five places where the loop's prose disagrees with what the bodies do

Bundled because they are all text in `skills/` or `docs/`: one `dw-solo` bump, one `pnpm eval:routing`
(the description edit shifts idf), one PR.

- `dw-land/SKILL.md:68-70` writes the decision-record bar as "or" where
  `references/decision-record.md:9` requires **all three** — and the loose reading is what a reader
  hits first.
- `dw-shape`'s `description` and `README.md:76` still promise one `CHANGE.md`, though the body now
  writes N for N shippable scopes. Run the evals, don't assume the idf shift is safe.
- `dw-ship/SKILL.md:51-52` offers the "you skipped `dw-check`" nudge only inside the PR path; the
  direct-push path reaches the irreversible step never mentioning a review. Fix in `dw-ship` — the
  closing pass is deliberately not a review pipeline (`dw-land:14-15`).
- `docs/SKILL-ANATOMY.md:44-45` cites `dw-check` for "free text **instead of** a mode" when it now
  does both — an undocumented fifth argument convention with no precedent to copy.
- `dw-ship:33` orders `dw-land` before shipping, which a task whose done-condition is "CI passes"
  cannot satisfy: workflows trigger only on `pull_request` or a push to `main`. Decide prose in
  `dw-ship`/`dw-land` or a `workflow_dispatch`.

Sources: `.ai/archive/shape-splits-changes`, `.ai/archive/pnpm-v11-migration`.
