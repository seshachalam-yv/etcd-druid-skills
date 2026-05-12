---
name: debug
description: Use when something is failing — test failures, reconciliation loops, backup errors, build failures in etcd-druid, etcd-backup-restore, or etcd-wrapper. Do not use for feature design or how-to questions.
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

## Before You Start: Worktree Gate

Before modifying any code, apply the worktree gate (`skills/worktree-gate/SKILL.md`).

If already in a worktree (e.g., dispatched from `implement`): use it.
If standalone: the gate creates a worktree branched from `upstream/master` with a `debug/<description>` branch.

Once in the worktree, you can always compare against master:
```bash
git diff upstream/master...HEAD              # what you changed
git show upstream/master:path/to/file        # read the original version
```

Never apply speculative fixes directly to your main working branch or fork root.

## Phase 1: Read the Error Carefully

Never scroll past error output.

- Note: file path, line number, error message, test name
- Read the full stack trace — the root cause is rarely the last line
- Distinguish compile errors from test failures

> **Building the feedback loop IS the skill.** See [FEEDBACK-LOOP.md](FEEDBACK-LOOP.md) for 10 progressively creative ways to construct a pass/fail signal.

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

**Integration test check (controller/component fixes only):**
If your fix is in `internal/controller/` or `internal/component/`, check whether an integration
test in `test/it/` covers the behavior you fixed. If yes, run it:
```bash
go test ./test/it/controller/<name>/... -v -run TestRelevantCase
```
If no integration test covers this behavior, either add one or note the gap in your report
for follow-up. Skip this step for test-only or non-controller fixes.

If the fix reveals an undocumented pattern or gotcha, add it to `docs/development/`.

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

---

For build failure triage, envtest tips, and Go gotchas, see [COMMON-FAILURES.md](COMMON-FAILURES.md). For Delve debugging and log analysis commands, see [DEBUG-COMMANDS.md](DEBUG-COMMANDS.md).

## Handoff

- Root cause identified, fix implemented → apply verification gate (`skills/verification/SKILL.md`)
- Fix implemented, needs regression test → invoke `/etcd-druid:tdd`; return here (Phase 5) once the regression test is committed and green
- Fix verified, ready for PR → invoke `/etcd-druid:review`
- Fix involves API change → invoke `/etcd-druid:api-change`
