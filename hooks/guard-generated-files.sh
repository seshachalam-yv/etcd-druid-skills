#!/usr/bin/env bash
# PreToolUse hook: block edits to generated files.
# Generated files must only be produced by `cd api && make generate` — never manually edited.
# This hook fires BEFORE the Edit/Write tool executes and can block the operation.

set -euo pipefail

TOOL_NAME="${CLAUDE_TOOL_NAME:-}"
FILE_PATH="${CLAUDE_TOOL_INPUT_file_path:-${CLAUDE_TOOL_INPUT_filePath:-}}"

if [[ "$TOOL_NAME" != "Edit" && "$TOOL_NAME" != "Write" ]]; then
    exit 0
fi

if [ -z "$FILE_PATH" ]; then
    exit 0
fi

# Normalise to basename checks and pattern matches
BASENAME=$(basename "$FILE_PATH")

PLUGIN_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PATTERNS_FILE="${PLUGIN_ROOT}/.claude-plugin/generated-file-patterns.txt"

if [ ! -f "$PATTERNS_FILE" ]; then
    exit 0
fi

blocked=false
reason=""

# Read patterns file — skip comments and empty lines
while IFS='|' read -r pattern block_reason; do
    # Skip comments and empty
    case "$pattern" in
        \#*|"") continue ;;
    esac

    # Match pattern against basename (for simple patterns) or full path (for glob patterns)
    # shellcheck disable=SC2254
    case "$FILE_PATH" in
        $pattern) blocked=true; reason="$block_reason"; break ;;
    esac
    case "$BASENAME" in
        $pattern) blocked=true; reason="$block_reason"; break ;;
    esac
done < "$PATTERNS_FILE"

if [ "$blocked" = true ]; then
    cat <<EOF
{
  "decision": "block",
  "reason": "BLOCKED: This is a generated file. ${reason} To regenerate: cd api && make generate"
}
EOF
    exit 0
fi

# Not a generated file — allow the edit
exit 0
