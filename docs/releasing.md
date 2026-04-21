# Releasing

Releases are created entirely from the GitHub UI — no local tooling required.

## Triggering a release from GitHub UI

1. Go to **Actions → Release** on GitHub
2. Click **Run workflow**
3. Enter the version (e.g. `0.2.0`) — no leading `v` needed
4. Click **Run workflow**

The workflow will:

1. Validate the version is a valid semver and the tag doesn't already exist
2. Bump `.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json` (both fields), and the `README.md` version badge
3. Regenerate `CHANGELOG.md` from conventional commits via `git-cliff`
4. Commit the changes to master: `chore(release): prepare v0.2.0`
5. Create and push an annotated tag `v0.2.0`
6. Create a GitHub Release with the changelog entry as the release body

## Version scheme

Releases follow [Semantic Versioning](https://semver.org/):

| Change type | Bump |
|-------------|------|
| New skill, new hook, significant capability | `minor` (0.Y.0) |
| Bug fix, doc correction, small improvement | `patch` (0.0.Z) |
| Breaking change to skill interface or hook contract | `major` (X.0.0) |

Pre-release suffixes (e.g. `0.2.0-beta.1`) are supported — the workflow marks them as pre-releases automatically.

## Local release (optional)

If you prefer to release from the command line instead of the UI:

```bash
./scripts/bump-version.sh 0.2.0
git push origin master --tags
```

`scripts/bump-version.sh` does the same steps as the workflow — version bumps, git-cliff CHANGELOG, signed commit, and annotated tag. Requires `jq` and optionally `git-cliff` (`brew install git-cliff`).

## How CHANGELOG.md is generated

`cliff.toml` configures `git-cliff` to:

- Parse [Conventional Commits](https://www.conventionalcommits.org/) (`feat:`, `fix:`, `docs:`, etc.)
- Group into sections: **Features**, **Fixes**, **Refactor**, **Documentation**, **Testing**, **CI / Infrastructure**, **Miscellaneous**
- Link each commit to its SHA on GitHub
- Skip `chore(release)` commits (the bump commits themselves)

To preview what the next release notes will look like without committing:

```bash
git-cliff --config cliff.toml --unreleased
```
