#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export OUTPUT_BASE="${OUTPUT_BASE:-/tmp/etcd-druid-skills-tests/$(date +%s)}"

passed=0; failed=0

for scenario in "$SCRIPT_DIR/scenarios/"*.md; do
    name=$(basename "$scenario" .md)
    if bash "$SCRIPT_DIR/run-scenario.sh" "$scenario"; then
        echo "[PASS] $name"
        passed=$((passed+1))
    else
        echo "[FAIL] $name"
        failed=$((failed+1))
    fi
    echo ""
done

echo "Compliance tests: $passed passed, $failed failed"

echo ""
echo "--- Generating highlights ---"
python3 "$SCRIPT_DIR/../report.py" "$OUTPUT_BASE" || true

[ $failed -eq 0 ]
