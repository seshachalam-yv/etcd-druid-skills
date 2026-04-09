---
name: debug
description: Use when something is failing or broken in etcd-druid, etcd-backup-restore, or etcd-wrapper — test failures, reconciliation loops, backup failures, build errors. Do not use for how-to questions, feature design, or environment setup.
user-invocable: true
effort: high
paths: "**/*.go"
---

# Debugging in the etcd-druid Ecosystem

Use this skill when you hit: test failures, unexpected reconciliation behavior, backup/restore failures, etcd startup issues, or build failures.

## ⛔ Iron Law

**NO FIX ATTEMPT WITHOUT A REPRODUCIBLE FAILURE FIRST.**

| Rationalization | Why it fails |
|---|---|
| "I can see what's wrong from the error" | You have a hypothesis. Reproduce it — your hypothesis may be wrong |
| "I've seen this before" | You've seen something similar. Reproduce this specific instance |
| "It's obviously X" | "Obviously" precedes most debugging rabbit holes |
| "Reproducing it takes too long" | Fixing without reproduction takes longer |

## Before You Start: Protect Your Working State

```bash
# If you have uncommitted changes, stash them before investigating
git stash push -m "WIP: stashing before debug investigation"

# Work on a separate branch to avoid polluting main/master
git checkout -b debug/investigate-<short-description>

# To restore after investigation:
git stash pop
```

Never apply speculative fixes directly to your main working branch.
Investigation often requires trying multiple approaches — do it on a throwaway branch.

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

Check `docs/development/` in the relevant repo for documented patterns before
assuming something is a bug. If the code diverges from what the docs describe,
that is itself a finding.

### etcd-druid reconciliation failures

- Entry point: `internal/controller/etcd/reconciler.go` — `Reconcile()` method
- Component operators live in `internal/component/<name>/`
- Each component implements: `PreSync`, `Sync`, `TriggerDelete`, `GetExistingResourceNames`
- Controller registration: `internal/controller/register.go`
- EtcdOpsTask controller: `internal/controller/etcdopstask/`
- Feature gate checks: `api/config/v1alpha1/features.go`

### API validation failures

- CEL rules: `api/core/v1alpha1/` — look for `+kubebuilder:validation:XValidation` markers
- Generated code: `api/core/v1alpha1/zz_generated.deepcopy.go`
- After changing API types: `cd api && make generate` — NEVER manually edit generated files
- CEL tests: `test/it/crdvalidation/etcd/`, `test/it/crdvalidation/etcdopstask/`

### Test failures

- Shared helpers: `test/utils/`
- OperatorContext, fake client, and DruidError assertion patterns: see `docs/development/testing.md`
- Integration test env: `test/it/` (newer, Go native) and `test/integration/` (older, Ginkgo)

### etcd-backup-restore failures

- Snapshotter: `pkg/snapshot/snapshotter/snapshotter.go` — full/delta loop, event watch
- Restorer: `pkg/snapshot/restorer/restorer.go` — base restore + delta apply
- Compactor: `pkg/compactor/compactor.go` — embedded etcd restore + compact + snapshot
- HTTP server: `pkg/server/httpAPI.go` — endpoint handlers, leader forwarding
- Member control: `pkg/member/member_control.go` — scale-up, learner promotion
- Snapstore: `pkg/snapstore/` — provider-specific implementations (S3, ABS, GCS, etc.)

### etcd-wrapper failures

- Bootstrap loop: `internal/bootstrap/bootstrap.go` — BR init loop, config fetch
- Embedded etcd start: `internal/app/app.go` — `Setup()` → `Start()` flow
- BR client: `internal/brclient/brclient.go` — HTTP calls to backup-restore sidecar
- Readiness: `internal/app/readycheck.go` — `/readyz` endpoint, etcd client polling

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

Apply the verification gate (`skills/verification/SKILL.md`) before claiming the fix is confirmed.

If the fix reveals an undocumented pattern or gotcha, add it to `docs/development/`.

## Phase 6: If 3+ Fixes Have Failed

Stop. Do not attempt another fix.

- Question your hypothesis — re-read the original error
- Check if the issue is architectural (wrong abstraction, wrong layer)
- Ask the human before trying more

## Debugging with Delve

For complex reconciliation bugs or stepping through controller logic:

```bash
# Debug a specific test
dlv test ./internal/component/statefulset/... -- -test.run TestFoo

# Debug integration tests with envtest
dlv test ./test/it/controller/etcd/... -- -test.run TestReconciler

# Attach to a running controller in KIND (etcd-druid)
# First deploy with debug mode:
make deploy-debug   # deploys with dlv listening on :2345
# Then attach from host:
dlv connect localhost:2345
```

For etcd-backup-restore, similar debugging works:
```bash
dlv test ./pkg/snapshot/snapshotter/... -- -test.run TestSnapshotter
```

For etcd-wrapper:
```bash
dlv test ./internal/app/... -- -test.run TestSuit
```

## Log Analysis

Each repo uses a different logging framework. Know where to look and how to increase verbosity.

### etcd-druid (logr)

```bash
# Controller logs in KIND cluster
kubectl logs -n etcd-druid-e2e deploy/etcd-druid -f

# Filter by reconciliation key
kubectl logs -n etcd-druid-e2e deploy/etcd-druid | grep "etcd.*etcd-main"

# Increase verbosity: set log level in OperatorConfiguration or --zap-log-level=debug
```

### etcd-backup-restore (logrus)

```bash
# Sidecar logs in a pod
kubectl logs -n <ns> <etcd-pod> -c etcd-backup-restore -f

# Key log fields to watch: "operation", "snapstore", "kind" (Full/Incr)
# Snapshot failures: grep for "failed to save" or "error taking snapshot"
# Restore failures: grep for "failed to restore" or "restoration failure"

# Increase verbosity: --log-level=5 (default is 4)
```

### etcd-wrapper (zap)

```bash
# Wrapper logs in a pod
kubectl logs -n <ns> <etcd-pod> -c etcd-wrapper -f

# Key log fields: "msg", "error"
# Init loop: grep for "initialization" or "trigger"
# Etcd startup: grep for "starting etcd" or "embed"
```

## Build Failure Triage

### `make ci-checks` failures

| Failure pattern | Cause | Fix |
|----------------|-------|-----|
| `goimports-reviser` diff | Import ordering wrong | `make format` then commit |
| `golangci-lint` errors | Lint violations | Fix reported issues; check `.golangci.yaml` for config |
| License header missing | New file without SPDX header | `make add-license-headers` |
| `check-git-status` fails | Uncommitted changes after format/generate | Commit generated changes separately |
| `check-apidiff` fails | Breaking API change | Read `docs/development/changing-api.md` for deprecation path |
| `check-generate` fails | Generated files stale | `cd api && make generate` and commit output |

### `make test-unit` / `make test-integration` failures

| Failure pattern | Cause | Fix |
|----------------|-------|-----|
| `envtest` binary missing | Setup not run | `make start-envtest` or set `KUBEBUILDER_ASSETS` |
| CRD not found in envtest | Wrong CRD path | Check `CRDDirectoryPaths` in test setup |
| Flaky `Eventually` timeout | Timeout too short or race | Increase timeout; add retry-on-conflict for status updates |
| `gomock` expectation not met | Mock setup wrong | Check `EXPECT()` calls match actual invocations |
| `NEGATIVE:` test prefix | etcd-backup-restore naming convention | Not a failure — these run in a separate pass |

### Dependency / module failures

| Failure pattern | Cause | Fix |
|----------------|-------|-----|
| `go mod tidy` produces diff | Deps changed but not tidied | `make tidy` (etcd-druid) or `make revendor` (ebr, wrapper) |
| `vendor/` directory stale | Deps changed but not re-vendored | `make revendor` (etcd-backup-restore, etcd-wrapper only) |
| Module mismatch (api/ vs root) | API module has separate go.mod | `cd api && go mod tidy` separately |

## envtest Debugging Tips

envtest starts a real API server and etcd for integration tests. Common issues:

- **API server won't start:** Check if ports 1024-65535 range has conflicts. envtest picks random ports.
- **CRD installation fails:** Verify CRD YAML files exist at the paths in `CRDDirectoryPaths`. Both CEL and non-CEL variants must be present.
- **K8s version mismatch:** CEL validation tests require K8s >= 1.29. Use `skipCELTestsForOlderK8sVersions(t)` guard.
- **CEL rule silently accepts invalid input** (test asserts rejection, got `nil`): the `XValidation` rule is placed on the wrong struct level — `self.*` can only reference fields within the struct it is annotated on. Move the rule to the innermost struct that owns all referenced fields, or to the `Etcd` root type for cross-field rules. Confirm the rule was emitted by running `kubectl apply --dry-run=server -f api/core/v1alpha1/crds/*.yaml` and checking that `x-kubernetes-validations` appears at the expected path in the output.
- **Slow tests:** envtest startup takes 5-10s. Group related tests in the same test function to share the env.
- **Status update conflicts:** Use retry-on-conflict when updating `.status` — see etcd-druid PR #1302 for the pattern.
- **Cleanup:** `defer testEnv.Stop()` must always run. Leaked envtest processes block ports.

## Red Flags — Stop and Re-read

- "It probably needs X" — hypothesis without reading the error first
- Changing code before reproducing the failure — go back to Phase 2
- Multiple changes in one attempt — you can't know what worked
- "One more quick fix" after two failures — see Phase 6

## Handoff

- Root cause identified, fix implemented → apply verification gate (`skills/verification/SKILL.md`)
- Fix implemented, needs regression test → invoke `/etcd-druid:tdd`; return here (Phase 5) once the regression test is committed and green
- Fix verified, ready for PR → invoke `/etcd-druid:review`
- Fix involves API change → invoke `/etcd-druid:api-change`
