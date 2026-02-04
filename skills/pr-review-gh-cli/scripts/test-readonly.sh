#!/usr/bin/env bash
# Test script to verify read-only enforcement works correctly.
# Run this to validate the security wrapper.
#
# Usage: ./test-readonly.sh
#
# Note: Some tests require network access and valid gh auth.
# The wrapper blocking tests work regardless of auth status.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PASS=0
FAIL=0

# Colors (disabled if not a terminal)
if [[ -t 1 ]]; then
  RED='\033[0;31m'
  GREEN='\033[0;32m'
  YELLOW='\033[1;33m'
  NC='\033[0m'
else
  RED=''
  GREEN=''
  YELLOW=''
  NC=''
fi

pass() {
  echo -e "${GREEN}PASS${NC}: $1"
  ((PASS++)) || true
}

fail() {
  echo -e "${RED}FAIL${NC}: $1"
  ((FAIL++)) || true
}

info() {
  echo -e "${YELLOW}INFO${NC}: $1"
}

# Test that output contains expected pattern (blocking tests)
run_blocked_test() {
  local name="$1"
  shift
  local cmd="$*"
  
  local output exit_code=0
  output=$(bash -c "source '$SCRIPT_DIR/env.sh' 2>/dev/null && $cmd" 2>&1) || exit_code=$?
  
  if [[ $exit_code -eq 2 ]] && echo "$output" | grep -q "gh-readonly: blocked"; then
    pass "$name"
  else
    fail "$name (exit=$exit_code, expected=2)"
    echo "      Output: $output"
  fi
}

# Test that a command is allowed (not blocked by wrapper)
run_allowed_test() {
  local name="$1"
  shift
  local cmd="$*"
  
  local output exit_code=0
  output=$(bash -c "source '$SCRIPT_DIR/env.sh' 2>/dev/null && $cmd" 2>&1) || exit_code=$?
  
  # Wrapper blocks with exit 2; any other exit means wrapper allowed it
  if [[ $exit_code -ne 2 ]] && ! echo "$output" | grep -q "gh-readonly: blocked"; then
    pass "$name"
  else
    fail "$name (unexpectedly blocked)"
    echo "      Output: $output"
  fi
}

echo "========================================"
echo "Testing gh-readonly enforcement"
echo "========================================"
echo

info "Testing BLOCKED commands (must exit 2 with 'blocked' message)..."
echo

run_blocked_test "gh pr create" "gh pr create --title test --body test"
run_blocked_test "gh pr merge" "gh pr merge 1"
run_blocked_test "gh pr close" "gh pr close 1"
run_blocked_test "gh pr comment" "gh pr comment 1 --body test"
run_blocked_test "gh pr edit" "gh pr edit 1 --title test"
run_blocked_test "gh pr review" "gh pr review 1 --approve"
run_blocked_test "gh issue create" "gh issue create --title test --body test"
run_blocked_test "gh issue close" "gh issue close 1"
run_blocked_test "gh auth login" "gh auth login"
run_blocked_test "gh repo create" "gh repo create test"
run_blocked_test "gh api POST" "gh api -X POST /repos/test/test/issues"
run_blocked_test "gh api DELETE" "gh api -X DELETE /repos/test/test/issues/1"
run_blocked_test "gh api PATCH" "gh api -X PATCH /repos/test/test/issues/1"
run_blocked_test "gh api with -f body" "gh api /repos/test/test/issues -f title=test"
run_blocked_test "gh api with -F body" "gh api /repos/test/test/issues -F title=test"
run_blocked_test "gh api disallowed endpoint" "gh api /repos/test/test/labels"

echo
info "Testing BYPASS attempts (must be intercepted)..."
echo

run_blocked_test "command gh pr merge" "command gh pr merge 1"
run_blocked_test "command -p gh pr merge" "command -p gh pr merge 1"
run_blocked_test "env gh" "env gh pr list"

echo
info "Testing ALLOWED commands (wrapper must not block)..."
echo

run_allowed_test "gh pr list --help" "gh pr list --help"
run_allowed_test "gh pr view --help" "gh pr view --help"
run_allowed_test "gh pr diff --help" "gh pr diff --help"
run_allowed_test "gh pr checks --help" "gh pr checks --help"
run_allowed_test "gh issue view --help" "gh issue view --help"
run_allowed_test "gh search code --help" "gh search code --help"
run_allowed_test "gh search issues --help" "gh search issues --help"
run_allowed_test "gh auth status" "gh auth status || true"  # may fail if not authed

echo
info "Testing status function..."
echo

output=$(bash -c "source '$SCRIPT_DIR/env.sh' 2>/dev/null && gh-readonly-status" 2>&1)
if echo "$output" | grep -q "ACTIVE"; then
  pass "gh-readonly-status shows ACTIVE"
else
  fail "gh-readonly-status"
  echo "      Output: $output"
fi

echo
echo "========================================"
echo -e "Results: ${GREEN}$PASS passed${NC}, ${RED}$FAIL failed${NC}"
echo "========================================"

[[ $FAIL -eq 0 ]]
