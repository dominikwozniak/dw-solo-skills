---
created: 2026-08-13
source: setup-lives-in-tracked-agents-md
---

# Retire `link-local-memory`, the hook with no subject left

Blocked on `own-root-under-budget-and-router`: until it moves the `**Lint command**` bullets into
`AGENTS.md`, the legacy file is the only thing answering the hooks in this repo. Then ~182 lines and
one carry class go — the hook (two copies), `worktree.sh`'s `link_local_memory()` and its
`worktree.test.sh` group, plus the `.claude/settings.json` wiring, `dw-init`'s legacy-only offer
clause and `dw-start`'s sentence; needs a `dw-solo-setup` bump. It is already incoherent: `dw-init`
**moves** a found `CLAUDE.local.md`, so the condition that offers the hook is the one the same run
eliminates. **Keep** the `AGENTS.md`-first fallback in the two command hooks regardless — one string
per `for` loop, and it is what keeps them byte-identical with the `dw-skills` copies that still read
the legacy file. Reasoning: `.ai/archive/setup-lives-in-tracked-agents-md/`.
