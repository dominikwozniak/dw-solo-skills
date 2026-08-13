---
created: 2026-08-01
---

# Retire `link-local-memory.sh`, and self-test `block-non-pnpm.sh` — one change, because retiring beats testing

Two items that must be decided together: writing self-tests for a hook that is about to be deleted
is the wasted half. Once `CLAUDE.local.md` is gone from this repo, `link-local-memory` is subjectless
here — the hook (two copies, ~90 lines), `worktree.sh`'s `link_local_memory()` (32) and its
`worktree.test.sh` group (60) come out, plus the `.claude/settings.json` wire, `dw-init`'s
legacy-only offer clause and `dw-start`'s sentence. It is already incoherent: `dw-init` **moves** a
found `CLAUDE.local.md`, so the run that offers the hook is the run that eliminates its subject.

- Keep the `AGENTS.md`-first **fallback** in `lint-on-edit` and `typecheck-on-stop` regardless — one
  string per `for` loop, and it is what keeps them byte-identical with the `dw-skills` copies that
  still read the legacy file.
- `block-non-pnpm.sh` is still untested and nothing else is going to touch it.

Edits shipped payload, so it needs the plugin version bump.
Reasoning: `.ai/archive/own-root-under-budget-and-router/`.
