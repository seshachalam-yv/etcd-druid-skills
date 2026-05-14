# Per-Pod Monitor Agent

Defines the prompt template and behavior for background sub-agents that monitor individual etcd pods during an evidence session.

## Agent Dispatch Template

For each pod index `i` in range `0..replicas-1`:

    Agent(
      description: "Monitor etcd-<cluster>-<i>",
      prompt: "<filled template below>",
      run_in_background: true
    )

All agents are dispatched in a **single message** (parallel spawn).

## Prompt Template

Fill `<cluster>`, `<index>`, `<namespace>`, and `<scenario-context>` before dispatch:

---

You are monitoring pod `etcd-<cluster>-<index>` in namespace `<namespace>`.

**Session context:** <scenario-context>

**Your job:** Track this pod's full lifecycle and report a structured summary when asked to stop.

### Phase 1: Pre-Existence (pod not yet created)

Poll every 5 seconds until the pod appears:

```bash
kubectl get pod etcd-<cluster>-<index> -n <namespace> 2>&1
kubectl get events -n <namespace> --field-selector involvedObject.name=etcd-<cluster>-<index> --sort-by='.lastTimestamp' 2>/dev/null
kubectl get sts etcd-<cluster> -n <namespace> -o jsonpath='{.status.readyReplicas}/{.spec.replicas}' 2>/dev/null
```

Record with timestamps (relative to your start time):
- When pod first appears in API (Pending)
- Scheduling events (assigned to node, or failures like Insufficient CPU)
- Image pull events (pulling, pulled, or ErrImagePull/ImagePullBackOff)
- Init container events (started, completed, or failed)

Transition to Phase 2 when pod phase = Running.

### Phase 2: Running

Poll every 10 seconds:

```bash
kubectl logs etcd-<cluster>-<index> -n <namespace> -c etcd --tail=20 2>/dev/null
kubectl logs etcd-<cluster>-<index> -n <namespace> -c backup-restore --tail=20 2>/dev/null
kubectl get events -n <namespace> --field-selector involvedObject.name=etcd-<cluster>-<index> --sort-by='.lastTimestamp' 2>/dev/null
kubectl exec etcd-<cluster>-<index> -n <namespace> -c backup-restore -- wget -qO- https://localhost:2379/health --no-check-certificate 2>/dev/null
```

Track:
- Container restarts (compare restart count between polls)
- Error/warning lines in logs (lines containing "error", "fatal", "warning", "failed")
- State transitions: not-ready → ready, leader election, snapshot activity
- Health check pass/fail count

### Phase 3: Termination (scale-down scenarios only)

If the pod starts terminating:
- Record the timestamp when pod enters Terminating state
- Record final events (preStop hook, SIGTERM, deletion)
- Note: this is EXPECTED in scale-down scenarios — report as INFO, not ERROR

### Output Format (when asked to stop)

Return EXACTLY this markdown structure:

For a running pod:

    ### etcd-<cluster>-<index> (<role>)
    **Lifecycle:** Running T+<X>s → T+<Y>s
    **Startup:**
    - T+<N>s: <event>
    - T+<N>s: <event>
    ...
    **Running:** T+<X>s → T+<Y>s | <N>/<M> health checks passed
    **Errors:** none | <list of error lines with timestamps>
    **Notable events:** none | <leader change, snapshot, restart, etc.>

For a removed pod (scale-down):

    ### etcd-<cluster>-<index> (removed)
    **Lifecycle:** Running T+<X>s → Terminated T+<Y>s
    **Startup:**
    - T+<N>s: <event>
    ...
    **Removal sequence:**
    - T+<N>s: Member removed from etcd cluster
    - T+<N>s: Pod terminating
    - T+<N>s: Pod deleted
    **Health checks:** <N>/<M> passed (before removal)

---

## Scenario-Specific Context Strings

Use these for the `<scenario-context>` placeholder based on the identified scenario:

### Scale-Down

    This is a scale-down from <N> to <M> replicas. Pods etcd-<cluster>-{<M>..<N-1>} will be
    removed during this session. If you are monitoring one of those pods, their termination is
    EXPECTED — report it as a normal lifecycle event (INFO), not an error. Track the removal
    sequence: when the member is removed from etcd, when the pod enters Terminating, and when
    it's deleted.

### Scale-Up

    This is a scale-up from <N> to <M> replicas. Your pod (etcd-<cluster>-<index>) may not exist
    at the start. Track the full creation sequence: when the StatefulSet creates it, scheduling,
    image pull, init containers, etcd joining the cluster, and readiness.

### EtcdOpsTask

    An EtcdOpsTask (<type>) is being executed against this cluster. In addition to normal pod
    monitoring, also check for snapshot/compaction/defrag activity in the backup-restore container
    logs. Report any task-related log lines (containing "snapshot", "compact", "defrag", or
    "task").

### Version Upgrade

    An etcd version upgrade is in progress. Watch for the etcd container restarting with a new
    version. After restart, check that the member rejoins the cluster successfully. Report the
    old and new version strings from the etcd logs.

### Generic (default)

    Monitor this pod for the duration of the evidence session. Report any errors, restarts,
    leader changes, or unexpected behavior.

## Spawning Multiple Monitors

Dispatch all monitors in ONE message with multiple Agent tool calls:

    Agent(description: "Monitor etcd-test-0", prompt: "...", run_in_background: true)
    Agent(description: "Monitor etcd-test-1", prompt: "...", run_in_background: true)
    Agent(description: "Monitor etcd-test-2", prompt: "...", run_in_background: true)

This ensures they all start simultaneously and begin tracking from the same baseline.

## Stopping Monitors

When the user says "done" or "report":

1. Send a message to each running monitor agent: "Stop monitoring and return your summary now."
2. Collect all summaries
3. Assemble into the Pod Monitors section of the report

If a monitor has already self-terminated (10 minutes without state change), use its last reported summary.
