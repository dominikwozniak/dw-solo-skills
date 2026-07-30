#!/usr/bin/env bash
# dw-doctor — read-only environment diagnostic for a dw-* repo.
#
# Checks whether the tools a dw-* repo assumes are present and whether its
# hooks/skills will actually work, then prints one line per check
# (OK / WARN / FAIL) with a fix hint. It diagnoses the CURRENT git repo
# (resolved from cwd), not the skill's own location.
#
# READ-ONLY: it never installs anything and never edits a file. It only runs
# `command -v` and `--version` probes and reads files. Exits 0 always — the
# report text carries the verdict.
#
# Stack checks are conditional on what the repo declares (package.json /
# Gemfile / tsconfig.json / CLAUDE.local.md), mirroring how the hooks resolve
# their commands — so nothing about a stack is hardcoded.
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
  report warn "gh" "absent — dw-git PRs & dw-quality 'gh pr diff' need it. Install: brew install gh"
fi

# --- JavaScript / TypeScript (only if package.json) ---------------------------
pkg="$ROOT/package.json"
group "JavaScript / TypeScript"
if [ ! -f "$pkg" ]; then
  report info "—" "no package.json — JS/TS checks skipped"
elif have jq && ! jq empty "$pkg" 2>/dev/null; then
  report fail "package.json" "present but not valid JSON"
else
  # node vs engines.node
  if have node; then
    cur="$(node -v 2>/dev/null | sed 's/^v//')"
    min=""
    have jq && min="$(jq -r '.engines.node // empty' "$pkg" 2>/dev/null | grep -oE '[0-9]+(\.[0-9]+)*' | head -n1)"
    if [ -n "$min" ]; then
      if ver_ge "$min" "$cur"; then
        report ok "node" "$cur (engines: >=$min)"
      else
        report warn "node" "$cur < required $min — upgrade (see .nvmrc, or brew install node)"
      fi
    else
      report ok "node" "$cur"
    fi
  else
    report fail "node" "missing — install via nvm (.nvmrc) or brew install node"
  fi

  # pnpm vs packageManager
  pm=""; have jq && pm="$(jq -r '.packageManager // empty' "$pkg" 2>/dev/null)"
  want_pnpm=0; pmver=""
  case "$pm" in pnpm@*) want_pnpm=1; pmver="${pm##*@}"; pmver="${pmver%%+*}" ;; esac
  if [ -f "$ROOT/pnpm-lock.yaml" ] || [ "$want_pnpm" -eq 1 ]; then
    if have pnpm; then
      cur_pnpm="$(pnpm -v 2>/dev/null)"
      if [ "$want_pnpm" -eq 1 ] && [ -n "$pmver" ] && [ "$cur_pnpm" != "$pmver" ]; then
        report warn "pnpm" "$cur_pnpm (packageManager pins $pmver — run: corepack enable)"
      else
        report ok "pnpm" "${cur_pnpm:-present}"
      fi
    else
      report fail "pnpm" "missing — hooks enforce pnpm. Install: corepack enable (or npm i -g pnpm)"
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

# --- Ruby (only if Gemfile) ---------------------------------------------------
gemfile="$ROOT/Gemfile"
if [ -f "$gemfile" ]; then
  group "Ruby"
  if have bundle; then
    report ok "bundle" "$(bundle --version 2>/dev/null | head -n1)"
  else
    report warn "bundle" "missing — install: gem install bundler"
  fi
  if grep -qE "^[[:space:]]*gem[[:space:]]+[\"']standard[\"']" "$gemfile"; then
    report info "lint" "Gemfile declares standard → bundle exec standardrb"
  elif grep -qE "^[[:space:]]*gem[[:space:]]+[\"']rubocop" "$gemfile"; then
    report info "lint" "Gemfile declares rubocop → bundle exec rubocop"
  else
    report info "lint" "no rubocop/standard in Gemfile — lint-on-edit-rb hook no-ops (unless CLAUDE.local.md sets one)"
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

# This lane's home is `.ai/work/`. `.ai/runs/` belongs to the team lane
# (the `dw-skills` marketplace) — finding it here means the wrong plugin is
# installed for this repo, so it's reported rather than silently ignored.
if [ -d "$ROOT/.ai/work" ]; then
  report ok "lane" "solo — .ai/work/ (dw-shape / dw-next / dw-land)"
  if [ -d "$ROOT/.ai/runs" ]; then
    report warn "lane" ".ai/runs/ also present — that's the team lane; one lane per repo, or two skills compete for \"start a feature\""
  fi
elif [ -d "$ROOT/.ai/runs" ]; then
  report warn "lane" ".ai/runs/ but no .ai/work/ — this repo runs the team lane; install dw-planning + dw-quality instead of dw-solo"
elif [ -d "$ROOT/.ai" ]; then
  report warn ".ai/" "present but no work/ — fix: dw-init"
else
  report warn ".ai/" "absent — fix: dw-init, then dw-shape"
fi

# dw-land promotes into these, so their absence breaks the closing step.
if [ -d "$ROOT/docs/decisions" ]; then
  report ok "docs/decisions/" "present"
else
  report warn "docs/decisions/" "absent — dw-land promotes decision records here; fix: dw-init"
fi
if [ -f "$ROOT/CONTEXT.md" ]; then
  report ok "CONTEXT.md" "present"
else
  report warn "CONTEXT.md" "absent — dw-land promotes domain terms here; fix: dw-init"
fi
if [ -f "$ROOT/CLAUDE.md" ]; then
  if grep -qE '^##[[:space:]]+Gotchas' "$ROOT/CLAUDE.md" 2>/dev/null; then
    report ok "CLAUDE.md ## Gotchas" "present"
  else
    report warn "CLAUDE.md ## Gotchas" "section missing — dw-land appends traps there; fix: dw-init"
  fi
  if grep -qE '^##[[:space:]]+Commands' "$ROOT/CLAUDE.md" 2>/dev/null; then
    report ok "CLAUDE.md ## Commands" "present"
  else
    report warn "CLAUDE.md ## Commands" "section missing — the only tracked copy of test/lint/typecheck; fix: dw-init"
  fi
else
  report warn "CLAUDE.md" "absent — dw-land has nowhere to promote gotchas; fix: dw-init"
fi

# The lane switch dw-init sets. The team-lane plugins live in a different
# marketplace (`dw-skills`), so they may not be installed at all — but if they
# are, leaving them enabled here means two skills compete for "start a feature".
# A hand-written enabledPlugins key with a wrong marketplace id is silently
# ignored, so this is worth asserting rather than assuming.
if [ -f "$settings" ] && have jq; then
  n_off="$(jq -r '.enabledPlugins // {} | to_entries[] | select(.value == false) | .key' "$settings" 2>/dev/null | grep -cE '^(dw-planning|dw-quality)@' || true)"
  if [ "${n_off:-0}" -ge 1 ]; then
    report ok "lane switch" "$n_off team-lane plugin(s) disabled for this project"
  else
    report info "lane switch" "dw-planning/dw-quality not disabled here — harmless if neither is installed, else: claude plugin disable dw-planning --scope project"
  fi
fi

if [ -f "$ROOT/CLAUDE.local.md" ]; then
  report ok "CLAUDE.local.md" "present"
else
  report warn "CLAUDE.local.md" "absent — hooks + dw-git read it for commands & conventions"
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
