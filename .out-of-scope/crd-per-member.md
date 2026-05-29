# Rejected: One CRD per etcd Member

## Context

An alternative data model would define one Custom Resource per etcd member (e.g., EtcdMember CR), rather than the current model of one Etcd CR representing the entire cluster. This would make each member independently declarative.

## Decision

Rejected.

## Reasoning

1. **Cluster is the unit of management** — Users declare the desired state of an etcd cluster (replicas, backup schedule, resource requirements). The cluster, not individual members, is the meaningful abstraction for operators and Gardener.

2. **Member-level concerns are already handled** — Individual member identity, health, and state are tracked via MemberLeases. This provides member-level visibility without the overhead of full CRDs per member.

3. **API call multiplication** — With N members per cluster and M clusters, a per-member CRD model would require N*M resources to watch, reconcile, and update status on. This multiplies API server load linearly with cluster size.

4. **Status aggregation complexity** — Determining cluster health requires aggregating across all member CRs. With a single Etcd CR, cluster-level status is maintained in one place with clear ownership.

5. **Declarative spec model** — A single Etcd CR spec declares "I want a 3-member cluster with these properties." Splitting this across 3 member CRs makes it unclear which resource owns the cluster-level spec (backup config, TLS settings, resource templates).

6. **Scaling semantics** — Changing `spec.replicas` from 3 to 5 on a single CR is straightforward. With per-member CRDs, scaling means creating/deleting CRs, raising questions about who creates them and how they discover each other.

## Prior Discussions

- The Etcd CRD + MemberLease design is documented in etcd-druid's architecture.
- MemberLeases were introduced specifically to provide per-member state without per-member CRDs.
