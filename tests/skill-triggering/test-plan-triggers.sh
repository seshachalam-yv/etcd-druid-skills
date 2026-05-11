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

echo "=== Skill Triggering Tests: plan ==="
check "plan" "Use when" "description starts with trigger"
check "plan" "Iron Law" "has Iron Law section"
check "plan" "Gate 1" "has Gate 1 approval"
check "plan" "No Placeholders" "has No Placeholders section"
check "plan" "Self-Review" "has Self-Review section"

echo ""
echo "=== Skill Triggering Tests: general ==="
for skill in plan debug tdd implement review e2e api-change; do
  check "$skill" "Iron Law" "$skill has Iron Law"
done

echo ""
echo "=== Skill Structure Tests: Red Flags ==="
for skill in plan debug tdd worktree-gate api-change review e2e verification receiving-review; do
  check "$skill" "Red Flags\|Why it fails" "$skill has Red Flags or rationalization table"
done

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] || exit 1
