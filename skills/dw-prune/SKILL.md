---
name: dw-prune
description: >-
  Walk `.ai/backlog/` and decide every entry out loud: drop what is stale or already done, do what is
  cheap and unblocked, bundle what ships with a cousin, leave the rest. One pass, no shaping.
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
- **Cheap and unblocked** — the absorption bar, applied late. Do the work now and `git rm` the entry
  in the same commit, the fix and the deletion together. Where an open change is **checked out in this
  tree**, that commit belongs to it; otherwise it is a commit here. Never reach into a change living in
  another worktree — you cannot commit there, and this pass only ever commits in the tree it runs in.
- **Bundled** — an entry that would ship with a cousin (same version bump, same gate run, one PR)
  merges into it. Rewrite the survivor to cover both, `git rm` the other.
- **Stays** — real work whose moment hasn't come. Say so, write nothing. On a healthy folder most
  entries end here, and that is the right answer.

**Never decide a batch.** An entry waved through with the others survived by not being read, which is
the failure this skill exists to reverse.

### 3. Commit, then report

Commit the way `dw-git` does, staged by name, and let its one-logical-change rule cut the pass rather
than forcing everything into one commit:

- **The sweep is one commit** — every stale deletion and bundle rewrite together, since walking the
  folder was the single act that produced them.
- **Each fix is its own**, carrying the entry it just closed. The work and the `git rm` that follows
  from it are one change; a code fix riding along in a backlog sweep is the "spans concerns" case
  `dw-git` names.

Then report the count each way and what is left.

**Next:** `dw-shape` — what survives the prune is what it reads.
