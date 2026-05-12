# Rejected: Single Container Pod for etcd

## Context

The question arises whether etcd pods should run a single container that handles both the etcd process and backup/restore operations, rather than the current multi-container architecture (etcd-wrapper + backup-restore sidecar).

## Decision

Rejected.

## Reasoning

1. **Separation of concerns** — The backup-restore sidecar handles initialization, periodic/incremental snapshots, data validation, and full restore independently of the etcd process lifecycle. Combining these into one binary would create tight coupling between unrelated responsibilities.

2. **Independent lifecycle management** — etcd-wrapper manages the embedded etcd process (startup, shutdown, configuration). The backup-restore sidecar manages snapshot scheduling, upload to object storage, and restore orchestration. These have different failure modes and restart semantics.

3. **Independent versioning and updates** — The sidecar can be updated (new snapshot features, storage backend support, bug fixes) without touching the etcd-wrapper or etcd binary. This enables faster iteration on backup functionality without risking etcd stability.

4. **Restart isolation** — If the backup-restore process crashes, it can restart without affecting the running etcd member. Conversely, if etcd restarts, snapshot state in the sidecar is preserved.

5. **Resource accounting** — Separate containers allow distinct resource requests/limits for etcd (memory-intensive) and backup-restore (I/O-intensive during snapshots), enabling better scheduling decisions.

## Prior Discussions

- This architecture is foundational to both etcd-backup-restore and etcd-wrapper projects.
- The sidecar pattern is a well-established Kubernetes design pattern for auxiliary processes.
