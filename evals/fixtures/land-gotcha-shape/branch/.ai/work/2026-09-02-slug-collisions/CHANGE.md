---
change: slug-collisions
branch: slug-collisions
created: 2026-09-02
status: building
---

# Change — a slug collision gets the first free numeric suffix

## Goal

`slugify("Hello World", new Set(["hello-world"]))` returns `hello-world-2`, and where that is taken
too it returns `hello-world-3`. A title with no collision is unchanged. `pnpm test` covers all three.

## Decisions

- The caller passes the taken set — `slug.js` stays pure and does no lookup of its own.
- The first free number wins rather than the count of collisions, so a deleted slug is reused.

## Tasks

<!-- Convention: `- [ ]` pending, `- [x]` done — `dw-next` flips the box in the task's own commit.
A task that stopped being necessary keeps its box and gains `**skip:** <reason>`; every later
invocation reads that as not remaining. Never rename a task title. -->

- [x] 1. `slugify` takes a `taken` set and returns the base slug when it is free.
- [x] 2. A collision gets the first free `-<n>` suffix, with tests for both branches.

## Anchors

- `slug.js:3` — `slugify`, the only export.
- `slug.test.js` — the two existing cases the new ones sit beside.

## Notes

- **2026-09-02 — the docs gate went green over a suite that ran nothing.** While adding the two new
  cases I renamed `slug.test.js` to `slug.spec.js` for about ten minutes, because that is the
  convention I am used to from the last project, and `pnpm test` kept printing a green summary the
  whole time. It took a second pair of eyes to notice the summary said `pass 0`. What happens is that
  `pnpm test` is `node --test` with no path argument, so the runner discovers its own files by
  pattern — `*.test.js`, `*_test.js`, and a few others — and a file called `slug.spec.js` matches
  none of them. Having found zero test files it does not treat that as an error: it prints a report
  with every counter at zero and exits 0. I checked this on Node 24 in an empty directory to be sure
  it was not something about our setup, and it is not, it is the documented behaviour. So the entire
  suite can be renamed out of existence and both `pnpm test` locally and CI will report success,
  which is the worst possible failure mode because it looks exactly like the thing you want to see.
  We should probably assert a minimum test count somewhere, or pass an explicit path so the runner
  fails when the path does not exist. For now the thing to remember is that a green `node --test`
  means nothing on its own unless you have also looked at the number next to `pass`.
