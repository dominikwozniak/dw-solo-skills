#!/usr/bin/env bash
# dw-doctor — read-only environment diagnostic for a solo-lane repo.
#
# Checks whether the tools this lane assumes are present and whether its
# hooks/skills will actually work, then prints one line per check
# (OK / WARN / FAIL) with a fix hint. It diagnoses the CURRENT git repo
# (resolved from cwd), not the skill's own location.
#
# READ-ONLY: it never installs anything and never edits a file. It only runs
# `command -v` and `--version` probes and reads files. Exits 0 always — the
# report text carries the verdict.
#
# Stack checks are conditional on what the repo declares (package.json /
# tsconfig.json / AGENTS.md), mirroring how the hooks resolve their commands —
# so nothing about a stack is hardcoded. Where it reads AGENTS.md it falls back
# to a legacy CLAUDE.local.md in the same order the hooks do, so a repo
# scaffolded before agent memory moved still reports accurately.
set -uo pipefail

# --- output helpers (color only on a TTY) ------------------------------------
if [ -t 1 ]; then
  C_OK=$'\033[32m'; C_WARN=$'\033[33m'; C_FAIL=$'\033[31m'; C_DIM=$'\033[2m'; C_RST=$'\033[0m'
else
  C_OK=; C_WARN=; C_FAIL=; C_DIM=; C_RST=
fi

OK=0; WARN=0; FAIL=0

report() {
  # report <ok|warn|fail|info> <label> [message]
  local level="$1" label="$2" msg="${3:-}"
  case "$level" in
    ok)   OK=$((OK + 1));     printf '  %s[ OK ]%s %-22s %s\n' "$C_OK"   "$C_RST" "$label" "$msg" ;;
    warn) WARN=$((WARN + 1)); printf '  %s[WARN]%s %-22s %s\n' "$C_WARN" "$C_RST" "$label" "$msg" ;;
    fail) FAIL=$((FAIL + 1)); printf '  %s[FAIL]%s %-22s %s\n' "$C_FAIL" "$C_RST" "$label" "$msg" ;;
    info) printf '  %s%-28s %s%s\n' "$C_DIM" "$label" "$msg" "$C_RST" ;;
  esac
}

group() { printf '\n%s%s%s\n' "$C_DIM" "$1" "$C_RST"; }

have() { command -v "$1" >/dev/null 2>&1; }

# ver_ge MIN CUR → true when CUR >= MIN (version-sorted; MIN sorts first or ties).
ver_ge() { [ "$(printf '%s\n%s\n' "$1" "$2" | sort -V | head -n1)" = "$1" ]; }

# --- locate the target repo ---------------------------------------------------
ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"

printf '%sdw-doctor%s — read-only environment diagnostic\n' "$C_DIM" "$C_RST"
printf '%srepo: %s%s\n' "$C_DIM" "$ROOT" "$C_RST"

# --- core tools ---------------------------------------------------------------
group "Core tools"
if have git; then
  report ok "git" "$(git --version 2>/dev/null | head -n1)"
else
  report fail "git" "missing — install: xcode-select --install (or brew install git)"
fi
if have jq; then
  report ok "jq" "$(jq --version 2>/dev/null)"
else
  report fail "jq" "MISSING — every .claude/hooks/*.sh silently no-ops without it. Install: brew install jq"
fi

# --- optional tools -----------------------------------------------------------
group "Optional tools"
if have gh; then
  report ok "gh" "$(gh --version 2>/dev/null | head -n1)"
else
  report warn "gh" "absent — dw-git PRs and dw-ship merges need it. Install: brew install gh"
fi
# Codex is the only companion the skills route to by name — dw-check delegates an outside review to
# it, dw-ship reaches for it on a stuck merge. WARN tier and never FAIL: the whole loop works without
# it, only those two routes degrade. Depth stops at "installed": probing auth would mean a network
# call from a read-only diagnostic, and a logged-out codex is the user's business, not this script's.
codex_plugin=""
# ${HOME:-} — this script runs under `set -u`, and a bare $HOME with HOME unset aborts it outright,
# taking every check below down with it. Rare, but a diagnostic that dies is worse than one that
# reports a gap.
for d in "${HOME:-/nonexistent}"/.claude/plugins/cache/*codex*; do
  [ -d "$d" ] && codex_plugin="$d" && break
done
if have codex && [ -n "$codex_plugin" ]; then
  report ok "codex" "on PATH, plugin at ${codex_plugin#"$HOME"/}"
elif have codex; then
  report warn "codex" "on PATH but no codex plugin installed — dw-check's /codex: routes won't resolve; fix: /codex:setup"
elif [ -n "$codex_plugin" ]; then
  report warn "codex" "plugin installed but the codex CLI is not on PATH; fix: /codex:setup"
else
  report warn "codex" "absent — dw-check's outside reviewer and dw-ship's rescue route need it; fix: /codex:setup"
fi

# --- JavaScript / TypeScript (only if package.json) ---------------------------
pkg="$ROOT/package.json"
group "JavaScript / TypeScript"
if [ ! -f "$pkg" ]; then
  report info "—" "no package.json — JS/TS checks skipped"
elif have jq && ! jq empty "$pkg" 2>/dev/null; then
  report fail "package.json" "present but not valid JSON"
else
  # node vs the version the repo declares. devEngines.runtime first, then engines.node — the same
  # precedence the pnpm block below applies to devEngines.packageManager, and for the same reason:
  # pnpm 11 reads the devEngines entry, downloads that runtime and runs every script under it, so a
  # repo migrated to it may carry the exact version there and only a floor in engines.
  ndver=""; ndsrc=""
  if have jq; then
    if [ "$(jq -r '.devEngines.runtime.name // empty' "$pkg" 2>/dev/null)" = "node" ]; then
      ndver="$(jq -r '.devEngines.runtime.version // empty' "$pkg" 2>/dev/null)"
      [ -n "$ndver" ] && ndsrc="devEngines"
    fi
    if [ -z "$ndver" ]; then
      ndver="$(jq -r '.engines.node // empty' "$pkg" 2>/dev/null)"
      [ -n "$ndver" ] && ndsrc="engines"
    fi
  fi
  # Whatever the source, the comparison is a FLOOR, never an equality — and that is the one place
  # this block deliberately parts from the pnpm block it otherwise mirrors. An exact
  # devEngines.runtime pin IS in effect for everything pnpm runs, whatever `node` on PATH says, since
  # pnpm downloads it; the pin can only be *missed* by a bare `node` older than it. Demanding equality
  # would warn forever on a machine one patch release ahead, which is the normal case, not a fault.
  ndmin="$(printf '%s' "$ndver" | grep -oE '[0-9]+(\.[0-9]+)*' | head -n1)"
  if have node; then
    # Probed from `/`, and for the same reason as pnpm below. A `node` on PATH may be a version-proxy
    # shim (pnpm's own, or a `vp`-style one): run inside the repo it resolves the repo's declaration,
    # downloads a runtime to satisfy it and answers as THAT version — so the check would compare the
    # declaration against itself, and a declaration nothing can satisfy makes it answer nothing at all.
    # Measured: `node -v` in a fixture declaring `>=99.0.0` prints a resolve failure and exits 1.
    cur="$( (cd / && node -v) 2>/dev/null | sed 's/^v//')"
    if [ -z "$cur" ]; then
      report warn "node" "on PATH but does not run — check: cd / && node -v"
    elif [ -z "$ndmin" ]; then
      report ok "node" "$cur"
    elif ! ver_ge "$ndmin" "$cur"; then
      report warn "node" "$cur < $ndsrc $ndver — upgrade (see .nvmrc, or brew install node)"
    elif [ "$cur" = "$ndmin" ] || [ "$ndsrc" = "engines" ]; then
      report ok "node" "$cur ($ndsrc: $ndver)"
    else
      # Ahead of an exact pin: fine, and worth spelling out — pnpm-run scripts get $ndver, a bare
      # `node` gets this one, and someone reading two different versions deserves to know why.
      report ok "node" "$cur on PATH ($ndsrc pins $ndver, which pnpm downloads for its own scripts)"
    fi
  else
    report fail "node" "missing — install via nvm (.nvmrc) or brew install node"
  fi

  # pnpm vs the version the repo pins. devEngines.packageManager first — pnpm 11 reads it and
  # gives it priority over packageManager, and a repo migrated to v11 may carry only that one.
  # No corepack anywhere: pnpm self-manages through devEngines' own onFail, and corepack is
  # unbundled from Node 25.
  pmver=""; pmsrc=""; cur_pnpm=""
  if have jq; then
    if [ "$(jq -r '.devEngines.packageManager.name // empty' "$pkg" 2>/dev/null)" = "pnpm" ]; then
      pmver="$(jq -r '.devEngines.packageManager.version // empty' "$pkg" 2>/dev/null)"
      [ -n "$pmver" ] && pmsrc="devEngines"
    fi
    if [ -z "$pmver" ]; then
      pm="$(jq -r '.packageManager // empty' "$pkg" 2>/dev/null)"
      case "$pm" in pnpm@*) pmver="${pm##*@}"; pmver="${pmver%%+*}"; pmsrc="packageManager" ;; esac
    fi
  fi
  if [ -f "$ROOT/pnpm-lock.yaml" ] || [ -n "$pmver" ]; then
    if have pnpm; then
      # Probed from OUTSIDE the repo, and both halves of that matter. Run with the repo as cwd,
      # `pnpm -v` obeys devEngines.packageManager: it downloads the pinned pnpm and REWRITES
      # pnpm-lock.yaml (packageManagerDependencies, packages:, snapshots:) — breaking this script's
      # headline promise never to edit a file — and then answers with the pinned version, so the
      # comparison below could only ever tie and the "pin is not in effect" warning could never fire.
      # From `/` there is no package.json above it, so the answer is the PATH pnpm this check is about.
      cur_pnpm="$( (cd / && pnpm -v) 2>/dev/null )"
      if [ -z "$cur_pnpm" ]; then
        # Empty from `/` no longer means "this repo rejects it" — no package.json applies there, so
        # nothing repo-local can be the cause. It means the binary on PATH cannot run at all: a
        # half-finished install, a broken shim, a node it can't find.
        report warn "pnpm" "on PATH but does not run — check: cd / && pnpm -v"
      else
        case "$pmver" in
          # No pin to check against.
          "") report ok "pnpm" "$cur_pnpm" ;;
          # A range (devEngines allows ">=11.0.0 <12.0.0") is not comparable by string.
          *[!0-9.]*) report ok "pnpm" "$cur_pnpm ($pmsrc wants $pmver)" ;;
          *)
            if [ "$cur_pnpm" = "$pmver" ]; then
              report ok "pnpm" "$cur_pnpm ($pmsrc pins $pmver)"
            else
              report warn "pnpm" "$cur_pnpm, but $pmsrc pins $pmver — the pin is not in effect. Upgrade the pnpm on PATH: brew upgrade pnpm"
            fi
            ;;
        esac
      fi
    else
      report fail "pnpm" "missing — hooks enforce pnpm. Install: brew install pnpm"
    fi

    # Two things pnpm 11 does in silence, each worth its own line. Only checked when v11 is
    # actually in play — on v10 a `pnpm` block is correct and the old lockfile is current.
    v11=0
    case "${cur_pnpm%%.*}" in ''|*[!0-9]*) ;; *) [ "${cur_pnpm%%.*}" -ge 11 ] && v11=1 ;; esac
    case "${pmver%%.*}" in ''|*[!0-9]*) ;; *) [ "${pmver%%.*}" -ge 11 ] && v11=1 ;; esac
    if [ "$v11" -eq 1 ]; then
      # v11 reads none of `package.json#pnpm`, and warns only about the keys on its own
      # relocation list — anything else it drops without a word. So flag the block's existence.
      if have jq && jq -e 'has("pnpm")' "$pkg" >/dev/null 2>&1; then
        report warn "pnpm settings" "package.json#pnpm is present but pnpm 11 reads none of it, and names only the keys it recognises — move them to pnpm-workspace.yaml"
      fi
      # `lockfileVersion` is NOT the tell: v11 still writes '9.0'. Its own marks are the leading
      # document separator and the two per-importer keys it added.
      lock="$ROOT/pnpm-lock.yaml"
      if [ -f "$lock" ] &&
        ! head -n1 "$lock" | grep -q '^---[[:space:]]*$' &&
        ! grep -q '^[[:space:]]*\(configDependencies\|packageManagerDependencies\):' "$lock"; then
        report warn "pnpm-lock.yaml" "written before pnpm 11 (lockfileVersion still reads '9.0', so it is not the tell) — run: pnpm install"
      fi
    fi
  fi

  # declared deps actually installed
  if have jq; then
    ndeps="$(jq -r '((.dependencies // {}) + (.devDependencies // {})) | length' "$pkg" 2>/dev/null || echo 0)"
    if [ "${ndeps:-0}" -gt 0 ] && [ ! -d "$ROOT/node_modules" ]; then
      report warn "node_modules" "absent but deps declared — run: pnpm install"
    else
      for t in agnix prettier; do
        if jq -e --arg t "$t" '(.devDependencies // {})[$t] // (.dependencies // {})[$t]' "$pkg" >/dev/null 2>&1; then
          if [ -x "$ROOT/node_modules/.bin/$t" ]; then
            report ok "$t" "installed"
          else
            report warn "$t" "declared but not in node_modules — run: pnpm install"
          fi
        fi
      done
    fi
  fi

  # tsc — only if the repo asks for typechecking
  has_ts=0
  [ -f "$ROOT/tsconfig.json" ] && has_ts=1
  if have jq && jq -e '.scripts.typecheck' "$pkg" >/dev/null 2>&1; then has_ts=1; fi
  if [ "$has_ts" -eq 1 ]; then
    if [ -x "$ROOT/node_modules/.bin/tsc" ] || { have jq && jq -e '(.devDependencies // {}).typescript // (.dependencies // {}).typescript' "$pkg" >/dev/null 2>&1; }; then
      report ok "tsc" "typescript available"
    else
      report warn "tsc" "tsconfig/typecheck present but no typescript dep — run: pnpm install (or add typescript)"
    fi
  fi
fi

# --- repo structure -----------------------------------------------------------
group "Structure"
settings="$ROOT/.claude/settings.json"
if [ -f "$settings" ]; then
  if have jq && ! jq empty "$settings" 2>/dev/null; then
    report fail ".claude/settings.json" "invalid JSON"
  else
    report ok ".claude/settings.json" "present"
    if have jq; then
      found_hook=0
      while IFS= read -r cmd; do
        [ -z "$cmd" ] && continue
        script_path="$(printf '%s' "$cmd" | grep -oE '[^" ]*\.sh' | head -n1)"
        [ -z "$script_path" ] && continue
        found_hook=1
        script_path="${script_path//\$\{CLAUDE_PROJECT_DIR\}/$ROOT}"
        script_path="${script_path//\$CLAUDE_PROJECT_DIR/$ROOT}"
        case "$script_path" in /*) ;; *) script_path="$ROOT/$script_path" ;; esac
        rel="${script_path#"$ROOT"/}"
        if [ ! -f "$script_path" ]; then
          report fail "hook script" "missing: $rel — that guardrail won't run"
        elif [ ! -x "$script_path" ]; then
          report fail "hook script" "not executable: $rel — fix: chmod +x"
        else
          report ok "hook script" "$rel"
        fi
      done < <(jq -r '.hooks // {} | to_entries[] | .value[]? | .hooks[]? | .command // empty' "$settings" 2>/dev/null)
      [ "$found_hook" -eq 0 ] && report info "hooks" "none wired in settings.json"
    else
      report warn ".claude/hooks" "skipped (needs jq to parse settings.json)"
    fi
  fi
else
  report warn ".claude/settings.json" "absent — no hooks/guardrails in this repo"
fi

# This plugin serves the solo lane (.ai/work/). A repo carrying .ai/runs/ runs the
# team lane from the other marketplace — flag it instead of half-checking its shape.
SOLO=0
if [ -d "$ROOT/.ai/runs" ]; then
  report warn "lane" ".ai/runs/ found — this repo runs the team lane; the solo plugin is the wrong one here"
fi
if [ -d "$ROOT/.ai/work" ]; then
  report ok ".ai/work/" "present (dw-shape / dw-next / dw-land)"
  SOLO=1
elif [ ! -d "$ROOT/.ai/runs" ]; then
  report warn ".ai/work/" "absent — not scaffolded for the solo loop yet; fix: dw-init"
fi

# The promotion targets dw-land writes into; their absence breaks the closing step.
if [ "$SOLO" -eq 1 ]; then
  if [ -d "$ROOT/docs/decisions" ]; then
    # Presence only. The records carry a contract — the filename number is the identity and
    # superseded-by: is a pointer made of it — and this used to run check-decisions.sh over them.
    # That script was 489 lines of enforcement, deleted along with this call: a folder one person
    # writes to does not need a parser to catch a malformed record they just wrote.
    report ok "docs/decisions/" "present"
  else
    report warn "docs/decisions/" "absent — dw-land promotes decision records here; fix: dw-init"
  fi
  if [ -f "$ROOT/CONTEXT.md" ]; then
    report ok "CONTEXT.md" "present"
  else
    report warn "CONTEXT.md" "absent — dw-land promotes domain terms here; fix: dw-init"
  fi
fi

# --- the always-loaded file ----------------------------------------------------
# AGENTS.md is the one file every session loads in full: the git conventions dw-git reads, and the two
# command bullets the lint and typecheck hooks grep. It is tracked, which is the whole point — a
# gitignored CLAUDE.local.md reached neither a fresh clone nor a worktree, and every gap failed
# silently. That file is still honoured as a fallback here, in the same order the hooks use it.
group "Agent memory"
agents="$ROOT/AGENTS.md"
legacy="$ROOT/CLAUDE.local.md"

# Skipped outright for a team-lane repo. The lane warning above already says the solo plugin is the
# wrong one here, so three more lines of "fix: dw-init" would be advice for a lane this script just
# disclaimed — the same reason the promotion-target checks sit behind $SOLO.
MEMORY=1
if [ -d "$ROOT/.ai/runs" ] && [ "$SOLO" -eq 0 ]; then
  MEMORY=0
  report info "—" "team-lane repo — agent-memory checks skipped (see the lane warning above)"
fi

# Counted ONCE, and the line count is newlines + 1 — which is what the shipped checker's
# `split("\n").length` yields. `wc -l` alone is one lower, so a file sitting exactly on its budget
# passed here and failed the gate. The doctor's whole claim is that it agrees with what enforces.
if [ "$MEMORY" -eq 1 ] && [ -f "$agents" ]; then
  agents_lines=$(($(wc -l <"$agents" | tr -d ' ') + 1))
  agents_bytes="$(wc -c <"$agents" | tr -d ' ')"
  report ok "AGENTS.md" "present ($agents_lines lines, $agents_bytes B)"

  # The budget, read from the file's own declaration — same grammar the shipped checker parses:
  # `Budget: **120 lines / 10 KB**`, bare number = bytes, KB = x1024, anything else malformed.
  bline="$(grep -m1 'Budget:' "$agents" 2>/dev/null)"
  if [ -z "$bline" ]; then
    report warn "AGENTS.md budget" "no 'Budget: **N lines / M KB**' declaration — nothing caps the file every session loads"
  else
    decl="$(printf '%s' "${bline#*Budget:}" | tr -d '*`')"
    # The tail must be empty or start with , . ; — exactly what the shipped checker's regex allows.
    # An open `.*` accepted `120 lines / 10 KB trailing garbage` here and the gate rejected it, which
    # is the same class of divergence as the line count: the doctor is only worth reading if it agrees
    # with what enforces.
    parsed="$(printf '%s' "$decl" | sed -nE 's|^[[:space:]]*([0-9][0-9_]*)[[:space:]]*lines?[[:space:]]*/[[:space:]]*([0-9][0-9_]*)[[:space:]]*([A-Za-z]*)[[:space:]]*([,.;].*)?$|\1 \2 \3|p')"
    if [ -z "$parsed" ]; then
      report warn "AGENTS.md budget" "declaration not parseable: '$(printf '%s' "$decl" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')' — expected 'N lines / M[ KB]'"
    else
      read -r max_lines max_bytes unit <<<"$parsed"
      # 10# forces base 10. Without it a leading zero is read as octal and `08 KB` — which Node's
      # Number("08") accepts as 8 — made bash bail out of the arithmetic, dropping the budget line
      # from the report entirely rather than failing loudly.
      max_lines=$((10#$(printf '%s' "$max_lines" | tr -d '_')))
      max_bytes=$((10#$(printf '%s' "$max_bytes" | tr -d '_')))
      case "$unit" in
        "" | b | B) ;;
        kb | Kb | kB | KB) max_bytes=$((max_bytes * 1024)) ;;
        *) max_bytes="" ;;
      esac
      if [ -z "$max_bytes" ]; then
        report warn "AGENTS.md budget" "unit '$unit' not understood — use a bare byte count or KB"
      elif [ "$agents_lines" -gt "$max_lines" ] || [ "$agents_bytes" -gt "$max_bytes" ]; then
        report warn "AGENTS.md budget" "$agents_lines/$max_lines lines, $agents_bytes/$max_bytes B — over. Move a topic into docs/agents/ with a router row"
      else
        report ok "AGENTS.md budget" "$agents_lines/$max_lines lines, $agents_bytes/$max_bytes B"
      fi
    fi
  fi

  # A placeholder that survived the render is read as content by the next session and eval'ed as a
  # command by the hooks — which is why they carry an explicit guard against these tokens.
  stray="$(grep -oE '\{\{[A-Z_]+\}\}' "$agents" 2>/dev/null | sort -u | tr '\n' ' ')"
  if [ -n "$stray" ]; then
    report warn "AGENTS.md placeholders" "unrendered: ${stray% } — give each a value or drop the line"
  fi

  # The Task Router, and whether the topic layer it indexes has outgrown it.
  if grep -qE '^##[[:space:]]+Task Router' "$agents" 2>/dev/null; then
    # Sliced out ONCE, and coverage is grepped against the slice — not the whole file. Naming a topic
    # file in some other section is not routing to it, and scanning everything made the check pass on
    # a row written outside the table.
    router="$(awk '/^##[[:space:]]+Task Router/{f=1;next} f && /^##[[:space:]]/{f=0} f' "$agents")"
    nrows="$(printf '%s\n' "$router" | grep -cE '^[[:space:]]*\|' || true)"
    ncontent=$((nrows - 2))
    [ "$ncontent" -lt 0 ] && ncontent=0
    if [ "$ncontent" -eq 0 ]; then
      report warn "AGENTS.md Task Router" "section present but holds no rows — a task has nothing to match against"
    else
      report ok "AGENTS.md Task Router" "$ncontent row(s)"
    fi
    if [ -d "$ROOT/docs/agents" ]; then
      unrouted=""
      for f in "$ROOT"/docs/agents/*.md; do
        [ -f "$f" ] || continue
        base="$(basename "$f")"
        [ "$base" = "CLAUDE.md" ] && continue
        printf '%s\n' "$router" | grep -qF "docs/agents/$base" || unrouted="$unrouted $base"
      done
      if [ -n "$unrouted" ]; then
        report warn "docs/agents/ coverage" "no router row for:${unrouted} — a topic file nothing routes to is a file nothing reads"
      else
        report ok "docs/agents/ coverage" "every topic file has a row"
      fi
    fi
  else
    report warn "AGENTS.md Task Router" "no '## Task Router' section — nothing indexes docs/agents/; fix: dw-init"
  fi

  # CLAUDE.md must be the symlink, not a second copy. A materialized copy forks the corpus silently.
  if [ -L "$ROOT/CLAUDE.md" ]; then
    tgt="$(readlink "$ROOT/CLAUDE.md")"
    # Judged by destination, the way the shipped checker judges it. `-ef` compares device and inode
    # with the link followed, so `AGENTS.md`, `./AGENTS.md`, an absolute path and a path through a
    # symlinked parent all read as the one link they are — and a dangling link is correctly false.
    # Comparing the raw link text would warn about a repo that is set up right.
    if [ "$ROOT/CLAUDE.md" -ef "$ROOT/AGENTS.md" ]; then
      report ok "CLAUDE.md" "symlink -> AGENTS.md"
    else
      report warn "CLAUDE.md" "symlink -> $tgt, not AGENTS.md; fix: ln -sf AGENTS.md CLAUDE.md"
    fi
  elif [ -f "$ROOT/CLAUDE.md" ]; then
    report warn "CLAUDE.md" "a real file beside AGENTS.md — two always-loaded copies that will diverge; fix: keep AGENTS.md, ln -sf AGENTS.md CLAUDE.md"
  else
    report warn "CLAUDE.md" "absent — Claude Code loads this name; fix: ln -s AGENTS.md CLAUDE.md"
  fi
elif [ "$MEMORY" -eq 1 ] && { [ -f "$ROOT/CLAUDE.md" ] || [ -f "$legacy" ]; }; then
  report warn "AGENTS.md" "absent, but CLAUDE.md/CLAUDE.local.md is here — a pre-migration layout; fix: dw-init moves it"
elif [ "$MEMORY" -eq 1 ]; then
  report warn "AGENTS.md" "absent — the one always-loaded file; dw-git and both command hooks read it; fix: dw-init"
fi

# The two bullets the hooks grep, resolved in the hooks' own order. A value of `none` is a valid
# answer, not a gap: it tells the hook to skip rather than eval a command the project hasn't got.
if [ "$MEMORY" -eq 1 ]; then
  for bullet in Lint Typecheck; do
    pattern="^[[:space:]]*[-*]?[[:space:]]*\*{0,2}$bullet command\*{0,2}:"
    src=""; src_path=""
    if [ -f "$agents" ] && grep -qE "$pattern" "$agents" 2>/dev/null; then
      src="AGENTS.md"; src_path="$agents"
    elif [ -f "$legacy" ] && grep -qE "$pattern" "$legacy" 2>/dev/null; then
      src="CLAUDE.local.md (legacy)"; src_path="$legacy"
    fi
    if [ -z "$src" ]; then
      report warn "$bullet command" "declared nowhere — the hook falls through to a probe, or silently lints nothing"
    else
      # Extracted in the hooks' own order, not merely plausibly: the `none` sentinel is tested on the
      # raw remainder FIRST, then the first backticked span, then the rest of the line. Reporting a
      # command the hook would never run is the one thing a diagnostic cannot afford.
      line="$(grep -m1 -E "$pattern" "$src_path" 2>/dev/null)"
      rest="$(printf '%s\n' "$line" | sed -e 's/.*command[*]*://' -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
      case "$rest" in
        none | None | NONE | none[!A-Za-z0-9]* | None[!A-Za-z0-9]* | NONE[!A-Za-z0-9]*)
          report ok "$bullet command" "none (declared, so the hook skips) — from $src"
          continue
          ;;
      esac
      val="$(printf '%s\n' "$line" | sed -n 's/.*command[*]*:[^`]*`\([^`]*\)`.*/\1/p')"
      [ -z "$val" ] && val="$rest"
      case "$val" in
        "" | '{{'*) report warn "$bullet command" "empty or unrendered in $src — the hook will no-op" ;;
        *) report ok "$bullet command" "$val — from $src" ;;
      esac
    fi
  done
fi

# The gate on all of the above. Its absence is not a failure — it is a repo nobody wired one into.
if [ "$MEMORY" -eq 1 ] && [ -f "$ROOT/scripts/check-agents-docs.mjs" ]; then
  report ok "agents:check" "scripts/check-agents-docs.mjs present (run it: node scripts/check-agents-docs.mjs)"
elif [ "$MEMORY" -eq 1 ] && [ -f "$agents" ]; then
  report warn "agents:check" "no scripts/check-agents-docs.mjs — nothing enforces the budget or the router; fix: dw-init"
fi

if [ "$MEMORY" -eq 1 ] && [ -f "$legacy" ]; then
  report info "CLAUDE.local.md" "present (legacy) — nothing writes it any more; AGENTS.md is read first"
fi

# --- plugins (opportunistic: only a marketplace repo has this) ----------------
mkt="$ROOT/.claude-plugin/marketplace.json"
if [ -f "$mkt" ]; then
  group "Plugins (marketplace repo)"
  if have jq; then
    n="$(jq '.plugins | length' "$mkt" 2>/dev/null || echo '?')"
    report ok "marketplace.json" "$n plugin(s) declared"
    mism=0
    while IFS=$'\t' read -r name source mp_v; do
      [ -z "$name" ] && continue
      pj="$ROOT/${source#./}/.claude-plugin/plugin.json"
      if [ ! -f "$pj" ]; then
        report warn "$name" "plugin.json missing at ${pj#"$ROOT"/}"; mism=1; continue
      fi
      pj_v="$(jq -r '.version' "$pj" 2>/dev/null)"
      if [ "$mp_v" != "$pj_v" ]; then
        report warn "$name" "version drift: marketplace=$mp_v vs plugin.json=$pj_v"; mism=1
      fi
    done < <(jq -r '.plugins[] | [.name, .source, .version] | @tsv' "$mkt" 2>/dev/null)
    [ "$mism" -eq 0 ] && report ok "version sync" "all in sync (full check: pnpm validate:manifests)"
  else
    report warn "marketplace.json" "present but skipped (needs jq)"
  fi
fi

# --- summary ------------------------------------------------------------------
group "Summary"
printf '  %d OK, %d warning(s), %d failure(s)\n' "$OK" "$WARN" "$FAIL"
if [ "$FAIL" -gt 0 ]; then
  printf '  %sAction needed:%s resolve the [FAIL] lines above — start with jq/git, they gate the rest.\n' "$C_FAIL" "$C_RST"
fi
printf '  %sRead-only: nothing was installed or modified.%s\n' "$C_DIM" "$C_RST"
exit 0
