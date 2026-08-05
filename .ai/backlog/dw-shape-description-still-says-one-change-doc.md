---
created: 2026-08-05
source: shape-splits-changes
---

# `dw-shape`'s description and README row still promise one `CHANGE.md`

The body now writes N when a request carries N shippable scopes, but the `description` ("into one
durable `CHANGE.md`") and `README.md:76` ("one goal + decisions + task checklist") were left as-is
for fear of shifting idf and knocking a skill off rank-1. That fear is cheap to test: the same edit
on `dw-check` came back at exactly the documented baseline. Run `pnpm eval:routing`, don't assume.
