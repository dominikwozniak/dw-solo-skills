---
change: dw-check-reads-the-diff-itself
branch: dw-check-reviews-first
created: 2026-09-11
status: building # shaping | building | landed | rejected
---

# Change — dw-check reads the diff itself, codex confirms on request

## Goal

`dw-check` reviews every diff in the main thread with its own prose, then offers `codex:rescue` a
second read in one line inside the stop it already makes. The outside pass runs only on a yes, or on
`codex` in the argument. `0012`'s delegate-by-default is superseded, the triviality floor keeps a
smaller job — whether to bother asking — and no model or effort is named anywhere in the repo.

## Decisions

- **The review stays cheap and stays ours.** Step 2 forbids `/code-review`, `/simplify`,
  `/security-review`, a subagent and any effort level by name. The bound is the existing
  five-finding filter, not a knob. The harness `code-review` skill reuses the last effort level
  typed, so a bare call can inherit `high` from an unrelated session — worth naming in the step.
- **No model is pinned.** The codex plugin passes `model: options.model ?? null` and its prose says
  to leave it unset, so `~/.codex/config.toml` decides. A model name in a shipped skill goes stale
  on a plan change or a rename.
- **A missing plugin loses its line.** Under `0012` it cost you the only review; now it costs an
  optional extra, so it is not a degradation. `dw-doctor` still names the install.
- Rejected: keeping `0012` and only swapping the configured model. The dependency was the problem,
  not the model — a gate whose only reader sits behind someone else's billing is one downgrade away
  from being worse than no gate.

## Tasks

- [x] 1. `skills/dw-check/SKILL.md` — description, argument-hint, `## What it reads`, and steps 2–4.
      proof: read the new steps against a real diff by hand; the body is unexercised until reinstall.
- [x] 2. The prose that cited the old behaviour — `CONTEXT.md` triviality floor, `README.md` row,
      `docs/agents/tooling.md` gotcha opener, `evals/cases/dw-check.json` note.
      proof: `pnpm validate:docs`, `pnpm eval:routing`.
- [x] 3. `docs/decisions/` — `0012` superseded in exactly two fields, `0027` written.
      proof: `pnpm validate:docs` (the 80-line ceiling).
- [x] 4. `skills/dw-doctor/` — the dead "dw-land's review offer on the PR" claim in `doctor.sh` and
      `SKILL.md`. proof: `bash scripts/tests/doctor.test.sh`.
- [x] 5. Version bumps — `dw-solo` 0.9.5, `dw-solo-setup` 0.4.7, both manifests.
      proof: `pnpm validate:manifests` and `pnpm validate:versions`.

## Anchors

- `skills/dw-check/SKILL.md:29` — step 2, the pass that now always runs
- `skills/dw-doctor/scripts/doctor.sh:101` — the warn string that named dw-land
- `docs/decisions/0012-bare-dw-check-delegates-by-default.md` — what 0027 supersedes

## Notes

- Sol and Terra both answered a live read-only `codex exec` on 2026-09-11, and the auth token still
  claims `plus`, so the tier change is not active yet. Nothing in this change depends on which model
  is configured — that is the point of it.
