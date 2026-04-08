---
name: plan
description: Use at the start of any etcd-druid development work — picking up a GitHub issue, designing a feature or bug fix, choosing an approach, writing a code plan with acceptance criteria. Output is an approved plan file. Invoke implement next to execute it.
user-invocable: true
effort: medium
---

# Planning etcd-druid Work

Turn a GitHub issue or requirement into an approved, executable code plan. Two outputs: a plan file and Gate 1 approval. Nothing is built here.

## Work type — classify first

Before any other step, classify what you're building:

| Type | Examples | How the workflow adapts |
|------|----------|------------------------|
| **Incremental** | Add API field, fix controller bug, new component method | Full workflow as written. "Look at merged PRs" applies. |
| **New sidecar / new binary** | etcd-steward, etcd-wrapper rewrite | Phases are larger. Break tasks at package boundary. "Look at merged PRs" skipped — no prior art exists. |

When in doubt: if the task touches >5 packages or creates a new binary, it's a new sidecar.

## ⛔ Iron Law

**NO CODE BEFORE GATE 1.**

| Rationalization | Why it fails |
|---|---|
| "The task is tiny, a plan is overkill" | Small tasks skip assumptions that compound fastest |
| "I already know what to write" | Gate 1 is for the human to catch wrong assumptions before code exists |
| "The plan is in my head, that's enough" | Plans not written are not reviewable and lost after compaction |
| "Just a quick prototype to show direction" | Prototypes become the implementation. Gate 1 exists for this. |

---

## Phase 1: Design

1. Create tasks for all workflow phases with TaskCreate
2. Explore upstream (read-only) to understand current state:
   - Which controller, component, or API is affected?
   - Change type: API (`api/core/v1alpha1/`) | component (`internal/component/`) | controller (`internal/controller/`) | test only
   - Test scope required: unit (`make test-unit`) | integration (`make test-integration`) | both
   - **Look at previously merged PRs** *(incremental work only — skip for new sidecars)*
     (`gh pr list --state merged --repo gardener/etcd-druid`). Find 1–2 comparable PRs and read their diffs to understand how the team structures commits, names things, and what reviewers flag. This shapes your plan before the human sees it.
3. **State your assumptions explicitly before asking anything.** Before proposing approaches, list every assumption you are making: expected behaviour, scope, which repo is affected, whether the change is breaking. Ask about any you are not confident in. Do not silently pick an interpretation and run with it.
4. Ask clarifying questions one at a time — domain-focused
5. Propose 2–3 approaches with trade-offs
6. Confirm approach before writing plan

**Change type guide:**

| Change | Key files | Generation needed |
|--------|-----------|-------------------|
| New API field | `api/core/v1alpha1/*.go` | Yes — `cd api && make generate` |
| New component | `internal/component/<name>/` | No |
| Controller logic | `internal/controller/<name>/` | No |
| Test only | `internal/component/<name>/*_test.go` or `test/it/` | No |

**API change note:** For any API change, invoke `/etcd-druid:api-change` — it covers field design, field-scoped vs cross-field CEL validation, two-commit generate workflow, CRD test requirements, and `/kind api-change` PR label.

---

## Phase 2: Code Plan

Write plan to fork (worktree does not exist yet):

```bash
mkdir -p <fork-root>/docs/plans
```

Path: `<fork-root>/docs/plans/YYYY-MM-DD-issue-{id}-{short-description}.md`

**Plan format:**

```markdown
> **For agentic workers:** Gate 1 is pre-approved for etcd-steward work.
> For etcd-druid work, present this plan and wait for human approval before starting.
> Use implement Phase 2 (per-task subagent loop) to execute tasks.

## Issue
Link: https://github.com/gardener/etcd-druid/issues/{id}
Summary: one sentence.

## Change Type
[ ] API change (api/core/v1alpha1/)
[ ] New component (internal/component/)
[ ] Controller change (internal/controller/)
[ ] Test only

## Design Summary
Chosen approach and why. Alternatives considered.

## Tasks
- [ ] Task 1: <name>
      Acceptance criteria: <see format below>
      Files: <list>
      Tests: unit | integration | both
      API generation: yes | no

- [ ] Task 2: ...

### Acceptance criteria format

Each criterion must be falsifiable by reading code or running a test — not by trusting the implementer's description.

| ❌ Vague — spec-reviewer cannot check | ✅ Falsifiable — spec-reviewer reads code or runs test |
|---------------------------------------|-------------------------------------------------------|
| "state transitions are persisted" | `after Init() returns, member.Transitions[0].State == StateNew` (verified by `TestInitializer_NewSingleNode`) |
| "covers all 4 initialization paths" | `TestInitializer_PathA`, `_PathB`, `_PathC`, `_PathD` all exist and pass |
| "LastRestoration is updated" | `EtcdMember.Status.LastRestoration.Status == RestorationSucceeded` after `TestRestoreFromSnapshot` |

For state machine work: write the exact transition sequence for each path as a table, then name the test that verifies it. The test name IS the acceptance criterion.

## PR Checklist (pre-submission)
- [ ] make ci-checks passes
- [ ] make test-unit passes
- [ ] make test-integration passes (if integration touched)
- [ ] E2e verification: <test name or "not required — test-only change">
- [ ] Documentation updated in docs/ (if user-facing change)
- [ ] examples/ updated (if API changed)

## Rollback
How to revert if needed.
```

---

## ⛔ GATE 1: Plan Approval

STOP. No code. No worktree.

Present:
- Task list with acceptance criteria and files
- Which tasks need `cd api && make generate`
- Testing scope per task
- Plan file path

Say: **"Code plan written to `docs/plans/<filename>`. Reply 'approved' to proceed, or tell me what to change."**

Wait for explicit approval. Changes requested → update plan → present again.

---

## Handoff

Gate 1 approved → invoke `/etcd-druid:implement` with the plan file path.

Pass to `implement`:
- Plan file path (`docs/plans/YYYY-MM-DD-issue-{id}-{short-description}.md`)
- Fork root path
- Issue number
