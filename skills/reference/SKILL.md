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

## Repository Paths

```
Upstream (read-only):
  github.com/gardener/etcd-druid
  github.com/gardener/etcd-backup-restore
  github.com/gardener/etcd-wrapper

Fork (write here):
  github.com/<your-github-user>/etcd-druid  (check `git remote -v` for local path)

Worktree (active development):
  .worktrees/etcd-druid-ai-TASK-{id}/   (under fork root, gitignored)
```

---

## Key Source Locations

### etcd-druid

```
API types:           api/core/v1alpha1/  (etcd.go, etcdopstask.go, etcdcopybackupstask.go)
Config types:        api/config/v1alpha1/  (OperatorConfiguration, features.go)
Component operators: internal/component/<name>/  (10 components — see list below)
Component registry:  internal/component/registry.go
Controllers:         internal/controller/etcd/reconciler.go
                     internal/controller/compaction/
                     internal/controller/etcdcopybackupstask/
                     internal/controller/etcdopstask/
                     internal/controller/secret/
Controller register: internal/controller/register.go
Error types:         internal/errors/
Health checks:       internal/health/
Image vector:        internal/images/
Metrics:             internal/metrics/
Store abstraction:   internal/store/
Utilities:           internal/utils/
Webhooks:            internal/webhook/
Test utilities:      test/utils/
E2e tests:           test/e2e/  (Go native tests, refactored from Ginkgo in v0.35)
Integration tests:   test/it/  (newer, Go native + envtest)
                     test/integration/  (older, Ginkgo + envtest)
CEL validation:      test/it/crdvalidation/etcd/
                     test/it/crdvalidation/etcdopstask/
                     test/it/crdvalidation/etcdcopybackupstask/
druidctl CLI:        druidctl/  (own go.mod, own Makefile)
Generated client:    client/  (own go.mod — clientset, informers, listers)
Generated code:      api/core/v1alpha1/zz_generated.deepcopy.go
                     api/core/v1alpha1/crds/*.yaml  (with + without CEL variants)
                     charts/crds/*.yaml
                     docs/api-reference/etcd-druid-api.md
Development docs:    docs/development/
Helm charts:         charts/
Examples:            examples/
```

**10 components** in `internal/component/`:
clientservice, configmap, memberlease, peerservice, poddistruptionbudget,
role, rolebinding, serviceaccount, snapshotlease, statefulset.

### etcd-backup-restore

```
Entry point:         main.go → cmd/  (cobra subcommands: server, snapshot, restore, compact, initialize, copy)
Snapshotter:         pkg/snapshot/snapshotter/
Restorer:            pkg/snapshot/restorer/
Copier:              pkg/snapshot/copier/
Compactor:           pkg/compactor/
Defragmentor:        pkg/defragmentor/
Initializer:         pkg/initializer/
Member control:      pkg/member/
Leader election:     pkg/leaderelection/
Health/heartbeat:    pkg/health/heartbeat/
HTTP server:         pkg/server/
Snap store:          pkg/snapstore/  (S3, ABS, GCS, Swift, OSS, ECS, OCS, Local)
Types/config:        pkg/types/
Compression:         pkg/compressor/  (gzip, lzw, zlib)
Errors:              pkg/errors/
Metrics:             pkg/metrics/
Utilities:           pkg/miscellaneous/
Mocks:               pkg/mock/
Test suites:         test/integration/, test/e2e/, test/perf/
Development docs:    docs/development/  (local_setup.md, testing_and_dependencies.md, tests.md, new_cp_support.md)
Usage docs:          docs/usage/  (backup_sync_dual_site.md, enabling_immutable_snapshots.md, garbage_collection.md)
Operations docs:     docs/operations/  (manual_restoration.md, metrics.md, leader_election.md)
Vendored deps:       vendor/  (uses go mod vendor, NOT go mod tidy alone)
```

### etcd-wrapper

```
Entry point:         main.go → cmd/etcd.go  (stdlib flag, NOT cobra)
Application core:    internal/app/app.go  (Setup + Start flow)
Readiness server:    internal/app/readycheck.go  (/readyz, /stop on port 9095)
Bootstrap/init:      internal/bootstrap/bootstrap.go  (BR init loop, config fetch, file perms)
BR HTTP client:      internal/brclient/brclient.go  (GetInitializationStatus, TriggerInitialization, GetEtcdConfig)
Config types:        internal/types/config.go, constants.go
TLS utilities:       internal/util/tls.go
HTTP utilities:      internal/util/http.go
Retry (generics):    internal/util/retry.go  (Retry[T], Result[T])
Signal handling:     internal/signal/signal.go  (SetupHandler[T] with generics)
Test TLS helper:     internal/testutil/tls.go  (TLSResourceCreator)
Local dev scripts:   hack/local-dev/  (kind.sh, etcd-up.sh, etcd-down.sh, generate_pki.sh)
Ops/debug:           ops/Dockerfile  (ephemeral debug container with etcdctl)
                     ops/print-etcd-cheatsheet.sh
Development docs:    docs/development/  (testing.md, contribution.md)
Concepts:            docs/concepts/bootstrap.md  (lifecycle diagram)
Vendored deps:       vendor/  (uses go mod vendor)
```

---

## Development Guides (read before coding)

### etcd-druid `docs/development/`:
- `contribution.md` — contributing workflow
- `testing.md` — test framework, fake client, helpers
- `add-new-etcd-cluster-component.md` — new component guide
- `changing-api.md` — API change and deprecation process
- `implementing-new-etcdopstask.md` — adding new EtcdOpsTask types
- `controllers.md` — controller architecture
- `getting-started-locally.md` — local dev setup
- `running-e2e-tests.md` — e2e test guide
- `dependency-management.md` — Go dependency management
- `updating-documentation.md` — mkdocs setup

### etcd-backup-restore `docs/development/`:
- `local_setup.md` — local build/run, credential setup
- `testing_and_dependencies.md` — dependency management (vendor), test execution, coverage
- `tests.md` — integration tests, unit tests, perf tests, e2e with emulators
- `new_cp_support.md` — adding new cloud provider for snapstore

### etcd-wrapper `docs/development/`:
- `testing.md` — testing.T + Gomega patterns, table-driven tests, coverage
- `contribution.md` — fork workflow, prerequisites, make targets

---

## Make Targets

### etcd-druid

```bash
make build                # build binary (replaced make druid in v0.33)
make tidy                 # go mod tidy (must produce no diff in CI)
make ci-checks            # full pre-PR: format + lint + license + api-diff
make check                # format + golangci-lint only
make test-unit            # unit tests (Ginkgo + Go native)
make test-integration     # integration tests with envtest
make ci-e2e-kind          # full e2e on KIND cluster
make test-e2e             # e2e against already-deployed cluster
make docker-build         # build container image
make deploy / deploy-dev  # skaffold deploy to cluster
make kind-up / kind-down  # manage KIND cluster
make add-license-headers  # add Apache-2.0 headers
make update-dependencies  # update Go dependencies

# API generation (run from api/ subdirectory):
cd api && make generate       # regenerate deepcopy, CRDs, charts/crds/, client/
cd api && make check-generate # verify no uncommitted diff after generate
cd api && make check-apidiff  # validate API compatibility
cd api && make test-unit      # API module unit tests
```

### etcd-backup-restore

```bash
make build                # build etcdbrctl binary (CGO_ENABLED=0)
make verify               # check + test-unit
make check                # golangci-lint + goimports + helm + format
make test-unit            # Ginkgo unit tests
make test-integration     # integration tests
make ci-e2e-kind          # e2e with Localstack (AWS) on KIND
make ci-e2e-kind-gcp      # e2e with FakeGCS
make ci-e2e-kind-azure    # e2e with Azurite
make revendor             # go mod tidy + go mod vendor
make docker-build         # build container image
make kind-up / kind-down  # manage KIND cluster
make deploy-localstack    # deploy AWS emulator
make deploy-fakegcs       # deploy GCS emulator
make deploy-azurite       # deploy Azure emulator
```

### etcd-wrapper

```bash
make build                # CGO_ENABLED=0 go build -mod vendor
make test                 # go test with coverage
make check                # golangci-lint
make sast                 # gosec security scanner
make revendor             # go mod tidy + go mod vendor
make docker-build         # build container image
make add-license-headers  # add license headers
make clean                # remove bin/
```

After API type changes: commit hand-written API changes first, then
`cd api && make generate` and commit the generated output separately.
NEVER manually edit generated files — a PreToolUse hook blocks this automatically.

---

## Targeted Test Commands

```bash
# Run single test in etcd-druid
go test ./internal/component/statefulset/... -v -run TestFoo

# Run with race detector
go test -race ./internal/...

# Run single integration test (etcd-druid)
go test ./test/it/controller/etcd/... -v -run TestFoo

# Verbose Ginkgo (etcd-backup-restore)
ginkgo -v ./pkg/...

# Run specific Ginkgo test (etcd-backup-restore)
ginkgo -v --focus "should take full snapshot" ./pkg/snapshot/snapshotter/

# Run etcd-wrapper tests
go test -v ./cmd/... ./internal/... -run TestFoo

# Run targeted e2e (etcd-druid)
make PROVIDERS="none,local" GO_TEST_ARGS="-run TestEtcdReconcilerWithNoBackup -v" test-e2e
```

---

## Git Workflow

```bash
# Create worktree (under .worktrees/, gitignored)
git worktree add .worktrees/etcd-druid-ai-TASK-{id} \
  -b ai/TASK-{id}/claude/{short-description} upstream/master

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

---

## EtcdOpsTask (Controller — etcd-druid v0.34+)

`EtcdOpsTask` CRD (`etcdopstask.druid.gardener.cloud/v1alpha1`) — manages one-shot operational tasks against an etcd cluster.

```
Controller:    internal/controller/etcdopstask/
CRD:           api/core/v1alpha1/etcdopstask.go
Proposal:      docs/proposals/05-etcdopstask.md
Usage guide:   docs/usage/using-etcdopstask.md
New task guide: docs/development/implementing-new-etcdopstask.md
IT tests:      test/it/controller/etcdopstask/
               test/it/crdvalidation/etcdopstask/
```

Supported task types:
- `OnDemandSnapshot` — trigger full/delta snapshot (also auto-triggered during hibernation and UpgradeEtcdVersion)
- `QuorumRecovery` — recover quorum after node loss
- `Compaction` — trigger etcd compaction
- `Defragmentation` — defrag etcd storage
- `BackupCopy` — copy backup to a secondary target

Execution model: FIFO, one active task per Etcd cluster.
TTL-based cleanup: `ttlSecondsAfterFinished`.

Status state machine:
```
Pending → InProgress → Succeeded
                    ↘ Failed
                    ↘ Rejected  (invalid task or cluster not ready)
```

LastOperationType: `Admit`, `Execution`, `Cleanup`.

---

## druidctl CLI

CLI tool for operators to interact with etcd-druid without direct kubectl.
Location: `druidctl/` (own go.mod, own Makefile). Merged in PR #1212 (Phase 1).

Key commands:
```bash
druidctl reconcile suspend --namespace <ns> --name <etcd>
druidctl reconcile resume  --namespace <ns> --name <etcd>
druidctl protect           --namespace <ns> --name <etcd>   # set deletion protection
druidctl list              --namespace <ns>                  # list Etcd resources
```

---

## Etcd Version Upgrade (`UpgradeEtcdVersion` — alpha, v0.36+)

Coordinated across all three repos. If touching upgrade-related code, check all repos for paired changes.

```
1. etcd-druid:
   - Feature gate enabled in OperatorConfiguration (api/config/v1alpha1/features.go)
   - Creates EtcdOpsTask (OnDemandSnapshot, IsFinal=true) BEFORE upgrade begins
   - Adds --next-cluster-version-compatible to generated etcd configmap
   - Also triggers pre-hibernation snapshot when replicas → 0

2. etcd-backup-restore:
   - --next-cluster-version-compatible flag passed to embedded etcd in compaction
   - /snapshot/full?final=true marks snapshots as final for migration safety
   - Restorer handles compressed + final snapshots

3. etcd-wrapper:
   - Starts embedded etcd 3.5.27 with upgraded embed.Config from BR /config endpoint
   - Readiness check via /readyz verifies etcd is healthy post-upgrade
```

---

## Feature Gates (etcd-druid)

Defined in `api/config/v1alpha1/features.go`. Configured via `OperatorConfiguration.FeatureGates` map.

| Gate | Default | Stage | Since | Notes |
|------|---------|-------|-------|-------|
| `UpgradeEtcdVersion` | false | alpha | v0.36 | Coordinates etcd 3.5.27 upgrade with pre-upgrade snapshot |
| `UseEtcdWrapper` | true | GA (locked) | v0.25 | Cannot be disabled; effectively always on |

---

## etcd-backup-restore Flags — Key Changes

| Flag | Status | Version | Notes |
|------|--------|---------|-------|
| `--store-endpoint-override` | new | v0.41+ | Overrides storage endpoint; replaces deprecated secret-based approach |
| `--secondary-*` flags | new | v0.41+ | Dual-site backup sync (secondary-storage-provider, secondary-store-container, etc.) |
| `--next-cluster-version-compatible` | new | v0.42+ | For etcd version upgrade compatibility |
| `--compress-snapshots` | default=true | v0.40+ | Snapshot compression on by default (gzip) |
| `--enable-etcd-member-gc` | **removed** | v0.42 | Do not reference |
| `--k8s-member-gc-duration` | **removed** | v0.42 | Do not reference |

Dual-site backup: configure via `--secondary-*` flags and `SECONDARY_` env var prefix.
Immutable snapshots: S3 (Object Lock), ABS, GCS, OSS (WORM Lock).

---

## etcd-wrapper CLI Flags

| Flag | Default | Description |
|------|---------|-------------|
| `--etcd-wrapper-port` | 9095 | HTTP server port (/readyz, /stop) |
| `--etcd-client-port` | 2379 | etcd client port |
| `--backup-restore-host-port` | :8080 | BR sidecar address |
| `--backup-restore-tls-enabled` | false | TLS for BR communication |
| `--backup-restore-ca-cert-bundle-path` | "" | CA cert for BR TLS |
| `--etcd-server-name` | "" | Server name for etcd TLS |
| `--etcd-client-cert-path` | "" | etcd client TLS cert |
| `--etcd-client-key-path` | "" | etcd client TLS key |
| `--etcd-ready-timeout` | 0 (forever) | Timeout waiting for etcd ready |

---

## Recent API Additions (etcd-druid)

| Field | Version | Notes |
|-------|---------|-------|
| `spec.etcd.clientService.trafficDistribution` | v0.36 | `PreferSameZone`, `PreferSameNode` (K8s 1.34). `PreferClose` **deprecated**. |
| `spec.etcd.enableGRPCGateway` | v0.35 | Enable gRPC gateway |
| `spec.backup.store.endpointOverride` | v0.35 | Object store endpoint override (replaces deprecated secret-based approach) |
| `spec.etcd.snapshotCount` | v0.33 | Default reduced from 75000 to 10000 |
| `EtcdOpsTask` CRD | v0.34 | On-demand operational tasks |
| `ClusterIDMismatch` condition | v0.34 | Split-brain detection |

---

## Dependency Management

| Repo | Vendoring | Tidy command | Notes |
|------|-----------|-------------|-------|
| etcd-druid | No | `make tidy` | Standard go.sum |
| etcd-druid api/ | No | `cd api && make tidy` | Separate module |
| etcd-druid client/ | No | (generated) | Separate module, do not edit |
| etcd-druid druidctl/ | No | `cd druidctl && go mod tidy` | Separate module |
| etcd-backup-restore | **Yes** (vendor/) | `make revendor` | Always vendor after dep changes |
| etcd-wrapper | **Yes** (vendor/) | `make revendor` | Always vendor after dep changes |

---

## Tooling Versions (current)

| Tool | etcd-druid | etcd-backup-restore | etcd-wrapper |
|------|------------|---------------------|--------------|
| Go | 1.24+ | 1.25+ | 1.25+ |
| etcd | 3.5.27 | 3.5.27 | 3.5.27 |
| golangci-lint | v2 | v2 | v2 |
| K8s deps | v0.34.3 | — | — |
| controller-runtime | v0.22.5 | — | — |

---

## Skills Available (on-demand)

- `plan` — design phase: issue analysis, approach selection, code plan with approval gate (Gate 1)
- `implement` — execution phase: worktree setup, per-task subagent loop, verification, PR creation (Gate 2)
- `api-change` — API field design, CEL validation (field-scoped + cross-field), two-commit generate, CRD tests
- `tdd` — TDD cycle for all three repos
- `debug` — systematic debugging workflow
- `review` — code review checklist
- `e2e` — manual e2e testing: KIND setup, custom image builds, sidecar overrides, pre-PR CI
- `reference` — this card
