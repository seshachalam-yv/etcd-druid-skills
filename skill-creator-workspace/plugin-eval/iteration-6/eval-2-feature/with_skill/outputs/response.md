I've explored the codebase and have a good picture of the architecture. Here's what I understand so far:

**Issue #445 scope:**
- New `UpgradeEtcdVersion` feature gate (alpha, default off)
- Trigger a full snapshot via `EtcdOpsTask` (type `OnDemandSnapshot`) before two events:
  1. **Hibernation** — when `spec.Replicas` goes from >0 to 0
  2. **Etcd version upgrade** — when the feature gate is enabled and the etcd image changes
- The StatefulSet component's `PreSync` method is the natural hook point — it runs before `Sync` during reconciliation
- Image selection logic in `internal/utils/image.go` needs to switch between `etcd-wrapper`/`etcd-wrapper-next` based on the gate
- Helm charts need the new gate in `values.yaml`
- Touches: feature gates, StatefulSet component, etcd reconciler flow, image utils, helm charts, plus unit and integration tests

First clarifying question:

**For the hibernation snapshot trigger — should this always fire (regardless of the `UpgradeEtcdVersion` gate being enabled), or should it only fire when the gate is on?** My reading of the reference docs suggests the hibernation pre-snapshot is unconditional (always safe to snapshot before scaling down), while the upgrade pre-snapshot is gated. Can you confirm?
