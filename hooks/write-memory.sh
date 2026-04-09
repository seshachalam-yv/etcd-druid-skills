#!/usr/bin/env bash
# Write a new entry to ~/.etcd-druid-plugin/memory.jsonl.
# Usage: write-memory.sh "<content>" "<tag1,tag2,tag3>" [confidence]
# content: the memory text (keep under 200 chars for injection readability)
# tags: comma-separated keywords for recall scoring
# confidence: float 0.0-1.0, defaults to 0.8

set -uo pipefail

CONTENT="${1:-}"
TAGS_CSV="${2:-}"
CONFIDENCE="${3:-0.8}"

if [ -z "$CONTENT" ]; then
    exit 0
fi

if ! command -v jq >/dev/null 2>&1; then
    exit 0
fi

MEMORY_FILE="${HOME}/.etcd-druid-plugin/memory.jsonl"
mkdir -p "$(dirname "$MEMORY_FILE")"

# Generate ID from timestamp + content hash (portable: macOS uses md5, Linux uses md5sum)
if command -v md5sum >/dev/null 2>&1; then
    HASH=$(printf '%s' "$CONTENT" | md5sum | cut -c1-6)
elif command -v md5 >/dev/null 2>&1; then
    HASH=$(printf '%s' "$CONTENT" | md5 | cut -c1-6)
else
    HASH=$(date +%N 2>/dev/null | cut -c1-6 || echo "000000")
fi
ID="mem-$(date +%s)-${HASH}"
NOW=$(date +%s)

# Convert comma-separated tags to JSON array using jq
TAGS_JSON=$(printf '%s' "$TAGS_CSV" | tr ',' '\n' \
    | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' \
    | grep -v '^$' \
    | jq -R . \
    | jq -s . 2>/dev/null || echo '[]')

# Deduplicate: skip if first 60 chars of content already exists in any stored entry
CONTENT_PREFIX=$(printf '%s' "$CONTENT" | cut -c1-60)
if [ -f "$MEMORY_FILE" ] && jq -r '.content' "$MEMORY_FILE" 2>/dev/null | grep -qF "$CONTENT_PREFIX"; then
    exit 0
fi

# Validate confidence is a JSON number; fall back to 0.8 if not
if ! printf '%s' "$CONFIDENCE" | jq -e 'type == "number"' >/dev/null 2>&1; then
    CONFIDENCE="0.8"
fi

# Build and append entry using jq for safe JSON construction
jq -n \
    --arg id "$ID" \
    --arg content "$CONTENT" \
    --argjson tags "$TAGS_JSON" \
    --argjson confidence "$CONFIDENCE" \
    --argjson last_used "$NOW" \
    '{id: $id, content: $content, tags: $tags, confidence: $confidence, last_used: $last_used}' \
    >> "$MEMORY_FILE"

exit 0
