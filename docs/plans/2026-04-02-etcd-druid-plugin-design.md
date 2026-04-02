# etcd-druid Claude Code Plugin — Design Spec

**Date:** 2026-04-02  
**Author:** Seshachalam Yerasala Venkata  
**Status:** Draft — awaiting user review  

---

## Problem Statement

When developing etcd-druid, every new Claude session requires re-explaining:
- The three-component architecture (etcd-druid + etcd-backup-restore + etcd-wrapper)
- Which repo to work in (fork vs upstream)
- The Operator interface contract for new components
- Testing patterns per repo
- Commit message style
- Safety invariants (approval gates, never push without consent)

This plugin encodes all of that knowledge once, injecting it automatically at session start and loading deep domain content on demand via skills.

---

## Goals

1. Orient Claude to the three-component system at every session start (medium, ~40 lines)
2. Guide feature development end-to-end: design → plan → worktree → implement (subagents) → verify → PR
3. Enforce repo-specific testing patterns (Go native + Gomega for etcd-druid/wrapper, Ginkgo v2 + Gomega for backup-restore)
4. Debug failures across all three components using real HTTP APIs and log patterns
5. Review code against actual safety invariants of the system
6. Provide deep domain reference on demand (backup-restore API, CRD spec, TLS, component authoring)
7. Enforce two hard approval gates: after plan, before PR — never push without explicit human approval

---

## Non-Goals

- No dependency on superpowers or any other plugin at runtime — fully standalone
- No named persistent multi-agents (GEX/Dev-Alpha) — subagents only
- No coverage of Gardener components outside the etcd three-component system
- No tutorial content — audience is an expert etcd-druid developer

---

## Plugin Identity

| Field | Value |
|---|---|
| Plugin name | `etcd-druid` |
| Skill invocation prefix | `etcd-druid:<skill>` |
| Target repo (implementation) | `/Users/I568019/go/src/github.com/seshachalam-yv/etcd-druid` (fork) |
| Reference repo (read-only) | `/Users/I568019/go/src/github.com/gardener/etcd-druid` (upstream) |
| Plugin repo | `/Users/I568019/go/src/github.com/seshachalam-yv/etcd-druid-skills` |

---

## Repository Layout

```
etcd-druid-skills/
├── .claude-plugin/
│   └── plugin.json                          # manifest
├── hooks/
│   ├── hooks.json                           # SessionStart hook registration
│   ├── session-start                        # bash script — injects medium orientation
│   └── run-hook.cmd                         # hook runner
├── skills/
│   ├── feature-dev/
│   │   ├── SKILL.md                         # full workflow orchestration (standalone)
│   │   ├── implementer-prompt.md            # subagent: write code in worktree
│   │   ├── spec-reviewer-prompt.md          # subagent: plan compliance check
│   │   └── code-reviewer-prompt.md          # subagent: etcd-druid conventions
│   ├── tdd/
│   │   └── SKILL.md                         # testing patterns per repo
│   ├── debug/
│   │   └── SKILL.md                         # 3-component debug flow
│   ├── review/
│   │   └── SKILL.md                         # safety invariants, Operator interface
│   └── reference/
│       └── SKILL.md                         # deep domain reference
└── docs/
    └── plans/                               # plan files written during feature-dev
```

---

## Component 1: plugin.json

```json
{
  "name": "etcd-druid",
  "description": "Expert skills for etcd-druid development: feature workflow, TDD, debugging, and domain reference",
  "version": "1.0.0",
  "author": { "name": "Seshachalam Yerasala Venkata" },
  "keywords": ["etcd-druid", "gardener", "kubernetes", "operator", "go"]
}
```

---

## Component 2: Session-Start Hook

### hooks/hooks.json
Registers a `SessionStart` hook that runs `session-start` on every session open, clear, or compact.

### hooks/session-start
Bash script that:
1. Reads the orientation content (hardcoded in script, not from a skill file)
2. Escapes it for JSON embedding
3. Outputs `hookSpecificOutput.additionalContext` for Claude Code

### Injected orientation content (~40 lines)

```
You are working on etcd-druid, a Kubernetes operator managing etcd clusters for Gardener.

## Three-Component System

etcd-druid (this repo)
  Kubernetes operator — owns the Etcd CRD, reconciles all cluster resources.
  Components implement the Operator interface: PreSync, Sync, TriggerDelete, GetExistingResourceNames.
  Controllers: etcd, compaction, etcdcopybackupstask, etcdopstask, secret.

etcd-backup-restore (sidecar)
  Manages snapshots, restore, and etcd initialization.
  HTTP API: /initialization/start, /initialization/status, /snapshot/full,
            /snapshot/delta, /snapshot/latest, /config, /healthz, /metrics
  Uses logrus for logging.

etcd-wrapper (sidecar)
  Calls backup-restore HTTP API to initialize etcd, then starts embedded etcd
  via go.etcd.io/etcd/server/v3/embed.
  Uses zap for logging.

## Working Directories
Fork (implementation):  /Users/I568019/go/src/github.com/seshachalam-yv/etcd-druid
Upstream (read-only):   /Users/I568019/go/src/github.com/gardener/etcd-druid

NEVER commit to upstream.
NEVER push or create a PR without explicit human approval.

## Key Invariants
- New components must implement the Operator interface (all four methods)
- API changes in api/core/v1alpha1/ require CEL validation annotations
- etcd-druid tests: Go native testing.T + Gomega assertions — no Ginkgo
- etcd-wrapper tests: Go native testing.T + Gomega assertions
- etcd-backup-restore tests: Ginkgo v2 suite + Gomega assertions
- Always follow the testing pattern of the repo you are working in
- Errors: fmt.Errorf("failed to X: %w", err) — never swallow silently
- Logging: log.FromContext(ctx).WithValues("etcd", req.NamespacedName) in druid
- Commits: imperative sentence case, ends with period, issue number: "Fix X. (#1350)"
- Branch: ai/TASK-{issue-id}/{short-description} in fork
- Before committing: make test-unit && make test-integration && make check

## Available Skills
etcd-druid:feature-dev   Use when starting any feature or bug fix — design to PR
etcd-druid:tdd           Use when writing or fixing tests in any of the three repos
etcd-druid:debug         Use when etcd pod not ready, snapshots failing, reconciliation
                         stuck, restore not triggering, or member health issues
etcd-druid:review        Use before submitting work — safety invariants checklist
etcd-druid:reference     Use for deep lookup: backup-restore API, CRD spec, TLS,
                         component authoring, controller flow, store providers
```

---

## Component 3: feature-dev Skill

### SKILL.md — orchestration

**Trigger:** Use when starting any feature, bug fix, or enhancement in etcd-druid.

**Workflow (fully standalone, no external skill dependencies):**

```
Phase 1: Design
  - Explore relevant code in upstream (read-only) to understand current state
  - Ask clarifying questions one at a time (domain-focused: which component,
    which controller, API change or internal only, test scope)
  - Propose 2-3 approaches with trade-offs
  - Present design, get approval

Phase 2: Plan
  - Write plan to: docs/plans/YYYY-MM-DD-issue-{id}-{short-description}.md
    in the fork working directory (not worktree — plan written before worktree setup)
  - Plan format:
      ## Issue
      ## Design Summary
      ## Tasks (numbered, with checkboxes, acceptance criteria, files affected)
      ## Testing Strategy
      ## Rollback Notes
  - Create TaskCreate entries for all tasks

⛔ GATE 1: Plan approval
  - STOP. Present plan summary (tasks list, files affected, test strategy)
  - Show: "Review docs/plans/<filename>. Reply 'approved' to proceed, or request changes."
  - Wait for explicit "approved" — do not proceed otherwise
  - If changes requested: update plan file, show summary again

Phase 3: Worktree setup
  - git worktree add in fork: ai/TASK-{issue-id}/{short-description}
  - All subsequent implementation work happens inside this worktree
  - Pass worktree path to all subagents

Phase 4: Per-task implementation (repeat for each task)
  a. Mark task in_progress in TaskUpdate
  b. Dispatch implementer subagent (./implementer-prompt.md)
     - provide: full task text, worktree path, plan context, files affected
     - subagent: reads only what it needs, implements, tests, commits, reports back
  c. Show implementer report to user
  d. Dispatch spec-reviewer subagent (./spec-reviewer-prompt.md)
     - provide: task acceptance criteria, git SHAs of commits
  e. If spec issues found: implementer fixes, spec-reviewer re-reviews
  f. Dispatch code-reviewer subagent (./code-reviewer-prompt.md)
     - provide: git SHAs, etcd-druid conventions checklist
  g. If quality issues found: implementer fixes, code-reviewer re-reviews
  h. Mark task completed, update plan file checkbox
  i. Move to next task

Phase 5: Verify
  - Run in worktree: make test-unit && make test-integration && make check
  - All must pass — if not, dispatch fix subagent with failure output
  - Do not proceed to Gate 2 until all checks pass

⛔ GATE 2: PR approval
  - STOP. Present:
      - PR title (sentence case, imperative)
      - PR description draft (problem, changes, testing done)
      - git diff --stat summary
      - Commits list with messages
  - Show: "Reply 'approved' to push and create PR, or request changes."
  - Wait for explicit "approved" — do not git push otherwise
  - If changes requested: fix, re-verify, show Gate 2 again

Phase 6: PR creation
  - git push fork branch to origin
  - gh pr create targeting upstream master with approved description
  - Show PR URL
```

### implementer-prompt.md

Subagent prompt template providing:
- Worktree path as working directory
- Full task text (pasted, not file reference)
- Files affected list from plan
- etcd-druid commit style: "Verb noun detail. (#issue)"
- Operator interface requirement if task touches components
- Testing requirement: use testing.T + Gomega (etcd-druid), match existing test patterns
- Self-review checklist before reporting back
- Status reporting: DONE | DONE_WITH_CONCERNS | BLOCKED | NEEDS_CONTEXT

### spec-reviewer-prompt.md

Subagent prompt template providing:
- Task acceptance criteria (pasted from plan)
- Git SHAs to review
- Checklist: every acceptance criterion met? anything extra built that wasn't asked?
- Output: ✅ compliant or ❌ with specific gaps listed

### code-reviewer-prompt.md

Subagent prompt template providing:
- Git SHAs to review
- etcd-druid-specific checklist:
  - Operator interface: all four methods implemented?
  - Error wrapping: fmt.Errorf("failed to X: %w", err)?
  - No silent error swallowing?
  - API changes have CEL validation annotations?
  - RBAC markers present if new verbs needed?
  - Status updates via subresource only?
  - Finalizer check before cleanup?
  - Test uses testing.T + Gomega, no time.Sleep()?
  - Commit message follows etcd-druid style?
- Output: ✅ approved or issues categorized as Critical / Important / Suggestion

---

## Component 4: tdd Skill

**Trigger:** Use when writing or fixing tests in any of the three repos.

**Content:**

```
etcd-druid (internal/component/*, internal/controller/*)
  Framework: Go native testing.T
  Assertions: Gomega (import . "github.com/onsi/gomega")
  Pattern: table-driven tests with struct slices
  Helpers: test/utils/ — use existing helpers before creating new ones
  Mocks: go.uber.org/mock/gomock for interfaces
  Run: make test-unit (unit), make test-integration (envtest)
  Never use time.Sleep() — use gomega.Eventually/Consistently
  Always check existing tests in the same package before writing new ones

etcd-wrapper (internal/*)
  Framework: Go native testing.T
  Assertions: Gomega (import . "github.com/onsi/gomega")
  Logger in tests: zaptest.NewLogger(t)
  HTTP mocking: TestRoundTripper pattern (see internal/bootstrap/bootstrap_test.go)
  Run: go test ./...

etcd-backup-restore (pkg/*)
  Framework: Ginkgo v2 + Go native testing.T
  Assertions: Gomega
  Suite setup: RegisterFailHandler(Fail) + RunSpecs in *_suite_test.go
  Run: go test ./... or make test

ALWAYS follow the testing pattern of the repo you are working in.
ALWAYS check existing tests in the same package first.
NEVER introduce Ginkgo into etcd-druid or etcd-wrapper.
NEVER use time.Sleep() — use Eventually/Consistently with a timeout.
```

---

## Component 5: debug Skill

**Trigger:** Use when:
- etcd pod is not becoming Ready
- Snapshots not being taken or BackupReady condition is False
- Reconciliation loop is stuck or erroring
- etcd cluster member issues (AllMembersReady False, ClusterIDMismatch True)
- Restore not triggering after data loss
- Test failures that are clearly etcd-druid domain failures (not Go compilation
  errors, import issues, or general Kubernetes problems — handle those directly)

**NOT for:** Go compilation errors, import issues, unrelated Kubernetes problems.

**Debug flow:**

```
Phase 1: Check backup-restore HTTP API (per pod)
  GET /healthz                  → {"health": true/false}
  GET /initialization/status    → New | Progress | Successful | Failed
  GET /snapshot/latest          → last snapshot metadata
  Log format: logrus, level=info/error, field-based

Phase 2: Check etcd-wrapper
  GET readycheck endpoint (WrapperPort in EtcdConfig)
  Log format: zap, structured JSON

Phase 3: Check Etcd CRD status conditions
  kubectl get etcd <name> -o yaml
  Conditions: Ready, AllMembersReady, BackupReady, ClusterIDMismatch
  Fields: lastOperation, lastErrors, currentReplicas, readyReplicas

Phase 4: Check druid controller logs
  Log format: logr, structured, includes runID per reconciliation
  Look for: component sync errors, lastOperation state transitions

Phase 5: Check component resource state
  StatefulSet ready replicas vs desired
  MemberLeases — one per etcd member
  SnapshotLeases — full and delta
  ConfigMap — etcd config generation issues
```

---

## Component 6: review Skill

**Trigger:** Use before submitting any work for PR.

**Checklist:**

```
Operator interface (if new component added):
  [ ] PreSync implemented
  [ ] Sync implemented
  [ ] TriggerDelete implemented
  [ ] GetExistingResourceNames implemented
  [ ] Registered in component registry

API changes (api/core/v1alpha1/):
  [ ] CEL validation annotations present (+kubebuilder:validation:XValidation)
  [ ] deepcopy regenerated (make generate)
  [ ] CRD YAML updated in charts/

RBAC:
  [ ] +kubebuilder:rbac markers added for any new resource verbs
  [ ] make generate run to update role manifests

Error handling:
  [ ] fmt.Errorf("failed to X: %w", err) — no bare errors.New() without context
  [ ] No silent swallowing (no _ = err)

Status updates:
  [ ] Via subresource only (r.Status().Update())
  [ ] Not via r.Update() on main object

Finalizers:
  [ ] controllerutil.ContainsFinalizer check before cleanup

Tests:
  [ ] Go native testing.T + Gomega (etcd-druid/wrapper)
  [ ] No time.Sleep() — Eventually/Consistently used
  [ ] make test-unit passes
  [ ] make test-integration passes
  [ ] make check (lint) passes

Commits:
  [ ] Sentence case, imperative, ends with period
  [ ] Issue number appended: (#NNNN)
  [ ] One commit per logical task

Safety:
  [ ] Working in fork, not upstream
  [ ] No force push
  [ ] No --no-verify
  [ ] Gate 2 approval received before push
```

---

## Component 7: reference Skill

**Trigger:** Use for deep lookup of domain knowledge not in session-start orientation.

**Sections:**

### backup-restore HTTP API
```
POST /initialization/start?mode=<full|sanity>
GET  /initialization/status   → "New" | "Progress" | "Successful" | "Failed"
POST /snapshot/full           → triggers full snapshot
POST /snapshot/delta          → triggers delta snapshot
GET  /snapshot/latest         → latest snapshot metadata
GET  /config                  → etcd configuration (used by etcd-wrapper)
GET  /healthz                 → {"health": true/false}
GET  /metrics                 → Prometheus metrics
```

### Etcd CRD key fields
```
spec.replicas                 → cluster size (1 or 3)
spec.etcd.serverPort          → etcd peer port
spec.etcd.clientPort          → etcd client port
spec.etcd.wrapperPort         → etcd-wrapper readycheck port
spec.backup.port              → backup-restore HTTP port
spec.backup.store             → object store config (provider, container, prefix, secretRef)
spec.backup.fullSnapshotSchedule → cron expression
spec.backup.deltaSnapshotPeriod  → duration
spec.backup.tls               → TLSConfig (tlsCASecretRef, serverTLSSecretRef, clientTLSSecretRef)
spec.etcd.tls                 → TLSConfig for etcd peer/client TLS
status.conditions             → Ready, AllMembersReady, BackupReady, ClusterIDMismatch
status.lastOperation          → state: Processing | Succeeded | Failed | Error
status.lastErrors             → []LastError with code, description, lastUpdateTime
```

### Component authoring guide
```
1. Create package: internal/component/<name>/
2. Define operator struct implementing component.Operator interface
3. Implement all four methods: PreSync, Sync, TriggerDelete, GetExistingResourceNames
4. Register in createAndInitializeOperatorRegistry() in internal/controller/etcd/reconciler.go
5. Add RBAC markers for any new resource kinds
6. Write tests using testing.T + Gomega in <name>_test.go
7. Run make generate if new types added
```

### Controller flow
```
Reconcile() entry point (internal/controller/etcd/reconciler.go)
  → reconcileEtcdDeletion (if DeletionTimestamp set)
    → TriggerDelete on all components in reverse order
  → reconcileSpec (internal/controller/etcd/reconcile_spec.go)
    → PreSync on all components
    → Sync on all components
  → reconcileStatus (internal/controller/etcd/reconcile_status.go)
    → update Etcd CRD status conditions
```

### TLS secret structure
```
tlsCASecretRef:      Secret with ca.crt (and optional ca.key)
serverTLSSecretRef:  Secret with tls.crt, tls.key
clientTLSSecretRef:  Secret with tls.crt, tls.key
SecretReference.dataKey: optional override for the key name in the secret data map
```

### Store providers
```
Provider values: S3, GCS, ABS (Azure), Swift, OSS, ECS, OCS, Local
StoreSpec.secretRef: credentials secret reference
StoreSpec.container: bucket/container name
StoreSpec.prefix:    path prefix within bucket
```

### EtcdOpsTask and EtcdCopyBackupsTask
```
EtcdOpsTask: one-shot operations (maintenance, snapshot, hibernation)
  Managed by: etcdopstask controller (internal/controller/etcdopstask/)
  Status: Pending → InProgress → Succeeded | Failed

EtcdCopyBackupsTask: copy backups between store providers
  Managed by: etcdcopybackupstask controller
  Used for: cluster migration between cloud providers
```

---

## Approval Gate Rules (Hard)

These rules are encoded in feature-dev SKILL.md and all subagent prompts:

1. **Gate 1 (after plan):** Claude MUST stop and present the plan summary. No code is written, no worktree is created, until the user replies with "approved" or equivalent explicit confirmation.

2. **Gate 2 (before PR):** Claude MUST stop and present the PR description + diff summary + commit list. No `git push`, no `gh pr create` is executed until the user replies with "approved" or equivalent explicit confirmation.

3. **Subagent constraint:** No subagent prompt authorizes git push or PR creation. The implementer subagent only commits locally to the worktree. Only main Claude executes push/PR after Gate 2.

4. **Violations:** If a subagent attempts to push or create a PR, main Claude must block it and surface the decision to the human.

---

## Progress Tracking

### In-session (TaskCreate/TaskUpdate)
```
Task 1: Design phase                    pending → in_progress → completed
Task 2: Write plan                      pending → in_progress → completed
Task 3: ⛔ Gate 1 — human approves plan pending → in_progress → completed
Task 4: Set up worktree                 pending → in_progress → completed
Task N: Implement <task name>           pending → in_progress → completed
Task N: Spec review <task name>         pending → in_progress → completed
Task N: Code review <task name>         pending → in_progress → completed
Task M: Verify (make test-unit etc.)    pending → in_progress → completed
Task M+1: ⛔ Gate 2 — human approves PR pending → in_progress → completed
Task M+2: Create PR                     pending → in_progress → completed
```

### Cross-session (plan file on disk)
Plan file at `docs/plans/YYYY-MM-DD-issue-{id}-{short-description}.md` in fork.
Tasks use markdown checkboxes. Resuming a session: read plan file, check git log in worktree, continue from first unchecked task.

---

## Decisions Log

| Decision | Choice | Reason |
|---|---|---|
| Plugin name | `etcd-druid` | Matches repo name, clean invocation prefix |
| Skill structure | Skill folders + prompt templates | Focused subagent prompts per role |
| Workflow | Fully standalone, no external plugin deps | No superpowers runtime dependency |
| Session-start | Medium (~40 lines) | Expert developer, no hand-holding |
| Subagent model | Subagents only, no named multi-agents | Single developer, no coordination overhead |
| Commit style | etcd-druid sentence case with issue # | Matches actual repo commit history |
| Testing | Per-repo pattern (testing.T+Gomega / Ginkgo+Gomega) | Matches actual codebase |
| Plan location | `docs/plans/` in fork | Standalone, no superpowers path references |
| Approval gates | After plan AND before PR | Both required by hard rule |
| Commits per task | One commit per task | Clean bisect history, maintainers can squash-merge |
| Progress tracking | TaskCreate/TaskUpdate + plan file checkboxes | In-session visibility + cross-session resume |
