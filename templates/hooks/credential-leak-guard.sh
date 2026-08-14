#!/bin/bash
# PreToolUse Bash hook — refuses the three shapes of credential hunting that
# `block-env-access.sh` does not cover. Wire with matcher "Bash".
#
# THE BOUNDARY WITH ITS SIBLINGS, because three things guard this ground and each
# leaves a different gap. `block-env-access.sh` owns `.env` files and nothing
# else. The CI `trufflehog` scan reads what was committed, so it fires long after
# the fact and never sees a value that only ever passed through a shell. What is
# left, and what this hook owns:
#
#   1. the credential stores that are not dotenv — ~/.ssh, ~/.aws, ~/.gnupg,
#      ~/.kube, ~/.netrc, ~/.git-credentials, ~/.pypirc, ~/.pgpass
#   2. hunting the ENVIRONMENT for secrets: an `env`/`printenv` dump filtered for
#      a credential-ish name, or echoing such a variable straight out
#   3. exfil: `curl`/`wget` in the same command as a credential path, a
#      credential-ish variable, or a dotenv file
#
# Check 3 is deliberately NOT "no network calls". A hook that blocked every curl
# would be turned off within the day; one that blocks curl carrying a secret is
# one nobody has to argue with.
#
# Exit 2 + stderr message causes Claude to see the block and self-correct.
# Guardrail against agent accidents — NOT a security boundary. Quoted spans are
# stripped before the path check so prose passes, which is the same trade
# block-env-access.sh documents; for a tilde path it costs nothing, since bash
# does not expand `~` inside quotes and a quoted one was already broken.

set -uo pipefail

command -v jq >/dev/null || exit 0

INPUT=$(cat)
COMMAND=$(jq -r '.tool_input.command // empty' <<<"$INPUT")

[[ -z "$COMMAND" ]] && exit 0

# Credential-ish name fragments, matched case-blind against a variable name or a
# grep pattern. A bare `key` is deliberately absent — it matches keyboard,
# keychain and keys() — and `auth` failed that same test after shipping bare for
# one commit: it swallowed `$AUTHOR`, `$AUTHORS` and `$AUTHOR_DATE`, which is
# everyday git scripting, so `echo $AUTHOR` was refused. `auth` now has to end the
# word (`$AUTH`, `$BASIC_AUTH`) or be followed by a separator (`$AUTH_TOKEN`),
# with `authorization` spelled out because it continues into letters. ERE has no
# negative lookahead, so "not followed by a letter" is the closest expressible
# thing — and it consumes that character, which is safe only because nothing in
# either regex below follows CRED_WORDS.
CRED_WORDS='(token|secret|password|passwd|passphrase|api[_-]?key|access[_-]?key|private[_-]?key|credential|authorization|auth([^A-Za-z]|$))'

block() {
  echo "BLOCKED: $1" >&2
  echo "Refused by a dw-* guardrail hook. If this is genuinely needed, the user must run it manually." >&2
  exit 2
}

# --- 1. the credential stores ------------------------------------------------
# Same two-stage strip as block-env-access.sh: heredoc bodies are prose and carry
# no quoting to find, so they go first, by line; then quoted spans; then the
# remainder is split into tokens.
#
# DUPLICATED, NOT SHARED: `HEREDOC_OPEN` and `strip_heredocs` are byte-identical
# to block-env-access.sh's, and a fix to one belongs in both. There is no shared
# library to put them in on purpose — each hook is installed and pruned on its
# own, so a `source` would make every hook depend on a file dw-init may not have
# copied. Nothing detects the drift, which is the same standing hazard
# hooks-in-sync.test.sh's header records about the dw-skills vendored copies.
HEREDOC_OPEN='(^|[^<])<<-?[[:space:]]*["'"'"'\]?([A-Za-z_][A-Za-z0-9_]*)'
strip_heredocs() {
  local line delim="" body=0
  while IFS= read -r line; do
    if [[ $body -eq 1 ]]; then
      [[ "$line" =~ ^[[:space:]]*$delim[[:space:]]*$ ]] && {
        body=0
        delim=""
      }
      continue
    fi
    printf '%s\n' "$line"
    [[ "$line" =~ $HEREDOC_OPEN ]] && {
      delim="${BASH_REMATCH[2]}"
      body=1
    }
  done
  # Pin the status: the loop's own is that last test, false for any command not
  # ending on an opener, which would sink the pipeline under pipefail.
  return 0
}

# is_cred_path <token> — 0 when a path COMPONENT is a credential directory, or the
# basename is a credential file. Component-exact on purpose: a substring match
# would read `docs/ssh-setup.md` and `scripts/.awsome` as credential stores.
is_cred_path() {
  local tok="$1" comp
  case "${tok##*/}" in
    .netrc | .git-credentials | .pypirc | .pgpass) return 0 ;;
    # `.npmrc` is the one entry here with a legitimate PROJECT-LOCAL twin —
    # committed registry config holding no secret — and this hook ships through
    # templates/ to every scaffolded Node repo, so refusing `cat .npmrc` there
    # would be wrong far more often than right. Only the user's own one counts.
    # The siblings above need no such test: they are home-dir files by
    # convention and a project-local `.netrc` is already a mistake.
    .npmrc)
      case "$tok" in
        '~/'* | '$HOME/'* | /*) return 0 ;;
      esac
      ;;
  esac
  local IFS=/
  for comp in $tok; do
    case "$comp" in
      .ssh | .aws | .gnupg | .kube) return 0 ;;
    esac
  done
  return 1
}

STRIPPED=$(printf '%s\n' "$COMMAND" | strip_heredocs | tr '\n' ' ' | sed -E 's/"[^"]*"//g' | sed -E "s/'[^']*'//g")

CRED_PATH_HIT=""
while IFS= read -r token; do
  [[ -z "$token" ]] && continue
  if is_cred_path "$token"; then
    CRED_PATH_HIT="$token"
    break
  fi
done < <(printf '%s\n' "$STRIPPED" | tr -s "[:space:];|&()<>=\`\"'" '\n')

# --- 2. hunting the environment ----------------------------------------------
# An env dump is fine on its own — `env` to see what is set is ordinary. Filtered
# for a credential name it is not a look, it is a search.
#
# `set` only counts with NO ARGUMENTS, which is the spelling that dumps the
# environment. `set -e` and `set -euo pipefail` set shell options and dump
# nothing, and matching them meant `set -e && grep -rn "password" src/` was
# refused — searching your own source for a field name is ordinary work, and that
# is exactly the false positive that gets a hook unwired. The alternatives end
# `($|[;&|])` rather than `$` so that `set | grep -i token`, the real hunting
# form, still matches.
ENV_DUMP='(^|[;&|][[:space:]]*)((env|printenv)([[:space:]]|$)|export -p|declare -x|set[[:space:]]*($|[;&|]))'
env_hunt=0
if printf '%s' "$COMMAND" | grep -qE "$ENV_DUMP" \
  && printf '%s' "$COMMAND" | grep -qiE "(grep|rg|ag|awk|sed|fgrep|egrep)[^;&|]*$CRED_WORDS"; then
  env_hunt=1
fi
# Printing a credential-ish variable straight out. Referencing one is not the
# problem — `gh` wants $GITHUB_TOKEN and that is its job; putting the VALUE on
# stdout, where it lands in a transcript, is.
echo_secret=0
if printf '%s' "$COMMAND" | grep -qiE "(^|[;&|][[:space:]]*)(echo|printf|print)[^;&|]*\\\$\{?[A-Za-z_]*$CRED_WORDS"; then
  echo_secret=1
fi

# --- 3. exfil ----------------------------------------------------------------
exfil=0
if printf '%s' "$COMMAND" | grep -qE '(^|[;&|][[:space:]]*)(sudo[[:space:]]+)?(curl|wget)([[:space:]]|$)'; then
  if [[ -n "$CRED_PATH_HIT" ]] \
    || printf '%s' "$COMMAND" | grep -qiE "\\\$\{?[A-Za-z_]*$CRED_WORDS" \
    || printf '%s' "$STRIPPED" | grep -qE '(^|[[:space:]=])[^[:space:]]*\.env([.[:space:]]|$)'; then
    exfil=1
  fi
fi

# Exfil first: it is the same command as a bare read, plus a destination, and
# naming the destination is the more useful refusal.
if ((exfil)); then
  block "this command sends a credential off the machine — a curl/wget carrying a secret file or variable. Nothing an agent does should need that."
fi
if [[ -n "$CRED_PATH_HIT" ]]; then
  block "'$COMMAND' touches the credential store '$CRED_PATH_HIT'. SSH keys, cloud credentials and .netrc are the user's, not the agent's, and reading one puts it in a transcript."
fi
if ((env_hunt)); then
  block "'$COMMAND' searches the environment for credentials. Dumping the environment is fine; filtering it for a token, secret or key is not a look, it is a search — and the matches land in a transcript."
fi
if ((echo_secret)); then
  block "'$COMMAND' prints a credential-ish variable's VALUE to stdout, where it lands in the transcript. Referencing the variable in the command that needs it is fine; printing it is not."
fi

exit 0
