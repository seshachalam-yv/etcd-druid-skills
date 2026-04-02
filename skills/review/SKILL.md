---
name: review
description: Code review checklist for etcd-druid, etcd-backup-restore, and etcd-wrapper contributions
---

# etcd-druid Code Review

Standalone checklist for reviewing etcd-druid, etcd-backup-restore, and etcd-wrapper contributions.

## When to Use

- Before creating a PR (self-review gate)
- When reviewing someone else's PR
- After implementing a feature (sanity check)

---

## Step 1: Read the Diff

```bash
git diff upstream/master...HEAD
```

Read every changed file. Note each category: API, component logic, tests, docs.

## Step 2: Operator Interface Completeness

New or modified component in `internal/component/<name>/` must implement all four methods:

- `PreSync(ctx OperatorContext, etcd *druidv1alpha1.Etcd) error`
- `Sync(ctx OperatorContext, etcd *druidv1alpha1.Etcd) error`
- `TriggerDelete(ctx OperatorContext, etcdObjMeta metav1.ObjectMeta) error`
- `GetExistingResourceNames(ctx OperatorContext, etcdObjMeta metav1.ObjectMeta) ([]string, error)`

Verify registration in `createAndInitializeOperatorRegistry()` in `internal/controller/etcd/reconciler.go`.

## Step 3: Error Handling

Component code must use `druiderr`, NOT `fmt.Errorf`:

```go
import druiderr "github.com/gardener/etcd-druid/internal/errors"

var ErrGetFoo = errors.New("ErrGetFoo")

return druiderr.WrapError(err, ErrGetFoo, component.OperationPreSync,
    "failed to get foo for etcd %s", druidv1alpha1.GetNamespaceName(etcd.ObjectMeta))
```

Red flags: `fmt.Errorf("...: %w", err)` in component files, `_ = err`, empty error branches.

## Step 4: API Changes

If `api/core/v1alpha1/` was touched:
- New fields need `+kubebuilder:validation:XValidation` CEL annotation
- `make generate` must have been run — `zz_generated.deepcopy.go` updated
- Breaking changes need a deprecation path or version bump

## Step 5: RBAC Markers

New resource access needs a marker in `internal/controller/etcd/reconciler.go` or the component file:

```go
// +kubebuilder:rbac:groups=apps,resources=statefulsets,verbs=get;list;watch;create;update;patch;delete
```

## Step 6: Status Updates and Finalizers

```go
r.Status().Update(ctx, obj)  // correct — subresource
r.Update(ctx, obj)           // wrong — patches main object

if controllerutil.ContainsFinalizer(obj, finalizerName) {
    // cleanup
    controllerutil.RemoveFinalizer(obj, finalizerName)
}
```

## Step 7: Tests (etcd-druid)

- Go native `testing.T` — no Ginkgo; `import . "github.com/onsi/gomega"`
- No gomock — use fake client:

```go
cl := testutils.CreateTestFakeClientForObjects(nil, nil, nil, nil, existingObjs, objKey)
cl := testutils.NewTestClientBuilder().WithObjects(obj1, obj2).Build()
opCtx := component.NewOperatorContext(ctx, logr.Discard(), uuid.NewString())
testutils.CheckDruidError(g, expectedErr, actualErr)
```

- No `time.Sleep()` — use `Eventually` / `Consistently`
- Table-driven for multiple scenarios; `t.Parallel()` in subtests

## Step 8: Commit Messages

`Verb noun detail (#NNNN)` — sentence case, imperative, no trailing period.

- `Add PreSync method to configmap component (#1350)` ✅
- `Fixed the bug.` ❌

## Step 9: Docs

New feature → update `docs/`. New component → mention in operator registry comment.

---

## Verdict

**LGTM** — all items pass, ready for PR.

**Changes required** — list each issue:
```
- <file>:<line>  What's wrong: ...  Should be: ...
```

---

## Repo Differences

| | etcd-druid | etcd-backup-restore | etcd-wrapper |
|---|---|---|---|
| Test framework | Go native + Gomega | Ginkgo v2 + Gomega | Go native + Gomega |
| Error wrapping | `druiderr.WrapError` | repo-specific patterns | standard wraps |
| Operator interface | Required | N/A | N/A |
