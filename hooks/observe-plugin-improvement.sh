#!/usr/bin/env bash
# Stop hook: use Claude to evaluate whether the just-completed response reveals
# a specific, actionable improvement to the etcd-druid-skills plugin itself.
#
# Runs async (non-blocking). Writes observations to $PLUGIN_ROOT/plugin-observations.md.
# Never blocks the Stop event — exits 0 always.

set -uo pipefail

PLUGIN_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OBSERVATIONS_FILE="${PLUGIN_ROOT}/plugin-observations.md"

# Read Stop hook payload from stdin
PAYLOAD=$(cat)

LAST_MESSAGE=$(printf '%s' "$PAYLOAD" | jq -r '.last_assistant_message // empty' 2>/dev/null || true)

# Skip if message is too short to contain a plugin-level observation
if [ -z "$LAST_MESSAGE" ] || [ "${#LAST_MESSAGE}" -lt 200 ]; then
    exit 0
fi

# Build the evaluation prompt — Claude evaluates whether the response reveals a plugin gap
EVAL_PROMPT=$(cat <<'PROMPT_EOF'
You are reviewing a Claude Code assistant response to determine whether it reveals a specific, actionable improvement to the etcd-druid-skills plugin — a Claude Code plugin that helps contributors work on etcd-druid, etcd-backup-restore, and etcd-wrapper.

The plugin consists of:
- skills/feature-dev/SKILL.md — feature development workflow (phases, gates, subagent loop)
- skills/api-change/SKILL.md — API field design, CEL validation, two-commit generate workflow
- skills/tdd/SKILL.md — test framework per repo, TDD cycle, fake client patterns
- skills/tdd/testing-anti-patterns.md — known anti-patterns with code examples
- skills/debug/SKILL.md — systematic debugging across three repos
- skills/review/SKILL.md — pre-PR checklist, footguns list, verdict format
- skills/e2e/SKILL.md — KIND cluster setup, custom image builds, sidecar overrides
- skills/reference/SKILL.md — make targets, file paths, flags, feature gates, EtcdOpsTask
- skills/verification/SKILL.md — verification gate referenced by tdd/debug/feature-dev
- skills/receiving-review/SKILL.md — handling incoming review feedback
- hooks/session-start — orientation injected at session start (component system, invariants, skills list)
- hooks/guard-generated-files.sh — PreToolUse hook blocking edits to generated files
- hooks/check-dev-docs.sh — PostToolUse hook nudging Claude to read docs/development/

## Your task

Read the response below and answer ONE question:

Does this response contain evidence that a specific part of the plugin is WRONG, INCOMPLETE, or MISLEADING in a way that would cause future Claude sessions to make the same mistake?

## Rules for what qualifies

QUALIFY — plugin-level observations:
- A skill stated that a flag, make target, file path, or type exists — and the response shows it does not (or was removed)
- A skill said to do X in situation S — but doing X in situation S caused a problem the skill did not warn about
- Claude encountered a convention that no skill documents, and this convention applies across sessions (not just to this task)
- A workflow step in a skill was unclear or caused Claude to go the wrong direction — the ambiguity is in the skill text, not the task
- A footgun was encountered that is not in skills/review/SKILL.md Known Footguns section
- The session-start hook stated something factually wrong about the component system
- A rationalization was used to bypass an Iron Law that no rationalization table currently covers

DO NOT QUALIFY — task-specific or too vague:
- This specific PR/task/component needs X (even if X is interesting)
- A general Go, Kubernetes, or etcd observation not tied to plugin guidance
- Something Claude is uncertain about — "I think this might be wrong" is not enough
- A pattern specific to one codebase location and unlikely to recur
- A suggestion to add more content when the existing content is correct

## Confidence threshold

Only output an observation if ALL THREE are true:
1. You can name the EXACT plugin file and section that is wrong or missing
2. You can state the EXACT wrong/missing text or guidance
3. You can state what the CORRECT text should be, specific enough that someone could write the fix without further investigation

If you cannot satisfy all three, output null.

## Output format

If an observation qualifies, output this JSON and nothing else:

{
  "type": "wrong_claim" | "missing_convention" | "missing_footgun" | "unclear_workflow" | "stale_path_or_flag" | "missing_iron_law_rationalization",
  "confidence": "high" | "medium",
  "plugin_file": "<path relative to plugin root, e.g. skills/review/SKILL.md>",
  "plugin_section": "<heading or section name where the issue lives>",
  "wrong_text": "<exact text in the skill that is wrong, or MISSING if content does not exist yet>",
  "correct_text": "<what the text should say, specific enough to write the fix>",
  "evidence": "<the specific sentence or action in the response that revealed this — quote it directly>"
}

If no observation qualifies, output exactly:
null

Do not output explanation, commentary, or multiple observations. One observation or null.

## Response to evaluate

PROMPT_EOF
)

# Call Claude to evaluate — use --bare to skip plugin/hook overhead
EVAL_OUTPUT=$(printf '%s\n\n%s' "$EVAL_PROMPT" "$LAST_MESSAGE" \
    | timeout 45 claude --bare -p --output-format text 2>/dev/null || true)

# Trim whitespace
EVAL_OUTPUT=$(printf '%s' "$EVAL_OUTPUT" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

# If output is null, empty, or non-JSON, nothing to record
if [ -z "$EVAL_OUTPUT" ] || [ "$EVAL_OUTPUT" = "null" ]; then
    exit 0
fi

# Validate it parses as JSON with required fields
if ! printf '%s' "$EVAL_OUTPUT" | jq -e '.type and .plugin_file and .correct_text and .evidence' >/dev/null 2>&1; then
    exit 0
fi

# Extract fields
OBS_TYPE=$(printf '%s' "$EVAL_OUTPUT" | jq -r '.type')
OBS_CONFIDENCE=$(printf '%s' "$EVAL_OUTPUT" | jq -r '.confidence')
OBS_FILE=$(printf '%s' "$EVAL_OUTPUT" | jq -r '.plugin_file')
OBS_SECTION=$(printf '%s' "$EVAL_OUTPUT" | jq -r '.plugin_section')
OBS_WRONG=$(printf '%s' "$EVAL_OUTPUT" | jq -r '.wrong_text')
OBS_CORRECT=$(printf '%s' "$EVAL_OUTPUT" | jq -r '.correct_text')
OBS_EVIDENCE=$(printf '%s' "$EVAL_OUTPUT" | jq -r '.evidence')
OBS_DATE=$(date +%Y-%m-%d)

# Determine next OBS number
if [ -f "$OBSERVATIONS_FILE" ]; then
    LAST_NUM=$(grep -oE '^## OBS-[0-9]+' "$OBSERVATIONS_FILE" | grep -oE '[0-9]+' | sort -n | tail -1 || echo "0")
else
    LAST_NUM=0
fi
NEXT_NUM=$(printf '%03d' $((LAST_NUM + 1)))

# Create file with header if it doesn't exist
if [ ! -f "$OBSERVATIONS_FILE" ]; then
    cat > "$OBSERVATIONS_FILE" <<'HEADER_EOF'
# Plugin Observations

Auto-captured observations about the etcd-druid-skills plugin.
Each entry is a specific, actionable finding that a contributor can act on.

Review and triage periodically. When an observation is fixed (PR merged),
move it to the Resolved section with the PR link.

---

## Resolved

_(none yet)_
HEADER_EOF
fi

# Insert new observation before the Resolved section
NEW_ENTRY=$(cat <<ENTRY_EOF

## OBS-${NEXT_NUM} — ${OBS_TYPE} in ${OBS_FILE}

**Date:** ${OBS_DATE}
**Type:** ${OBS_TYPE}
**Confidence:** ${OBS_CONFIDENCE}
**File:** \`${OBS_FILE}\`
**Section:** ${OBS_SECTION}

**Wrong / Missing:**
> ${OBS_WRONG}

**Should be:**
${OBS_CORRECT}

**Evidence:**
> ${OBS_EVIDENCE}

**Status:** open

---
ENTRY_EOF
)

# Insert before "## Resolved" line
if grep -q '^## Resolved' "$OBSERVATIONS_FILE"; then
    # Use a temp file to insert before the Resolved section
    TMPFILE=$(mktemp)
    awk -v entry="$NEW_ENTRY" '/^## Resolved/{print entry} {print}' "$OBSERVATIONS_FILE" > "$TMPFILE"
    mv "$TMPFILE" "$OBSERVATIONS_FILE"
else
    printf '%s\n' "$NEW_ENTRY" >> "$OBSERVATIONS_FILE"
fi

exit 0
