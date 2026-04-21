# Releasing

Releases are created from GitHub Actions. The workflow triggers on any tag matching `v*` and publishes a GitHub Release with notes extracted from `CHANGELOG.md`.

## Prerequisites

- `jq` — used by the bump script and CI (`brew install jq`)
- `git-cliff` — generates `CHANGELOG.md` from conventional commits (`brew install git-cliff`)
  - Optional: the script degrades gracefully without it, but you'll need to update `CHANGELOG.md` manually.

## Steps

### 1. Run the bump script

```bash
./scripts/bump-version.sh X.Y.Z
```

This single command:

1. Validates the new version is a valid semver
2. Checks the working tree is clean
3. Updates `.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json` (both fields), and `README.md`
4. Regenerates `CHANGELOG.md` via `git-cliff` (groups commits by type, links each to its SHA)
5. Creates a signed commit: `chore(release): prepare vX.Y.Z`
6. Creates an annotated tag: `vX.Y.Z`

### 2. Review the generated CHANGELOG entry

```bash
git show HEAD -- CHANGELOG.md
```

Amend if needed before pushing.

### 3. Push

```bash
git push origin master --tags
```

This:
- Triggers the **Validate** workflow on master (version consistency, frontmatter, hook executability)
- Triggers the **Release** workflow on the tag, which:
  1. Validates that the tag version matches all three version fields
  2. Extracts the matching `## [X.Y.Z]` section from `CHANGELOG.md`
  3. Creates a GitHub Release at `https://github.com/seshachalam-yv/etcd-druid-skills/releases/tag/vX.Y.Z`

### 4. Verify

```bash
gh release view vX.Y.Z
```

## How CHANGELOG.md is generated

`cliff.toml` configures `git-cliff` to:

- Parse [Conventional Commits](https://www.conventionalcommits.org/) (`feat:`, `fix:`, `docs:`, etc.)
- Group them into sections: **Features**, **Fixes**, **Refactor**, **Documentation**, **Testing**, **CI / Infrastructure**, **Miscellaneous**
- Link each commit to its SHA on GitHub
- Skip `chore(release)` commits (the bump commits themselves)
- Output Keep-a-Changelog format

To preview what the next release notes will look like without committing:

```bash
git-cliff --config cliff.toml --tag vX.Y.Z --unreleased
```

## Version scheme

Releases follow [Semantic Versioning](https://semver.org/):

| Change type | Bump |
|-------------|------|
| New skill, new hook, significant capability | `minor` (0.Y.0) |
| Bug fix, doc correction, small improvement | `patch` (0.0.Z) |
| Breaking change to skill interface or hook contract | `major` (X.0.0) |

Pre-release suffixes (e.g. `v0.2.0-beta.1`) are supported — the Release workflow marks them as pre-releases automatically.
