<!-- PR title must follow Conventional Commits: type(scope): description -->
<!-- Types: feat, fix, docs, refactor, test, chore, ci                   -->
<!-- Scopes: skill/NAME, hook/NAME, ci, release, docs                    -->

### What type of change?

- [ ] New skill or hook
- [ ] Enhancement to existing skill or hook
- [ ] Bug fix
- [ ] Documentation
- [ ] CI / infrastructure
- [ ] Breaking change (describe below)

### What this PR does and why

<!-- Explain the motivation and what changed. The "why" matters more than the "what". -->

### Related issue(s)

Fixes #

### Checklist

- [ ] Skill has `name:` and `description:` frontmatter
- [ ] Hook scripts are executable (`chmod +x`)
- [ ] No inline code in skill markdown — instructions only, code lives in `docs/development/`
- [ ] All version fields updated if this is a release (`plugin.json`, `marketplace.json`)
- [ ] `CHANGELOG.md` updated (or N/A for docs-only changes)
- [ ] Tested locally with the Claude CLI

### Release note

<!-- One line describing the user-facing change. Write NONE if not user-facing. -->

```release-note

```
