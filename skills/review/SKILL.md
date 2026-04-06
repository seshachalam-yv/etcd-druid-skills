---
name: review
description: Use whenever someone wants code reviewed or validated before opening a PR in etcd-druid, etcd-backup-restore, or etcd-wrapper — pre-merge checklists, self-reviews before submitting, "final check" on a completed implementation, pattern validation ("is testing.T okay here?", "is this commit format right?"), or any "review my changes before I open a PR" request. Do not use for implementation help, debugging test failures, or explanatory questions.
user-invocable: true
---

# etcd-druid Code Review

Standalone checklist for reviewing etcd-druid, etcd-backup-restore, and etcd-wrapper contributions.

## When to Use

- Before creating a PR (self-review gate)
- When reviewing someone else's PR
- After implementing a feature (sanity check)

---

## Step 1: Read the Diff and the Docs

```bash
git diff upstream/master...HEAD
```

Read every changed file. Note each category: API, component logic, tests, docs.

Then read `docs/development/` in the repo. Verify the diff matches documented conventions.
Any convention found in the code but missing from the docs is a **documentation gap** —
note it in the verdict and open a follow-up to document it.

## Step 2: Operator Interface Completeness

New or modified component in `internal/component/<name>/` must implement all four methods.
Verify registration in `internal/controller/etcd/reconciler.go`.

## Step 3: Error Handling

Check `docs/development/` for the correct error wrapping pattern.

Red flags: bare `fmt.Errorf` in component files, `errors.New(...)` used as an error code,
`_ = err`, empty error branches.

## Step 4: API Changes

If `api/core/v1alpha1/` was touched:
- New fields need CEL validation annotation
- `cd api && make generate` must have been run — all generated outputs must appear in the diff
- Two-commit rule: Commit 1 = hand-written API changes; Commit 2 = `make generate` output. NEVER manually edit generated files.
- CEL validation test added in `test/it/crdvalidation/etcd/` or `test/it/crdvalidation/etcdopstask/`
- Breaking changes need a deprecation path (see `docs/development/changing-api.md`)

## Step 5: RBAC Markers

New resource access needs a `+kubebuilder:rbac` marker in the component or reconciler file.

## Step 6: Status Updates and Finalizers

- Use `r.Status().Update()` for status subresource fields, not `r.Update()`
- Check `controllerutil.ContainsFinalizer` before cleanup

## Step 7: Tests

Check `docs/development/testing.md` for the expected framework, helpers, and patterns.

Core rules that apply regardless of repo:
- No `time.Sleep()` — use `Eventually` / `Consistently`
- No gomock in etcd-druid component tests
- Table-driven for multiple scenarios; `t.Parallel()` in subtests

## Step 8: Commit Messages

`Verb noun detail (#NNNN)` — sentence case, imperative, no trailing period.

- `Add PreSync method to configmap component (#1350)` ✅
- `Fixed the bug.` ❌

## Step 9: Docs

New feature → update `docs/`. New component → mention in operator registry comment.
Any pattern found in code but absent from `docs/development/` → add it.

---

## Verdict

**LGTM** — all items pass, ready for PR.

**Changes required** — list each issue:
```
- <file>:<line>  What's wrong: ...  Should be: ...
```

**Documentation gaps** — conventions in code not yet in docs/development/:
```
- <description of undocumented pattern> → should go in docs/development/<file>.md
```

---

## Repo Differences

| | etcd-druid | etcd-backup-restore | etcd-wrapper |
|---|---|---|---|
| Test framework | Go native + Gomega | Ginkgo v2 + Gomega | Go native + Gomega |
| Error wrapping | `druiderr.WrapError` | repo-specific patterns | standard wraps |
| Operator interface | Required | N/A | N/A |
