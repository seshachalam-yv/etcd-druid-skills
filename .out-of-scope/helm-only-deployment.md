# Rejected: Helm Charts Only (No Operator)

## Context

The question arises whether etcd could be deployed and managed purely through Helm charts, without an active operator running in the cluster. Helm charts could template StatefulSets, Services, ConfigMaps, and PVCs for etcd clusters.

## Decision

Rejected.

## Reasoning

1. **Day-2 operations require active reconciliation** — Compaction, defragmentation, backup scheduling, incremental snapshots, and restore cannot be expressed as static Kubernetes manifests. They require a controller that monitors state and takes action over time.

2. **Health monitoring and remediation** — etcd clusters need continuous health checks with automated remediation (restarting unhealthy members, triggering restores from backup). Helm charts are applied once and have no runtime presence.

3. **Scaling with safety** — Adding or removing etcd members requires coordination with the existing cluster (member add/remove API calls, data migration). A Helm upgrade that changes replica count cannot safely orchestrate this sequence.

4. **Rolling updates with quorum awareness** — Updating etcd versions must respect quorum — never updating more members than the cluster can tolerate losing. This requires an active controller that tracks member readiness, not just a rolling update strategy.

5. **Backup and restore orchestration** — Scheduling backups, uploading to object storage, validating snapshots, and performing restores from backup are inherently operational tasks that require a running process with access to cluster state.

6. **Operational knowledge codification** — The operator encodes operational expertise (when to defragment, how to handle split-brain, how to bootstrap from backup) that would otherwise require manual intervention or external tooling.

## Prior Discussions

- etcd-druid exists specifically because static deployment methods proved insufficient for production etcd management at scale in Gardener.
- The operator pattern is the standard Kubernetes solution for workloads requiring active lifecycle management.
