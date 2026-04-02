---
name: reference
description: Quick reference for etcd-druid, etcd-backup-restore, and etcd-wrapper — paths, commands, patterns, interfaces
---

# etcd-druid Ecosystem — Quick Reference Card

## Repository Paths

```
Upstream (read-only):
  /Users/I568019/go/src/github.com/gardener/etcd-druid/
  /Users/I568019/go/src/github.com/gardener/etcd-backup-restore/
  /Users/I568019/go/src/github.com/gardener/etcd-wrapper/

Fork (write here):
  /Users/I568019/go/src/github.com/seshachalam-yv/etcd-druid/

Worktree (active development):
  ../etcd-druid-ai-TASK-{id}/   (relative to fork)
```

## Key Source Locations (etcd-druid)

```
API types:           api/core/v1alpha1/
Component operators: internal/component/<name>/
Controller:          internal/controller/etcd/reconciler.go
Error types:         internal/errors/
Test utilities:      test/utils/
CEL validation:      hack/cel-tests/
Generated code:      api/core/v1alpha1/zz_generated.deepcopy.go
                     charts/   (CRD YAML)
```

## Operator Interface (all 4 required)

```go
type Operator interface {
    PreSync(ctx OperatorContext, etcd *druidv1alpha1.Etcd) error
    Sync(ctx OperatorContext, etcd *druidv1alpha1.Etcd) error
    TriggerDelete(ctx OperatorContext, etcdObjMeta metav1.ObjectMeta) error
    GetExistingResourceNames(ctx OperatorContext, etcdObjMeta metav1.ObjectMeta) ([]string, error)
}

// Register in: internal/controller/etcd/reconciler.go → createAndInitializeOperatorRegistry()
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
import druiderr "github.com/gardener/etcd-druid/internal/errors"

var (
    ErrGetFoo    = errors.New("ErrGetFoo")
    ErrCreateFoo = errors.New("ErrCreateFoo")
)

// In component method:
return druiderr.WrapError(err, ErrGetFoo, component.OperationPreSync,
    "failed to get foo for etcd %s", druidv1alpha1.GetNamespaceName(etcd.ObjectMeta))
```

## Fake Client (tests — NO gomock)

```go
import testutils "github.com/gardener/etcd-druid/test/utils"

// With error injection on specific get:
cl := testutils.CreateTestFakeClientForObjects(getErr, nil, nil, nil, existingObjects, objKey)

// Builder pattern:
cl := testutils.NewTestClientBuilder().WithObjects(objs...).Build()
```

## Common Make Targets

```bash
# etcd-druid (fork or worktree)
make test-unit            # Unit tests
make test-integration     # Integration tests
make generate             # Regenerate code after API changes
make check                # Lint + vet
golangci-lint run ./...   # Lint only

# etcd-backup-restore
make test

# etcd-wrapper
go test ./...
```

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
