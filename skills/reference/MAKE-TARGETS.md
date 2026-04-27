# Make Targets & Test Commands

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
