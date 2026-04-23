#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TIMESTAMP=$(date +%s)
export OUTPUT_BASE="/tmp/etcd-druid-skills-tests/${TIMESTAMP}"
mkdir -p "$OUTPUT_BASE"

echo "========================================"
echo " etcd-druid-skills Test Suite"
echo "========================================"
echo "Time: $(date)"
echo "Claude: $(claude --version 2>/dev/null || echo 'not found')"
echo "Output: $OUTPUT_BASE"
echo ""

if ! command -v claude &>/dev/null; then
    echo "ERROR: claude CLI not found"
    exit 1
fi

passed=0; failed=0

run_suite() {
    local name="$1" script="$2"
    echo "--- $name ---"
    if bash "$script"; then
        echo "[PASS] $name"
        passed=$((passed + 1))
    else
        echo "[FAIL] $name"
        failed=$((failed + 1))
    fi
    echo ""
}

run_suite "Trigger Tests"     "$SCRIPT_DIR/trigger/run-all.sh"
run_suite "Compliance Tests"  "$SCRIPT_DIR/compliance/run-all.sh"

echo "========================================"
echo " Results: $passed passed, $failed failed"
echo "========================================"

echo ""
echo "--- Generating combined highlights ---"
python3 "$SCRIPT_DIR/report.py" "$OUTPUT_BASE" || true

[ $failed -eq 0 ]
