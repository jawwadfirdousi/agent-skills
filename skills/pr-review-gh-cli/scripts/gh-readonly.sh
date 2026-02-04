#!/usr/bin/env bash
set -euo pipefail

# Use the real gh binary path if set by env.sh, otherwise find it ourselves
# This prevents infinite recursion when gh is shadowed by a shell function
if [[ -n "${__GH_READONLY_REAL_GH:-}" ]]; then
  GH_BIN="$__GH_READONLY_REAL_GH"
else
  # Find the actual gh binary, skipping any shell functions or aliases
  GH_BIN="$(command -v gh 2>/dev/null || true)"
  if [[ -z "$GH_BIN" ]]; then
    echo "gh-readonly: error: gh CLI not found in PATH" >&2
    exit 1
  fi
fi

deny() {
  echo "gh-readonly: blocked: $*" >&2
  exit 2
}

usage() {
  cat <<'USAGE'
Usage:
  gh-readonly.sh [global gh options] <read-only gh command...>

Allowed command families:
  auth status
  api (GET only, allowlisted endpoints only)
  pr view|diff|checks|list
  issue view
  search code|issues

This wrapper is intentionally strict and denies all mutating operations.
USAGE
}

require_value() {
  local idx="$1"
  local size="$2"
  local flag="$3"
  (( idx + 1 < size )) || deny "missing value for '$flag'"
}

normalize_upper() {
  printf '%s' "$1" | tr '[:lower:]' '[:upper:]'
}

is_allowed_api_endpoint() {
  local endpoint="${1#/}"

  [[ "$endpoint" == "user" ]] && return 0

  [[ "$endpoint" =~ ^repos/[^/]+/[^/]+/commits(/[^/?]+)?(\?.*)?$ ]] && return 0
  [[ "$endpoint" =~ ^repos/[^/]+/[^/]+/contents/.+\?ref=.+$ ]] && return 0
  [[ "$endpoint" =~ ^repos/[^/]+/[^/]+/issues/[0-9]+/comments(\?.*)?$ ]] && return 0
  [[ "$endpoint" =~ ^repos/[^/]+/[^/]+/pulls/[0-9]+/(comments|files|reviews)(\?.*)?$ ]] && return 0
  [[ "$endpoint" =~ ^repos/[^/]+/[^/]+/secret-scanning/alerts(/[^/?]+)?(\?.*)?$ ]] && return 0

  return 1
}

check_no_mutating_api_flags() {
  local -a api_args=("$@")
  local i
  local method="GET"
  local endpoint=""

  for ((i = 0; i < ${#api_args[@]}; i++)); do
    case "${api_args[$i]}" in
      -X|--method)
        require_value "$i" "${#api_args[@]}" "${api_args[$i]}"
        method="${api_args[$((i + 1))]}"
        i=$((i + 1))
        ;;
      --method=*)
        method="${api_args[$i]#*=}"
        ;;
      -f|--field|-F|--raw-field|--input)
        deny "request body flags are not allowed for read-only API usage ('${api_args[$i]}')"
        ;;
      -f=*|--field=*|-F=*|--raw-field=*|--input=*)
        deny "request body flags are not allowed for read-only API usage ('${api_args[$i]}')"
        ;;
      --paginate|--silent|--verbose)
        ;;
      -H|--header|--jq|--template)
        require_value "$i" "${#api_args[@]}" "${api_args[$i]}"
        i=$((i + 1))
        ;;
      --header=*|--jq=*|--template=*)
        ;;
      -*)
        deny "unsupported gh api flag '${api_args[$i]}'"
        ;;
      *)
        if [[ -z "$endpoint" ]]; then
          endpoint="${api_args[$i]}"
        fi
        ;;
    esac
  done

  [[ -n "$endpoint" ]] || deny "gh api endpoint is required"
  [[ "$(normalize_upper "$method")" == "GET" ]] || deny "gh api is restricted to GET requests"
  is_allowed_api_endpoint "$endpoint" || deny "endpoint is not allowlisted for read-only use: $endpoint"
}

parse_global_args() {
  local -a raw=("$@")
  local i=0

  GLOBAL_ARGS=()
  CMD_ARGS=()

  while (( i < ${#raw[@]} )); do
    case "${raw[$i]}" in
      -R|--repo|--hostname)
        require_value "$i" "${#raw[@]}" "${raw[$i]}"
        GLOBAL_ARGS+=("${raw[$i]}" "${raw[$((i + 1))]}")
        i=$((i + 2))
        ;;
      --repo=*|--hostname=*|-R=*)
        GLOBAL_ARGS+=("${raw[$i]}")
        i=$((i + 1))
        ;;
      --help|-h)
        usage
        exit 0
        ;;
      *)
        CMD_ARGS=("${raw[@]:$i}")
        return 0
        ;;
    esac
  done

  return 0
}

run_gh() {
  "$GH_BIN" "${GLOBAL_ARGS[@]}" "$@"
}

if [[ $# -eq 0 ]]; then
  usage
  exit 2
fi

GLOBAL_ARGS=()
CMD_ARGS=()
parse_global_args "$@"

[[ ${#CMD_ARGS[@]} -gt 0 ]] || deny "missing command"

sub="${CMD_ARGS[0]}"

case "$sub" in
  auth)
    [[ ${#CMD_ARGS[@]} -ge 2 ]] || deny "missing auth action"
    [[ "${CMD_ARGS[1]}" == "status" ]] || deny "only 'gh auth status' is allowed"
    run_gh "${CMD_ARGS[@]}"
    ;;
  api)
    [[ ${#CMD_ARGS[@]} -ge 2 ]] || deny "missing api endpoint"
    check_no_mutating_api_flags "${CMD_ARGS[@]:1}"
    run_gh "${CMD_ARGS[@]}"
    ;;
  pr)
    [[ ${#CMD_ARGS[@]} -ge 2 ]] || deny "missing pr action"
    case "${CMD_ARGS[1]}" in
      view|diff|checks|list)
        run_gh "${CMD_ARGS[@]}"
        ;;
      *)
        deny "only 'gh pr view|diff|checks|list' are allowed"
        ;;
    esac
    ;;
  issue)
    [[ ${#CMD_ARGS[@]} -ge 2 ]] || deny "missing issue action"
    [[ "${CMD_ARGS[1]}" == "view" ]] || deny "only 'gh issue view' is allowed"
    run_gh "${CMD_ARGS[@]}"
    ;;
  search)
    [[ ${#CMD_ARGS[@]} -ge 2 ]] || deny "missing search scope"
    case "${CMD_ARGS[1]}" in
      code|issues)
        run_gh "${CMD_ARGS[@]}"
        ;;
      *)
        deny "only 'gh search code|issues' are allowed"
        ;;
    esac
    ;;
  *)
    deny "unsupported gh command family '$sub'"
    ;;
esac
