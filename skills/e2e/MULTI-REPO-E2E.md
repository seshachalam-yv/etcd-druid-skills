# Cluster Observation and Handoff

## Observing a Running Cluster

After deploying with `RETAIN_KIND_CLUSTER=true`:

```bash
export KUBECONFIG=<fork>/hack/kind/kubeconfig

# Watch etcd-druid controller logs
kubectl logs -n etcd-druid-e2e deploy/etcd-druid -f

# Watch etcd pod logs (etcd-main-0 is the first member)
kubectl logs -n <test-ns> etcd-main-0 -c etcd-wrapper -f
kubectl logs -n <test-ns> etcd-main-0 -c etcd-backup-restore -f

# Check Etcd resource status
kubectl get etcd -A -o wide
kubectl describe etcd etcd-main -n <test-ns>

# Check backup status
kubectl get etcd etcd-main -n <test-ns> -o jsonpath='{.status.lastFullBackup}'
```

### Debugging Distroless Containers

etcd-backup-restore uses a distroless image — no shell, no etcdctl. To interact with etcd directly:

```bash
# Run a temporary etcdctl client pod (use etcd version matching your cluster)
kubectl run etcd-client --rm -i --restart=Never \
  --image=registry.k8s.io/etcd:3.5.x-0 -n <ns> -- \
  etcdctl --endpoints=http://<etcd-name>-client.<ns>.svc:2379 \
  get /test/key

# For TLS clusters, mount secrets into ephemeral pod or use port-forward:
kubectl port-forward -n <ns> <etcd-pod> 2379:2379 &
ETCDCTL_API=3 etcdctl --endpoints=https://localhost:2379 \
  --cacert=<ca> --cert=<cert> --key=<key> endpoint health

# Check backup-restore health (wget is available in distroless):
kubectl exec <pod> -n <ns> -c backup-restore -- wget -qO- http://localhost:8080/healthz
```

---

## Triggering Spec Reconciliation

etcd-druid does NOT automatically reconcile spec changes. Reconciliation requires one of:

1. **Annotation** (one-shot): `kubectl annotate etcd <name> -n <ns> gardener.cloud/operation=reconcile`
   - Consumed after reconciliation — must be re-added for each spec change
2. **OperatorConfiguration** (permanent): `EnableEtcdSpecAutoReconcile=true`
   - Set via Helm values or operator config; not default in e2e deployments

When testing spec changes (replicas, resources, etc.) and nothing happens after patching:

```bash
# Re-trigger reconciliation
kubectl annotate etcd <name> -n <ns> gardener.cloud/operation=reconcile --overwrite
# Watch for reconcileSpec in logs
kubectl logs deploy/etcd-druid -n <ns> | grep reconcileSpec
```

---

## POC / Prototype Testing

When testing new features that require additional RBAC permissions not yet in the Helm chart:

```bash
# Check current ClusterRole permissions
kubectl get clusterrole etcd-druid -o yaml | grep -A5 "persistentvolumeclaims"

# Patch ClusterRole to add missing verbs (replace N with the rule index)
kubectl patch clusterrole etcd-druid --type=json -p='[
  {"op": "replace", "path": "/rules/N/verbs", "value": ["get","list","watch","delete"]}
]'

# Or edit directly for complex changes
kubectl edit clusterrole etcd-druid
```

For repeated POC testing, maintain a `hack/rbac-patch.yaml` with your additional permissions.

---

## Handoff

After e2e passes:
- If invoked from `/etcd-druid:implement` Phase 3 — return there to complete the verify checklist and proceed to Gate 2
- If invoked standalone — invoke `/etcd-druid:review` for pre-PR checklist
- Check `.github/workflows/` in the repo to confirm which CI checks run automatically on PR open
