---
name: reference
description: Use when you need quick lookup of file paths, make targets, branch naming, or git workflow for the etcd-druid ecosystem
user-invocable: true
---

# etcd-druid Ecosystem — Quick Reference Card

For code patterns, conventions, and best practices: read `docs/development/` in the
repo you are working in. This card covers locations, targets, and workflow only.

## Repository Paths

```
Upstream (read-only):
  github.com/gardener/etcd-druid
  github.com/gardener/etcd-backup-restore
  github.com/gardener/etcd-wrapper

Fork (write here):
  github.com/<your-github-user>/etcd-druid  (check `git remote -v` for local path)

Worktree (active development):
  ../etcd-druid-ai-TASK-{id}/   (relative to fork)
```

## Key Source Locations (etcd-druid)

```
API types:           api/core/v1alpha1/
Component operators: internal/component/<name>/
Controllers:         internal/controller/etcd/reconciler.go
Error types:         internal/errors/
Test utilities:      test/utils/
CEL validation:      test/it/crdvalidation/
Generated code:      api/core/v1alpha1/zz_generated.deepcopy.go
                     api/core/v1alpha1/crds/*.yaml
                     charts/crds/*.yaml
                     client/
Development docs:    docs/development/
```

## Development Guides (read before coding)

```
etcd-druid:           docs/development/
etcd-backup-restore:  docs/development/
etcd-wrapper:         docs/development/
```

Key files in etcd-druid `docs/development/`:
- `contribution.md` — contributing workflow
- `testing.md` — test framework, fake client, helpers
- `add-new-etcd-cluster-component.md` — new component guide
- `changing-api.md` — API change and deprecation process
- `getting-started-locally.md` — local dev setup

## Make Targets

```bash
# etcd-druid root (fork or worktree)
make test-unit            # unit tests
make test-integration     # integration tests with envtest
make ci-checks            # full pre-PR: format + lint + license + api-diff
make check                # format + golangci-lint only

# API generation (run from api/ subdirectory):
cd api && make generate       # regenerate deepcopy, CRDs, charts/crds/, client/
cd api && make check-generate # verify no uncommitted diff after generate
cd api && make check-apidiff  # validate API compatibility

# etcd-backup-restore
make test

# etcd-wrapper
go test ./...
```

After API type changes: commit hand-written API changes first, then
`cd api && make generate` and commit the generated output separately.
NEVER manually edit generated files.

## Targeted Test Commands

```bash
# Run single test in etcd-druid
go test ./internal/component/statefulset/... -v -run TestFoo

# Run with race detector
go test -race ./internal/...

# Verbose Ginkgo (etcd-backup-restore)
ginkgo -v ./pkg/...
```

## Git Workflow

```bash
# Create worktree
git worktree add ../etcd-druid-ai-TASK-{id} -b ai/TASK-{id}/claude/{short-description} upstream/master

# Commit style (no trailing period)
git commit -m "Add foo to bar component (#1350)"

# PR (from worktree, after human approval)
gh pr create --title "Add foo to bar component" --body "..." --base master
```

## Branch Naming

```
ai/TASK-{issue-id}/claude/{short-description}
Example: ai/TASK-1350/claude/add-configmap-ttl
```

## Skills Available (on-demand)

- `feature-dev` — full feature development workflow with approval gates
- `tdd` — TDD cycle for all three repos
- `debug` — systematic debugging workflow
- `review` — code review checklist
- `reference` — this card
