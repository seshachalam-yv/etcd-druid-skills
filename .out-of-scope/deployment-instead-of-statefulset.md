# Rejected: Use Deployment Instead of StatefulSet for etcd

## Context

The question arises whether etcd pods could be managed via a Deployment (with PVCs attached) rather than a StatefulSet, potentially simplifying rollout and scaling logic.

## Decision

Rejected.

## Reasoning

etcd members require guarantees that only StatefulSet provides:

1. **Stable network identity (DNS)** — Each etcd member must be reachable at a predictable, stable hostname for peer communication and client discovery. StatefulSet provides `<pod-name>.<headless-service>` DNS records. Deployments generate random pod names with no stable DNS.

2. **Stable persistent storage** — Each member's data directory must survive pod rescheduling and bind back to the same member. StatefulSet's `volumeClaimTemplates` ensure PVC-to-pod affinity. Deployments have no such mechanism.

3. **Ordered startup and shutdown** — Cluster bootstrap and member removal are order-sensitive operations. StatefulSet guarantees ordinal-based ordering. Deployments start/stop pods in arbitrary order.

Using a Deployment would require reimplementing all three guarantees at the operator level, duplicating what StatefulSet already provides with upstream Kubernetes support and testing.

## Prior Discussions

- Fundamental to etcd-druid's design since project inception.
- Kubernetes documentation recommends StatefulSet for any workload needing stable identity or storage: https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/
