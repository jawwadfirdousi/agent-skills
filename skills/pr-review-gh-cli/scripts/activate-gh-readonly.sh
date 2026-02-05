#!/usr/bin/env bash
# Source this file to enable read-only gh enforcement.
# Usage: source /path/to/activate-gh-readonly.sh
#
# After sourcing, all `gh` calls in the current shell session are intercepted
# and filtered through the read-only wrapper. Direct gh binary access is blocked.
#
# Protection covers:
#   - `gh <args>`           -> wrapped
#   - `command gh <args>`   -> wrapped
#   - `\gh <args>`          -> wrapped (backslash bypass)
#   - `env gh <args>`       -> blocked
#   - `/path/to/gh <args>`  -> cannot intercept, but skill instructions prohibit
#
# For maximum security, the wrapper script validates commands regardless of
# how it's invoked.

# Prevent re-sourcing
if [[ "${__GH_READONLY_ACTIVE:-}" == "1" ]]; then
  echo "gh-readonly: already active in this session" >&2
  return 0 2>/dev/null || exit 0
fi

__GH_READONLY_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
__GH_READONLY_WRAPPER="${__GH_READONLY_SCRIPT_DIR}/gh-readonly.sh"

# Find the real gh binary before we shadow it
__GH_READONLY_REAL_GH="$(builtin command -v gh 2>/dev/null || true)"

if [[ -z "$__GH_READONLY_REAL_GH" ]]; then
  echo "gh-readonly: error: gh CLI not found in PATH" >&2
  return 1 2>/dev/null || exit 1
fi

if [[ ! -x "$__GH_READONLY_WRAPPER" ]]; then
  echo "gh-readonly: error: wrapper script not found or not executable: $__GH_READONLY_WRAPPER" >&2
  return 1 2>/dev/null || exit 1
fi

# Export for the wrapper script to use
export __GH_READONLY_REAL_GH
export __GH_READONLY_WRAPPER
export __GH_READONLY_ACTIVE=1

# Define the gh function that shadows the binary
gh() {
  "$__GH_READONLY_WRAPPER" "$@"
}
export -f gh

# Shadow `command` builtin to intercept `command gh` bypass attempts
command() {
  case "${1:-}" in
    gh)
      shift
      gh "$@"
      ;;
    env)
      # `command env gh ...` is a common bypass attempt; route through our env wrapper
      shift
      env "$@"
      ;;
    --)
      # `command -- <cmd>` can be used to bypass simple case matching; intercept gh/env
      shift
      case "${1:-}" in
        gh)
          shift
          gh "$@"
          ;;
        env)
          shift
          env "$@"
          ;;
        *)
          builtin command -- "$@"
          ;;
      esac
      ;;
    -v)
      if [[ "${2:-}" == "gh" || ( "${2:-}" == "--" && "${3:-}" == "gh" ) ]]; then
        echo "gh (read-only wrapper)"
        return 0
      fi
      if [[ "${2:-}" == "env" || ( "${2:-}" == "--" && "${3:-}" == "env" ) ]]; then
        echo "env (read-only wrapper)"
        return 0
      fi
      builtin command "$@"
      ;;
    -p)
      # `command -p` uses the default PATH - intercept gh/env to prevent bypass
      if [[ "${2:-}" == "--" && "${3:-}" == "gh" ]]; then
        shift 3
        gh "$@"
      elif [[ "${2:-}" == "--" && "${3:-}" == "env" ]]; then
        shift 3
        env "$@"
      elif [[ "${2:-}" == "gh" ]]; then
        shift 2
        gh "$@"
      elif [[ "${2:-}" == "env" ]]; then
        # `command -p env gh ...` is a bypass attempt; route through our env wrapper
        shift 2
        env "$@"
      else
        builtin command "$@"
      fi
      ;;
    *)
      builtin command "$@"
      ;;
  esac
}
export -f command

# Shadow `env` to block `env gh` bypass
__gh_readonly_original_env="$(builtin command -v env 2>/dev/null)"
export __gh_readonly_original_env
env() {
  local args=("$@")
  local i
  for ((i = 0; i < ${#args[@]}; i++)); do
    case "${args[$i]}" in
      gh)
        echo "gh-readonly: blocked: env gh bypass attempt" >&2
        return 2
        ;;
      -*)
        # Skip option flags
        ;;
      *=*)
        # Skip environment variable assignments
        ;;
      *)
        # First non-option, non-assignment is the command
        if [[ "${args[$i]}" == "gh" ]]; then
          echo "gh-readonly: blocked: env gh bypass attempt" >&2
          return 2
        fi
        break
        ;;
    esac
  done
  "$__gh_readonly_original_env" "$@"
}
export -f env

# Verification function to confirm read-only mode is active
gh-readonly-status() {
  if [[ "${__GH_READONLY_ACTIVE:-}" == "1" ]]; then
    echo "gh-readonly: ACTIVE"
    echo "  wrapper: $__GH_READONLY_WRAPPER"
    echo "  real gh: $__GH_READONLY_REAL_GH"
    return 0
  else
    echo "gh-readonly: NOT ACTIVE"
    return 1
  fi
}
export -f gh-readonly-status

echo "gh-readonly: read-only mode enabled for this shell session"
echo "gh-readonly: run 'gh-readonly-status' to verify"
