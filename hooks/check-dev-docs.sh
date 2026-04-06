#!/usr/bin/env bash
# PostToolUse hook: nudge Claude to read docs/development/ before editing source files
# Triggers when Claude edits a .go file without having read any docs/development/ file first.
# Light-touch — outputs a reminder, never blocks.

set -euo pipefail

# Only care about Edit/Write tool calls on .go files
TOOL_NAME="${CLAUDE_TOOL_NAME:-}"
FILE_PATH="${CLAUDE_TOOL_INPUT_file_path:-}"

if [[ "$TOOL_NAME" != "Edit" && "$TOOL_NAME" != "Write" ]]; then
    exit 0
fi

# Only trigger for .go source files (not test helpers, not generated files)
if [[ "$FILE_PATH" != *.go ]]; then
    exit 0
fi

# Skip generated files — they have their own guard
if [[ "$FILE_PATH" == *zz_generated* || "$FILE_PATH" == */client/* ]]; then
    exit 0
fi

# Check if we're inside one of the three repos
repo_root=$(git -C "$(dirname "$FILE_PATH")" rev-parse --show-toplevel 2>/dev/null || true)
if [ -z "$repo_root" ]; then
    exit 0
fi

# Check if docs/development/ exists in this repo
if [ ! -d "$repo_root/docs/development" ]; then
    exit 0
fi

# Emit a reminder — Claude will see this as tool output context
cat <<EOF
{
  "continue": true,
  "suppressOutput": true,
  "hookSpecificOutput": {
    "hookEventName": "PostToolUse",
    "additionalContext": "Reminder: before editing source files, read the relevant files in ${repo_root}/docs/development/ — they are the authoritative source for conventions, patterns, and make targets in this repo. If you discover a pattern not yet documented there, add it as part of this task."
  }
}
EOF

exit 0
