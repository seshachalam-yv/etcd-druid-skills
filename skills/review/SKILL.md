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

- `UseEtcdWrapper` feature gate is **GA, locked true** — it cannot be disabled. Any code that checks `Enabled(UseEtcdWrapper)` is dead code.
- `--enable-etcd-member-gc` AND `--k8s-member-gc-duration` flags in etcd-backup-restore were **both removed** in v0.42 — do not reference either.
- `PreferClose` in `ClientService.TrafficDistribution` is **deprecated** — use `PreferSameZone` or `PreferSameNode` instead.
- `StoreSpec` secret-based endpoint configuration is **deprecated** — use `spec.backup.store.endpointOverride` (etcd-druid) / `--store-endpoint-override` (etcd-backup-restore) instead.
- EtcdOpsTask controller lives in `internal/controller/etcdopstask/` — review task state machine transitions if touched. `OnDemandSnapshot` is also auto-triggered during hibernation (replicas=0) and `UpgradeEtcdVersion` flow.
- `UpgradeEtcdVersion` feature gate is alpha — if touched, gating code must check `featureGates.Enabled(features.UpgradeEtcdVersion)`. Feature gates defined in `api/config/v1alpha1/features.go`.
- Snapshot compression is **enabled by default** in etcd-backup-restore v0.40+ — do not add explicit `--compress-snapshots=true` unless overriding the default policy.
- etcd-backup-restore and etcd-wrapper use **vendored dependencies** — any dependency change requires `make revendor`, not just `go mod tidy`.

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
**File:** \`<skills/name/SKILL.md>\`
**Section:** <section heading>

**Wrong / Missing:**
> <exact wrong text, or MISSING>

**Proposed fix:**
<what it should say — specific enough to write without investigation>

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

- Review verdict is LGTM → return to `feature-dev` Phase 5 Gate 2
- Review verdict is CHANGES REQUESTED and you are the author → follow `skills/receiving-review/SKILL.md`
- Review finds a pattern not in Known Footguns → add it to this skill's Known Footguns section
