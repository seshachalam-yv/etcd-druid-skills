#!/usr/bin/env bash
set -euo pipefail

SKILL_DIR="$(cd "$(dirname "$0")/../.." && pwd)/skills"
PASS=0
FAIL=0

check() {
  local skill="$1" pattern="$2" label="$3"
  if grep -qi "$pattern" "$SKILL_DIR/$skill/SKILL.md"; then
    echo "[PASS] $skill: $label"
    PASS=$((PASS + 1))
  else
    echo "[FAIL] $skill: $label"
    FAIL=$((FAIL + 1))
  fi
}

echo "=== Skill Triggering Tests: debug ==="
check "debug" "Use when" "description starts with trigger"
check "debug" "Iron Law" "has Iron Law section"
check "debug" "Reproduce" "has reproduction phase"
check "debug" "integration test" "mentions integration tests"
check "debug" "Red Flags" "has Red Flags section"
check "debug" "Worktree" "references worktree gate"

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] || exit 1
