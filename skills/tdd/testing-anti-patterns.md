# etcd-druid Testing Anti-Patterns

Referenced by `tdd/SKILL.md`. Read this before writing tests in the etcd-druid ecosystem.

---

## Anti-Pattern 1: Testing the Fake Client Instead of the Component

**What it looks like:**
```go
// Asserting that Create was called on the fake client
Expect(fakeClient.CreateCallCount()).To(Equal(1))
```

**Why it fails:** You are testing the test infrastructure, not the component. The component
could call Create with the wrong object and this assertion would still pass.

**Correct alternative:** Assert the observable output — read the object from the fake client
and verify its fields:
```go
sts := &appsv1.StatefulSet{}
Expect(fakeClient.Get(ctx, client.ObjectKey{...}, sts)).To(Succeed())
Expect(sts.Spec.Replicas).To(PointTo(Equal(int32(3))))
```

---

## Anti-Pattern 2: Using gomock in etcd-druid Component Tests

**What it looks like:**
```go
mockClient := mock.NewMockClient(ctrl)
mockClient.EXPECT().Create(gomock.Any(), gomock.Any()).Return(nil)
```

**Why it fails:** etcd-druid component tests use the fake client from
`sigs.k8s.io/controller-runtime/pkg/client/fake`. gomock is for etcd-backup-restore
(which uses `go.uber.org/mock`). Mixing them causes import conflicts and violates
the documented convention in `docs/development/testing.md`.

**Correct alternative:**
```go
fakeClient := fake.NewClientBuilder().WithScheme(scheme).WithObjects(etcd).Build()
```

---

## Anti-Pattern 3: `time.Sleep()` for Async Assertions

**What it looks like:**
```go
time.Sleep(2 * time.Second)
Expect(someCondition).To(BeTrue())
```

**Why it fails:** Sleep duration is arbitrary. Tests become flaky under load (CI is slower
than local). Race conditions are masked, not fixed.

**Correct alternative:**
```go
Eventually(func(g Gomega) {
    g.Expect(someCondition).To(BeTrue())
}).WithTimeout(10 * time.Second).WithPolling(100 * time.Millisecond).Should(Succeed())
```

---

## Anti-Pattern 4: Ginkgo in etcd-druid or etcd-wrapper Test Files

**What it looks like:**
```go
import . "github.com/onsi/ginkgo/v2"

var _ = Describe("MyComponent", func() {
    It("should do X", func() { ... })
})
```

**Why it fails:** etcd-druid and etcd-wrapper use Go native `testing.T` + Gomega.
Only etcd-backup-restore uses Ginkgo v2. Mixing frameworks causes test suite registration
issues and violates the documented convention.

**Correct alternative for etcd-druid:**
```go
func TestMyComponent(t *testing.T) {
    g := gomega.NewWithT(t)
    // ...
}
```

---

## Anti-Pattern 5: Using `EtcdBuilderWithDefaults` When You Need Field Control

**What it looks like:**
```go
etcd := utils.EtcdBuilderWithDefaults("test-ns", "etcd-main").Build()
// Test asserts on etcd.Spec.Replicas — but defaults already set it to 3
Expect(etcd.Spec.Replicas).To(Equal(pointer.Int32(3)))  // always passes
```

**Why it fails:** `EtcdBuilderWithDefaults` pre-populates fields. If your test asserts
on a field that defaults set, the assertion is vacuous — it passes even if your code
never touches that field.

**Correct alternative:** Use `EtcdBuilderWithoutDefaults` when you need to control
specific field values and verify your code sets them:
```go
etcd := utils.EtcdBuilderWithoutDefaults("test-ns", "etcd-main").
    WithReplicas(3).
    Build()
```

---

## Anti-Pattern 6: Table-Driven Tests Without `t.Parallel()`

**What it looks like:**
```go
func TestMyComponent(t *testing.T) {
    cases := []struct{ ... }{ ... }
    for _, tc := range cases {
        t.Run(tc.name, func(t *testing.T) {
            // no t.Parallel()
            result := myFunc(tc.input)
            Expect(result).To(Equal(tc.expected))
        })
    }
}
```

**Why it fails:** Without `t.Parallel()`, subtests run sequentially. This slows CI and
masks shared-state bugs — a subtest that accidentally mutates shared state will pass
because the next subtest has not run yet. Running in parallel exposes the race.

**Correct alternative:**
```go
for _, tc := range cases {
    tc := tc  // capture loop variable (required before Go 1.22)
    t.Run(tc.name, func(t *testing.T) {
        t.Parallel()
        result := myFunc(tc.input)
        Expect(result).To(Equal(tc.expected))
    })
}
```

Exception: omit `t.Parallel()` only when the subtest mutates shared state that cannot
be isolated (e.g., a global registry). Document the reason with a comment.
