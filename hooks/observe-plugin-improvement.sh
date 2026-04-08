#!/usr/bin/env bash
# Stop hook: capture plugin improvement observations from Claude's responses.
#
# Three capture channels, cheapest first:
#   1. <plugin-gap> XML markers — Claude emits these explicitly, zero LLM cost
#   2. User correction signal — UserPromptSubmit hook sets a flag file
#   3. LLM evaluator — only fires when correction signal flag is present
#
# Never blocks the Stop event. Exits 0 always.
# Runs async — no session latency impact.

set -uo pipefail

PLUGIN_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OBSERVATIONS_FILE="${PLUGIN_ROOT}/plugin-observations.md"
CORRECTION_FLAG="/tmp/etcd-druid-correction-signal-${SESSION_ID:-default}"

# ── Guard: prevent infinite recursion ────────────────────────────────────────
# stop_hook_active is set to true when a Stop hook is already running.
# Without this check, calling claude inside here would fire another Stop hook.
PAYLOAD=$(cat)
STOP_HOOK_ACTIVE=$(printf '%s' "$PAYLOAD" | jq -r '.stop_hook_active // false' 2>/dev/null || echo "false")
if [ "$STOP_HOOK_ACTIVE" = "true" ]; then
    exit 0
fi

SESSION_ID=$(printf '%s' "$PAYLOAD" | jq -r '.session_id // "default"' 2>/dev/null || echo "default")
TRANSCRIPT_PATH=$(printf '%s' "$PAYLOAD" | jq -r '.transcript_path // empty' 2>/dev/null || true)

if [ -z "$TRANSCRIPT_PATH" ] || [ ! -f "$TRANSCRIPT_PATH" ]; then
    exit 0
fi

# ── Extract last assistant message from transcript JSONL ──────────────────────
# Transcript is JSONL. Each line is a message object.
# Assistant messages have role="assistant" and content is an array of typed blocks.
LAST_MESSAGE=$(grep '"role":"assistant"' "$TRANSCRIPT_PATH" 2>/dev/null | tail -1 \
    | jq -r '(.message.content // .content // [])
             | map(select(.type == "text"))
             | map(.text)
             | join("\n")' 2>/dev/null || true)

# Fallback: try simpler structure variants
if [ -z "$LAST_MESSAGE" ]; then
    LAST_MESSAGE=$(grep '"role":"assistant"' "$TRANSCRIPT_PATH" 2>/dev/null | tail -1 \
        | jq -r '.content // empty' 2>/dev/null || true)
fi

if [ -z "$LAST_MESSAGE" ] || [ "${#LAST_MESSAGE}" -lt 100 ]; then
    exit 0
fi

# ── Helper: write an observation entry ───────────────────────────────────────
write_observation() {
    local obs_type="$1"
    local obs_confidence="$2"
    local obs_file="$3"
    local obs_section="$4"
    local obs_wrong="$5"
    local obs_correct="$6"
    local obs_diff="$7"
    local obs_evidence="$8"
    local obs_source="$9"
    local obs_date
    obs_date=$(date +%Y-%m-%d)

    # Deduplicate: skip if same file+section already has an open entry
    if [ -f "$OBSERVATIONS_FILE" ]; then
        if grep -q "^\*\*File:\*\* \`${obs_file}\`" "$OBSERVATIONS_FILE" 2>/dev/null; then
            if grep -A3 "^\*\*File:\*\* \`${obs_file}\`" "$OBSERVATIONS_FILE" \
               | grep -q "^\*\*Section:\*\* ${obs_section}"; then
                # Same file+section already recorded — skip to avoid duplicates
                return 0
            fi
        fi
    fi

    # Determine next OBS number
    local last_num=0
    if [ -f "$OBSERVATIONS_FILE" ]; then
        last_num=$(grep -oE '^## OBS-[0-9]+' "$OBSERVATIONS_FILE" \
            | grep -oE '[0-9]+' | sort -n | tail -1 2>/dev/null || echo "0")
    fi
    local next_num
    next_num=$(printf '%03d' $((last_num + 1)))

    # Create file with header if needed
    if [ ! -f "$OBSERVATIONS_FILE" ]; then
        cat > "$OBSERVATIONS_FILE" <<'HEADER'
# Plugin Observations

Auto-captured observations about the etcd-druid-skills plugin.
Each entry is a specific, actionable finding that a contributor can act on.

Run `/etcd-druid:observations` to review and triage entries.

---

## Resolved

_(none yet)_
HEADER
    fi

    # Build entry — obs_diff inserted via awk after heredoc to prevent shell
    # expansion of any $(...) or `...` sequences the LLM may have emitted.
    local new_entry
    new_entry=$(cat <<ENTRY

## OBS-${next_num} — ${obs_type} in ${obs_file}

**Date:** ${obs_date}
**Source:** ${obs_source}
**Type:** ${obs_type}
**Confidence:** ${obs_confidence}
**File:** \`${obs_file}\`
**Section:** ${obs_section}

**Wrong / Missing:**
> ${obs_wrong}

**Proposed fix:**
${obs_correct}

**Apply:**
\`\`\`bash
__OBS_DIFF_PLACEHOLDER__
\`\`\`

**Evidence:**
> ${obs_evidence}

**Status:** open

---
ENTRY
)
    # Replace placeholder with obs_diff safely — use temp file to support multi-line
    # values and to avoid BSD awk's "newline in string" error with awk -v.
    local diff_tmp
    diff_tmp=$(mktemp)
    printf '%s' "$obs_diff" > "$diff_tmp"
    new_entry=$(printf '%s' "$new_entry" \
        | awk -v dfile="$diff_tmp" '
            BEGIN { while ((getline line < dfile) > 0) d = d line ORS }
            /__OBS_DIFF_PLACEHOLDER__/ { printf "%s", d; next }
            { print }
        ')
    rm -f "$diff_tmp"

    # Insert before Resolved section
    if grep -q '^## Resolved' "$OBSERVATIONS_FILE"; then
        local tmpfile
        tmpfile=$(mktemp)
        awk -v entry="$new_entry" '/^## Resolved/{print entry} {print}' \
            "$OBSERVATIONS_FILE" > "$tmpfile"
        mv "$tmpfile" "$OBSERVATIONS_FILE"
    else
        printf '%s\n' "$new_entry" >> "$OBSERVATIONS_FILE"
    fi
}

# ── Channel 1: <plugin-gap> XML markers ──────────────────────────────────────
# Claude emits these explicitly when it notices a gap while working.
# Format: <plugin-gap file="..." section="..." type="...">description</plugin-gap>
# Zero LLM cost — just string matching.

if printf '%s' "$LAST_MESSAGE" | grep -q '<plugin-gap'; then
    # Extract each marker
    while IFS= read -r gap_block; do
        gap_file=$(printf '%s' "$gap_block" | grep -oP '(?<=file=")[^"]+' || true)
        gap_section=$(printf '%s' "$gap_block" | grep -oP '(?<=section=")[^"]+' || true)
        gap_type=$(printf '%s' "$gap_block" | grep -oP '(?<=type=")[^"]+' || true)
        gap_type="${gap_type:-missing_convention}"
        gap_body=$(printf '%s' "$gap_block" | sed 's/<plugin-gap[^>]*>//;s|</plugin-gap>||' | xargs || true)

        if [ -n "$gap_file" ] && [ -n "$gap_body" ]; then
            write_observation \
                "${gap_type:-missing_convention}" \
                "high" \
                "$gap_file" \
                "${gap_section:-unknown}" \
                "MISSING" \
                "$gap_body" \
                "MULTILINE — apply manually" \
                "$(printf '%s' "$gap_body" | head -c 200)" \
                "explicit-marker"
            # Persist to cross-session memory store
            bash "${PLUGIN_ROOT}/hooks/write-memory.sh" \
                "$(printf '%s' "$gap_body" | cut -c1-200)" \
                "$(basename "$gap_file" .md),${gap_type:-missing_convention},etcd-druid" \
                "0.8" &
        fi
    done < <(printf '%s' "$LAST_MESSAGE" | grep -oP '<plugin-gap[^>]*>.*?</plugin-gap>' || true)
fi

# ── Channel 2+3: correction signal + LLM evaluator ───────────────────────────
# Only run LLM evaluation if UserPromptSubmit hook detected a correction phrase
# in the user's preceding message. Without this gate, we'd call LLM on every turn.

CORRECTION_FLAG="/tmp/etcd-druid-correction-${SESSION_ID}"

if [ ! -f "$CORRECTION_FLAG" ]; then
    exit 0
fi

# Consume the flag — one evaluation per correction signal
rm -f "$CORRECTION_FLAG"

# Build evaluation prompt
EVAL_PROMPT=$(cat <<'PROMPT_EOF'
You are reviewing a Claude Code assistant response to determine whether it reveals a specific, actionable improvement to the etcd-druid-skills plugin — a Claude Code plugin helping contributors work on etcd-druid, etcd-backup-restore, and etcd-wrapper.

The plugin contains:
- skills/feature-dev/SKILL.md — feature workflow, phases, gates, subagent loop
- skills/api-change/SKILL.md — API field design, CEL validation, two-commit generate workflow
- skills/tdd/SKILL.md — test frameworks per repo, TDD cycle, fake client patterns
- skills/tdd/testing-anti-patterns.md — 5 domain-specific anti-patterns with code examples
- skills/debug/SKILL.md — systematic debugging across three repos
- skills/review/SKILL.md — pre-PR checklist, footguns list, verdict format
- skills/e2e/SKILL.md — KIND cluster setup, custom image builds, sidecar overrides
- skills/reference/SKILL.md — make targets, file paths, flags, feature gates
- skills/verification/SKILL.md — verification gate (5-step, cross-cutting)
- skills/receiving-review/SKILL.md — handling incoming review feedback
- hooks/session-start — orientation block: component system, invariants, skills list
- hooks/guard-generated-files.sh — blocks edits to generated files

## Context

This response followed a user correction or clarification. The user said something indicating that Claude's previous response was wrong or that something was missing. Your job: determine whether the correction reveals a specific flaw in the plugin guidance that would cause future sessions to make the same mistake.

## Qualifies as a plugin observation

- A make target, flag, file path, or type stated in a skill is wrong or removed
- A skill workflow step caused Claude to go the wrong direction and the skill text is the source of the ambiguity
- A convention exists in the codebase that no skill documents — applies across sessions, not just this task
- A footgun was encountered not listed in skills/review/SKILL.md Known Footguns
- The session-start orientation stated something factually wrong
- A rationalization was used to bypass an Iron Law not covered by any rationalization table

## Does NOT qualify

- Task-specific findings (this PR, this component, this bug)
- General Go/Kubernetes/etcd observations not tied to plugin guidance
- Uncertainty — "I think this might be wrong" is not enough
- Patterns specific to one location and unlikely to recur

## Confidence threshold — all three required

1. Exact plugin file and section named
2. Exact wrong or missing text identified
3. Exact proposed fix stated — specific enough to write without further investigation

Output this JSON if all three are met, nothing else:

{
  "type": "wrong_claim" | "missing_convention" | "missing_footgun" | "unclear_workflow" | "stale_path_or_flag" | "missing_iron_law_rationalization",
  "confidence": "high" | "medium",
  "plugin_file": "<path relative to plugin root>",
  "plugin_section": "<section heading>",
  "wrong_text": "<exact text in skill that is wrong, or MISSING>",
  "correct_text": "<proposed replacement text — complete, ready to apply>",
  "diff_apply": "<the minimal sed or awk one-liner to apply the fix, e.g.: sed -i 's/old text/new text/' skills/tdd/SKILL.md>",
  "evidence": "<quote from response that revealed this>"
}

The diff_apply field must be a single bash command that applies correct_text over wrong_text in plugin_file.
Use sed -i for simple line replacements. If the change is multi-line, use: "MULTILINE — apply manually".

If threshold not met, output exactly: null

PROMPT_EOF
)

# Call Claude with --no-hooks to prevent Stop hook recursion
# (belt-and-suspenders alongside stop_hook_active check)
EVAL_OUTPUT=$(printf '%s\n\n## Response to evaluate\n\n%s' "$EVAL_PROMPT" "$LAST_MESSAGE" \
    | timeout 60 claude --bare --no-hooks -p --output-format text 2>/dev/null || true)

EVAL_OUTPUT=$(printf '%s' "$EVAL_OUTPUT" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

if [ -z "$EVAL_OUTPUT" ] || [ "$EVAL_OUTPUT" = "null" ]; then
    exit 0
fi

# Validate JSON structure
if ! printf '%s' "$EVAL_OUTPUT" \
   | jq -e '.type and .plugin_file and .correct_text and .evidence' >/dev/null 2>&1; then
    exit 0
fi

OBS_TYPE=$(printf '%s' "$EVAL_OUTPUT" | jq -r '.type')
OBS_CONFIDENCE=$(printf '%s' "$EVAL_OUTPUT" | jq -r '.confidence')
OBS_FILE=$(printf '%s' "$EVAL_OUTPUT" | jq -r '.plugin_file')
OBS_SECTION=$(printf '%s' "$EVAL_OUTPUT" | jq -r '.plugin_section')
OBS_WRONG=$(printf '%s' "$EVAL_OUTPUT" | jq -r '.wrong_text')
OBS_CORRECT=$(printf '%s' "$EVAL_OUTPUT" | jq -r '.correct_text')
OBS_DIFF=$(printf '%s' "$EVAL_OUTPUT" | jq -r '.diff_apply // "MULTILINE — apply manually"')
# NOTE: the em-dash (—) in "MULTILINE — apply manually" above must byte-match the
# literal at the Channel 1 call site; don't convert it to a hyphen or en-dash
OBS_EVIDENCE=$(printf '%s' "$EVAL_OUTPUT" | jq -r '.evidence')

write_observation \
    "$OBS_TYPE" \
    "$OBS_CONFIDENCE" \
    "$OBS_FILE" \
    "$OBS_SECTION" \
    "$OBS_WRONG" \
    "$OBS_CORRECT" \
    "$OBS_DIFF" \
    "$OBS_EVIDENCE" \
    "llm-evaluator"

# Persist to cross-session memory store
MEMORY_CONTENT=$(printf '%s' "$OBS_CORRECT" | cut -c1-200)
MEM_TAGS="$(basename "$OBS_FILE" .md),${OBS_TYPE},etcd-druid"
bash "${PLUGIN_ROOT}/hooks/write-memory.sh" "$MEMORY_CONTENT" "$MEM_TAGS" "0.8" &

exit 0
