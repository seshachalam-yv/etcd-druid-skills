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

- `UseEtcdWrapper` feature gate is **GA, locked true** — it cannot be disabled. Any code that checks `Enabled(UseEtcdWrapper)` is dead code.
- `--enable-etcd-member-gc` AND `--k8s-member-gc-duration` flags in etcd-backup-restore were **both removed** in v0.42 — do not reference either.
- `PreferClose` in `ClientService.TrafficDistribution` is **deprecated** — use `PreferSameZone` or `PreferSameNode` instead.
- `StoreSpec` secret-based endpoint configuration is **deprecated** — use `spec.backup.store.endpointOverride` (etcd-druid) / `--store-endpoint-override` (etcd-backup-restore) instead.
- EtcdOpsTask controller lives in `internal/controller/etcdopstask/` — review task state machine transitions if touched. `OnDemandSnapshot` is also auto-triggered during hibernation (replicas=0) and `UpgradeEtcdVersion` flow.
- `UpgradeEtcdVersion` feature gate is alpha — if touched, gating code must check `featureGates.Enabled(features.UpgradeEtcdVersion)`. Feature gates defined in `api/config/v1alpha1/features.go`.
- Snapshot compression is **enabled by default** in etcd-backup-restore v0.40+ — do not add explicit `--compress-snapshots=true` unless overriding the default policy.
- etcd-backup-restore and etcd-wrapper use **vendored dependencies** — any dependency change requires `make revendor`, not just `go mod tidy`.
- **Container lookup must use name, not index** — when finding a container in a StatefulSet PodSpec, always `findContainerByName("etcd")` or iterate and match `.Name`. Never assume `containers[0]` is the etcd container — init containers, sidecars, or reordering break index-based lookups.
- **Error codes use `Err` prefix (Go identifier) / `ERR_` prefix (string code)** — etcd-druid-specific error types in `internal/errors/` use Go's `Err` camelCase prefix for the identifier (e.g., `ErrCreateStatefulSet`) and an `ERR_` underscore-separated string for the error code value. Do not invent new error code styles or use bare `errors.New()` in component files.
- **Use `*int32` / `*bool` for optional fields, not sentinels** — optional numeric fields in the API use pointer types (`*int32`, `*bool`) with `omitempty`, not sentinel values like `-1` or `0`. Sentinel values leak into CEL validation logic and cause confusing rules.
- **CEL rules: check for redundancy between field-scoped and cross-field** — a field-scoped rule on `EtcdConfig` and a cross-field rule on `Etcd` root may enforce the same constraint. Reviewers should verify no overlap exists — redundant rules cause double-rejection error messages that confuse operators.
- **Operator-visible names must be descriptive** — names that appear in `kubectl get` output, events, or conditions (e.g., container names, condition types) should be human-readable and descriptive. Do not use internal code identifiers or abbreviations as operator-facing names.
- **Feature gate changes require `docs/deployment/feature-gates.md` update** — when adding, graduating, or removing a feature gate in `api/config/v1alpha1/features.go`, the documentation at `docs/deployment/feature-gates.md` must be updated in the same PR.
- **Test assertions must exercise all test table fields** — in table-driven tests, every field in the test struct must be asserted somewhere in the test body. A field like `expectedRequeue` that exists in the table but is never checked in assertions is dead code that gives false confidence.

---

## Red Flags — Stop Before Issuing Verdict

| Observation | What it means |
|---|---|
| Diff is >500 lines or touches >5 packages | Too large for a single review — flag this to the author before proceeding |
| API type changed but no generated files in diff | Two-commit rule violated — `cd api && make generate` was not run |
| Test file uses `import . "github.com/onsi/ginkgo/v2"` in etcd-druid | Wrong framework — etcd-druid uses `testing.T`, not Ginkgo |
| `time.Sleep()` in any test | Async anti-pattern — should use `Eventually`/`Consistently` |
| `CHANGES REQUESTED` verdict without reading `docs/development/` | Iron Law violation — read the docs first |
| New function, type, or parameter with no caller in this PR | YAGNI violation — flag it |

---

## Verdict

**LGTM** — all items pass, ready for PR.

**Changes required** — list each issue:
```
- <file>:<line>  What's wrong: ...  Should be: ...
```

If you are the author receiving this verdict, follow `skills/receiving-review/SKILL.md` to handle the feedback.

**Documentation gaps** — conventions in code not yet in docs/development/, OR mistakes found in this plugin's skills:

For gaps in **repo docs** (`docs/development/`): list them inline as before.

For gaps or mistakes in **this plugin's skills**: write each one directly to `plugin-observations.md` using the Bash tool:

```bash
PLUGIN_OBS="${CLAUDE_PLUGIN_ROOT}/plugin-observations.md"
NEXT_NUM=$(grep -oE '^## OBS-[0-9]+' "$PLUGIN_OBS" 2>/dev/null | grep -oE '[0-9]+' | sort -n | tail -1 || echo "0")
NEXT_NUM=$(printf '%03d' $((NEXT_NUM + 1)))

# Create file with header if needed
if [ ! -f "$PLUGIN_OBS" ]; then
  printf '# Plugin Observations\n\nAuto-captured. Run `/etcd-druid:observations` to triage.\n\n---\n\n## Resolved\n\n_(none yet)_\n' > "$PLUGIN_OBS"
fi

# Insert before Resolved section
TMPFILE=$(mktemp)
awk -v entry="
## OBS-${NEXT_NUM} — <type> in <plugin_file>

**Date:** $(date +%Y-%m-%d)
**Source:** review-skill
**Type:** <wrong_claim|missing_convention|missing_footgun|unclear_workflow|stale_path_or_flag>
**Confidence:** high
**Count:** 1
**File:** \`<skills/name/SKILL.md>\`
**Section:** <section heading>

**Wrong / Missing:**
> <exact wrong text, or MISSING>

**Proposed fix:**
<what it should say — specific enough to write without investigation>

**Apply:** MULTILINE — apply manually

**Evidence:**
> <what in the diff or docs revealed this>

**Status:** open

---
" '/^## Resolved/{print entry} {print}' "$PLUGIN_OBS" > "$TMPFILE" && mv "$TMPFILE" "$PLUGIN_OBS"
```

Fill in `<type>`, `<plugin_file>`, `<section>`, `<wrong_text>`, `<proposed_fix>`, and `<evidence>` from what you found. Run the bash block once per plugin gap found. The user will triage these via `/etcd-druid:observations`.

---

## Repo Differences

| | etcd-druid | etcd-backup-restore | etcd-wrapper |
|---|---|---|---|
| Test framework | Go native + Gomega | Ginkgo v2 + Gomega | Go native + Gomega |
| Error wrapping | `druiderr.WrapError` | repo-specific patterns | standard wraps |
| Operator interface | Required | N/A | N/A |
| CLI framework | cobra (main), stdlib flag (druidctl) | cobra | stdlib `flag` |
| Dependency management | `make tidy` | `make revendor` (vendor/) | `make revendor` (vendor/) |
| Logging | logr (structured) | logrus (field-based) | zap (structured JSON) |
| CI pipeline | `.github/workflows/base.yaml` | `.github/workflows/build.yaml` | `.github/workflows/build.yaml` |
| Lint config | golangci-lint v2 | golangci-lint v2 | golangci-lint v2 |
| Generated files | deepcopy, CRDs, client/, api-ref | none | none |
| Commit convention | imperative, `(#NNNN)` suffix | imperative, `(#NNNN)` suffix | imperative, `(#NNNN)` suffix |

## Handoff

- Review verdict is LGTM and invoked from `/etcd-druid:implement` Phase 3 → return there for Gate 2
- Review verdict is LGTM and invoked standalone (from `tdd` or `debug`) → work is ready to open a PR
- Review verdict is CHANGES REQUESTED and you are the author → follow `skills/receiving-review/SKILL.md`
- Review finds a pattern not in Known Footguns → add it to this skill's Known Footguns section
