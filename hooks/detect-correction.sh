#!/usr/bin/env bash
# UserPromptSubmit hook: detect user correction phrases.
#
# When a user corrects Claude ("that's wrong", "actually it's", "the skill says X but..."),
# this hook writes a flag file that observe-plugin-improvement.sh reads to decide
# whether to run the LLM evaluator on the next Stop event.
#
# This targets the most valuable signal: user corrections have perfect ground truth.
# Without this gate, the Stop hook would call the LLM evaluator on every response.

set -uo pipefail

PAYLOAD=$(cat)
SESSION_ID=$(printf '%s' "$PAYLOAD" | jq -r '.session_id // "default"' 2>/dev/null || echo "default")

# Extract the user's message text
USER_MESSAGE=$(printf '%s' "$PAYLOAD" | jq -r '.message // empty' 2>/dev/null || true)

if [ -z "$USER_MESSAGE" ]; then
    exit 0
fi

# Normalise to lowercase for matching
MSG_LOWER=$(printf '%s' "$USER_MESSAGE" | tr '[:upper:]' '[:lower:]')

# Correction signal patterns — phrases that strongly indicate Claude said something wrong
# or that the plugin guidance was missing/incorrect
CORRECTION_DETECTED=false

correction_patterns=(
    "that'?s wrong"
    "that is wrong"
    "not correct"
    "incorrect"
    "actually it'?s"
    "actually the"
    "actually,? it"
    "the skill says.*but"
    "the docs say.*but"
    "plugin says.*but"
    "you said.*but"
    "that'?s not right"
    "that'?s not how"
    "no,? the"
    "wrong,? the"
    "mistake"
    "you'?re wrong"
    "that'?s incorrect"
    "not accurate"
    "outdated"
    "stale"
    "no longer"
    "was removed"
    "doesn'?t exist"
    "doesn'?t work"
    "wrong flag"
    "wrong command"
    "wrong path"
    "wrong target"
    "wrong version"
)

for pattern in "${correction_patterns[@]}"; do
    if printf '%s' "$MSG_LOWER" | grep -qE "$pattern"; then
        CORRECTION_DETECTED=true
        break
    fi
done

if [ "$CORRECTION_DETECTED" = "true" ]; then
    # Write flag file — Stop hook reads this to decide whether to run LLM evaluator
    FLAG_FILE="/tmp/etcd-druid-correction-${SESSION_ID}"
    printf '%s' "$USER_MESSAGE" > "$FLAG_FILE"
fi

# Never block — always exit 0
exit 0
