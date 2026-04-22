#!/usr/bin/env bash
# Run one trigger test case.
# Usage: ./run-test.sh <case.yaml>
# A case.yaml has fields: prompt, expected_skill, must_not_invoke (optional list)
set -euo pipefail

CASE_FILE="$1"
if [ -z "$CASE_FILE" ] || [ ! -f "$CASE_FILE" ]; then
    echo "Usage: $0 <case.yaml>"
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$SCRIPT_DIR/../compliance/helpers/assert-transcript.sh"

# Parse YAML fields (simple key: value, no nested)
get_yaml_field() {
    local file="$1" field="$2"
    grep "^${field}:" "$file" | head -1 | sed "s/^${field}:[[:space:]]*//" | tr -d '"'
}
get_yaml_list() {
    local file="$1" field="$2"
    awk "/^${field}:/{flag=1;next} /^[^ ]/{flag=0} flag && /^  - /{print}" "$file" | sed 's/.*- //'
}

PROMPT=$(get_yaml_field "$CASE_FILE" "prompt")
EXPECTED_SKILL=$(get_yaml_field "$CASE_FILE" "expected_skill")
CASE_NAME=$(basename "$CASE_FILE" .yaml)

TIMESTAMP="${OUTPUT_BASE:-/tmp/etcd-druid-skills-tests/$(date +%s)}"
OUTPUT_DIR="$TIMESTAMP/trigger/$CASE_NAME"
mkdir -p "$OUTPUT_DIR"
LOG_FILE="$OUTPUT_DIR/claude-output.json"
START_TIME=$SECONDS

echo "=== Trigger Test: $CASE_NAME ==="
echo "Expected skill: ${EXPECTED_SKILL:-'(none)'}"
echo "Prompt: ${PROMPT:0:80}..."
echo ""

timeout 180 claude -p "$PROMPT" \
    --plugin-dir "$PLUGIN_DIR" \
    --dangerously-skip-permissions \
    --max-turns 3 \
    --verbose \
    --output-format stream-json \
    > "$LOG_FILE" 2>&1 || true

passed=0; failed=0

if [ -n "$EXPECTED_SKILL" ] && [ "$EXPECTED_SKILL" != "none" ]; then
    if assert_skill_invoked "$LOG_FILE" "$EXPECTED_SKILL" "expected skill invoked"; then
        passed=$((passed+1))
    else
        failed=$((failed+1))
    fi
else
    # Negative test: no skill should be invoked
    if ! grep -q '"name":"Skill"' "$LOG_FILE" 2>/dev/null; then
        echo "  [PASS] negative test: no skill invoked"
        passed=$((passed+1))
    else
        echo "  [FAIL] negative test: a skill was unexpectedly invoked"
        grep -o '"skill":"[^"]*"' "$LOG_FILE" | sort -u | sed 's/^/    /'
        failed=$((failed+1))
    fi
fi

# Check must_not_invoke list
while IFS= read -r forbidden; do
    [ -z "$forbidden" ] && continue
    if assert_skill_not_invoked "$LOG_FILE" "$forbidden" "must_not_invoke: $forbidden"; then
        passed=$((passed+1))
    else
        failed=$((failed+1))
    fi
done < <(get_yaml_list "$CASE_FILE" "must_not_invoke")

echo ""
echo "Result: $passed passed, $failed failed  |  Log: $LOG_FILE"

# Write sidecar for report.py
START_TIME="${START_TIME:-$SECONDS}"
python3 -c "
import json
r = {
    'name': '${CASE_NAME}',
    'suite': 'trigger',
    'result': 'passed' if ${failed} == 0 else 'failed',
    'failure_message': None if ${failed} == 0 else 'trigger assertion failed — check log',
    'duration_s': $((SECONDS - START_TIME)),
}
with open('${OUTPUT_DIR}/result.json', 'w') as f:
    json.dump(r, f)
" 2>/dev/null || true

[ $failed -eq 0 ]
