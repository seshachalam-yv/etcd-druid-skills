---
name: tdd
description: Use when writing new tests or learning the correct test pattern for etcd-druid, etcd-backup-restore, or etcd-wrapper — TDD cycle, framework choice, async assertions, table-driven tests. Do not use for debugging a failing test or fixing CI failures.
user-invocable: true
effort: medium
paths: "**/*.go"
---

# TDD for etcd-druid Ecosystem

Three repos, two test frameworks. Follow Red-Green-Refactor strictly.

## ⛔ Iron Law

**NO IMPLEMENTATION CODE BEFORE A FAILING TEST.**

| Rationalization | Why it fails |
|---|---|
| "This is too simple to need a test first" | The test takes two minutes. If it's simple, prove it with a test |
| "I'll add the test after" | You won't. Implementation drifts; test adapts to cover what was written, not what was required |
| "The framework is awkward here" | That's a signal to read `docs/development/testing.md`, not to skip |
| "It's a one-liner / generated code" | Generated files are never tested directly. One-liners break too. |

## Framework by Repo

| Repo | Framework | Run command |
|------|-----------|-------------|
| etcd-druid | Go native `testing.T` + Gomega | `make test-unit` |
| etcd-wrapper | Go native `testing.T` + Gomega | `make test` |
| etcd-backup-restore | Ginkgo v2 + Gomega | `make test-unit` (via `hack/test-unit.sh`) |

Before writing any tests, read `docs/development/` in the repo you are working in.
The testing guide there is authoritative for patterns, helpers, and conventions.
If you discover a pattern not documented there, add it.

## The TDD Cycle

### Step 1 — Red: Write the failing test

Write the test first. It must compile and then fail — not just fail to compile.

Run and confirm failure:
```bash
make test-unit 2>&1 | grep -A 5 "FAIL\|--- FAIL"   # etcd-druid
make test 2>&1 | grep -A 5 "FAIL\|Failure"          # etcd-backup-restore
go test ./... 2>&1 | grep -A 5 "FAIL\|--- FAIL"     # etcd-wrapper
```

### Step 2 — Green: Write minimal code to pass

Implement only what the test requires. No extra logic.

Run and confirm green — read the full output before claiming it passes:
```bash
make test-unit  # or go test ./... or make test
```

Apply the verification gate (`skills/verification/SKILL.md`) before claiming green.

### Step 3 — Refactor: Clean up while staying green

- Extract magic values to named constants
- Simplify conditional logic
- Remove duplication
- Re-run tests after each change — they must stay green

### Step 4 — Commit: One commit per passing test group

Commit message style: `Add unit tests for <component> (#<issue>)` — no trailing period.

## Rules

- NEVER use `time.Sleep()` — use `Eventually` / `Consistently` for async assertions
- NEVER use gomock for component tests — use the fake client (see docs/development/)
- NEVER use Ginkgo in etcd-druid or etcd-wrapper test files — new code uses Go native `testing.T` + Gomega (some legacy packages still use Ginkgo but new tests must not add to them)
- ALWAYS run the test before writing implementation to confirm it fails
- ALWAYS use `t.Parallel()` in table-driven tests unless the test mutates shared state
- If API types in `api/core/v1alpha1/` change, run `cd api && make generate` and commit
  the hand-written API change first, then the generated output separately. NEVER manually
  edit generated files.
- See `testing-anti-patterns.md` in this directory for domain-specific anti-patterns to avoid.

## Red Flags — Stop and re-read the Iron Law

| Thought | Why it fails |
|---|---|
| "I'll write the test after, just to see if it works" | The test becomes a verification, not a specification. You've already anchored on the implementation. |
| "This is obvious, the test would just mirror the code" | Obvious tests catch obvious regressions. Write it. |
| "The framework is awkward here so I'll skip TDD" | That's a signal to read `docs/development/testing.md`, not to skip. |
| "It's a refactor — behavior doesn't change" | If behavior doesn't change, the test is trivial. Write it first. |
| "I already wrote similar tests" | You wrote tests for similar code. Write tests for this code. |

## Integration Tests (etcd-druid)

etcd-druid has two integration test directories — use the newer one (`test/it/`) for new tests:

| Directory | Style | When to use |
|-----------|-------|-------------|
| `test/it/` | Go native `testing.T` + envtest | **New tests** — controller IT, CRD validation |
| `test/integration/` | Ginkgo + envtest | **Existing tests** — modify in place, do not migrate |

### envtest setup pattern

```go
func TestMyController(t *testing.T) {
    g := gomega.NewWithT(t)
    testEnv := &envtest.Environment{
        CRDDirectoryPaths: []string{filepath.Join("..", "..", "api", "core", "v1alpha1", "crds")},
    }
    cfg, err := testEnv.Start()
    g.Expect(err).NotTo(gomega.HaveOccurred())
    defer testEnv.Stop()
    // ...
}
```

**Important:**
- Do NOT use `t.Parallel()` in envtest integration tests — they share the API server
- Use `Eventually` / `Consistently` for async controller assertions, never `time.Sleep()`
- CRD installation happens via `CRDDirectoryPaths` — both CEL and non-CEL variants exist
- Use `skipCELTestsForOlderK8sVersions(t)` guard for CEL validation tests

### Fake client and test builders (etcd-druid)

etcd-druid uses a fake client builder for unit tests (not gomock). Key utilities in `test/utils/`:

```go
// Build an Etcd resource for testing
etcd := utils.EtcdBuilderWithoutDefaults("test-ns", "etcd-main").
    WithReplicas(3).
    WithProviderLocal().
    Build()

// Create a fake client pre-loaded with objects
fakeClient := fake.NewClientBuilder().
    WithScheme(scheme).
    WithObjects(etcd).
    WithStatusSubresource(etcd).
    Build()
```

**Rules:**
- Use `EtcdBuilderWithoutDefaults` (not `EtcdBuilderWithDefaults`) when you need to control specific field values
- Use `WithStatusSubresource` when the test reads or writes `.status`
- Use `fake.NewClientBuilder()` from `sigs.k8s.io/controller-runtime/pkg/client/fake`
- NEVER use gomock for component tests — the fake client replaces it entirely

### etcd-backup-restore test patterns

Uses Ginkgo v2 with a specific naming convention:
- **Positive tests:** Normal `It("should do X")` blocks
- **Negative tests:** Prefixed with `NEGATIVE:` — e.g., `It("NEGATIVE: should fail when X")`
- Tests run in two passes: positive first (`--skip="NEGATIVE:.*"`), then negative (`--focus="NEGATIVE:.*"`)
- Race detection enabled by default (`-race -trace`)
- Mock generation via `go.uber.org/mock`

### etcd-wrapper test patterns

Uses `testing.T` + Gomega with:
- `g := NewWithT(t)` pattern everywhere
- Table-driven tests as the standard
- Custom `TestRoundTripper` (function implementing `http.RoundTripper`) for HTTP mocking
- `EtcdFakeKV` struct implementing `clientv3.KV` for etcd client mocking
- `internal/testutil/tls.go` generates real CA + client certs in test temp dirs
- `zaptest.NewLogger(t)` for production-like zap loggers in tests

## Handoff

- Test written and passing → run `make ci-checks` first, then invoke `/etcd-druid:review`
- Test failing unexpectedly after Green → invoke `/etcd-druid:debug`; if dispatched from debug Phase 5, return there once the regression test is committed
- Writing tests for a feature being implemented → tests feed into `/etcd-druid:implement` Phase 2
