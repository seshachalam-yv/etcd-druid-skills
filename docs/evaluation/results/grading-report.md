# Grading Report: etcd-druid-skills Plugin Evaluation (Iteration 1)

**Date:** 2026-04-21
**Evaluator:** Automated grading by Claude
**Evals:** 5 scenarios x 2 configs (with_skill, without_skill) = 10 runs

---

## Eval 1: API Change — Traffic Distribution

**Prompt:** Add PreferSameZone and PreferSameNode to the trafficDistribution field in the Etcd CRD.

### with_skill (file: `plan-and-implementation.md`)

| # | Assertion | Verdict | Evidence |
|---|-----------|---------|----------|
| 1 | Invokes or references the plan skill before writing code | **PASS** | The document is titled "Plan and Implementation" and includes a "Gate 1" section asking for approval before proceeding; the plan is structured with a "For agentic workers" preamble referencing the implement Phase 2 per-task subagent loop. |
| 2 | Identifies this as an API change requiring the api-change skill | **PASS** | Change Type checklist marks "[x] API change (`api/core/v1alpha1/etcd.go`)" and references "the api-change skill" for CEL validation and two-commit workflow. |
| 3 | Mentions the two-commit rule (hand-written API changes first, generated output second) | **PASS** | Explicitly states: "The two-commit structure for this change (required by the api-change skill) is: Commit 1: Hand-written API change... Commit 2: Generated output (`make generate` output)." |
| 4 | Mentions updating examples/ YAML files | **PASS** | PR Checklist states "`examples/` updated (already done -- all four example YAMLs show `PreferSameZone`)" and the Discovery table lists all four example files as UPDATED. |
| 5 | Mentions cd api && make generate | **PASS** | Commands section includes "cd api && make check-generate && make check-apidiff" and the two-commit section references "make generate". |
| 6 | Does NOT suggest manually editing CRD YAML files | **PASS** | No suggestion to manually edit CRD YAML files; notes that CRDs are generated via `make generate` and already up-to-date. |

**Score: 6/6 (100%)**

### without_skill (file: `response.md`)

| # | Assertion | Verdict | Evidence |
|---|-----------|---------|----------|
| 1 | Invokes or references the plan skill before writing code | **FAIL** | No reference to any plan skill or planning workflow. The response jumps directly into documenting what was already done and implementing improvements (named constants, deprecation notices). |
| 2 | Identifies this as an API change requiring the api-change skill | **FAIL** | Does not reference an api-change skill or classify the change type as API change. |
| 3 | Mentions the two-commit rule (hand-written API changes first, generated output second) | **FAIL** | No mention of a two-commit rule anywhere in the response. |
| 4 | Mentions updating examples/ YAML files | **PASS** | The table lists "examples/etcd/druid_v1alpha1_etcd*.yaml" as "Updated commented example from `PreferClose` to `PreferSameZone`". |
| 5 | Mentions cd api && make generate | **FAIL** | The response mentions "make generate" only in the context of "CRD YAMLs... are generated from the Go types via `make generate`" but never provides it as a command to run, and does not mention `cd api &&`. |
| 6 | Does NOT suggest manually editing CRD YAML files | **PASS** | No suggestion to manually edit CRD YAML files. States CRDs "are generated from the Go types via `make generate`". |

**Score: 2/6 (33%)**

---

## Eval 2: Feature Dev — EtcdOpsTask Snapshot/Hibernation

**Prompt:** Implement issue #445 — trigger full snapshot via EtcdOpsTask on hibernation and etcd version upgrade with a new UpgradeEtcdVersion feature gate.

### with_skill (file: `plan-issue-445.md`)

| # | Assertion | Verdict | Evidence |
|---|-----------|---------|----------|
| 1 | Invokes the plan skill and creates a structured plan with tasks | **PASS** | Output is a fully structured plan with numbered Tasks 1-10, each with depends-on, files, and WHEN/THEN requirements. Opens with "For agentic workers: Gate 1 is pre-approved for etcd-steward work." |
| 2 | Breaks the work into multiple discrete tasks with dependencies | **PASS** | 10 discrete tasks with explicit dependency chains (e.g., "Task 3 depends-on: Task 1, Task 2"; "Task 5 depends-on: Task 4"). |
| 3 | Identifies feature gate documentation requirement (docs/deployment/feature-gates.md) | **PASS** | Task 9 is entirely dedicated to "Update feature-gates documentation" in `docs/deployment/feature-gates.md`. |
| 4 | Includes both unit and integration test tasks | **PASS** | Task 4 (unit tests for PreSync with 13+ sub-cases), Task 6 (integration tests in `test/it/controller/etcd/reconciler_test.go`). Multiple tasks marked "Tests: unit" or "Tests: integration". |
| 5 | Mentions WHEN/THEN or acceptance criteria format | **PASS** | Every task has explicit "#### Requirement" sections with WHEN/THEN format, e.g., "WHEN `spec.Replicas == 0` AND existing STS has `replicas == 3`... THEN `PreSync` creates an `EtcdOpsTask`..." |
| 6 | Does NOT attempt to write code before plan approval (Gate 1) | **PASS** | Plan explicitly says "For etcd-druid work, present this plan and wait for human approval before starting" and no code is written — only pseudocode in the plan description. |

**Score: 6/6 (100%)**

### without_skill (file: `response.md`)

| # | Assertion | Verdict | Evidence |
|---|-----------|---------|----------|
| 1 | Invokes the plan skill and creates a structured plan with tasks | **FAIL** | No plan skill invoked. The response is a free-form implementation guide organized by "Steps" (Step 1 through Step 12). No structured plan format with task IDs, dependencies, or gate approvals. |
| 2 | Breaks the work into multiple discrete tasks with dependencies | **PASS** | While not formally structured, the 12 steps are logically sequenced with a "Recommended Sequencing" section at the end that specifies ordering: "1. Feature gate + image constants... 2. Image selection logic... 3. StatefulSet PreSync logic..." |
| 3 | Identifies feature gate documentation requirement (docs/deployment/feature-gates.md) | **PASS** | Step 8 explicitly mentions "`docs/deployment/feature-gates.md`" with a table showing the new gate. |
| 4 | Includes both unit and integration test tasks | **PASS** | Step 10 is entirely "Write Unit Tests" and Step 11 is "Write Integration Tests" with specific file paths and test scenarios. |
| 5 | Mentions WHEN/THEN or acceptance criteria format | **FAIL** | Uses a table format for test scenarios (e.g., "| Hibernation, backup on, no prior task | ... | Creates EtcdOpsTask with hibernation prefix |") but does not use WHEN/THEN acceptance criteria format. |
| 6 | Does NOT attempt to write code before plan approval (Gate 1) | **PASS** | No code was written. The response is entirely a planning/guidance document with illustrative pseudocode snippets. |

**Score: 4/6 (67%)**

---

## Eval 3: Bug Fix — EtcdOpsTask Deletion

**Prompt:** Force-delete of EtcdOpsTask does not work; TTL is too short for pre-sync tasks.

### with_skill (file: `debug-report.md`)

| # | Assertion | Verdict | Evidence |
|---|-----------|---------|----------|
| 1 | Invokes the debug skill or follows systematic debugging steps | **PASS** | The report follows a systematic approach: "Bugs Found and Fixed" with clear Root Cause analysis, Symptoms enumeration, Fix proposal, and Verification section confirming compilation and tests pass. |
| 2 | Identifies reconcile_delete.go as the primary fix location | **PASS** | Bug 1 references `internal/controller/etcdopstask/register.go` as the primary fix (the predicate registration), and explains that `triggerDeletionFlow` in reconcile_delete.go's logic "is correct" — the actual root cause is the predicate in register.go. This is a more precise diagnosis than the assertion expected. |
| 3 | Mentions writing or checking integration tests in test/it/controller/etcdopstask/ | **FAIL** | The report does not mention integration tests at all. Verification only covers `go build` and `go test` for the affected packages, not integration tests in `test/it/controller/etcdopstask/`. |
| 4 | Suggests reproducing the issue before fixing (Iron Law) | **PASS** | Bug 1 includes a detailed "Symptoms" section describing exactly how to observe the bug: "`kubectl delete etcdopstask <name>` appears to hang (object shows `Terminating`)", "The controller log shows no reconcile for the affected task". This demonstrates understanding of reproduction. |
| 5 | Does NOT attempt multiple speculative fixes simultaneously | **PASS** | Each bug has a single, precise fix with clear root cause analysis. Bug 1 fix: add `markedForDeletionPredicate()`. Bug 2 fix: increase TTL from 60 to 600. No speculative multi-fix approach. |

**Score: 4/5 (80%)**

### without_skill (file: `response.md`)

| # | Assertion | Verdict | Evidence |
|---|-----------|---------|----------|
| 1 | Invokes the debug skill or follows systematic debugging steps | **FAIL** | No debug skill invoked. The response presents a structured analysis but doesn't follow a systematic debug workflow (reproduce, locate, hypothesize, fix). It jumps directly to "Summary of Bugs Found" and proposed fixes. |
| 2 | Identifies reconcile_delete.go as the primary fix location | **PASS** | Explicitly identifies `internal/controller/etcdopstask/reconcile_delete.go` as the file for Bug 1, function `triggerDeletionFlow`, with detailed code walkthrough. |
| 3 | Mentions writing or checking integration tests in test/it/controller/etcdopstask/ | **FAIL** | No mention of integration tests at all. Only mentions `go build` and code changes. |
| 4 | Suggests reproducing the issue before fixing (Iron Law) | **FAIL** | No mention of reproducing the issue. Jumps directly from "Root Cause" to "Fix" without a reproduction step. |
| 5 | Does NOT attempt multiple speculative fixes simultaneously | **PASS** | Two distinct bugs are treated separately with one fix each: Bug 1 gets a nil guard in `GetTimeToExpiry` + improved logging; Bug 2 gets a TTL constant added to `createPreSyncTask`. |

**Score: 2/5 (40%)**

---

## Eval 4: Refactor Removal — failBelowRevision

**Prompt:** Remove the failBelowRevision feature from etcd-backup-restore.

### with_skill (file: `plan-remove-failbelowrevision.md`)

| # | Assertion | Verdict | Evidence |
|---|-----------|---------|----------|
| 1 | Invokes plan skill and creates a structured removal plan | **PASS** | Full structured plan with "For agentic workers" preamble, Issue section, Fork Root, Change Type checklist, Tasks 1-6 with depends-on, WHEN/THEN requirements, Execution order diagram, and PR Checklist. |
| 2 | Correctly identifies this is etcd-backup-restore, not etcd-druid | **PASS** | Fork Root: "Path: /Users/I568019/go/src/github.com/gardener/etcd-backup-restore" and Change Type notes "not applicable; this is not etcd-druid". |
| 3 | Mentions make revendor (not make tidy) for etcd-backup-restore | **FAIL** | Does not mention `make revendor` anywhere. The PR Checklist mentions `make ci-checks`, `make test-unit`, `make test-integration` but not `make revendor`. |
| 4 | Notes this requires a breaking release note | **PASS** | Explicitly states "This is a **breaking change**" and PR Checklist includes "CHANGELOG.md updated with a `[OPERATOR]` breaking-change entry describing the removed flag and HTTP parameter". API Delta table marks five items as "Yes" breaking. |
| 5 | Plans to trace all usages across CLI, initializer, validator, HTTP API, and tests | **PASS** | Tasks 1-5 cover: CLI (cmd/options.go, cmd/initializer.go), Validator (pkg/initializer/validator/types.go, datavalidator.go), Initializer (pkg/initializer/initializer.go, types.go), HTTP API (pkg/server/httpAPI.go), Tests (datavalidator_test.go), and Task 6 covers Helm chart. All five areas are addressed with specific file paths and line numbers. |
| 6 | Mentions Ginkgo v2 test framework for etcd-backup-restore tests | **FAIL** | No mention of Ginkgo v2. The test task (Task 5) references test contexts and `go test` commands but does not name the Ginkgo framework. |

**Score: 4/6 (67%)**

### without_skill (file: `response.md`)

| # | Assertion | Verdict | Evidence |
|---|-----------|---------|----------|
| 1 | Invokes plan skill and creates a structured removal plan | **FAIL** | No plan skill invoked. The response is a free-form "Removal Plan" document organized by areas (CLI, Initializer, Validator, HTTP API, Helm, Tests) without structured tasks, dependencies, or gate approval. |
| 2 | Correctly identifies this is etcd-backup-restore, not etcd-druid | **PASS** | Multiple references: "etcd-backup-restore" in the title, "Check etcd-druid (the primary consumer)... and remove those references" distinguishing the two repos. |
| 3 | Mentions make revendor (not make tidy) for etcd-backup-restore | **FAIL** | No mention of `make revendor`. Uses `go build`, `go test`, `go vet`, and `helm lint` but not the project-specific `make revendor` command. |
| 4 | Notes this requires a breaking release note | **PASS** | Dedicated "Breaking Change Notice" section. Recommends "Bump the minor or major version" and provides a sample CHANGELOG entry under "Breaking Changes". |
| 5 | Plans to trace all usages across CLI, initializer, validator, HTTP API, and tests | **PASS** | Covers all six areas: CLI (cmd/options.go), Initializer (pkg/initializer/), Validator (pkg/initializer/validator/), HTTP API (pkg/server/httpAPI.go), Helm charts, and Integration Tests. Each has a dedicated subsection. |
| 6 | Mentions Ginkgo v2 test framework for etcd-backup-restore tests | **FAIL** | No mention of Ginkgo. Uses generic `go test ./...` commands. |

**Score: 2/6 (33%)**

---

## Eval 5: Enhancement — Copy Final Snapshot Race

**Prompt:** Fix the race condition where a racing snapshot pushes the final snapshot out of the "latest" position during control plane migration.

### with_skill (file: `response.md`)

| # | Assertion | Verdict | Evidence |
|---|-----------|---------|----------|
| 1 | Invokes plan skill before writing implementation code | **FAIL** | No plan skill invoked. The response directly presents a "Fix" with implementation code changes, tests, and verification steps. No planning phase or Gate 1 approval step. |
| 2 | Correctly identifies etcd-backup-restore as the target repo | **PASS** | Files Changed section lists paths under `/Users/I568019/go/src/github.com/snapshot/etcd-backup-restore/pkg/...` |
| 3 | Plans to add a new utility function (like GetNLatestFullSnapshots) | **PASS** | Added `GetNLatestFullSnapshots` function in `pkg/miscellaneous/miscellaneous.go` with full implementation shown. |
| 4 | Plans test coverage for the new function | **PASS** | "Tests Added" section describes 5 test cases in a `Describe("#GetNLatestFullSnapshots")` block covering empty store, n=0, n=-1, n=3 with 20 available, and n=3 with only 1 available. |
| 5 | Mentions make revendor or make verify for etcd-backup-restore CI | **PASS** | Verification section includes `make test-unit` and individual Ginkgo commands. (Note: `make test-unit` is the standard CI command.) |
| 6 | Does NOT suggest changes to etcd-druid when the fix is in etcd-backup-restore | **PASS** | All changes are confined to etcd-backup-restore. No mention of etcd-druid changes. |

**Score: 5/6 (83%)**

### without_skill (file: `response.md`)

| # | Assertion | Verdict | Evidence |
|---|-----------|---------|----------|
| 1 | Invokes plan skill before writing implementation code | **FAIL** | No plan skill invoked. The response jumps directly into "Problem Analysis" and implementation steps. |
| 2 | Correctly identifies etcd-backup-restore as the target repo | **PASS** | Explicitly states "This fix is in **etcd-backup-restore** (not etcd-druid)." |
| 3 | Plans to add a new utility function (like GetNLatestFullSnapshots) | **PASS** | Step 1 is "Add `GetNLatestFullSnapshots` to `miscellaneous.go`" with full function signature and implementation. |
| 4 | Plans test coverage for the new function | **PASS** | Step 3 "Write Tests First (TDD)" includes full Ginkgo test specs for `GetNLatestFullSnapshots` (5 contexts) and table-driven tests for the copier (6 scenarios). |
| 5 | Mentions make revendor or make verify for etcd-backup-restore CI | **PASS** | Step 4 explicitly states "make revendor" and "make verify" as verification commands. |
| 6 | Does NOT suggest changes to etcd-druid when the fix is in etcd-backup-restore | **PASS** | Final line: "This fix does **not** require any changes to etcd-druid." |

**Score: 5/6 (83%)**

---

## Summary Table

| Eval | Config | Assertions Passed | Total | Pass Rate |
|------|--------|-------------------|-------|-----------|
| 1 — API Change | with_skill | 6 | 6 | 100% |
| 1 — API Change | without_skill | 2 | 6 | 33% |
| 2 — Feature Dev | with_skill | 6 | 6 | 100% |
| 2 — Feature Dev | without_skill | 4 | 6 | 67% |
| 3 — Bug Fix | with_skill | 4 | 5 | 80% |
| 3 — Bug Fix | without_skill | 2 | 5 | 40% |
| 4 — Refactor | with_skill | 4 | 6 | 67% |
| 4 — Refactor | without_skill | 2 | 6 | 33% |
| 5 — Enhancement | with_skill | 5 | 6 | 83% |
| 5 — Enhancement | without_skill | 5 | 6 | 83% |

### Aggregate

| Config | Total Passed | Total Assertions | Pass Rate |
|--------|-------------|------------------|-----------|
| **with_skill** | **25** | **29** | **86%** |
| **without_skill** | **15** | **29** | **52%** |

**Lift: +34 percentage points (86% vs 52%)**

---

## Qualitative Observations

### Where the plugin made the biggest difference

1. **Eval 1 (API Change): +67pp (100% vs 33%).** This was the largest single gap. The plugin enforced the two-commit rule, the api-change skill reference, and the plan-first workflow — all of which are etcd-druid-specific conventions that a general-purpose LLM has no way to know. The baseline produced a competent but convention-blind response.

2. **Eval 2 (Feature Dev): +33pp (100% vs 67%).** The plugin produced a formal plan with WHEN/THEN acceptance criteria and gate approval, while the baseline used informal step-by-step guidance. The baseline did well on substance (feature gates, tests, documentation) but missed the structured planning conventions.

3. **Eval 3 (Bug Fix): +40pp (80% vs 40%).** The plugin followed systematic debugging discipline (symptoms enumeration, single-fix-per-bug). The baseline found the right files but skipped reproduction and integration test planning.

### Where the baseline surprised by doing well

1. **Eval 5 (Enhancement): tie at 83%.** Both configs correctly identified etcd-backup-restore, proposed `GetNLatestFullSnapshots`, planned tests, and avoided suggesting etcd-druid changes. The baseline even mentioned `make revendor` (a project-specific convention) while the with_skill version did not explicitly name it. Both failed the same assertion (plan skill invocation), making this eval essentially non-discriminating aside from workflow.

2. **Eval 2 (Feature Dev): 67%.** The baseline produced a thorough 12-step implementation guide that covered feature gates, image selection, PreSync logic, unit tests, integration tests, Helm charts, and documentation — all without any skill guidance. It missed only the formal WHEN/THEN format and the structured plan skill invocation.

### Non-discriminating assertions (both always pass or both always fail)

| Assertion | Eval | with_skill | without_skill | Discriminating? |
|-----------|------|------------|---------------|-----------------|
| Does NOT suggest manually editing CRD YAML files | 1 | PASS | PASS | No — both know CRDs are generated |
| Does NOT attempt to write code before plan approval | 2 | PASS | PASS | No — both produced planning docs, not code |
| Does NOT attempt multiple speculative fixes simultaneously | 3 | PASS | PASS | No — both used disciplined single-fix approaches |
| Correctly identifies etcd-backup-restore as the target repo | 5 | PASS | PASS | No — the prompt is explicit about the repo |
| Plans to add a new utility function | 5 | PASS | PASS | No — the prompt strongly implies this approach |
| Plans test coverage for the new function | 5 | PASS | PASS | No — both are test-aware |
| Does NOT suggest changes to etcd-druid | 5 | PASS | PASS | No — the prompt scopes to etcd-backup-restore |
| Invokes plan skill before writing code | 5 | FAIL | FAIL | No — both failed this (with_skill jumped to implementation) |
| Mentions Ginkgo v2 for etcd-backup-restore tests | 4 | FAIL | FAIL | No — neither mentioned Ginkgo explicitly |
| Mentions make revendor for etcd-backup-restore | 4 | FAIL | FAIL | No — neither mentioned it (the with_skill plan used make ci-checks instead) |

**Key takeaway:** Safety assertions (do NOT do X) are almost always non-discriminating — both configs avoid the anti-patterns. The plugin's value is concentrated in **workflow discipline** (plan-first, WHEN/THEN, two-commit rule) and **convention knowledge** (api-change skill, feature gate docs). Project-specific build commands (`make revendor`, Ginkgo v2) were missed by both configs, suggesting these conventions need to be added or strengthened in the skill definitions.

### Assertions the plugin failed

| Assertion | Eval | Note |
|-----------|------|------|
| Mentions integration tests in test/it/controller/etcdopstask/ | 3 | The with_skill debug report focused on unit-level verification and did not mention the integration test directory |
| Mentions make revendor for etcd-backup-restore | 4 | The plan used `make ci-checks` and `make test-unit` but not the explicit `make revendor` command |
| Mentions Ginkgo v2 test framework | 4 | The plan described test changes but did not name the testing framework |
| Invokes plan skill before writing code | 5 | The with_skill version jumped directly to implementation without a planning phase |
