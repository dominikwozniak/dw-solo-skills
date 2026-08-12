---
change: block-env-heredoc-escape
branch: block-env-heredoc-escape
created: 2026-08-12
status: landed # shaping | building | landed
landed: 2026-08-12
---

# Change — `block-env-access.sh` stops blocking commit messages that name a dotenv file

## Goal

A heredoc commit message that mentions `.env` commits cleanly, while every real dotenv access stays
blocked. The hook drops heredoc bodies before tokenizing, so `git commit -F - <<'MSG' … .env … MSG`
exits 0 where it exits 2 today (re-measured 2026-08-12), and `cat > .env <<EOF` — where the path sits
on the opener line, not in the body — still exits 2. You know it worked when `pnpm validate:artifacts`
passes with the four new cases in `scripts/tests/block-env-access.test.sh`, and the `## Gotchas` entry
that tells you to route around the hook is gone.

## Decisions

- **Strip heredoc bodies wholesale; do not require a matching terminator.** A `<<` inside prose starts
  body mode and swallows the rest, so a contrived `"…<< …"` message followed by `cat .env` in one Bash
  call leaks. Accepted: the hook's own header scopes it as "a guardrail against accidental secret
  exposure — NOT a security boundary", and a terminator pre-scan needs lookahead this hook cannot buy
  cheaply on bash 3.2 (no `mapfile`).
- **The opener line is kept, only the body is dropped.** That is what preserves the blocking direction
  for `cat > .env <<EOF`, where the redirect target is a real path.
- **`tr '\n' ' '` at `:50` stays and its comment is corrected.** The fold is right for a multi-line
  `-m "…"`, where `sed` strips quotes per line; the comment reads as if it also covered heredocs, which
  is the misreading the backlog entry names. Line-based stripping must precede the fold.
- **The `dw-skills` twin is not a task here** — see Notes.

## Tasks

- [x] 1. **Drop heredoc bodies before tokenizing, and pin it.** Add the `strip_heredocs` pass to
      `templates/hooks/block-env-access.sh` (between the `COMMAND=` read and `STRIPPED=`), correct the
      `:44-47` comment, mirror the file byte-for-byte into `.claude/hooks/`, and extend
      `scripts/tests/block-env-access.test.sh` with two allowed cases (heredoc commit body, quoted and
      bare delimiter) and two blocked ones (`cat > .env <<EOF`; `cat .env` on a line after a closed
      heredoc). Bump `dw-solo-setup` 0.1.12 → 0.1.13 in `marketplace.json` **and**
      `plugins/dw-solo-setup/.claude-plugin/plugin.json` — the diff touches shipped payload.
- [x] 2. **Retire the workaround from `## Gotchas`.** Rewrite the `block-env-access.sh` entry in
      `AGENTS.md`: the `-F <path>` workaround is obsolete, what survives is that the hook still reads
      the whole Bash command and that a bare `<<` in prose now eats the lines below it. **Rewrite,
      never append** — the section is at 12/12 against `validate-artifacts.sh`'s cap.

## Anchors

- `templates/hooks/block-env-access.sh:44-54` — the fold-and-strip block the pass goes in front of, and
  the comment that misdescribes it.
- `scripts/tests/block-env-access.test.sh:72-81` — `prose-in-quotes`, `prose-multiline` and
  `multiline-cat-env` are the neighbours the four new cases copy; helper names and section headings are
  already there.
- `scripts/tests/hooks-in-sync.test.sh:38-43` — why the `.claude/hooks/` mirror is not optional.
- `scripts/validate-artifacts.sh:48` — `GOTCHAS_CAP=12`, currently exactly met.
- `AGENTS.md:283-286` — the entry task 2 rewrites.

## Notes

- **The prototype that sized this**, verified on GNU bash 3.2.57 — a `strip_heredocs` line loop that
  prints the opener and skips to a terminator matching `^[[:space:]]*$delim[[:space:]]*$`, with the
  opener recognised by `(^|[^<])<<-?[[:space:]]*["'\\]?([A-Za-z_][A-Za-z0-9_]*)`. The `[^<]` guard is
  what keeps here-strings out; the alphanumeric-only delimiter class is what makes interpolating
  `$delim` into the terminator regex safe.
- **The four new cases were measured against the pre-fix hook, not just the new one** — only
  `heredoc-commit-bare` moved (2 → 0); `heredoc-redirect-target` and `after-heredoc-cat-env` read 2
  before and after. Worth repeating if the pass is ever reworked: a blocked-case test that never
  failed on the old code pins nothing, and three of these four would have passed either way.
- **Verifying this hook from a session is awkward in a way that will recur.** Any Bash call carrying
  a bare `.env` token is refused by the **main tree's** copy of the hook before it runs, so probes
  must build the string (`D=$(printf ".%s" env)`) instead of writing it. That is also why the
  end-to-end check is a synthetic payload, never an actual heredoc commit here.
- **`strip_heredocs` had to be pinned to `return 0`** — the loop's status is its trailing `[[ ]]`
  test, so it returned 1 for any command not ending in an opener, making the pipeline non-zero under
  `pipefail`. Harmless while the file has no `set -e`, and the tests never saw it; caught in the land
  verdict. The general shape: a function whose last statement is a bare conditional leaks that
  conditional as its exit status.
- **The same fix is owed in `dw-skills`** — `templates/hooks/block-env-access.sh` and
  `scripts/tests/block-env-access.test.sh` at
  `/Users/dominik.wozniak/workspace/private/byarcadia-packages/dominikwozniak-skills` are byte-identical
  to this repo's copies (verified 2026-08-12), and nothing across the repo boundary detects the drift.
  Not a task here: a commit in another repo cannot land with this one. Take the hunk across by hand
  after merge.
- **The rewritten gotcha trades one trap for a smaller one rather than deleting an entry.** The
  `-F <path>` workaround is gone, but the unconditional strip is itself a trap worth writing down,
  and the "a bare token blocks any command" half was always the more general fact. Count held at
  12/12 — the cap forces this shape, and here it produced a better entry than an append would have.
- **Ordering against `setup-lives-in-tracked-agents-md`** — that change also edits `templates/hooks/`
  (different files: `lint-on-edit.sh`, `typecheck-on-stop.sh`) and also bumps `dw-solo-setup`. Whichever
  lands second re-checks the version: 0.1.13 may already be taken.
- **Ordering against `own-root-under-budget-and-router`** — that change moves the whole `## Gotchas`
  section out of `AGENTS.md` into routed topic files. If it lands first, task 2 edits the entry wherever
  it now lives, and the cap in `validate-artifacts.sh` may be gone entirely.
