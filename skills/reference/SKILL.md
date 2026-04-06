---
name: reference
description: Use when you need quick lookup of file paths, make targets, error patterns, fake client constructors, branch naming, or operator interface signatures for the etcd-druid ecosystem
user-invocable: true
---

# etcd-druid Ecosystem — Quick Reference Card

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
Controllers:         internal/controller/etcd/reconciler.go (etcd, compaction, etcdcopybackupstask, etcdopstask, secret)
Error types:         internal/errors/
Test utilities:      test/utils/
CEL validation:      test/it/crdvalidation/
Generated code:      api/core/v1alpha1/zz_generated.deepcopy.go
                     api/core/v1alpha1/crds/*.yaml  (generated CRD manifests)
                     charts/crds/*.yaml             (copied from above by make generate)
                     client/                        (generated typed clientset)
```

## Operator Interface (all 4 required)

```go
type Operator interface {
    PreSync(ctx OperatorContext, etcd *druidv1alpha1.Etcd) error
    Sync(ctx OperatorContext, etcd *druidv1alpha1.Etcd) error
    TriggerDelete(ctx OperatorContext, etcdObjMeta metav1.ObjectMeta) error
    GetExistingResourceNames(ctx OperatorContext, etcdObjMeta metav1.ObjectMeta) ([]string, error)
}

// Operation name constants:
component.OperationPreSync                  = "PreSync"
component.OperationSync                     = "Sync"
component.OperationTriggerDelete            = "TriggerDelete"
component.OperationGetExistingResourceNames = "GetExistingResourceNames"

// Register: registry.Register(component.Kind, operator)
// Find registration in: internal/controller/etcd/reconciler.go
```

## OperatorContext Construction (tests)

```go
import (
    "github.com/gardener/etcd-druid/internal/component"
    "github.com/go-logr/logr"
    "github.com/google/uuid"
)
opCtx := component.NewOperatorContext(context.Background(), logr.Discard(), uuid.NewString())
```

## Error Handling (component code)

```go
import (
    druidapicommon "github.com/gardener/etcd-druid/api/common"
    druiderr "github.com/gardener/etcd-druid/internal/errors"
)

// Error codes are typed string constants — NOT errors.New():
const (
    ErrGetFoo    druidapicommon.ErrorCode = "ERR_GET_FOO"
    ErrSyncFoo   druidapicommon.ErrorCode = "ERR_SYNC_FOO"
    ErrDeleteFoo druidapicommon.ErrorCode = "ERR_DELETE_FOO"
)

// WrapError signature:
// func WrapError(err error, code druidapicommon.ErrorCode, operation string, message string) error
return druiderr.WrapError(err, ErrGetFoo, component.OperationPreSync,
    fmt.Sprintf("failed to get foo for etcd %s", druidv1alpha1.GetNamespaceName(etcd.ObjectMeta)))
```

## Fake Client (tests — NO gomock)

```go
import testutils "github.com/gardener/etcd-druid/test/utils"

// With error injection on specific get:
cl := testutils.CreateTestFakeClientForObjects(getErr, nil, nil, nil, existingObjects, objKey)

// Builder pattern:
cl := testutils.NewTestClientBuilder().WithObjects(objs...).Build()
```

## Make Targets

```bash
# etcd-druid root (fork or worktree)
make test-unit            # Unit tests (Go native + Ginkgo suites)
make test-integration     # Integration tests with envtest
make ci-checks            # Full pre-PR: format + lint + license + api-diff
make check                # Format + golangci-lint only

# API generation (run from api/ subdirectory):
cd api && make generate       # Regenerate deepcopy, CRDs, charts/crds/, client/
cd api && make check-generate # Verify no uncommitted diff after generate
cd api && make check-apidiff  # Validate API compatibility

# etcd-backup-restore
make test

# etcd-wrapper
go test ./...
```

After API type changes: commit hand-written API changes first, then `cd api && make generate` and commit the generated output separately. NEVER manually edit generated files.

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

## CEL Validation (API fields)

```go
// +kubebuilder:validation:XValidation:rule="...",message="..."
type EtcdSpec struct {
    // +kubebuilder:validation:XValidation:rule="self >= 0",message="must be non-negative"
    SomeField *int32 `json:"someField,omitempty"`
}
```

## Skills Available (on-demand)

- `feature-dev` — full feature development workflow with approval gates
- `tdd` — TDD patterns for all three repos
- `debug` — systematic debugging workflow
- `review` — code review checklist
- `reference` — this card
