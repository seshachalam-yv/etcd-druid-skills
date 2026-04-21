# Releasing

Releases are created from GitHub Actions. The workflow triggers on any tag matching `v*` and publishes a GitHub Release with notes extracted from `CHANGELOG.md`.

## Steps

### 1. Update version files

All three files must carry the same version string:

| File | Field |
|------|-------|
| `.claude-plugin/plugin.json` | `.version` |
| `.claude-plugin/marketplace.json` | `.metadata.version` |
| `.claude-plugin/marketplace.json` | `.plugins[0].version` |

Also update the version badge in `README.md`:

```
[![Version](https://img.shields.io/badge/version-X.Y.Z-green.svg)](.claude-plugin/plugin.json)
```

And the section heading:

```
## Current versions (as of vX.Y.Z)
```

### 2. Add a CHANGELOG entry

Add a new section at the top of `CHANGELOG.md`, above any existing entries:

```markdown
## [X.Y.Z] - YYYY-MM-DD

### Skills
- ...

### Fixes
- ...
```

Link each item to its commit:

```markdown
- Short description ([abcdef1](https://github.com/seshachalam-yv/etcd-druid-skills/commit/abcdef1))
```

### 3. Commit

```bash
git add .claude-plugin/plugin.json .claude-plugin/marketplace.json README.md CHANGELOG.md
git commit -s -m "chore(release): prepare vX.Y.Z"
git push origin master
```

Wait for the **Validate** workflow to go green before tagging.

### 4. Tag and push

```bash
git tag vX.Y.Z
git push origin vX.Y.Z
```

This triggers the **Release** workflow, which:

1. Validates that the tag version matches all three version fields
2. Extracts the matching `## [X.Y.Z]` section from `CHANGELOG.md`
3. Creates a GitHub Release at `https://github.com/seshachalam-yv/etcd-druid-skills/releases/tag/vX.Y.Z`

### 5. Verify

```bash
gh release view vX.Y.Z
```

Or open the Releases page on GitHub to confirm the release body matches the CHANGELOG entry.

## Version scheme

Releases follow [Semantic Versioning](https://semver.org/):

| Change type | Bump |
|-------------|------|
| New skill, new hook, significant capability | `minor` (0.Y.0) |
| Bug fix, doc correction, small improvement | `patch` (0.0.Z) |
| Breaking change to skill interface or hook contract | `major` (X.0.0) |

Pre-release suffixes (e.g. `v0.2.0-beta.1`) are supported — the workflow marks them as pre-releases automatically.
