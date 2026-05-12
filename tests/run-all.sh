#!/usr/bin/env bash
set -euo pipefail

TESTS_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "Running all skill tests..."
echo ""

TOTAL_PASS=0
TOTAL_FAIL=0

for test_script in "$TESTS_DIR"/skill-triggering/test-*.sh; do
  if [ -x "$test_script" ]; then
    echo "--- $(basename "$test_script") ---"
    if "$test_script"; then
      echo ""
    else
      TOTAL_FAIL=$((TOTAL_FAIL + 1))
      echo ""
    fi
  fi
done

if [ "$TOTAL_FAIL" -gt 0 ]; then
  echo "FAILED: $TOTAL_FAIL test script(s) had failures"
  exit 1
else
  echo "ALL TEST SCRIPTS PASSED"
fi
