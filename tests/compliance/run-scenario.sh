#!/usr/bin/env bash
# Run one compliance scenario.
# Usage: ./run-scenario.sh <scenario.md>
# A scenario.md has a YAML front-matter block with fields:
#   skill, iron_law_id, forbidden_tool_pattern, pressure_prompt
set -euo pipefail

SCENARIO_FILE="$1"
if [ -z "$SCENARIO_FILE" ] || [ ! -f "$SCENARIO_FILE" ]; then
    echo "Usage: $0 <scenario.md>"
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$SCRIPT_DIR/helpers/assert-transcript.sh"

# Extract front-matter field
get_fm_field() {
    local file="$1" field="$2"
    awk "/^---$/{if(++c==2)exit} c==1 && /^${field}:/{print}" "$file" \
        | head -1 | sed "s/^${field}:[[:space:]]*//" | tr -d '"'
}
# Extract the pressure_prompt block (everything after second ---)
get_prompt() {
    awk '/^---$/{c++;next} c>=2{print}' "$1"
}

SKILL=$(get_fm_field "$SCENARIO_FILE" "skill")
IRON_LAW_ID=$(get_fm_field "$SCENARIO_FILE" "iron_law_id")
FORBIDDEN_PATTERN=$(get_fm_field "$SCENARIO_FILE" "forbidden_tool_pattern")
PROMPT=$(get_prompt "$SCENARIO_FILE")
SCENARIO_NAME=$(basename "$SCENARIO_FILE" .md)

TIMESTAMP="${OUTPUT_BASE:-/tmp/etcd-druid-skills-tests/$(date +%s)}"
OUTPUT_DIR="$TIMESTAMP/compliance/$SCENARIO_NAME"
mkdir -p "$OUTPUT_DIR"
LOG_FILE="$OUTPUT_DIR/claude-output.json"
START_TIME=$SECONDS

echo "=== Compliance Test: $SCENARIO_NAME ==="
echo "Skill: $SKILL  |  Iron Law: $IRON_LAW_ID"
echo "Forbidden action pattern: $FORBIDDEN_PATTERN"
echo ""

timeout 300 claude -p "$PROMPT" \
    --plugin-dir "$PLUGIN_DIR" \
    --dangerously-skip-permissions \
    --max-turns 5 \
    --verbose \
    --output-format stream-json \
    > "$LOG_FILE" 2>&1 || true

passed=0; failed=0

# 1. Correct skill must have been invoked
if assert_skill_invoked "$LOG_FILE" "$SKILL" "skill invoked"; then
    passed=$((passed+1))
else
    failed=$((failed+1))
fi

# 2. Iron Law must not be violated (forbidden tool not called)
if assert_iron_law_respected "$LOG_FILE" "$FORBIDDEN_PATTERN" "Iron Law respected ($IRON_LAW_ID)"; then
    passed=$((passed+1))
else
    failed=$((failed+1))
fi

# 3. Token usage report (informational, never fails)
echo ""
echo "Token usage:"
python3 "$SCRIPT_DIR/helpers/analyze-tokens.py" "$LOG_FILE" 2>/dev/null || echo "  (token analysis unavailable)"

echo ""
echo "Result: $passed passed, $failed failed  |  Log: $LOG_FILE"

# Write sidecar for report.py
_DURATION=$((SECONDS - START_TIME))
_RESULT=$([ $failed -eq 0 ] && echo "passed" || echo "failed")
_MSG=$([ $failed -eq 0 ] && echo "" || echo "compliance assertion failed — check log")
SCENARIO_NAME="$SCENARIO_NAME" OUTPUT_DIR="$OUTPUT_DIR" _DURATION="$_DURATION" \
  _RESULT="$_RESULT" _MSG="$_MSG" \
  python3 -c "
import json, os
r = {
    'name':            os.environ['SCENARIO_NAME'],
    'suite':           'compliance',
    'result':          os.environ['_RESULT'],
    'failure_message': os.environ['_MSG'] or None,
    'duration_s':      int(os.environ['_DURATION']),
}
with open(os.path.join(os.environ['OUTPUT_DIR'], 'result.json'), 'w') as f:
    json.dump(r, f)
" 2>/dev/null || true

[ $failed -eq 0 ]
