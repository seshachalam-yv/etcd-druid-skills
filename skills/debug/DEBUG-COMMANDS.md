# Debug Commands

## Debugging with Delve

For complex reconciliation bugs or stepping through controller logic:

```bash
# Debug a specific test
dlv test ./internal/component/statefulset/... -- -test.run TestFoo

# Debug integration tests with envtest
dlv test ./test/it/controller/etcd/... -- -test.run TestReconciler

# Attach to a running controller in KIND (etcd-druid)
# First deploy with debug mode:
make deploy-debug   # deploys with dlv listening on :2345
# Then attach from host:
dlv connect localhost:2345
```

For etcd-backup-restore, similar debugging works:
```bash
dlv test ./pkg/snapshot/snapshotter/... -- -test.run TestSnapshotter
```

For etcd-wrapper:
```bash
dlv test ./internal/app/... -- -test.run TestSuit
```

## Log Analysis

Each repo uses a different logging framework. Know where to look and how to increase verbosity.

### etcd-druid (logr)

```bash
# Controller logs in KIND cluster
kubectl logs -n etcd-druid-e2e deploy/etcd-druid -f

# Filter by reconciliation key
kubectl logs -n etcd-druid-e2e deploy/etcd-druid | grep "etcd.*etcd-main"

# Increase verbosity: set log level in OperatorConfiguration or --zap-log-level=debug
```

### etcd-backup-restore (logrus)

```bash
# Sidecar logs in a pod
kubectl logs -n <ns> <etcd-pod> -c etcd-backup-restore -f

# Key log fields to watch: "operation", "snapstore", "kind" (Full/Incr)
# Snapshot failures: grep for "failed to save" or "error taking snapshot"
# Restore failures: grep for "failed to restore" or "restoration failure"

# Increase verbosity: --log-level=5 (default is 4)
```

### etcd-wrapper (zap)

```bash
# Wrapper logs in a pod
kubectl logs -n <ns> <etcd-pod> -c etcd-wrapper -f

# Key log fields: "msg", "error"
# Init loop: grep for "initialization" or "trigger"
# Etcd startup: grep for "starting etcd" or "embed"
```
