# E2E Evidence Session Protocol

Captures structured evidence during manual task verification — from deploy through state transitions to final report.

## Session Lifecycle

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

## Starting a Session

When the user says "verify task X" or similar:

1. Ask: "What are you verifying?" (task/bug description for the report header)
2. Ask: "Where is the Etcd CR?" (path to yaml file — needed to extract replicas and cluster name)
3. Confirm the scenario type (see below) and expected state transitions

## Scenario Recognition

Identify the scenario type from the user's description:

| Trigger phrase | Scenario | Expected transitions |
|---------------|----------|---------------------|
| "scale down", "reduce replicas", "N to M members" | Scale-down | N-member → removal in progress → M-member stable |
| "scale up", "increase replicas" | Scale-up | N-member → new pods joining → M-member stable |
| "snapshot", "backup", "EtcdOpsTask" | EtcdOpsTask | Task Pending → InProgress → Succeeded |
| "restore", "recovery" | Restore | Trigger → restore running → cluster healthy |
| "upgrade", "version" | Version upgrade | Old version → snapshot → new version running |
| "hibernate", "replicas=0" | Hibernation | Running → snapshot → replicas=0 |
| (general fix/feature) | Generic | Deploy → healthy → feature works |

Once identified, generate the **state transition checklist** — the ordered list of states and what evidence is required at each.

## Deploy Phase (Auto-Capture)

Run each command and auto-capture evidence (verdict = PASS if exit 0):

| Step | Command | Notes |
|------|---------|-------|
| Build image | `make docker-build` | Captures image tag from output |
| Load to KIND | `kind load docker-image <image> --name etcd-druid-e2e` | Only if KIND cluster |
| Deploy operator | `make deploy` or `helm install` | Based on user's usual method |
| Parse CR | Read yaml file | Extract name, namespace, replicas |

After deploy, BEFORE applying the CR:
- Spawn monitor agents (see MONITOR-AGENT.md)
- Confirm monitors are running
- Then apply CR

## Spawning Monitor Agents

Read `spec.replicas` from the CR yaml (default 3). For each expected pod index 0..N-1:

    Agent(
      description: "Monitor etcd-<cluster>-<index>",
      prompt: <see MONITOR-AGENT.md template>,
      run_in_background: true
    )

Spawn ALL monitors in a single message (parallel dispatch). Monitors start polling immediately — they will observe the pod not existing yet, then catch the full creation sequence.

**For scale-down scenarios:** Spawn monitors for ALL current pods (the higher replica count), not just the target. Monitors for pods being removed will capture the removal sequence.

**For scale-up scenarios:** Spawn monitors for the target (higher) replica count. New pod monitors will capture the join sequence.

## Evidence Capture During Verification

For each verification step:

1. User describes what they're checking (or skill suggests based on state transition checklist)
2. Run the command
3. Capture the output
4. Assess verdict:
   - **PASS** — Exit 0 + expected content present + no error indicators
   - **FAIL** — Non-zero exit, error strings, missing expected content
   - **INFO** — Observation step, no pass/fail criteria
5. Record the evidence entry:
   - phase: DEPLOY / READY / VERIFY
   - state: which state this belongs to (e.g., "6-member running")
   - step: short description
   - command: exact command
   - output: raw (truncated at 50 lines)
   - verdict: PASS / FAIL / INFO
   - reason: expected vs actual
   - timestamp: relative to session start

## Guided Verification by Scenario

The skill actively guides the user through state transitions:

### Scale-Down (example: 6 → 3)

**State 1 — Baseline (6 members running):**
- "Let me verify the baseline. Running etcdctl member list..."
- "All 6 members healthy. Running endpoint health..."
- Evidence captured for: member count, health, pod status

**Transition — Patch CR:**
- "Ready to trigger scale-down. Patching CR to replicas=3..."
- Evidence captured for: patch command, EtcdOpsTask creation

**State 2 — Removal in progress:**
- "Monitoring member removal. Checking member list periodically..."
- Evidence captured PER REMOVED MEMBER: member list showing count decreasing
- "Cluster health during removal — remaining members still healthy..."

**State 3 — Final state (3 members stable):**
- "Scale-down complete. Final verification..."
- Evidence captured for: member count = 3, all healthy, no stale leases, EtcdOpsTask succeeded

### EtcdOpsTask (example: OnDemandSnapshot)

**State 1 — Task created:**
- "Creating EtcdOpsTask..."
- Evidence: task yaml shows state: Pending

**State 2 — Task in progress:**
- "Task picked up by operator..."
- Evidence: state = InProgress, operator logs show reconciliation

**State 3 — Task completed:**
- "Task finished..."
- Evidence: state = Succeeded, snapshot file exists, lastFullBackup updated

## Monitor Adaptation Per Scenario

Tell monitors what to expect so they report correctly:

| Scenario | Extra context in monitor prompt |
|----------|-------------------------------|
| Scale-down | "Pods etcd-\<cluster\>-{M..N-1} will be removed. Report their termination as INFO (expected), not ERROR." |
| Scale-up | "New pods etcd-\<cluster\>-{N..M-1} will appear. Report their creation and join sequence." |
| EtcdOpsTask | "Additionally poll: kubectl get etcdopstask -n \<ns\> -o jsonpath='{.status.state}' every 5s. Report state transitions." |
| Version upgrade | "Watch for etcd version change in endpoint status output." |

## Generating the Report

When user says "done" or "report":

1. Signal all monitor agents to stop and return their summaries
2. Collect all evidence entries from the session
3. Generate markdown report with structure:
   - Header (task, scenario, date, cluster, duration, overall result)
   - Deploy Phase table
   - State Transitions (one section per state + transition)
   - Pod Monitors (one section per pod with lifecycle, role, health, errors)
   - Summary (1-2 sentences)
4. Write to `docs/e2e-evidence/<date>-<task-slug>.md`
5. Show the user the report path and ask if they want to include it in their PR

## Constraints

- All commands are read-only — no mutations except the user's explicit actions (apply CR, patch CR)
- Monitors use `run_in_background` — no context window pollution
- Report truncates outputs at 50 lines (full in collapsible `<details>` blocks)
- Monitors self-terminate after 10 minutes without pod state change or user command
- Works with any Etcd CR (single-node, multi-node, with/without TLS)
