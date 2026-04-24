---
name: plan
description: Use when starting any development work — features, enhancements, bug fixes, refactoring, or any code change that touches more than one file. Always plan before implementing, even when the fix seems obvious. Creates an approved plan file for /etcd-druid:implement.
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

## Plan Sizing & Granularity

Right-size plans to avoid filling the context window during implementation. Oversized plans cause lost requirements, wrong-file edits, and wasted correction loops.

| Scope | Max plan lines | Strategy |
|-------|---------------|----------|
| Single-file, one-sentence diff | Skip plan | Direct implementation |
| 1–3 files | ~30 lines | Inline checklist |
| 4–10 files | ~100 lines | Task-level plan on disk |
| 10+ files | Split | One plan per subsystem, implement sequentially |

**When to split:** If the plan exceeds ~150 lines or covers more than one independent subsystem, break it into separate plan files — one per subsystem. Each plan goes through its own Gate 1 → implement cycle.

**Granularity rules:**
- Each task should be completable in 2–5 minutes — one action, independently verifiable
- No placeholders: no TBD, TODO, "similar to Task N", or "add appropriate handling"
- Exact file paths with line ranges where possible — prevents wrong-file edits
- Exact verification commands with expected output — prevents guessing

**Anti-patterns:**

| Anti-pattern | Problem | Fix |
|-------------|---------|-----|
| One plan for entire feature | Fills context, loses detail late in execution | Split into task-level plans |
| Plan lives only in conversation | Lost on `/compact` or context compression | Always save plan to disk file |
| Exploring >3 minutes before planning | Leads to wrong approaches and wasted context | Time-box exploration, then write plan |
| No verification commands in tasks | Leads to untested code and late failures | Include exact `make test` / `go vet` commands per task |
| Placeholders in plan steps | Agent interprets freely, produces wrong code | Write concrete requirements in every step |

---

## Phase 1: Design

1. Create tasks for all workflow phases with TaskCreate
2. **Read the issue first:** `gh issue view {id} --repo gardener/etcd-druid` — quote the title and acceptance criteria verbatim before doing anything else. Do not summarise from memory.
3. Explore upstream (read-only) to understand current state:
   - Which controller, component, or API is affected?
   - Change type: API (`api/core/v1alpha1/`) | component (`internal/component/`) | controller (`internal/controller/`) | test only
   - Test scope required: unit (`make test-unit`) | integration (`make test-integration`) | both
   - **Look at previously merged PRs** *(incremental work only — skip for new sidecars)*
     (`gh pr list --state merged --repo gardener/etcd-druid`). Find 1–2 comparable PRs and read their diffs to understand how the team structures commits, names things, and what reviewers flag. This shapes your plan before the human sees it.
4. **State your assumptions explicitly before asking anything.** Before proposing approaches, list every assumption you are making: expected behaviour, scope, which repo is affected, whether the change is breaking. Ask about any you are not confident in. Do not silently pick an interpretation and run with it.
5. Ask clarifying questions one at a time — domain-focused
6. Propose 2–3 approaches with trade-offs
7. Confirm approach before writing plan

**Change type guide:**

| Change | Key files | Generation needed |
|--------|-----------|-------------------|
| New API field | `api/core/v1alpha1/*.go` | Yes — `cd api && make generate` |
| New component | `internal/component/<name>/` | No |
| Controller logic | `internal/controller/<name>/` | No |
| Test only | `internal/component/<name>/*_test.go` or `test/it/` | No |

**API change note:** For any API change, invoke `/etcd-druid:api-change` — it covers field design, field-scoped vs cross-field CEL validation, two-commit generate workflow, CRD test requirements, and `/kind api-change` PR label.
For API changes: fill the `## API Delta` section in the plan (template below) — one row per field added, modified, or removed. This is the source of truth for what Commit 1 must contain.

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

## Fork Root
Path: <absolute path to local fork, e.g. /home/user/go/src/github.com/me/etcd-druid>

## Change Type
[ ] API change (api/core/v1alpha1/)
[ ] New component (internal/component/)
[ ] Controller change (internal/controller/)
[ ] Test only

## Feature Gate Impact Checklist *(required when the change introduces or modifies a feature gate that affects container images, args, or cross-container behaviour; omit otherwise)*

Follow the pattern of existing gates — search for `UseEtcdWrapper` or `UpgradeEtcdVersion` across the codebase to find every touch point. The full lifecycle (Alpha → Beta → GA) is documented in `docs/deployment/feature-gates.md` in the etcd-druid repo.

- [ ] Gate definition: `api/config/v1alpha1/features.go` — name, maturity level, default
- [ ] Image key constant: `internal/common/constants.go`
- [ ] Image selection logic: `internal/utils/image.go`
- [ ] Default image entry: `internal/images/images.yaml`
- [ ] Container spec (args, ports, probes): `internal/component/statefulset/builder.go`
- [ ] Test image vector: `test/utils/constants.go` + `test/utils/imagevector.go`
- [ ] Helm chart values: `charts/values.yaml` — add operator config toggle if applicable
- [ ] Cross-container contract: verify the new image satisfies every endpoint expected by other containers in the same Pod (read the consuming container's bootstrap/init source — not just the docs)
- [ ] Readiness/liveness probes: confirm probes still target a valid endpoint after the image swap
- [ ] Pod identity: confirm the new container receives pod name/namespace correctly (env vars vs CLI flags vs downward API)
- [ ] E2e override: document how to test with a custom image build (`IMAGEVECTOR_OVERWRITE`, local KIND registry, ConfigMap mount)

## Design Summary
Chosen approach and why. Alternatives considered.

## Tasks
- [ ] Task 1: <name>
      **depends-on:** — *(fill in: Task N if this task needs another to complete first, or `—` if none)*
      Files: <list>
      Tests: unit | integration | both
      API generation: yes | no

      #### Requirement: <what must be true after this task>
      - WHEN <the observable trigger or state>
      - THEN <specific observable outcome> (verified by `<TestName>` or `<file>:<field>:<value>`)

      *(Add one Requirement block per acceptance criterion. Multiple blocks allowed.)*

- [ ] Task 2: ...

### Acceptance criteria format

The WHEN/THEN format above is the required structure. The table below shows examples of strong vs. weak THEN clauses.

| ❌ Vague — spec-reviewer cannot check | ✅ Falsifiable — spec-reviewer reads code or runs test |
|---------------------------------------|-------------------------------------------------------|
| "state transitions are persisted" | `after Init() returns, member.Transitions[0].State == StateNew` (verified by `TestInitializer_NewSingleNode`) |
| "covers all 4 initialization paths" | `TestInitializer_PathA`, `_PathB`, `_PathC`, `_PathD` all exist and pass |
| "LastRestoration is updated" | `EtcdMember.Status.LastRestoration.Status == RestorationSucceeded` after `TestRestoreFromSnapshot` |

For state machine work: write the exact transition sequence for each path as a table, then name the test that verifies it. The test name IS the acceptance criterion.

## API Delta *(required when Change Type includes API change; omit for non-API plans)*

| Field | Change | Breaking |
|-------|--------|---------|
| `EtcdSpec.<FieldName>` | ADDED — optional `*<type>`, default nil | No |
| `EtcdSpec.<FieldName>` | MODIFIED — <description of change> | No / **Yes** |
| `EtcdSpec.<FieldName>` | REMOVED — replaced by `<new field>` | **Yes** |

*Change types: ADDED, MODIFIED, REMOVED. One row per changed field. Delete this section for non-API plans.*

## PR Checklist (pre-submission)
- [ ] make ci-checks passes (etcd-druid) / make verify (etcd-backup-restore) / make check && make test (etcd-wrapper)
- [ ] make test-unit passes
- [ ] make test-integration passes (if integration touched)
- [ ] make revendor run (etcd-backup-restore and etcd-wrapper only — required if any dependency changed)
- [ ] E2e verification: <test name or "not required — test-only change">
- [ ] Documentation updated in docs/ (if user-facing change)
- [ ] examples/ updated (if API changed)

## Rollback
How to revert if needed.
```

---

## ⛔ GATE 1: Plan Approval

STOP. No code. No worktree.

**Who approves:** The human — by replying "approved". For etcd-steward work the plan file header marks it pre-approved; for etcd-druid work, only an explicit human reply unblocks Phase 3.

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
