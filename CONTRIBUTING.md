# Contributing

Thanks for poking at these skills. This file is the short pointer; the real detail lives where the
agent (and CI) already read it.

## The rules that matter

- **Edit the canonical file.** A skill lives at `skills/<name>/SKILL.md`. Never edit through a
  `plugins/<plugin>/skills/<name>` symlink — that path is a git-tracked symlink back to `skills/`.
- **Keep it thin.** Every skill here assumes **one reader**. Anything that only pays off with a second
  reader belongs in [`dw-skills`](https://github.com/dominikwozniak/dw-skills) instead.
- **Match the shape.** Every `SKILL.md` follows one anatomy — see
  [`docs/SKILL-ANATOMY.md`](docs/SKILL-ANATOMY.md). Copy an existing skill that resembles yours and
  keep the section order.
- **Follow the checklist.** The full add-a-skill + version-bump checklist (symlinks, manifests,
  README task-router) lives in [`AGENTS.md`](AGENTS.md) — `CLAUDE.md` is a symlink to it.

## Before you push

```bash
pnpm lint && pnpm format && pnpm validate:manifests && pnpm validate:artifacts && pnpm validate:docs
```

CI runs those five plus a secrets scan on every PR and push to `main`:

| Gate                      | What it checks                                                                             |
| ------------------------- | ------------------------------------------------------------------------------------------ |
| `pnpm lint`               | `agnix` validates `CLAUDE.md` / `SKILL.md` frontmatter, hooks, manifests                   |
| `pnpm format`             | `prettier --check` (`printWidth: 100`, `proseWrap: preserve`)                              |
| `pnpm validate:manifests` | `claude plugin validate`, marketplace↔plugin version sync, runtime symlinks                |
| `pnpm validate:artifacts` | the self-tests in `scripts/tests/`, then `docs/decisions/` against the record contract     |
| `pnpm validate:docs`      | README / `DESIGN.md` ↔ skills sync — dead links, undocumented skills, `⭑`, `Next:` targets |
| `trufflehog`              | secrets scan                                                                               |

The validators name the exact missing entry, so run them instead of re-deriving the checklist.

## Design rationale

The _why_ behind the conventions — persistence in the skill, tracked `.ai/` artifacts,
technology-agnostic procedures, composable-not-chained — is in [`docs/DESIGN.md`](docs/DESIGN.md).
