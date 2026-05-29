# EtcdOpsTask & druidctl CLI

## EtcdOpsTask (Controller — etcd-druid v0.34+)

`EtcdOpsTask` CRD (`etcdopstask.druid.gardener.cloud/v1alpha1`) — manages one-shot operational tasks against an etcd cluster.

```
Controller:    internal/controller/etcdopstask/
CRD:           api/core/v1alpha1/etcdopstask.go
Proposal:      docs/proposals/05-etcdopstask.md
Usage guide:   docs/usage/using-etcdopstask.md
New task guide: docs/development/implementing-new-etcdopstask.md
IT tests:      test/it/controller/etcdopstask/
               test/it/crdvalidation/etcdopstask/
```

Supported task types:
- `OnDemandSnapshot` — trigger full/delta snapshot (also auto-triggered during hibernation and UpgradeEtcdVersion)
- `QuorumRecovery` — recover quorum after node loss
- `Compaction` — trigger etcd compaction
- `Defragmentation` — defrag etcd storage
- `BackupCopy` — copy backup to a secondary target

Execution model: FIFO, one active task per Etcd cluster.
TTL-based cleanup: `ttlSecondsAfterFinished`.

Status state machine:
```
Pending → InProgress → Succeeded
   ↘                 ↘ Failed
    └────────────────→ Rejected  (invalid task or cluster not ready — can skip InProgress)
```

LastOperationType: `Admit`, `Execution`, `Cleanup`.

---

## Handler Structure Convention

Multi-step EtcdOpsTask handlers should define steps as a slice of structs rather than
scattered helper functions with a separate ordering constant:

```go
type stepDef struct {
    step        recoveryStep   // enum/string name
    description string         // operator-visible progress description
    fn          func(ctx context.Context, etcd *druidv1alpha1.Etcd) error
}

var recoverySteps = []stepDef{
    {stepScaleDown, "Scaling StatefulSet to 0", h.scaleDown},
    {stepWaitScaleDown, "Waiting for scale-down", h.waitScaleDown},
    // ...
}
```

This pattern keeps step definitions, ordering, and implementations co-located.
It also reduces switch-case logic — iterate the slice instead. When steps have
variations (e.g., some need timeout enforcement), add an optional timeout field
to the struct.

Before implementing a new handler, read the closest existing handler end-to-end
(e.g., `internal/controller/etcdopstask/handler/ondemandsnapshot/`) and match its
conventions for struct layout, method signatures, and config patterns.

---

## druidctl CLI

CLI tool for operators to interact with etcd-druid without direct kubectl.
Location: `druidctl/` (own go.mod, own Makefile). Merged in PR #1212 (Phase 1).

Key commands:
```bash
druidctl reconcile suspend --namespace <ns> --name <etcd>
druidctl reconcile resume  --namespace <ns> --name <etcd>
druidctl protect           --namespace <ns> --name <etcd>   # set deletion protection
druidctl list              --namespace <ns>                  # list Etcd resources
```
