---
name: tdd
description: Use when the goal is to write tests that don't exist yet or learn the correct testing pattern — starting a TDD cycle, choosing between Ginkgo and native testing.T, setting up a Ginkgo suite, writing async assertions without time.Sleep, adding unit tests for a new method, or designing table-driven tests for better coverage. Applies across etcd-druid, etcd-backup-restore, and etcd-wrapper. Do not apply when debugging a panic in an already-written test, fixing flaky tests, or diagnosing CI failures.
user-invocable: true
---

# TDD for etcd-druid Ecosystem

Three repos, two test frameworks. Follow Red-Green-Refactor strictly.

## Framework by Repo

| Repo | Framework | Run command |
|------|-----------|-------------|
| etcd-druid | Go native `testing.T` + Gomega | `make test-unit` |
| etcd-wrapper | Go native `testing.T` + Gomega | `go test ./...` |
| etcd-backup-restore | Ginkgo v2 + Gomega | `make test` |

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

Commit message style: `Add unit tests for <component> (#<issue>)` — no trailing period.

## Rules

- NEVER use `time.Sleep()` — use `Eventually` / `Consistently` for async assertions
- NEVER use gomock for component tests — use the fake client (see docs/development/)
- NEVER use Ginkgo in etcd-druid or etcd-wrapper test files
- ALWAYS run the test before writing implementation to confirm it fails
- ALWAYS use `t.Parallel()` in table-driven tests unless the test mutates shared state
- If API types in `api/core/v1alpha1/` change, run `cd api && make generate` and commit
  the hand-written API change first, then the generated output separately. NEVER manually
  edit generated files.
