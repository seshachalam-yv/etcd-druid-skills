#!/usr/bin/env bash
# Hook runner for etcd-druid plugin.
# Usage: run-hook.sh <script-name> [args...]
# Executes the named hook script from the same directory.

set -euo pipefail

if [ -z "${1:-}" ]; then
    echo "run-hook.sh: missing script name" >&2
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SCRIPT_NAME="$1"
shift

exec bash "${SCRIPT_DIR}/${SCRIPT_NAME}" "$@"
