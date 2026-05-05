#!/usr/bin/env bash
# Supabase CLI - Management SQL helpers
set -euo pipefail

CLI_SUPABASE_ENV=""
CLI_SUPABASE_ENV_FILE=""
CLI_SUPABASE_PROJECT=""

# Resolve repo root for env discovery
resolve_repo_root() {
    local script_dir
    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    git -C "$script_dir" rev-parse --show-toplevel 2>/dev/null || echo "$script_dir"
}

# Load env file while preserving any explicitly set vars
load_env_file() {
    local env_file="$1"
    if [[ ! -f "$env_file" ]]; then
        echo "Error: env file not found: $env_file" >&2
        exit 1
    fi

    local original_url="${SUPABASE_URL:-}"
    local original_token="${SUPABASE_ACCESS_TOKEN:-}"

    set -a
    # shellcheck disable=SC1090
    source "$env_file"
    set +a

    if [[ -n "$original_url" ]]; then
        SUPABASE_URL="$original_url"
    fi

    if [[ -n "$original_token" ]]; then
        SUPABASE_ACCESS_TOKEN="$original_token"
    fi
}

load_env_if_needed() {
    if [[ -n "${SUPABASE_URL:-}" && -n "${SUPABASE_ACCESS_TOKEN:-}" ]]; then
        return
    fi

    local repo_root
    repo_root="$(resolve_repo_root)"
    local skill_dir
    skill_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
    local skill_env_dir="${skill_dir}/env"

    if [[ -n "$CLI_SUPABASE_ENV_FILE" ]]; then
        local env_file="$CLI_SUPABASE_ENV_FILE"
        [[ "$env_file" != /* ]] && env_file="${repo_root}/${env_file}"
        load_env_file "$env_file"
        return
    fi

    local skill_env_files=()
    if [[ -d "$skill_env_dir" ]]; then
        shopt -s nullglob
        skill_env_files=( "${skill_env_dir}"/*.env )
        shopt -u nullglob
    fi

    if [[ -n "$CLI_SUPABASE_PROJECT" || -n "$CLI_SUPABASE_ENV" ]]; then
        if [[ -z "$CLI_SUPABASE_PROJECT" || -z "$CLI_SUPABASE_ENV" ]]; then
            if (( ${#skill_env_files[@]} == 1 )); then
                load_env_file "${skill_env_files[0]}"
                return
            fi
            echo "Error: --project and --env must both be set unless skills/supabase/env has exactly one .env file." >&2
            exit 1
        fi

        local project_env_file="${skill_env_dir}/${CLI_SUPABASE_PROJECT}-${CLI_SUPABASE_ENV}.env"
        if [[ -f "$project_env_file" ]]; then
            load_env_file "$project_env_file"
            return
        fi

        echo "Error: Env file not found: ${project_env_file}" >&2
        exit 1
    fi

    if (( ${#skill_env_files[@]} == 1 )); then
        load_env_file "${skill_env_files[0]}"
        return
    fi

    if (( ${#skill_env_files[@]} > 1 )); then
        echo "Error: Multiple env files found in skills/supabase/env. Use --project and --env, or --env-file." >&2
        exit 1
    fi

    if [[ -n "${SUPABASE_ENV_FILE:-}" ]]; then
        local env_file="$SUPABASE_ENV_FILE"
        [[ "$env_file" != /* ]] && env_file="${repo_root}/${env_file}"
        load_env_file "$env_file"
        return
    fi

    if [[ -n "${SUPABASE_ENV:-}" ]]; then
        load_env_file "${repo_root}/.env.supabase.${SUPABASE_ENV}"
        return
    fi

    if [[ -f "${repo_root}/.env.supabase.admin" ]]; then
        load_env_file "${repo_root}/.env.supabase.admin"
        return
    fi

    if [[ -f "${repo_root}/.env.supabase" ]]; then
        load_env_file "${repo_root}/.env.supabase"
        return
    fi

    local matches=()
    local filtered=()
    shopt -s nullglob
    matches=( "${repo_root}/.env.supabase."* )
    shopt -u nullglob

    for file in "${matches[@]}"; do
        case "$file" in
            *.example|*.template|*.sample) ;;
            *) filtered+=( "$file" ) ;;
        esac
    done

    if (( ${#filtered[@]} == 1 )); then
        load_env_file "${filtered[0]}"
        return
    fi

    if (( ${#filtered[@]} > 1 )); then
        echo "Error: Multiple Supabase env files found. Set SUPABASE_ENV or SUPABASE_ENV_FILE." >&2
        exit 1
    fi
}

require_jq() {
    if ! command -v jq >/dev/null 2>&1; then
        echo "Error: jq is required" >&2
        exit 1
    fi
}

ensure_env() {
    load_env_if_needed

    if [[ -z "${SUPABASE_URL:-}" ]]; then
        echo "Error: SUPABASE_URL not set" >&2
        echo "Hint: cp skills/supabase/env/example.env.template skills/supabase/env/<project>-<env>.env and fill in values." >&2
        exit 1
    fi

    if [[ -z "${SUPABASE_ACCESS_TOKEN:-}" ]]; then
        echo "Error: SUPABASE_ACCESS_TOKEN not set (required for management SQL)" >&2
        echo "Hint: cp skills/supabase/env/example.env.template skills/supabase/env/<project>-<env>.env and fill in values." >&2
        exit 1
    fi
}

project_ref() {
    local ref
    ref="${SUPABASE_URL#https://}"
    ref="${ref#http://}"
    ref="${ref%%.supabase.co*}"

    if [[ -z "$ref" ]]; then
        echo "Error: Unable to derive project ref from SUPABASE_URL" >&2
        exit 1
    fi

    echo "$ref"
}

usage() {
    cat << 'USAGE'
Usage: supabase.sh <command> [args]

Commands:
  sql [options] <sql>       Run raw SQL via Supabase management API
  sql-file [options] <path> Run raw SQL from a file via Supabase management API
  help                 Show this help

Options:
  --project <name>     Project name for skills/supabase/env/<project>-<env>.env
  --env <name>         Environment name for skills/supabase/env/<project>-<env>.env
  --env-file <path>    Load env file by path (absolute or repo-relative)

Setup:
  cp skills/supabase/env/example.env.template skills/supabase/env/<project>-<env>.env
  # then fill in SUPABASE_URL and SUPABASE_ACCESS_TOKEN

Examples:
  supabase.sh sql --project my-project --env dev "SELECT * FROM users LIMIT 5"
  supabase.sh sql --project my-project --env prod "SELECT * FROM users LIMIT 5"
  supabase.sh sql-file --project my-project --env dev ./migrations/001_init.sql
USAGE
}

# Parse shared options for sql and sql-file commands
parse_shared_options() {
    CLI_SUPABASE_ENV=""
    CLI_SUPABASE_ENV_FILE=""
    CLI_SUPABASE_PROJECT=""

    while (( $# > 0 )); do
        case "$1" in
            --project)
                [[ -n "${2:-}" ]] || {
                    echo "Error: --project requires a value" >&2
                    exit 1
                }
                CLI_SUPABASE_PROJECT="$2"
                shift 2
                ;;
            --env)
                [[ -n "${2:-}" ]] || {
                    echo "Error: --env requires a value" >&2
                    exit 1
                }
                CLI_SUPABASE_ENV="$2"
                shift 2
                ;;
            --env-file)
                [[ -n "${2:-}" ]] || {
                    echo "Error: --env-file requires a value" >&2
                    exit 1
                }
                CLI_SUPABASE_ENV_FILE="$2"
                shift 2
                ;;
            --)
                shift
                break
                ;;
            -*)
                echo "Error: Unknown option: $1" >&2
                exit 1
                ;;
            *)
                break
                ;;
        esac
    done

    if [[ -n "$CLI_SUPABASE_ENV" && -n "$CLI_SUPABASE_ENV_FILE" ]]; then
        echo "Error: Use either --env or --env-file, not both" >&2
        exit 1
    fi

    if [[ -n "$CLI_SUPABASE_PROJECT" && -n "$CLI_SUPABASE_ENV_FILE" ]]; then
        echo "Error: Use either --project/--env or --env-file, not both" >&2
        exit 1
    fi

    REMAINING_ARGS=( "$@" )
}

# Run raw SQL via Supabase management API (returns results)
execute_sql() {
    local sql="$1"
    if [[ -z "$sql" ]]; then
        echo "Error: SQL query required" >&2
        exit 1
    fi

    ensure_env
    require_jq

    local ref
    ref="$(project_ref)"

    local payload
    payload=$(jq -n --arg q "$sql" '{query: $q}')
    curl -s -X POST "https://api.supabase.com/v1/projects/${ref}/database/query" \
        -H "Authorization: Bearer ${SUPABASE_ACCESS_TOKEN}" \
        -H "Content-Type: application/json" \
        -d "$payload" | jq .
}

# Run raw SQL via Supabase management API (returns results)
cmd_sql() {
    parse_shared_options "$@"

    local sql="${REMAINING_ARGS[*]-}"
    execute_sql "$sql"
}

# Run raw SQL from file via Supabase management API
cmd_sql_file() {
    parse_shared_options "$@"

    local path="${REMAINING_ARGS[0]-}"
    if [[ -z "$path" ]]; then
        echo "Error: SQL file path required" >&2
        exit 1
    fi

    if [[ ! -f "$path" ]]; then
        echo "Error: SQL file not found: $path" >&2
        exit 1
    fi

    local sql
    sql="$(cat "$path")"
    if [[ -z "$sql" ]]; then
        echo "Error: SQL file is empty: $path" >&2
        exit 1
    fi

    execute_sql "$sql"
}

# Main
case "${1:-help}" in
    sql)
        shift
        cmd_sql "$@"
        ;;
    sql-file)
        shift
        cmd_sql_file "$@"
        ;;
    help|--help|-h)
        usage
        ;;
    *)
        echo "Unknown command: $1" >&2
        usage
        exit 1
        ;;
esac
