#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export OUTPUT_BASE="${OUTPUT_BASE:-/tmp/etcd-druid-skills-tests/$(date +%s)}"

passed=0; failed=0

for case_file in "$SCRIPT_DIR/cases/"*.yaml; do
    name=$(basename "$case_file" .yaml)
    if bash "$SCRIPT_DIR/run-test.sh" "$case_file"; then
        echo "[PASS] $name"
        passed=$((passed+1))
    else
        echo "[FAIL] $name"
        failed=$((failed+1))
    fi
    echo ""
done

echo "Trigger tests: $passed passed, $failed failed"

echo ""
echo "--- Generating highlights ---"
python3 "$SCRIPT_DIR/../report.py" "$OUTPUT_BASE" || true

[ $failed -eq 0 ]
