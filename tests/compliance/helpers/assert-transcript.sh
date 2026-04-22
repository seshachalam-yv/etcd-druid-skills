#!/usr/bin/env bash
# Shared helpers for parsing Claude stream-json transcripts

# assert_skill_invoked LOG_FILE SKILL_NAME TEST_NAME
# Passes if the Skill tool was called with the given skill name
assert_skill_invoked() {
    local log="$1" skill="$2" test_name="${3:-assert_skill_invoked}"
    local pattern='"skill":"([^"]*:)?'"${skill}"'"'
    if grep -q '"name":"Skill"' "$log" && grep -qE "$pattern" "$log"; then
        echo "  [PASS] $test_name: skill '$skill' was invoked"
        return 0
    else
        echo "  [FAIL] $test_name: skill '$skill' was NOT invoked"
        echo "  Skills actually invoked:"
        grep -o '"skill":"[^"]*"' "$log" 2>/dev/null | sort -u | sed 's/^/    /' || echo "    (none)"
        return 1
    fi
}

# assert_skill_not_invoked LOG_FILE SKILL_NAME TEST_NAME
assert_skill_not_invoked() {
    local log="$1" skill="$2" test_name="${3:-assert_skill_not_invoked}"
    local pattern='"skill":"([^"]*:)?'"${skill}"'"'
    if grep -qE "$pattern" "$log" 2>/dev/null; then
        echo "  [FAIL] $test_name: skill '$skill' was unexpectedly invoked"
        return 1
    else
        echo "  [PASS] $test_name: skill '$skill' was correctly NOT invoked"
        return 0
    fi
}

# assert_text_contains LOG_FILE PATTERN TEST_NAME
# Checks assistant text output (not tool calls) for a pattern
assert_text_contains() {
    local log="$1" pattern="$2" test_name="${3:-assert_text_contains}"
    local text
    text=$(grep '"type":"assistant"' "$log" | jq -r '.message.content[]? | select(.type=="text") | .text' 2>/dev/null | tr '\n' ' ')
    if echo "$text" | grep -qiE "$pattern"; then
        echo "  [PASS] $test_name: found '$pattern' in assistant output"
        return 0
    else
        echo "  [FAIL] $test_name: '$pattern' NOT found in assistant output"
        echo "  Output (first 300 chars): ${text:0:300}"
        return 1
    fi
}

# assert_text_not_contains LOG_FILE PATTERN TEST_NAME
assert_text_not_contains() {
    local log="$1" pattern="$2" test_name="${3:-assert_text_not_contains}"
    local text
    text=$(grep '"type":"assistant"' "$log" | jq -r '.message.content[]? | select(.type=="text") | .text' 2>/dev/null | tr '\n' ' ')
    if echo "$text" | grep -qiE "$pattern"; then
        echo "  [FAIL] $test_name: '$pattern' unexpectedly found in assistant output"
        echo "  Output (first 300 chars): ${text:0:300}"
        return 1
    else
        echo "  [PASS] $test_name: '$pattern' correctly absent from assistant output"
        return 0
    fi
}

# assert_iron_law_respected LOG_FILE FORBIDDEN_PATTERN TEST_NAME
# Checks that the agent did NOT take a forbidden action (e.g., writing code before Gate 1)
assert_iron_law_respected() {
    local log="$1" forbidden_pattern="$2" test_name="${3:-iron_law}"
    local tool_calls
    tool_calls=$(grep '"type":"assistant"' "$log" | jq -r '.message.content[]? | select(.type=="tool_use") | .name' 2>/dev/null | tr '\n' ' ')
    if echo "$tool_calls" | grep -qiE "$forbidden_pattern"; then
        echo "  [FAIL] $test_name: Iron Law violated — forbidden action '$forbidden_pattern' was taken"
        echo "  Tool calls made: $tool_calls"
        return 1
    else
        echo "  [PASS] $test_name: Iron Law respected — '$forbidden_pattern' was not invoked"
        return 0
    fi
}

export -f assert_skill_invoked
export -f assert_skill_not_invoked
export -f assert_text_contains
export -f assert_text_not_contains
export -f assert_iron_law_respected
