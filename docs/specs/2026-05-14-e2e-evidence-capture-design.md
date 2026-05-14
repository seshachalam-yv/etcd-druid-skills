# E2E Evidence Capture — Design Spec

**Date:** 2026-05-14
**Type:** Extension to existing `e2e` skill
**Goal:** Capture structured evidence during manual e2e task verification, with per-pod sub-agent monitoring, producing PR-ready markdown reports.

---

## Problem

When verifying a task or bug fix against a live KIND cluster, there is no systematic way to:
1. Prove each verification step passed (for PR evidence)
2. See what's happening inside each etcd pod in real time (for debugging)
3. Catch startup failures (image pull errors, scheduling issues) before the cluster reaches steady state

Currently, evidence is ad-hoc — copy-pasted terminal output with no structure, no per-pod context, and no coverage of the deploy/startup phase.

---

## Solution: Evidence Session

An extension to the `e2e` skill that adds a conversational **evidence session** triggered when the user wants to verify a task by deploying etcd-druid and an Etcd CR.

---

## Session Lifecycle

```
1. START    → User says "verify <task/bug>"
2. DEPLOY   → Build image, deploy etcd-druid operator
             Evidence auto-captured for each deploy command
3. PARSE CR → Read the Etcd CR yaml, extract:
             • metadata.name (cluster name)
             • metadata.namespace
             • spec.replicas (N)
4. SPAWN    → Start N monitor sub-agents (one per expected pod)
             Monitors begin polling BEFORE CR is applied
5. APPLY CR → kubectl apply the Etcd CR
             Monitors already running — catch everything from creation
6. READY    → Monitors report when all pods healthy
             Evidence: etcdctl endpoint health output
7. VERIFY   → User runs task-specific verification commands
             Each command + output captured as evidence entry
8. STOP     → User says "done" / "report"
9. REPORT   → Monitors stop, consolidated markdown generated
```

---

## Per-Pod Monitor Sub-Agents

### Spawn Strategy

Monitors start **before** the CR is applied, based on `spec.replicas` from the CR yaml:
- Agent-0 watches for `etcd-<cluster>-0`
- Agent-1 watches for `etcd-<cluster>-1`
- Agent-N watches for `etcd-<cluster>-N`

### Pre-Existence Phase (pod not yet created)

Each monitor polls every 5s:
- `kubectl get pod etcd-<cluster>-<N> -n <ns>` (does pod exist?)
- `kubectl get events -n <ns> --field-selector involvedObject.name=etcd-<cluster>-<N>`
- `kubectl get sts etcd-<cluster> -n <ns>` (StatefulSet rollout progress)

Captures: scheduling failures, image pull errors, node affinity issues, any failure before Running state.

### Running Phase (pod exists)

Once pod reaches Running:
- Container logs: `kubectl logs <pod> -c etcd --tail=50`, `-c backup-restore`, `-c etcd-wrapper`
- Pod events: `kubectl get events --field-selector involvedObject.name=<pod>`
- Health: `etcdctl endpoint health --endpoints=<pod-ip>:2379` (every 10s)
- Status: `etcdctl endpoint status --endpoints=<pod-ip>:2379`

Reports significant state transitions: not-ready → ready, leader changes, snapshot start/complete, errors.

### Interference Safety

All monitor commands are **read-only** (logs, get, describe, etcdctl health/status). No mutations. Safe to run N agents in parallel.

### Agent Prompt Template

```
Monitor pod `<pod-name>` in namespace `<ns>` for cluster `<cluster>`.
The pod may not exist yet — poll for its creation.

Check every 5-10s:
1. Pod existence and phase (Pending/Running/Failed)
2. Events (scheduling, image pull, container start)
3. Container logs — all containers (look for errors, state transitions)
4. etcdctl endpoint health + status (once pod is Running)

Track timestamps relative to session start.
Report significant events: state changes, errors, leader election, snapshots.
When asked to stop, return a markdown summary with:
- Role (leader/follower)
- Startup timeline (key events from creation to Ready)
- Running phase summary (health check pass rate)
- Errors (if any)
```

---

## Scenario-Aware Verification

The evidence session adapts to the **type of work** being verified. Each scenario type defines expected state transitions, and evidence is captured at each transition point — not just start and end.

### Scenario Types

| Scenario | Expected State Transitions | Evidence Required At Each |
|----------|---------------------------|--------------------------|
| Scale-up/down | N members → M members (with intermediate states) | Member list, endpoint health, etcdctl member list at each replica count |
| EtcdOpsTask | Pending → InProgress → Succeeded/Failed | Task state, triggering event, completion evidence |
| Backup/Restore | Trigger → Running → Complete | Snapshot creation, file existence, restore verification |
| Member removal | N members → member decommission → N-1 members | Member list before, removal event, member list after, cluster health after |
| Version upgrade | Old version → snapshot → new version running | Version check, snapshot evidence, new version health |
| Hibernation | Running → OnDemandSnapshot → replicas=0 | Snapshot task, pod termination, PVC retention |

### Example: Scale-Down (6 → 3 members)

The skill recognizes this involves multiple state transitions and captures evidence at each:

```
┌─────────────────────────────────────────────────────────────┐
│  SCENARIO: Scale-down 6 → 3                                 │
│                                                             │
│  STATE 1: 6-member cluster running                          │
│  Evidence:                                                  │
│  • etcdctl member list (6 members, all healthy)             │
│  • kubectl get pods (6 pods Running)                        │
│  • etcdctl endpoint health --cluster (all endpoints)        │
│                                                             │
│  TRANSITION: Update CR spec.replicas=3                      │
│  Evidence:                                                  │
│  • kubectl patch/apply command + output                     │
│  • EtcdOpsTask created (if applicable)                      │
│                                                             │
│  STATE 2: Member removal in progress                        │
│  Evidence (per removed member):                             │
│  • etcdctl member remove <id> observed in operator logs     │
│  • Pod terminating events                                   │
│  • etcdctl member list (decreasing count)                   │
│  • Cluster health during removal (remaining members OK)     │
│                                                             │
│  STATE 3: 3-member cluster stable                           │
│  Evidence:                                                  │
│  • etcdctl member list (3 members, all healthy)             │
│  • kubectl get pods (3 pods Running)                        │
│  • etcdctl endpoint health --cluster                        │
│  • No stale member leases remaining                         │
│  • PVCs cleaned up (or retained per policy)                 │
└─────────────────────────────────────────────────────────────┘
```

### Example: EtcdOpsTask (OnDemandSnapshot)

```
┌─────────────────────────────────────────────────────────────┐
│  SCENARIO: EtcdOpsTask — OnDemandSnapshot                   │
│                                                             │
│  STATE 1: Task created                                      │
│  Evidence:                                                  │
│  • kubectl get etcdopstask <name> -o yaml (state: Pending)  │
│  • Task spec (type, cluster ref)                            │
│                                                             │
│  STATE 2: Task picked up                                    │
│  Evidence:                                                  │
│  • kubectl get etcdopstask (state: InProgress)              │
│  • Operator logs showing task reconciliation                │
│  • backup-restore logs showing snapshot triggered           │
│                                                             │
│  STATE 3: Task completed                                    │
│  Evidence:                                                  │
│  • kubectl get etcdopstask (state: Succeeded)              │
│  • Snapshot file exists in store                            │
│  • Etcd status.lastFullBackup updated                       │
│  • Task .status.lastError empty                             │
└─────────────────────────────────────────────────────────────┘
```

### How It Works

1. **Task recognition:** When the user describes the task ("verify scale-down from 6 to 3"), the skill identifies the scenario type
2. **Transition checklist:** Skill generates the expected state transitions and required evidence at each
3. **Monitor adaptation:** Sub-agent monitors adjust their polling based on scenario:
   - Scale-down: monitors for removed pods detect termination and report it (rather than treating it as failure)
   - EtcdOpsTask: monitors watch for task state changes in addition to pod state
4. **Guided verification:** Skill prompts the user to capture evidence at each transition ("Cluster is now at 5 members. Let me capture member list and health before next removal")
5. **Automatic transition detection:** Monitors report state changes ("etcd-test-5 terminated", "member list now shows 5 entries") which triggers the next evidence capture

### Monitor Adaptation Per Scenario

Monitors adjust behavior based on what's expected:

| Scenario | Monitor behavior change |
|----------|----------------------|
| Scale-down | Pods being removed are expected — report as INFO not ERROR. Track which members are removed in what order. |
| Scale-up | New pods appearing mid-session — spawn additional monitor agents dynamically. |
| EtcdOpsTask | Additionally poll `kubectl get etcdopstask -o jsonpath='{.status.state}'` every 5s. |
| Version upgrade | Watch for etcd version in member status output changing. |

---

## Evidence Entry Structure

Each verification step produces an entry:

| Field | Description |
|-------|-------------|
| phase | `DEPLOY` / `READY` / `VERIFY` |
| state | Which state this belongs to (e.g., "6-member running", "removal in progress", "3-member stable") |
| step | Short description (e.g., "Member count = 6", "Member etcd-test-5 removed") |
| command | Exact command executed |
| output | Raw output (truncated at 50 lines, full in collapsible) |
| verdict | `PASS` / `FAIL` / `INFO` |
| reason | Why pass/fail — expected vs actual |
| timestamp | Relative to session start |

### Verdict Logic

- **PASS** — Exit 0 + expected strings present + no error indicators
- **FAIL** — Non-zero exit, error strings, missing expected content
- **INFO** — Observation step with no pass/fail criteria

### Deploy Phase Auto-Capture

Deploy commands are auto-captured without user prompting:

| Step | Command | Auto-verdict |
|------|---------|-------------|
| Build image | `make docker-build` | PASS if exit 0 |
| Load to KIND | `kind load docker-image ...` | PASS if exit 0 |
| Deploy operator | `make deploy` | PASS if exit 0 |
| Apply CR | `kubectl apply -f ...` | PASS if exit 0 |
| Wait for pods | `kubectl wait --for=condition=Ready` | PASS if ready within timeout |

---

## Report Format

A single markdown file written to `docs/e2e-evidence/<date>-<task-slug>.md`:

```markdown
# E2E Verification Report

**Task:** <description>
**Scenario:** Scale-down 6→3 / EtcdOpsTask OnDemandSnapshot / etc.
**Date:** <ISO timestamp>
**Cluster:** <name> (<initial replicas> → <final replicas>)
**Namespace:** <ns>
**Duration:** <total time>
**Result:** ✅ ALL STATES VERIFIED | ❌ N FAILURES

---

## Deploy Phase

| # | Step | Command | Verdict |
|---|------|---------|---------|
| 1 | Build image | `make docker-build` | ✅ PASS |
| 2 | Deploy operator | `make deploy` | ✅ PASS |
| 3 | Apply Etcd CR (6 replicas) | `kubectl apply -f ...` | ✅ PASS |

---

## State Transitions

### State 1: 6-member cluster running

| # | Check | Command | Verdict |
|---|-------|---------|---------|
| 4 | Member count = 6 | `etcdctl member list` | ✅ PASS |
| 5 | All members healthy | `etcdctl endpoint health --cluster` | ✅ PASS |
| 6 | All pods Running | `kubectl get pods -l ...` | ✅ PASS |

<details><summary>etcdctl member list — full output</summary>

```
abc123, started, etcd-test-0, https://...:2380, https://...:2379, false
def456, started, etcd-test-1, ...
ghi789, started, etcd-test-2, ...
jkl012, started, etcd-test-3, ...
mno345, started, etcd-test-4, ...
pqr678, started, etcd-test-5, ...
```

</details>

### Transition: Scale down to 3 replicas

| # | Action | Command | Verdict |
|---|--------|---------|---------|
| 7 | Patch CR replicas=3 | `kubectl patch etcd test --type merge -p '{"spec":{"replicas":3}}'` | ✅ PASS |
| 8 | EtcdOpsTask created | `kubectl get etcdopstask -n ...` | ✅ PASS (state: Pending) |

### State 2: Member removal in progress

| # | Check | Command | Verdict |
|---|-------|---------|---------|
| 9 | EtcdOpsTask InProgress | `kubectl get etcdopstask -o jsonpath='{.status.state}'` | ✅ PASS |
| 10 | Member etcd-test-5 removed | `etcdctl member list` | ✅ PASS (5 members) |
| 11 | Member etcd-test-4 removed | `etcdctl member list` | ✅ PASS (4 members) |
| 12 | Member etcd-test-3 removed | `etcdctl member list` | ✅ PASS (3 members) |
| 13 | Remaining cluster healthy | `etcdctl endpoint health --cluster` | ✅ PASS |

<details><summary>Operator logs — member removal sequence</summary>

```
level=info msg="removing member" member=etcd-test-5 id=pqr678
level=info msg="member removed successfully" member=etcd-test-5
level=info msg="removing member" member=etcd-test-4 id=mno345
...
```

</details>

### State 3: 3-member cluster stable

| # | Check | Command | Verdict |
|---|-------|---------|---------|
| 14 | Member count = 3 | `etcdctl member list` | ✅ PASS |
| 15 | All 3 healthy | `etcdctl endpoint health --cluster` | ✅ PASS |
| 16 | Only 3 pods remain | `kubectl get pods -l ...` | ✅ PASS |
| 17 | No stale member leases | `kubectl get leases -l ...` | ✅ PASS |
| 18 | EtcdOpsTask Succeeded | `kubectl get etcdopstask -o jsonpath='{.status.state}'` | ✅ PASS |
| 19 | Etcd status replicas=3 | `kubectl get etcd test -o jsonpath='{.status.replicas}'` | ✅ PASS |

---

## Pod Monitors

### etcd-test-0 (leader)
**Lifecycle:** Running throughout (T+0s → T+180s)
**Role changes:** none (remained leader)
**Health checks:** 36/36 passed
**Notable events:** none

### etcd-test-1 (follower)
**Lifecycle:** Running throughout (T+0s → T+180s)
**Health checks:** 36/36 passed
**Notable events:** none

### etcd-test-2 (follower)
**Lifecycle:** Running throughout (T+0s → T+180s)
**Health checks:** 36/36 passed
**Notable events:** none

### etcd-test-3 (removed)
**Lifecycle:** Running T+0s → Terminated T+95s
**Removal sequence:**
- T+90s: Member removed from etcd cluster
- T+92s: Pod terminating
- T+95s: Pod deleted
**Health checks:** 18/18 passed (before removal)

### etcd-test-4 (removed)
**Lifecycle:** Running T+0s → Terminated T+85s
**Removal sequence:**
- T+80s: Member removed from etcd cluster
- T+83s: Pod terminating
- T+85s: Pod deleted
**Health checks:** 16/16 passed (before removal)

### etcd-test-5 (removed)
**Lifecycle:** Running T+0s → Terminated T+75s
**Removal sequence:**
- T+70s: Member removed from etcd cluster
- T+72s: Pod terminating
- T+75s: Pod deleted
**Health checks:** 14/14 passed (before removal)

---

## Summary
Scale-down from 6 to 3 members completed successfully in 180s.
Members removed in order: etcd-test-5, etcd-test-4, etcd-test-3.
Remaining 3-member cluster healthy throughout. EtcdOpsTask succeeded.
All 19 verification checks passed.
```

Report is **not auto-committed** — user decides whether to include in the PR.

---

## Integration with Existing E2E Skill

This is an extension, not a replacement. The existing e2e skill content (KIND setup, sidecar overrides, CI pipeline) remains unchanged. The evidence session is a new section added to the skill, triggered conversationally.

### Skill File Changes

- `skills/e2e/SKILL.md` — Add "Evidence Session" section with lifecycle description and invocation trigger
- `skills/e2e/EVIDENCE-SESSION.md` — New file with full evidence session protocol (agent prompts, capture logic, report template)
- `skills/e2e/MONITOR-AGENT.md` — New file with per-pod monitor agent prompt template and behavior spec

### Invocation

User says any of:
- "verify task X"
- "verify this fix"
- "run evidence session for <description>"
- "e2e verify"

The skill recognizes the intent and enters evidence session mode.

---

## Constraints

- All monitor commands are read-only — no mutations to the cluster
- Monitors use `run_in_background` agent dispatch — no context window pollution
- Report truncates individual outputs at 50 lines (full output in collapsible blocks)
- Session has no hard timeout but monitors self-terminate after 10 minutes without any pod state change or user verification command
- Works with any Etcd CR (single-node, multi-node, with/without TLS)
