---
change: drop-the-dead-dw-skills-sync-obligation
branch: drop-the-dead-dw-skills-sync-obligation
created: 2026-08-20
status: landed # shaping | building | landed
landed: 2026-08-20
pr: ""
---

# Change — remove every live reference to dw-skills

## Goal

`dw-skills` is unmaintained — recorded in `.ai/archive/dot-guardrails-swallow-dotfile-paths/CHANGE.md:32`
— yet the docs still send readers there and still demand every hook fix be applied twice. Both are
dead. Known when: `grep -rn "dw-skills"` returns hits only under `.ai/archive/` and
`docs/decisions/0001-*`, and every gate stays green.

## Decisions

- **Remove, don't rephrase** — the user's call: nothing live points at that repo, including the README's
  "Why two repos" section and the pointers in `AGENTS.md`, `README.md` and `CONTEXT.md`.
- **`docs/decisions/0001-*` and `.ai/archive/` are kept** — a decision record and the change history are
  the record of settled choices; deleting them erases why this repo exists rather than closing a duty.
- **One commit, not four** — six files of prose and comments answering to one goal, one version bump,
  one gate run.
- **The `Vendored` / `Fork` glossary terms go with it** — both were defined by the relationship to that
  repo. This also settles the term collision `.ai/archive/the-doc-layer-says-one-thing-once/CHANGE.md:183`
  parked: "vendored" now means only a consumer repo's copy of a shipped template.

## Tasks

- [x] 1. Strip every live reference in one commit: `README.md` (the thin-lane pointer and the whole
      `## ◈ Why two repos` section), `AGENTS.md:10-11`, `CONTEXT.md` (`Lane`, `Vendored`, `Fork`),
      `docs/agents/README.md:14`, `docs/agents/skills-and-plugins.md:32-56`,
      `scripts/validate-manifests.sh:157-158`, `skills/dw-init/SKILL.md:49-50`, and
      `templates/hooks/credential-leak-guard.sh:65` with its byte-identical `.claude/hooks/` twin
      (`scripts/tests/hooks-in-sync.test.sh` already stripped on disk, uncommitted). Bump
      `dw-solo-setup` 0.1.26 → 0.1.27 in both manifests and re-record the skill-corpus baseline.

## Anchors

- `.ai/archive/dot-guardrails-swallow-dotfile-paths/CHANGE.md:32` — where "no longer maintained" was
  decided; this is the sweep that decision never got.
- `scripts/tests/hooks-in-sync.test.sh:1-9` — the invariant that stays, now scoped to this repo alone.
- `docs/decisions/0001-separate-repo-from-dw-skills.md` — kept; the only remaining live account.
- `plugins/dw-solo-setup/.claude-plugin/plugin.json` + `.claude-plugin/marketplace.json` — the pair
  `validate-versions.sh` compares; `templates/` and `skills/dw-init/` are both its payload.

## Notes

- Blob hashes confirm the divergence: all five shared templates differ from the `dw-skills` copies, and
  its `block-non-pnpm.sh` still carries the one-`sudo` bug fixed here. "byte-identical today" was false.
- `validate-docs.sh` syncs README's _skill list_, not this prose — no constraint here.
