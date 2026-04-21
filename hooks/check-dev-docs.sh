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

# Map file path to the most relevant development doc
# *_test.go checked first — takes priority over path-based patterns
SPECIFIC_DOC=""
case "$FILE_PATH" in
    *_test.go)
        SPECIFIC_DOC="docs/development/testing.md — framework per repo (testing.T+Gomega for druid/wrapper, Ginkgo for backup-restore), fake client patterns"
        ;;
    */internal/component/*)
        SPECIFIC_DOC="docs/development/add-new-etcd-cluster-component.md — operator interface: PreSync, Sync, TriggerDelete, GetExistingResourceNames"
        ;;
    */internal/controller/*)
        SPECIFIC_DOC="docs/development/controllers.md — reconciler patterns and controller-runtime conventions"
        ;;
    */api/core/v1alpha1/*)
        SPECIFIC_DOC="docs/development/changing-api.md — field naming, CEL validation placement, two-commit generate rule"
        ;;
    */pkg/snapshot/snapshotter/*)
        SPECIFIC_DOC="docs/development/tests.md — snapshotter test patterns, full/delta snapshot cycle"
        ;;
    */pkg/snapshot/restorer/*)
        SPECIFIC_DOC="docs/development/tests.md — restorer test patterns, embedded etcd restore flow"
        ;;
    */pkg/snapstore/*)
        SPECIFIC_DOC="docs/development/new_cp_support.md — cloud provider snapstore interface, adding new providers"
        ;;
    */pkg/compactor/*)
        SPECIFIC_DOC="docs/development/tests.md — compactor patterns, embedded etcd for compaction"
        ;;
    */pkg/server/*)
        SPECIFIC_DOC="docs/development/local_setup.md — HTTP server endpoints, leader forwarding"
        ;;
    */pkg/member/*)
        SPECIFIC_DOC="docs/development/tests.md — member control patterns, scale-up, learner promotion"
        ;;
    */internal/bootstrap/*)
        SPECIFIC_DOC="docs/development/contribution.md — bootstrap flow, BR init loop, config fetch"
        ;;
    */internal/app/*)
        SPECIFIC_DOC="docs/development/testing.md — app lifecycle, embedded etcd start, readiness checks"
        ;;
    */internal/brclient/*)
        SPECIFIC_DOC="docs/development/contribution.md — BR HTTP client, initialization endpoints"
        ;;
esac

if [ -n "$SPECIFIC_DOC" ]; then
    REMINDER="Before editing ${FILE_PATH}: read ${repo_root}/${SPECIFIC_DOC}. It is the authoritative source for conventions in this area."
else
    REMINDER="Before editing ${FILE_PATH}: read the relevant files in ${repo_root}/docs/development/ — they are the authoritative source for conventions, patterns, and make targets in this repo."
fi

jq -n --arg ctx "$REMINDER" \
    '{"continue":true,"suppressOutput":true,"hookSpecificOutput":{"hookEventName":"PostToolUse","additionalContext":$ctx}}'

exit 0
