#!/usr/bin/env bash
# Bump the plugin version, regenerate CHANGELOG.md, and create a release commit + tag.
#
# Usage: ./scripts/bump-version.sh <new-version>
# Example: ./scripts/bump-version.sh 0.2.0
#
# Dependencies:
#   - jq   (required)
#   - git  (required)
#   - git-cliff (optional — install: brew install git-cliff)
#     If absent, CHANGELOG.md is left unchanged and must be updated manually.
#
# What it does:
#   1. Validates the new version is a valid semver (X.Y.Z or X.Y.Z-pre)
#   2. Updates .claude-plugin/plugin.json (.version)
#   3. Updates .claude-plugin/marketplace.json (.metadata.version, .plugins[0].version)
#   4. Updates the version badge and section heading in README.md
#   5. Regenerates CHANGELOG.md via git-cliff (if installed)
#   6. Creates a signed release commit: chore(release): prepare vX.Y.Z
#   7. Creates an annotated tag: vX.Y.Z
#
# After running, push with:
#   git push origin master --tags

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
NEW_VERSION="${1:-}"

# ── Validation ────────────────────────────────────────────────────────────────

if [[ -z "$NEW_VERSION" ]]; then
  echo "ERROR: version argument required" >&2
  echo "Usage: $0 <new-version>  (e.g. 0.2.0)" >&2
  exit 1
fi

# Strip leading 'v'
NEW_VERSION="${NEW_VERSION#v}"

# Validate semver: X.Y.Z or X.Y.Z-suffix
if ! [[ "$NEW_VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+(-[a-zA-Z0-9._-]+)?$ ]]; then
  echo "ERROR: '$NEW_VERSION' is not a valid semver (expected X.Y.Z or X.Y.Z-pre)" >&2
  exit 1
fi

# Ensure working tree is clean
if ! git -C "$REPO_ROOT" diff --quiet || ! git -C "$REPO_ROOT" diff --cached --quiet; then
  echo "ERROR: working tree has uncommitted changes — commit or stash them first" >&2
  exit 1
fi

CURRENT_VERSION="$(jq -r '.version' "$REPO_ROOT/.claude-plugin/plugin.json")"
echo "Current version : $CURRENT_VERSION"
echo "New version     : $NEW_VERSION"
echo ""

# ── 1. Update plugin.json ─────────────────────────────────────────────────────

jq --arg v "$NEW_VERSION" '.version = $v' \
  "$REPO_ROOT/.claude-plugin/plugin.json" > "$REPO_ROOT/.claude-plugin/plugin.json.tmp"
mv "$REPO_ROOT/.claude-plugin/plugin.json.tmp" "$REPO_ROOT/.claude-plugin/plugin.json"
echo "✓ .claude-plugin/plugin.json"

# ── 2. Update marketplace.json ────────────────────────────────────────────────

jq --arg v "$NEW_VERSION" '
  .metadata.version = $v |
  .plugins[0].version = $v
' "$REPO_ROOT/.claude-plugin/marketplace.json" > "$REPO_ROOT/.claude-plugin/marketplace.json.tmp"
mv "$REPO_ROOT/.claude-plugin/marketplace.json.tmp" "$REPO_ROOT/.claude-plugin/marketplace.json"
echo "✓ .claude-plugin/marketplace.json"

# ── 3. Update README.md ───────────────────────────────────────────────────────

sed -i.bak \
  -e "s|version-${CURRENT_VERSION}-green|version-${NEW_VERSION}-green|g" \
  -e "s|as of v${CURRENT_VERSION}|as of v${NEW_VERSION}|g" \
  "$REPO_ROOT/README.md"
rm -f "$REPO_ROOT/README.md.bak"
echo "✓ README.md"

# ── 4. Regenerate CHANGELOG.md ────────────────────────────────────────────────

if command -v git-cliff &>/dev/null; then
  git-cliff \
    --config "$REPO_ROOT/cliff.toml" \
    --tag "v${NEW_VERSION}" \
    --output "$REPO_ROOT/CHANGELOG.md"
  echo "✓ CHANGELOG.md (git-cliff)"
else
  echo "WARN: git-cliff not found — CHANGELOG.md not updated"
  echo "      Install: brew install git-cliff  (or: cargo install git-cliff)"
  echo "      Then manually add an entry for v${NEW_VERSION} before pushing the tag."
fi

# ── 5. Commit ─────────────────────────────────────────────────────────────────

git -C "$REPO_ROOT" add \
  .claude-plugin/plugin.json \
  .claude-plugin/marketplace.json \
  README.md \
  CHANGELOG.md

git -C "$REPO_ROOT" commit \
  --signoff \
  --message "chore(release): prepare v${NEW_VERSION}"

echo "✓ commit: chore(release): prepare v${NEW_VERSION}"

# ── 6. Tag ────────────────────────────────────────────────────────────────────

git -C "$REPO_ROOT" tag \
  --annotate \
  --message "v${NEW_VERSION}" \
  "v${NEW_VERSION}"

echo "✓ tag: v${NEW_VERSION}"
echo ""
echo "Ready to publish. Run:"
echo "  git push origin master --tags"
