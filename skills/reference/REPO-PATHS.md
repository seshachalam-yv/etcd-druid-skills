# Repository Paths & Source Locations

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
Reconcile triggers:  internal/controller/etcd/reconcile_spec.go
                     - shouldReconcileSpec(): requires annotation OR EnableEtcdSpecAutoReconcile
                     - Annotation: gardener.cloud/operation=reconcile (consumed after use)
                     - Config: OperatorConfiguration.EnableEtcdSpecAutoReconcile=true
                     - Without either, spec changes are NOT reconciled
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
