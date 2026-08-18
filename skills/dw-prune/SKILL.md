---
name: dw-prune
description: >-
  Walk `.ai/backlog/` and decide every entry out loud: drop what is stale or already done, do what is
  cheap and unblocked, bundle what ships with a cousin, leave the rest. One commit, no shaping.
  Explicit-invoke only — you are the one who can see the queue has stopped being one.
disable-model-invocation: true
---

# dw-prune — the queue stops being a record of everything you once considered

A backlog grows by append, and nothing else in the loop reads it end to end — so a stale entry
outlives what it described and the folder becomes a list you skim. This walks it once, deliberately.

## What it reads and writes

Every `.ai/backlog/*.md` except `README.md`, the folder's own contract rather than a queued idea. It
writes deletions, a rewrite of any entry it bundles into, and the fix itself where one is cheap enough
to close here. `.ai/` is tracked in git. It **shapes nothing**: an entry that is real work stays for
`dw-shape`.

## Workflow

### 1. Read the folder's own bars first

`.ai/backlog/README.md` states them — **will you ever?** and **should it have been done now?** — with
the entry shape and, where the repo caps the list, what a full one costs. Judge against those, not
against taste.

### 2. One pass, four outcomes, every entry gets one out loud

Oldest first, because age is the only signal the folder records:

- **Stale or already done** — the code moved on, another change closed it, the tool is gone. `git rm`
  it, reason in the commit message. A queue you never delete from is a record.
- **Cheap and unblocked** — the absorption bar, applied late. Do it now: a commit in the open change
  if there is one, else a commit here, and the entry goes in the same one.
- **Bundled** — an entry that would ship with a cousin (same version bump, same gate run, one PR)
  merges into it. Rewrite the survivor to cover both, `git rm` the other.
- **Stays** — real work whose moment hasn't come. Say so, write nothing. On a healthy folder most
  entries end here, and that is the right answer.

**Never decide a batch.** An entry waved through with the others survived by not being read, which is
the failure this skill exists to reverse.

### 3. One commit, then report

Commit the pass the way `dw-git` does, staged by name — deletions, bundles and any fix together, since
walking the folder was one act. Report the count each way and what is left.

**Next:** `dw-shape` — what survives the prune is what it reads.
