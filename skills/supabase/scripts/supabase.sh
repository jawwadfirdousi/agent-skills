#!/usr/bin/env bash
# Supabase CLI - Management SQL helpers
set -euo pipefail

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
        exit 1
    fi

    if [[ -z "${SUPABASE_ACCESS_TOKEN:-}" ]]; then
        echo "Error: SUPABASE_ACCESS_TOKEN not set (required for management SQL)" >&2
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
  sql <sql>            Run raw SQL via Supabase management API
  sql-file <path>      Run raw SQL from a file via Supabase management API
  help                 Show this help

Examples:
  supabase.sh sql "SELECT * FROM users LIMIT 5"
  supabase.sh sql-file ./migrations/001_init.sql
USAGE
}

# Run raw SQL via Supabase management API (returns results)
cmd_sql() {
    local sql="${1:-}"
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

# Run raw SQL from file via Supabase management API
cmd_sql_file() {
    local path="${1:-}"
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

    cmd_sql "$sql"
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
