#!/usr/bin/env bash
# SessionStart hook: inject relevant cross-session memories.
# Reads ~/.etcd-druid-plugin/memory.jsonl, decays confidence by time,
# keyword-matches against current repo+branch, injects top-5 entries.
# Never blocks. Exits 0 always.

set -uo pipefail

MEMORY_FILE="${HOME}/.etcd-druid-plugin/memory.jsonl"

if [ ! -f "$MEMORY_FILE" ]; then
    exit 0
fi

# Fix 2: guard against missing jq
if ! command -v jq >/dev/null 2>&1; then
    exit 0
fi

# Detect current repo for keyword context
REPO_CONTEXT=""
if git rev-parse --git-dir >/dev/null 2>&1; then
    REPO_CONTEXT=$(git remote get-url origin 2>/dev/null | sed 's|.*/||;s|\.git$||' || true)
fi

BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")
QUERY="${REPO_CONTEXT} ${BRANCH}"

# Fix 3: hoist now_ts before the loop so date +%s is called once
now_ts=$(date +%s)

# Read entries, compute decayed confidence, keyword-score, pick top 5
# Each line is JSON: {"id":"...","content":"...","tags":["..."],"confidence":0.8,"last_used":1234567890}
MEMORIES=$(while IFS= read -r line; do
    conf=$(printf '%s' "$line" | jq -r '.confidence // 0' 2>/dev/null)
    ts=$(printf '%s' "$line" | jq -r '.last_used // 0' 2>/dev/null)
    content=$(printf '%s' "$line" | jq -r '.content // ""' 2>/dev/null)
    tags=$(printf '%s' "$line" | jq -r '.tags // [] | join(" ")' 2>/dev/null)

    [ -z "$content" ] && continue

    # Decay: 30-day half-life
    # Fix 1: pass shell variables via -v to prevent awk code injection
    days_elapsed=$(awk -v now="$now_ts" -v ts="$ts" \
        'BEGIN {d=(now-ts)/86400; print (d<0)?0:d}')
    decay=$(awk -v conf="$conf" -v d="$days_elapsed" \
        'BEGIN {printf "%.6f", conf * (0.5 ^ (d/30))}')

    # Filter below threshold
    below=$(awk -v decay="$decay" \
        'BEGIN {print (decay < 0.3) ? 1 : 0}')
    [ "$below" = "1" ] && continue

    # Keyword score
    haystack=$(printf '%s %s' "$content" "$tags" | tr '[:upper:]' '[:lower:]')
    score=0
    # Word-split is intentional here — tokenises QUERY into individual search terms
    for tok in $QUERY; do
        tok_lower=$(printf '%s' "$tok" | tr '[:upper:]' '[:lower:]')
        [ -z "$tok_lower" ] && continue
        case "$haystack" in
            *"$tok_lower"*) score=$((score + 1)) ;;
        esac
    done

    [ "$score" -eq 0 ] && continue

    weighted=$(awk -v decay="$decay" -v score="$score" \
        'BEGIN {printf "%.6f", decay * score}')
    printf '%s\t%s\n' "$weighted" "$content"
done < "$MEMORY_FILE" \
    | sort -rn \
    | head -5 \
    | cut -f2-)

if [ -z "$MEMORIES" ]; then
    exit 0
fi

# Build injection block
MEMORY_BLOCK="Remembered from previous sessions:"
while IFS= read -r mem; do
    MEMORY_BLOCK="${MEMORY_BLOCK}
- ${mem}"
done <<< "$MEMORIES"

# Fix 4: drop dead sed variable — pass MEMORY_BLOCK directly to jq
jq -n --arg ctx "$MEMORY_BLOCK" \
    '{"continue":true,"suppressOutput":false,"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":$ctx}}'

# ── Upstream drift detection ──────────────────────────────────────────────────
# If the working directory has an upstream remote and a docs/development/ dir,
# check whether upstream/master has diverged from HEAD on those docs.
# Inject a warning if it has. No-op if no upstream remote or no docs/development/.

DRIFT_MSG=""

if git rev-parse --git-dir >/dev/null 2>&1; then
    REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || true)
    DEV_DOCS="${REPO_ROOT}/docs/development"

    if [ -d "$DEV_DOCS" ]; then
        # Fetch upstream quietly (no-op if no upstream remote)
        git fetch upstream --quiet 2>/dev/null || true

        # Check if docs/development/ differs from upstream/master
        if git rev-parse upstream/master >/dev/null 2>&1; then
            UPSTREAM_DIFF=$(git diff HEAD..upstream/master -- docs/development/ --name-only 2>/dev/null || true)

            if [ -n "$UPSTREAM_DIFF" ]; then
                CHANGED_FILES=$(printf '%s' "$UPSTREAM_DIFF" | head -5 | tr '\n' ',' | sed 's/,$//')
                DRIFT_MSG="Warning: docs/development/ has changed upstream since your last merge. Conventions in these files may differ from what the skills reference: ${CHANGED_FILES}. Read the updated docs before editing source files."
            fi
        fi
    fi
fi

if [ -n "$DRIFT_MSG" ]; then
    # Write drift warning as a high-confidence memory entry so it persists
    bash "$(dirname "$0")/write-memory.sh" \
        "$DRIFT_MSG" \
        "upstream-drift,docs-development,conventions" \
        "0.95" &

    jq -n --arg ctx "$DRIFT_MSG" \
        '{"continue":true,"suppressOutput":false,"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":$ctx}}'
fi

exit 0
