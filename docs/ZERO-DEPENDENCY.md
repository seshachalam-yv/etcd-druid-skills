# Zero-Dependency Policy

This plugin has zero runtime dependencies beyond Claude Code itself.

## Rules

1. **No npm packages.** Skills are markdown files, not code.
2. **No external binaries.** Skills reference only tools available in the user's environment (git, make, go, gh).
3. **No network calls at skill load time.** Skills are loaded from disk, never fetched.
4. **No generated code.** Everything is hand-written markdown.

## Why

- **Reliability:** No install step means no install failures.
- **Portability:** Works on any machine with Claude Code and git.
- **Security:** No supply chain attack surface.
- **Speed:** Skill load is instant (disk read only).

## What This Means in Practice

- Hook scripts use only POSIX shell and git commands
- Skills reference make targets and CLI tools the user already has
- Test infrastructure uses bash scripts, not test frameworks
- No `package.json`, `go.mod`, `requirements.txt`, or equivalent
