# Dependency Management

## Overview

| Repo | Vendoring | Tidy command | Notes |
|------|-----------|-------------|-------|
| etcd-druid | No | `make tidy` | Standard go.sum |
| etcd-druid api/ | No | `cd api && make tidy` | Separate module |
| etcd-druid client/ | No | (generated) | Separate module, do not edit |
| etcd-druid druidctl/ | No | `cd druidctl && go mod tidy` | Separate module |
| etcd-backup-restore | **Yes** (vendor/) | `make revendor` | Always vendor after dep changes |
| etcd-wrapper | **Yes** (vendor/) | `make revendor` | Always vendor after dep changes |

### Multi-module structure (etcd-druid)

etcd-druid has 4 separate Go modules. Dependency changes may need to be applied to multiple modules:

```
go.mod              ← main module (operator binary)
api/go.mod          ← API types module (imported by other projects)
client/go.mod       ← generated client (do not edit manually)
druidctl/go.mod     ← CLI tool module
```

When updating a dependency:
1. Update `go.mod` in the relevant module(s)
2. Run the appropriate tidy command per module
3. If api/ module changed: `cd api && make generate` (regenerates client/)
4. Verify: `make ci-checks` must produce no diff

### Dependabot PR workflow

Dependabot PRs require:
1. Add `/kind task` or `/kind enhancement` to the PR body (Prow blocks merge without `/kind`)
2. Verify CI passes — dependency bumps can break vendored builds
3. For etcd-backup-restore and etcd-wrapper: `make revendor` must be run if go.mod changed
4. Review: check if the dependency bump introduces breaking changes upstream

### Component version bumps (sidecar images)

When a new version of etcd-backup-restore or etcd-wrapper is released:
1. Update the image tag in `internal/images/images.yaml` (etcd-druid)
2. Add release notes in `.ocm/release-notes/` describing the sidecar update
3. Run `make ci-checks && make test-unit` to verify
4. Open a PR with `/area control-plane` and `/kind task`

### Go version upgrades

Go version is declared in multiple places per repo:
- `go.mod` (minimum version)
- `Dockerfile` (build stage)
- `.ci/pipeline_definitions` (CI runner image — Gardener CI)
- `.github/workflows/*.yaml` (GitHub Actions runner)

All must be updated together. Check the upstream Gardener Go version policy before upgrading.
