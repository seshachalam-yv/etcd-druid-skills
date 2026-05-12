---
name: review
description: Use before opening a PR in etcd-druid, etcd-backup-restore, or etcd-wrapper — pre-merge checklist, self-review, pattern validation. Do not use for implementation help, debugging test failures, or questions about how things work.
user-invocable: true
effort: medium
paths: "**/*.go"
context: fork
agent: Explore
---

# etcd-druid Code Review

Standalone checklist for reviewing etcd-druid, etcd-backup-restore, and etcd-wrapper contributions.

## ⛔ Iron Law

**NO VERDICT WITHOUT READING THE DIFF AND docs/development/ FIRST.**

| Rationalization | Why it fails |
|---|---|
| "I reviewed something similar recently" | You reviewed different code. Read this diff. |
| "The author said it passes all tests" | Test passage is not the same as convention compliance — read the diff |
| "It's a small change" | Small changes in API types and generated files are highest risk |
| "I know the conventions" | `docs/development/` may have been updated since you last read it |

## Red Flags — Stop and Re-read

| Thought | Why it fails |
|---|---|
| "The code works, that's enough" | Working code with poor patterns creates maintenance debt |
| "I'll clean up in a follow-up" | Follow-ups become tech debt tickets. Fix now |
| "This pattern is used elsewhere" | Existing patterns may be wrong. Validate against docs/development/ |
| "The reviewer will catch issues" | Self-review catches 80% of what reviewers flag. Respect their time |

## When to Use

- Before creating a PR (self-review gate)
- When reviewing someone else's PR
- After implementing a feature — invoked by `/etcd-druid:implement` Phase 3 before Gate 2

---

## Worktree Context

If invoked during implementation, you should be reviewing a worktree's changes against `upstream/master`. Apply the worktree gate (`skills/worktree-gate/SKILL.md`) to confirm you are operating in the correct worktree. Use `git diff upstream/master...HEAD` for the complete diff — this is the authoritative view of what changed.

## Step 1: Read the Diff, the Docs, and Similar Merged PRs

```bash
git diff upstream/master...HEAD
# If 'upstream' remote is missing: git remote add upstream https://github.com/gardener/<repo>
```

Read every changed file. Note each category: API, component logic, tests, docs.

Then read `docs/development/` in the repo. Verify the diff matches documented conventions.
Any convention found in the code but missing from the docs is a **documentation gap** —
note it in the verdict and open a follow-up to document it.

**Find a comparable merged PR** for this change type and read it:
```bash
gh pr list --state merged --repo gardener/<repo> --limit 10
gh pr view <number>     # body: area/kind labels, release note, checklist
gh pr diff <number>     # structure: commit layout, file scope, test coverage
```
Use it to calibrate: does this PR follow the same commit structure, `/area`+`/kind` labelling, docs scope, and release note category that a real merged PR of this type used? Divergences from prior merged PRs are worth flagging.

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

**Framework per repo** (using the wrong framework is a review rejection):

| Repo | Framework | Notes |
|------|-----------|-------|
| etcd-druid | Go native `testing.T` + Gomega | No Ginkgo in new tests |
| etcd-backup-restore | **Ginkgo v2** + Gomega + `go.uber.org/mock` | NEGATIVE: prefix for negative tests |
| etcd-wrapper | Go native `testing.T` + Gomega | Table-driven, `zaptest.NewLogger(t)` |

Core rules that apply regardless of repo:
- No `time.Sleep()` — use `Eventually` / `Consistently`
- No gomock in etcd-druid component tests (use fake client instead)
- Table-driven for multiple scenarios; `t.Parallel()` in subtests

**Verify tests pass locally** (run before opening PR, or confirm author ran them):

| Repo | Commands |
|---|---|
| etcd-druid | `make test-unit` (all); `make test-integration` (if controller/component touched) |
| etcd-backup-restore | `make revendor && make test-unit`; `make test-integration` (if etcdbr logic touched) |
| etcd-wrapper | `make revendor && make test` |

## Step 8: Commit Messages

`Verb noun detail (#NNNN)` — sentence case, imperative, no trailing period.

- `Add PreSync method to configmap component (#1350)` ✅
- `Fixed the bug.` ❌

## Step 9: Docs and PR Body

**Docs:** New feature → update `docs/`. New component → mention in operator registry comment.
Any pattern found in code but absent from `docs/development/` → add it.
If new docs files are added or structure changes: `mkdocs.yml` and `docs/README.md` must also be updated.

**PR body:** Read `.github/pull_request_template.md` and verify the draft body covers every section. Then check: do the `/area` and `/kind` labels, release note category, and checklist ticks match what a comparable merged PR used? Run `gh pr view <similar-merged-pr>` if unsure.

**Gardener PR conventions (Prow-enforced):**

Prow bots parse slash commands in the PR body. Missing or wrong labels stall reviews.

| Command | Purpose | Examples |
|---------|---------|---------|
| `/area <id>` | Categorize the change area | `control-plane`, `backup`, `disaster-recovery`, `high-availability`, `testing`, `dev-productivity`, `monitoring`, `security`, `usability`, `open-source` |
| `/kind <id>` | Classify change type | `api-change`, `bug`, `enhancement`, `cleanup`, `task`, `test`, `flake`, `technical-debt`, `regression` |

Missing `/kind` causes `do-not-merge/needs-kind` label — PR cannot merge until fixed.

**Release note format** (validated by `pr-release-notes-validation.yaml` CI check):
```
Release note:
<category> <target_group>
<description>
```
Categories: `breaking`, `noteworthy`, `feature`, `bugfix`, `doc`, `other`.
Target groups: `user`, `operator`, `developer`, `dependency`.
Example: `feature operator` for a new operator-facing field.

**Merge method labels:** Add `/merge squash` (default) or `/merge keep-commits` if the two-commit API rule requires preserving commit history.

## Step 10: Known Footguns

See [FOOTGUNS.md](FOOTGUNS.md) for the full list of known footguns.

---

## Verdict

For verdict format, red flags, and repo differences, see [REVIEW-CHECKLIST.md](REVIEW-CHECKLIST.md).

## Handoff

- Review verdict is LGTM and invoked from `/etcd-druid:implement` Phase 3 → return there for Gate 2
- Review verdict is LGTM and invoked standalone (from `tdd` or `debug`) → work is ready to open a PR
- Review verdict is CHANGES REQUESTED and you are the author → follow `skills/receiving-review/SKILL.md`
- Review finds a pattern not in Known Footguns → add it to [FOOTGUNS.md](FOOTGUNS.md)
