# API Changes, Feature Gates & Cross-Container Contracts

## Etcd Version Upgrade (`UpgradeEtcdVersion` — alpha, v0.36+)

Coordinated across all three repos. If touching upgrade-related code, check all repos for paired changes.

```
1. etcd-druid:
   - Feature gate enabled in OperatorConfiguration (api/config/v1alpha1/features.go)
   - Creates EtcdOpsTask (OnDemandSnapshot, IsFinal=true) BEFORE upgrade begins
   - Adds --next-cluster-version-compatible to generated etcd configmap
   - Also triggers pre-hibernation snapshot when replicas → 0

2. etcd-backup-restore:
   - --next-cluster-version-compatible flag passed to embedded etcd in compaction
   - /snapshot/full?final=true marks snapshots as final for migration safety
   - Restorer handles compressed + final snapshots

3. etcd-wrapper:
   - Starts embedded etcd 3.5.27 with upgraded embed.Config from BR /config endpoint
   - Readiness check via /readyz verifies etcd is healthy post-upgrade
```

---

## Feature Gates (etcd-druid)

Defined in `api/config/v1alpha1/features.go`. Configured via `OperatorConfiguration.FeatureGates` map.

| Gate | Default | Stage | Since | Notes |
|------|---------|-------|-------|-------|
| `UpgradeEtcdVersion` | false | alpha | v0.36 | Coordinates etcd 3.5.27 upgrade with pre-upgrade snapshot |
| `UseEtcdWrapper` | true | GA (locked) | v0.25 | Cannot be disabled; effectively always on |

---

## Cross-Container Contracts

When adding a new container image (via a feature gate or otherwise), verify the contract with every container it shares a Pod with. The source of truth is the consuming container's bootstrap/init code — not the docs, which can lag.

| Contract point | Where to verify |
|----------------|-----------------|
| Endpoints the new container must expose | Read the consuming container's HTTP client source (e.g., `internal/brclient/brclient.go` in etcd-wrapper) |
| Readiness/liveness probe paths | `internal/component/statefulset/builder.go` in etcd-druid — probes are hardcoded here |
| Pod identity (name, namespace) | Check whether the container reads these from env vars (`MY_POD_NAME`, `MY_POD_NAMESPACE`) vs CLI flags vs downward API — all three patterns exist |
| TLS config shared between containers | Check `OperatorConfiguration` and the StatefulSet builder for how certs are mounted and passed |
| Init container ordering | Check `StatefulSet.Spec.InitContainers` in the StatefulSet builder — wrong ordering causes bootstrap deadlock |

Read `docs/concepts/bootstrap.md` in etcd-wrapper for the lifecycle diagram before touching any container that participates in the init sequence.

---

## etcd-backup-restore Flags — Key Changes

| Flag | Status | Version | Notes |
|------|--------|---------|-------|
| `--store-endpoint-override` | new | v0.41+ | Overrides storage endpoint; replaces deprecated secret-based approach |
| `--secondary-*` flags | new | v0.41+ | Dual-site backup sync (secondary-storage-provider, secondary-store-container, etc.) |
| `--next-cluster-version-compatible` | new | v0.42+ | For etcd version upgrade compatibility |
| `--compress-snapshots` | default=true | v0.40+ | Snapshot compression on by default (gzip) |
| `--enable-etcd-member-gc` | **removed** | v0.42 | Do not reference |
| `--k8s-member-gc-duration` | **removed** | v0.42 | Do not reference |

Dual-site backup: configure via `--secondary-*` flags and `SECONDARY_` env var prefix.
Immutable snapshots: S3 (Object Lock), ABS, GCS, OSS (WORM Lock).

---

## etcd-wrapper CLI Flags

| Flag | Default | Description |
|------|---------|-------------|
| `--etcd-wrapper-port` | 9095 | HTTP server port (/readyz, /stop) |
| `--etcd-client-port` | 2379 | etcd client port |
| `--backup-restore-host-port` | :8080 | BR sidecar address |
| `--backup-restore-tls-enabled` | false | TLS for BR communication |
| `--backup-restore-ca-cert-bundle-path` | "" | CA cert for BR TLS |
| `--etcd-server-name` | "" | Server name for etcd TLS |
| `--etcd-client-cert-path` | "" | etcd client TLS cert |
| `--etcd-client-key-path` | "" | etcd client TLS key |
| `--etcd-ready-timeout` | 0 (forever) | Timeout waiting for etcd ready |

---

## Recent API Additions (etcd-druid)

| Field | Version | Notes |
|-------|---------|-------|
| `spec.etcd.clientService.trafficDistribution` | v0.36 | `PreferSameZone`, `PreferSameNode` (K8s 1.34). `PreferClose` **deprecated**. |
| `spec.etcd.enableGRPCGateway` | v0.35 | Enable gRPC gateway |
| `spec.backup.store.endpointOverride` | v0.35 | Object store endpoint override (replaces deprecated secret-based approach) |
| `spec.etcd.snapshotCount` | v0.33 | Default reduced from 75000 to 10000 |
| `EtcdOpsTask` CRD | v0.34 | On-demand operational tasks |
| `ClusterIDMismatch` condition | v0.34 | Split-brain detection |
