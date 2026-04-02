---
name: tdd
description: Use when implementing any feature or bugfix in the etcd-druid ecosystem — write failing tests first, then minimal code to pass, then refactor
---

# TDD for etcd-druid Ecosystem

Three repos, two test frameworks. Follow Red-Green-Refactor strictly.

## Framework by Repo

| Repo | Framework | Run command |
|------|-----------|-------------|
| etcd-druid | Go native `testing.T` + Gomega | `make test-unit` |
| etcd-wrapper | Go native `testing.T` + Gomega | `go test ./...` |
| etcd-backup-restore | Ginkgo v2 + Gomega | `make test` |

## The TDD Cycle

### Step 1 — Red: Write the failing test

**etcd-druid / etcd-wrapper** (Go native + Gomega):

```go
package statefulset_test  // use _test suffix for black-box testing

import (
    "context"
    "testing"

    . "github.com/onsi/gomega"
    "github.com/go-logr/logr"
    "github.com/google/uuid"
    "github.com/gardener/etcd-druid/internal/component"
    testutils "github.com/gardener/etcd-druid/test/utils"
)

func TestMyFeature(t *testing.T) {
    testCases := []struct {
        name        string
        input       string
        expectErr   bool
        expectedVal string
    }{
        {name: "returns value on success", input: "valid", expectedVal: "ok"},
        {name: "returns error on bad input", input: "", expectErr: true},
    }

    t.Parallel()
    for _, tc := range testCases {
        t.Run(tc.name, func(t *testing.T) {
            t.Parallel()
            g := NewWithT(t)

            // Build operator context (required for all component operations)
            opCtx := component.NewOperatorContext(context.Background(), logr.Discard(), uuid.NewString())

            // Build fake client — inject errors by position: (getErr, listErr, createErr, updateErr, objects, objKey)
            etcd := testutils.EtcdBuilderWithDefaults(testutils.TestEtcdName, testutils.TestNamespace).Build()
            cl := testutils.CreateTestFakeClientForObjects(nil, nil, nil, nil, nil, nil)

            result, err := MyFeature(opCtx, cl, etcd)

            if tc.expectErr {
                g.Expect(err).To(HaveOccurred())
            } else {
                g.Expect(err).ToNot(HaveOccurred())
                g.Expect(result).To(Equal(tc.expectedVal))
            }
        })
    }
}
```

Run and confirm it **fails** (not a compile error — the test must compile and then fail):
```bash
make test-unit 2>&1 | grep -A 5 "FAIL\|--- FAIL"
```

**etcd-backup-restore** (Ginkgo v2):

```go
var _ = Describe("MyFeature", func() {
    var (
        ctx context.Context
    )

    BeforeEach(func() {
        ctx = context.Background()
    })

    AfterEach(func() {
        // clean up resources
    })

    Context("when input is valid", func() {
        It("should return expected value", func() {
            result, err := MyFeature(ctx, "valid")
            Expect(err).ToNot(HaveOccurred())
            Expect(result).To(Equal("ok"))
        })
    })

    Context("when input is empty", func() {
        It("should return an error", func() {
            _, err := MyFeature(ctx, "")
            Expect(err).To(HaveOccurred())
        })
    })
})
```

Run and confirm failure:
```bash
make test 2>&1 | grep -A 5 "FAIL\|Failure"
```

### Step 2 — Green: Write minimal code to pass

Implement only what the test requires. No extra logic.

For component errors in etcd-druid, use `druiderr` (not `fmt.Errorf`):

```go
import (
    druidv1alpha1 "github.com/gardener/etcd-druid/api/core/v1alpha1"
    druiderr "github.com/gardener/etcd-druid/internal/errors"
)

var ErrGetMyResource = errors.New("ErrGetMyResource")

func getMyResource(ctx component.OperatorContext, cl client.Client, etcd *druidv1alpha1.Etcd) error {
    if err := cl.Get(ctx, client.ObjectKey{...}, obj); err != nil {
        return druiderr.WrapError(err, ErrGetMyResource, component.OperationPreSync,
            "failed to get my resource for etcd %s", druidv1alpha1.GetNamespaceName(etcd.ObjectMeta))
    }
    return nil
}
```

Run and confirm green:
```bash
make test-unit  # or go test ./... or make test
```

### Step 3 — Refactor: Clean up while staying green

- Extract magic values to named constants
- Simplify conditional logic
- Remove duplication
- Re-run tests after each change — they must stay green

### Step 4 — Commit: One commit per passing test group

```bash
git add <files>
git commit -m "Add unit tests for foo component (#1350)"
```

Commit message style: `Add unit tests for <component> (#<issue>)` — no trailing period.

## Fake Client Patterns

```go
// Inject a GET error for a specific object key:
cl := testutils.CreateTestFakeClientForObjects(testutils.TestAPIInternalErr, nil, nil, nil, existingObjs, objKey)

// Builder pattern for multiple pre-existing objects:
cl := testutils.NewTestClientBuilder().WithObjects(obj1, obj2).Build()

// Check a DruidError returned from component code:
testutils.CheckDruidError(g, expectedErr, actualErr)
```

## Rules

- NEVER use `time.Sleep()` — use `Eventually` / `Consistently` for async assertions
- NEVER use gomock for component tests — use the testutils fake client
- NEVER use Ginkgo in etcd-druid or etcd-wrapper test files
- ALWAYS run the test before writing implementation to confirm it fails
- ALWAYS use `t.Parallel()` in table-driven tests unless the test mutates shared state
