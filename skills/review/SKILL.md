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

## When to Use

- Before creating a PR (self-review gate)
- When reviewing someone else's PR
- After implementing a feature — invoked by `feature-dev` Phase 5 before Gate 2

---

## Step 1: Read the Diff, the Docs, and Similar Merged PRs

```bash
git diff upstream/master...HEAD
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

Core rules that apply regardless of repo:
- No `time.Sleep()` — use `Eventually` / `Consistently`
- No gomock in etcd-druid component tests
- Table-driven for multiple scenarios; `t.Parallel()` in subtests

## Step 8: Commit Messages

`Verb noun detail (#NNNN)` — sentence case, imperative, no trailing period.

- `Add PreSync method to configmap component (#1350)` ✅
- `Fixed the bug.` ❌

## Step 9: Docs and PR Body

**Docs:** New feature → update `docs/`. New component → mention in operator registry comment.
Any pattern found in code but absent from `docs/development/` → add it.
If new docs files are added or structure changes: `mkdocs.yml` and `docs/README.md` must also be updated.

**PR body:** Read `.github/pull_request_template.md` and verify the draft body covers every section. Then check: do the `/area` and `/kind` labels, release note category, and checklist ticks match what a comparable merged PR used? Run `gh pr view <similar-merged-pr>` if unsure.

## Step 10: Known Footguns

- `UseEtcdWrapper` feature gate was **removed** — any reference to it is a bug.
- `--enable-etcd-member-gc` flag in etcd-backup-restore was **removed** in v0.42 — do not reference.
- EtcdOpsTask controller lives in `internal/controller/etcdopstask/` — review task state machine transitions if touched.
- `UpgradeEtcdVersion` feature gate is alpha — if touched, gating code must check `featureGates.Enabled(features.UpgradeEtcdVersion)`.

---

## Red Flags — Stop and Re-read

- Forming a verdict before reading the full diff
- Skipping `docs/development/` because "I know this codebase"
- Marking API changes LGTM without checking both commits exist
- Missing the two-commit rule for `make generate` output
- Skipping the Repo Differences table for a repo you don't usually work in

---

## Verdict

**LGTM** — all items pass, ready for PR.

**Changes required** — list each issue:
```
- <file>:<line>  What's wrong: ...  Should be: ...
```

**Documentation gaps** — conventions in code not yet in docs/development/, OR mistakes found in this plugin's skills:
```
- <description of gap or mistake>
  → docs/development/<file>.md in <repo>   (if missing from repo docs)
  → skills/<skill>/SKILL.md in etcd-druid-skills plugin   (if skill was wrong or incomplete)
```

For each gap or mistake in the plugin, suggest a PR:

```
Plugin PR suggestion
Title: Fix <what was wrong> in <skill name> skill
Body:
  /kind bug

  **What this PR does / why we need it:**
  <describe the gap or mistake discovered during this review>

  **Discovered while:** <brief context — e.g. "reviewing PR #NNNN", "implementing feature X">

  **Fix:** <what the skill/hook/prompt should say instead>

  gh pr create \
    --repo seshachalam-yv/etcd-druid-skills \
    --base master \
    --title "Fix <what> in <skill> skill" \
    --body "..."
```

---

## Repo Differences

| | etcd-druid | etcd-backup-restore | etcd-wrapper |
|---|---|---|---|
| Test framework | Go native + Gomega | Ginkgo v2 + Gomega | Go native + Gomega |
| Error wrapping | `druiderr.WrapError` | repo-specific patterns | standard wraps |
| Operator interface | Required | N/A | N/A |

## Handoff

- LGTM → return to caller (feature-dev Gate 2, or done if standalone)
- Plugin mistake found → output the `gh pr create` block above
