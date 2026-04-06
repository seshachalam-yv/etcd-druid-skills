---
name: debug
description: Use when hitting test failures, build errors, reconciliation loops, backup/restore failures, or unexpected behavior in etcd-druid, etcd-backup-restore, or etcd-wrapper
---

# Debugging in the etcd-druid Ecosystem

Use this skill when you hit: test failures, unexpected reconciliation behavior, backup/restore failures, etcd startup issues, or build failures.

## Phase 1: Read the Error Carefully

Never scroll past error output.

- Note: file path, line number, error message, test name
- Read the full stack trace — the root cause is rarely the last line
- Distinguish compile errors from test failures

## Phase 2: Reproduce Consistently

Can it be triggered with a single command?

```bash
# etcd-druid unit tests
make test-unit
go test ./internal/component/<name>/... -v -run TestFoo

# etcd-druid integration tests
make test-integration

# etcd-backup-restore
make test
go test ./pkg/... -v -run TestFoo

# etcd-wrapper
go test ./... -v -run TestFoo
```

If flaky: run 3× to confirm. Do not form a hypothesis until you can reproduce it.

## Phase 3: Locate in Source

### etcd-druid reconciliation failures

- Entry point: `internal/controller/etcd/reconciler.go` — `Reconcile()` method
- Component operators live in `internal/component/<name>/`
- Each component implements: `PreSync`, `Sync`, `TriggerDelete`, `GetExistingResourceNames`
- Error variables are package-level:
  ```go
  var ErrGetFoo = errors.New("ErrGetFoo")
  ```
- Errors are wrapped with:
  ```go
  druiderr.WrapError(err, ErrGetFoo, component.OperationPreSync, "failed to get foo for etcd %s", ...)
  ```

### API validation failures

- CEL rules: `api/core/v1alpha1/` — look for `+kubebuilder:validation:XValidation` markers
- Generated code: `api/core/v1alpha1/zz_generated.deepcopy.go`
- After changing API types, run `make generate` — NEVER manually edit zz_generated.deepcopy.go or any file with a `// Code generated` header

### Test failures

- Shared helpers: `test/utils/`
- OperatorContext construction:
  ```go
  opCtx := component.NewOperatorContext(ctx, logr.Discard(), uuid.NewString())
  ```
- Fake client construction:
  ```go
  // (getErr, listErr, createErr, updateErr, objects, objKey)
  cl := testutils.CreateTestFakeClientForObjects(nil, nil, nil, nil, nil, nil)

  // Inject a GET error for a specific key:
  cl := testutils.CreateTestFakeClientForObjects(testutils.TestAPIInternalErr, nil, nil, nil, existingObjs, objKey)

  // Builder pattern:
  cl := testutils.NewTestClientBuilder().WithObjects(obj1, obj2).Build()
  ```
- Check DruidErrors returned from component code:
  ```go
  testutils.CheckDruidError(g, expectedErr, actualErr)
  ```

## Phase 4: Form a Single Hypothesis

Before touching any code, write it down:

> "The test fails because X, which causes Y"

Test with the smallest possible change. One change, one re-run.

## Phase 5: Fix Root Cause, Not Symptom

- Fix at the source, not where the error surfaces
- One change at a time — so you know what actually fixed it
- Run tests again to verify the fix

```bash
make test-unit          # etcd-druid
make test               # etcd-backup-restore
go test ./...           # etcd-wrapper
```

## Phase 6: If 3+ Fixes Have Failed

Stop. Do not attempt another fix.

- Question your hypothesis — re-read the original error
- Check if the issue is architectural (wrong abstraction, wrong layer)
- Ask the human before trying more

## Red Flags — Stop and Re-read

- "It probably needs X" — hypothesis without reading the error first
- Changing code before reproducing the failure — go back to Phase 2
- Multiple changes in one attempt — you can't know what worked
- "One more quick fix" after two failures — see Phase 6
