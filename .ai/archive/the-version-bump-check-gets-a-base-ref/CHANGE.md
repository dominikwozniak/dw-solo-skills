---
change: the-version-bump-check-gets-a-base-ref
branch: the-version-bump-check-gets-a-base-ref
created: 2026-08-19
status: landed # shaping | building | landed
landed: 2026-08-19
---

# Change — the version-bump check gets a base ref, so a bump that didn't happen fails CI

## Goal

`validate-manifests.sh` compares `marketplace.json` and `plugin.json` in one tree, so it cannot see a
version that didn't move. A new `scripts/validate-versions.sh` diffs against a base ref and fails when a
plugin's shipped surface changed without a strictly higher version. Known when: a scratch branch that
touches `skills/dw-shape/SKILL.md` without bumping `dw-solo` fails, and one that takes the number `main`
already holds fails too.

## Decisions

- **A new script, not a pass inside `validate-manifests.sh`** — that validator is pure-disk and stays
  history-free; its workflow's `paths:` filter is `**/*.json` only and would have to widen anyway.
- **Changed paths from the merge base, versions from the base tip** — merge-base alone misses the
  parallel-bump failure, because a branch that went 0.4.5→0.4.6 did grow relative to where it forked.
- **Strictly greater, no escape hatch** — a patch bump is one line; a `[no-bump]` marker is a second
  thing to get wrong and nothing can verify it.
- **The plugin→paths map is derived from the symlink graph**, never hardcoded — same rule as
  `validate-manifests.sh:35-37`, so adding a plugin stays a manifest entry plus symlinks.
- **A missing base ref is a SKIP, exit 0** — the validator never touches the network; CI fetches, the
  local gate uses whatever `origin/main` it has.
- **It gets a self-test**, against the precedent that this repo doesn't test its own CI validators. That
  held for disk checks; this is git plumbing over two refs, and `717f1e5` is the standing proof a
  validator passes silently while broken.
- **Both `paths:`-filter gaps ride along** — same failure mode (green while broken), a few lines each,
  cheaper to fix than to park.

## Tasks

- [x] 1. `scripts/validate-versions.sh` (755): `--base <ref>` defaulting to `origin/main`, unresolvable →
      SKIP exit 0; `PLUGIN_DIRS` from `marketplace.json`; per-plugin shipped surface read off the symlink
      graph (`plugins/<p>/**`, each linked `skills/<name>/`, each linked `scripts/runtime/<s>.sh`,
      `templates/` where the link exists — never `.claude-plugin/marketplace.json`, which is where the bump
      lands); `version_gt` as a pure-bash `IFS=.` compare, not `sort -V`; `::error::` naming the plugin,
      both versions and one changed path.
- [x] 2. `scripts/tests/validate-versions.test.sh` (755) — a fixture marketplace in a throwaway repo:
      bumped → pass, unbumped → fail, number already taken on `main` → fail, non-payload change → pass,
      plugin A's skill leaves B unflagged, no base ref → SKIP.
- [x] 3. Wiring: `validate:versions` in `package.json`, and `.github/workflows/validate-versions.yaml`
      with `fetch-depth: 0`, an explicit `git fetch origin`, and **no `paths:` filter** — the check's
      subject is which paths changed, so a filter would be the same blind spot one level up.
- [x] 4. Docs: rewrite the now-false gotcha at `docs/agents/skills-and-plugins.md:139-143` and the clause
      at line 91, and point `docs/agents/git-history.md:25` at the check. `AGENTS.md` needs no edit.
- [x] 5. The two filters that never fire: `validate-plugin-manifests.yaml` gains the symlink-layout paths
      its validator actually reads, `validate-artifacts.yaml` gains `.ai/backlog/**` for pass 2's cap.

## Anchors

- `scripts/validate-manifests.sh:25-33` — the equal-versions check this extends, and `:37` the
  never-hardcode-a-plugin idiom to reuse.
- `scripts/validate-artifacts.sh:47` — the `*.test.sh` glob that auto-discovers task 2's file.
- `scripts/tests/worktree.test.sh:20-38` — the throwaway-repo fixture shape (`mktemp -d`, `trap`,
  `pwd -P` for macOS, `git init -q -b main`).
- `scripts/tests/hooks-in-sync.test.sh` — the `note_pass`/`note_fail`/tally output shape.
- `.github/workflows/validate-plugin-manifests.yaml` — the workflow to model, minus the Claude CLI step.
- `docs/agents/skills-and-plugins.md:91,139-143` — the two claims that become false when this lands.

## Notes

No plugin version bump: this change touches only repo CI tooling, nothing under `templates/`,
`scripts/runtime/` or `skills/`. So the new check no-ops on its own PR — task 2's fixture and the scratch-
branch probe are what prove it works.

- The scratch-branch probe on the real repo confirmed failure 2 both directions (unbumped `dw-solo` →
  error naming `skills/dw-shape/SKILL.md`; bumped → OK). Failure 1 needs a base tip that already holds
  the number, which is fixture work — task 2 owns it, not a second real-repo probe.
- `block-dangerous-commands` refuses `git reset --hard`, so undoing a probe commit is mixed reset plus
  `git restore` by name.
- 13 cases, and the suite was mutation-checked: swapping the version lookup to `$MERGE_BASE` breaks
  exactly `number-already-taken-on-main-fails` and nothing else, so that one case carries the asymmetry.
- The fixture asserts ownership on the `OK  beta …` line, not the exit code — the run fails overall for
  alpha, so exit status cannot tell the two plugins apart.
- `AGENTS.md` is at **119/120 lines**, 7336/10240 B — one line of headroom, so task 4's prose has to
  stay in `docs/agents/`.
- The repo's workflow idiom comments the `pull_request` `paths:` block only and repeats the push list
  bare; task 5's first draft duplicated the comment into both.
- **Known and deliberately unfixed:** `git diff --name-only` C-quotes a path containing a newline, so
  the token starts with `"`, matches no surface, and that payload edit passes unbumped. No shipped
  filename has whitespace; the fix is `-z` plus a null-delimited read. Reviewed, declined, not lost.
