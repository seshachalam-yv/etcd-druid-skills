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

---

## Handoff

After e2e passes:
- If invoked from `/etcd-druid:implement` Phase 3 — return there to complete the verify checklist and proceed to Gate 2
- If invoked standalone — invoke `/etcd-druid:review` for pre-PR checklist
- Check `.github/workflows/` in the repo to confirm which CI checks run automatically on PR open
