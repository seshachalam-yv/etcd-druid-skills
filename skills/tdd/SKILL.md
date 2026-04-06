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

## Red Flags

Stop and re-read the Iron Law if you catch yourself thinking:

- "I'll write the implementation first since I know what it needs to do"
- "The test is taking too long to set up, I'll skip it for now"
- "This test would need a fake client — too complex, I'll just run it manually"
- "The existing test covers this close enough"
- "I changed the implementation slightly so the old test doesn't apply"

## Handoff

After Step 4 (all tests committed and green):
- If opening a PR: run `make ci-checks`, then invoke `/etcd-druid:review`
- If this was a regression fix from `/etcd-druid:debug`: return to debug Phase 5 to confirm root cause is resolved
