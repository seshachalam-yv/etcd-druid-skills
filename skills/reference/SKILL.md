---
name: reference
description: Use for quick lookup of make targets, file paths, git workflow, branch naming, EtcdOpsTask, druidctl, or feature gates in the etcd-druid ecosystem.
user-invocable: true
effort: low
---

# etcd-druid Ecosystem — Quick Reference Card

## Current Git State

- Branch: !`git branch --show-current 2>/dev/null || echo "(not in a git repo)"`
- Remote: !`git remote get-url origin 2>/dev/null || echo "(no origin)"`
- Recent: !`git log --oneline -3 2>/dev/null || echo "(no commits)"`

For code patterns, conventions, and best practices: read `docs/development/` in the
repo you are working in. This card covers locations, targets, and workflow only.

**Staleness warning:** Tooling versions, feature gate states, and CLI flags below are
snapshots that may drift as the repos evolve. Before citing a specific version or flag
in your output, verify it against the actual repo (`go.mod`, `Dockerfile`, or the
relevant source file). If you find a mismatch, update this card.

## Repository Paths

```
Upstream (read-only):
  github.com/gardener/etcd-druid
  github.com/gardener/etcd-backup-restore
  github.com/gardener/etcd-wrapper

Fork (write here):
  github.com/<your-github-user>/etcd-druid  (check `git remote -v` for local path)

Worktree (active development):
  .worktrees/etcd-druid-issue-{id}/   (under fork root, gitignored)
```

---

## Routing Table

Read the section you need — each file is self-contained.

| Topic | File | Contents |
|-------|------|----------|
| Source locations & dev guides | [REPO-PATHS.md](REPO-PATHS.md) | Key paths in all 3 repos, 10 components list, `docs/development/` index |
| Make targets & test commands | [MAKE-TARGETS.md](MAKE-TARGETS.md) | `make` targets per repo, targeted `go test` / Ginkgo examples |
| Git workflow & branch naming | [GIT-WORKFLOW.md](GIT-WORKFLOW.md) | Worktree creation, commit style, PR command, branch conventions |
| EtcdOpsTask & druidctl CLI | [ETCDOPSTASK.md](ETCDOPSTASK.md) | CRD paths, task types, state machine, druidctl commands |
| API changelog & flags | [API-CHANGELOG.md](API-CHANGELOG.md) | Version upgrade, feature gates, cross-container contracts, CLI flags, recent API fields |
| Dependency management | [DEPENDENCY-MANAGEMENT.md](DEPENDENCY-MANAGEMENT.md) | Multi-module structure, vendoring, Dependabot, sidecar bumps, Go upgrades |
| Tooling versions | [TOOLING-VERSIONS.md](TOOLING-VERSIONS.md) | Go, etcd, lint, K8s deps, controller-runtime versions |

---

## Skills Available (on-demand)

- `plan` — design phase: issue analysis, approach selection, code plan with approval gate (Gate 1)
- `implement` — execution phase: worktree setup, per-task subagent loop, verification, PR creation (Gate 2)
- `api-change` — API field design, CEL validation (field-scoped + cross-field), two-commit generate, CRD tests, CI pipeline verification before Gate 2
- `tdd` — TDD cycle for all three repos
- `debug` — systematic debugging workflow
- `review` — code review checklist
- `observations` — triage captured plugin improvement observations; invoke when session-start flags pending observations
- `e2e` — manual e2e testing: KIND setup, custom image builds, sidecar overrides, pre-PR CI
- `worktree-gate` — shared gate enforcing worktree isolation before any code modification; referenced by all code-modifying skills
- `reference` — this card
