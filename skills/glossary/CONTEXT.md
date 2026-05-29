# etcd-druid Ecosystem — Domain Glossary

This is the canonical glossary for the etcd-druid ecosystem. Every domain-specific
term used in issues, PRs, code, and conversations should have a single definition here.

---

### Etcd Cluster
**Definition:** A logical group of etcd members managed as a single unit by the Druid operator, represented by a single `Etcd` custom resource in Kubernetes.
**Avoid:** "etcd instance" (ambiguous — could mean one member or the whole cluster), "etcd deployment"
**Relationships:** Composed of Members; owned by a single Etcd CRD; backed by a StatefulSet
**Example:** "The Etcd cluster has 3 members running in namespace shoot--project--seed."

---

### Member
**Definition:** A single etcd process within an Etcd cluster, corresponding to one Pod in the StatefulSet, identified by a unique member ID in the etcd membership list.
**Avoid:** "node" (conflicts with Kubernetes Node), "instance" (too vague), "replica"
**Relationships:** Belongs to an Etcd Cluster; communicates with Peers; may hold a MemberLease
**Example:** "Member-2 failed its health check; the sidecar will restart it."

---

### Peer
**Definition:** Another member of the same etcd cluster from the perspective of a given member, communicating over the peer port (default 2380) for Raft consensus.
**Avoid:** "sibling", "partner"
**Relationships:** Every Member is a Peer to other Members; communicates via PeerService
**Example:** "The new learner cannot reach its peers because the PeerService DNS is not resolving."

---

### Learner
**Definition:** An etcd member that participates in log replication but does NOT vote in Raft elections, used during scale-up to safely add a new member without risking quorum.
**Avoid:** "non-voting member" (technically correct but not used in etcd-druid), "observer"
**Relationships:** Promoted to a full (voting) Member once caught up; tracked via MemberLease status
**Example:** "After adding member-3 as a Learner, wait until it catches up before promoting."

---

### Leader
**Definition:** The single etcd member in a cluster that has won the Raft election and is responsible for processing all write requests and replicating them to followers.
**Avoid:** "primary", "master" (outdated terminology)
**Relationships:** One Leader per Etcd Cluster at any time; other Members are followers; Leader election requires Quorum
**Example:** "Leader transfer was triggered before scaling down to avoid disrupting writes."

---

### Snapshot (Full)
**Definition:** A complete point-in-time backup of the entire etcd keyspace, stored as a single object in the Snapstore, taken periodically by the backup-restore sidecar.
**Avoid:** "backup" (ambiguous — could mean full or delta), "full backup", "base snapshot"
**Relationships:** Serves as the base for restoring; Delta Snapshots are applied on top of it
**Example:** "A full snapshot is taken every 24 hours and uploaded to the configured Snapstore."

---

### Snapshot (Delta)
**Definition:** An incremental backup containing only the etcd events (revisions) since the last snapshot (full or delta), stored as a separate object in the Snapstore.
**Avoid:** "incremental backup", "WAL backup", "diff snapshot"
**Relationships:** Applied sequentially on top of a Full Snapshot during restore; triggered by event threshold or time interval
**Example:** "Delta snapshots are taken every 5 minutes or every 100 events, whichever comes first."

---

### Compaction
**Definition:** The process of consolidating multiple delta snapshots into a new full snapshot to reduce restore time and Snapstore storage, performed by an on-demand compaction job.
**Avoid:** "etcd compaction" (that is an internal etcd keyspace operation, not the same thing), "snapshot merging"
**Relationships:** Reads Delta Snapshots and the previous Full Snapshot from Snapstore; produces a new Full Snapshot
**Example:** "The compaction job triggered because more than 200 delta snapshots accumulated."

---

### Defragmentation
**Definition:** An etcd-internal maintenance operation that reclaims free space in the etcd database file (bbolt) after compaction of the keyspace has removed old revisions.
**Avoid:** "compaction" (different operation), "cleanup", "shrink"
**Relationships:** Follows etcd keyspace compaction (not Druid snapshot compaction); managed by the backup-restore sidecar's defrag schedule
**Example:** "Defragmentation reduced the DB size from 4GB to 800MB after a mass deletion."

---

### Reconciliation
**Definition:** The control loop in the Druid operator that observes the current state of an Etcd custom resource and its sub-resources, then takes action to converge toward the desired state.
**Avoid:** "sync" (overloaded — see Sync below), "control loop" (too generic)
**Relationships:** Invokes Components (Sync, PreSync, TriggerDelete) to manage sub-resources; triggered by spec changes or periodic requeue
**Example:** "Reconciliation detected a replica count mismatch and triggered a StatefulSet scale-up."

---

### Component
**Definition:** An interface in the Druid operator that encapsulates the lifecycle management of a single Kubernetes sub-resource (e.g., StatefulSet, ConfigMap, Service) for an Etcd cluster.
**Avoid:** "resource" (too generic), "controller" (that is the reconciler itself)
**Relationships:** Implements Sync, PreSync, and TriggerDelete methods; orchestrated by the Reconciler
**Example:** "The StatefulSet component detected a spec change and performed a rolling update."

---

### Sync
**Definition:** The Component method that creates or updates the managed sub-resource to match the desired state derived from the Etcd spec.
**Avoid:** "reconcile" (that is the top-level loop), "apply"
**Relationships:** Called during Reconciliation after PreSync; counterpart to TriggerDelete
**Example:** "Component.Sync() patched the StatefulSet to increase replicas from 1 to 3."

---

### PreSync
**Definition:** The Component method called before Sync that performs prerequisite checks or preparatory mutations (e.g., verifying dependencies exist) before the main sub-resource is synced.
**Avoid:** "pre-check", "validate"
**Relationships:** Runs before Sync in the Component lifecycle; may short-circuit reconciliation if preconditions are not met
**Example:** "PreSync for the StatefulSet component verifies that PeerService exists before proceeding."

---

### TriggerDelete
**Definition:** The Component method that initiates deletion of the managed sub-resource, respecting finalizers and ordered teardown sequences.
**Avoid:** "delete" (too generic), "cleanup"
**Relationships:** Called during Etcd deletion reconciliation; inverse of Sync
**Example:** "TriggerDelete on the MemberLease component removes all leases before StatefulSet deletion."

---

### EtcdOpsTask
**Definition:** A custom resource that represents a discrete operational task (e.g., quorum recovery, defragmentation, restart) to be performed on an Etcd cluster, processed by the EtcdOpsTask controller.
**Avoid:** "maintenance task", "ops job", "EtcdOperation"
**Relationships:** References an Etcd cluster; has a state machine (Pending -> InProgress -> Succeeded/Failed/Error); some types interact with the backup-restore sidecar
**Example:** "An EtcdOpsTask of type QuorumRecovery was created to restore the single-member cluster."

---

### Quorum
**Definition:** The minimum number of etcd members (majority: floor(n/2)+1) that must agree on a write for it to be committed, ensuring consistency in the Raft consensus protocol.
**Avoid:** "majority" (imprecise in edge cases), "consensus" (that is the protocol, not the threshold)
**Relationships:** Loss of Quorum makes the cluster read-only; Quorum Recovery restores it
**Example:** "With 3 members, quorum is 2; losing 2 members means the cluster cannot accept writes."

---

### Quorum Recovery
**Definition:** The operator-driven process of restoring a non-functional etcd cluster (that lost quorum) to a healthy state, typically by bootstrapping from the latest snapshot with a single member and then scaling back up.
**Avoid:** "cluster restore" (ambiguous), "disaster recovery" (too broad), "failover"
**Relationships:** Triggered via EtcdOpsTask; uses Full + Delta Snapshots from Snapstore; results in a new member ID set
**Example:** "Quorum recovery was initiated after 2 of 3 members had unrecoverable disk failures."

---

### Backup-Restore Sidecar
**Definition:** The container running etcd-backup-restore that runs alongside the etcd main container in each Pod, responsible for taking snapshots, restoring data, managing the etcd process lifecycle, and performing health checks.
**Avoid:** "sidecar" (too generic in multi-container contexts), "backup agent", "BR"
**Relationships:** Manages the etcd process via etcd-wrapper; uploads to Snapstore; handles initialization and restoration
**Example:** "The backup-restore sidecar detected corruption and initiated a restore from the latest full snapshot."

---

### etcd-wrapper
**Definition:** A thin wrapper binary around the etcd process that handles signal forwarding, TLS certificate rotation, and integration with the backup-restore sidecar's lifecycle management.
**Avoid:** "etcd binary" (it wraps etcd, it is not etcd itself), "launcher"
**Relationships:** Invoked by the backup-restore sidecar; manages the actual etcd process; handles graceful shutdown
**Example:** "etcd-wrapper intercepted SIGTERM and initiated a graceful leadership transfer before shutdown."

---

### Embedded Etcd
**Definition:** An etcd instance started in embedded mode by the backup-restore sidecar for the purpose of performing a restore operation (replaying snapshots into a fresh database) without joining any cluster.
**Avoid:** "standalone etcd", "restore etcd", "temporary etcd"
**Relationships:** Used during restoration by the backup-restore sidecar; not part of the running Etcd Cluster; discarded after restore completes
**Example:** "The sidecar starts an embedded etcd to replay delta snapshots onto the full snapshot base."

---

### StatefulSet
**Definition:** The Kubernetes StatefulSet managed by the Druid operator that runs the etcd Pods with stable network identities and persistent storage, one Pod per etcd Member.
**Avoid:** "deployment" (wrong workload type), "pod set"
**Relationships:** Managed by the StatefulSet Component; each Pod runs etcd + backup-restore sidecar; uses PVCs for data
**Example:** "The StatefulSet was scaled from 1 to 3 replicas to restore a multi-member cluster."

---

### PeerService
**Definition:** The headless Kubernetes Service that provides stable DNS names for etcd peer-to-peer communication (port 2380) within the cluster.
**Avoid:** "headless service" (too generic), "internal service", "peer DNS"
**Relationships:** Used by Members to discover and communicate with Peers; managed by the PeerService Component
**Example:** "etcd-main-peer.shoot--project--seed.svc resolves to all member Pod IPs for Raft traffic."

---

### ClientService
**Definition:** The Kubernetes Service that exposes the etcd client endpoint (port 2379) for application workloads to connect and perform read/write operations.
**Avoid:** "etcd service" (ambiguous), "external service", "client endpoint"
**Relationships:** Load-balances across healthy Members; used by kube-apiserver to reach etcd
**Example:** "The kube-apiserver connects to the ClientService to store all cluster state in etcd."

---

### MemberLease
**Definition:** A Kubernetes Lease object created per etcd member that the backup-restore sidecar periodically renews to signal liveness, used by the operator to determine member health and detect failures.
**Avoid:** "health lease", "heartbeat lease", "member status"
**Relationships:** One per Member; renewed by the backup-restore sidecar; checked by the Reconciler to assess cluster health
**Example:** "Member-1's MemberLease expired after 30 seconds, indicating the sidecar is unresponsive."

---

### SnapshotLease
**Definition:** A Kubernetes Lease object used to record the timestamp and metadata of the last successful full or delta snapshot, enabling the operator to monitor backup recency without querying the Snapstore.
**Avoid:** "backup lease", "snapshot status", "snapshot timestamp"
**Relationships:** Updated by the backup-restore sidecar after each successful snapshot upload; read by the Reconciler to set status conditions
**Example:** "The SnapshotLease for delta snapshots shows the last successful backup was 3 minutes ago."

---

### Feature Gate
**Definition:** A named boolean toggle in the Druid operator's configuration that enables or disables experimental or in-progress functionality, following the Kubernetes feature gate pattern (Alpha/Beta/GA lifecycle).
**Avoid:** "feature flag" (informal but acceptable in conversation), "toggle", "experiment"
**Relationships:** Configured in OperatorConfiguration; guards new reconciliation paths or API fields
**Example:** "The UseEtcdWrapper feature gate must be enabled to activate the new process management flow."

---

### OperatorConfiguration
**Definition:** The typed configuration object (typically loaded from a ConfigMap or command-line flags) that controls Druid operator behavior including feature gates, worker counts, sync periods, and default values.
**Avoid:** "druid config" (too vague), "operator flags", "settings"
**Relationships:** Contains Feature Gates; consumed at operator startup; affects all Reconciliation loops
**Example:** "OperatorConfiguration sets the EtcdStatusCheckTimeout to 60s for slow networks."

---

### Snapstore
**Definition:** The abstraction over object storage (S3, GCS, ABS, Swift, or local) where the backup-restore sidecar uploads and retrieves full and delta snapshots.
**Avoid:** "bucket" (that is the underlying storage, not the abstraction), "backup store", "object store"
**Relationships:** Configured per Etcd resource via the store spec; accessed by the backup-restore sidecar and compaction job
**Example:** "The Snapstore is configured to use an S3 bucket with prefix /etcd-main/shoot--project--seed."

---

### Object Lock
**Definition:** An immutability feature on the Snapstore bucket that prevents snapshot objects from being deleted or overwritten for a configured retention period, protecting against accidental or malicious deletion.
**Avoid:** "bucket lock", "immutable backup", "WORM" (technically correct but jargon)
**Relationships:** Applied at the Snapstore (bucket) level; ensures Full and Delta Snapshots cannot be tampered with
**Example:** "Object Lock with a 7-day retention ensures snapshots survive even if credentials are compromised."

---

### WAL (Write-Ahead Log)
**Definition:** The append-only log where etcd records every proposed change before applying it to the key-value store, providing durability guarantees and enabling crash recovery.
**Avoid:** "transaction log", "redo log", "journal"
**Relationships:** Persisted on the PVC alongside the etcd database; replayed on restart; distinct from Delta Snapshots (which are event-level backups taken by the sidecar)
**Example:** "The WAL directory grew to 1GB because snapshotting was paused, preventing space reclamation."

---

### Revision
**Definition:** A monotonically increasing 64-bit integer assigned to every key modification in etcd, serving as the logical clock for the entire keyspace.
**Avoid:** "version" (that is per-key, not global), "sequence number", "transaction ID"
**Relationships:** Delta Snapshots record events between revisions; etcd compaction removes data below a given revision
**Example:** "The cluster is at revision 1,247,892; the last delta snapshot covers up to revision 1,247,500."

---

### Endpoint
**Definition:** A network address (host:port) used to connect to an etcd member, either the client endpoint (2379) for read/write operations or the peer endpoint (2380) for cluster communication.
**Avoid:** "URL" (endpoint includes both advertised and listen addresses), "address" (too generic)
**Relationships:** Advertised via ClientService and PeerService; configured in etcd flags and peer URLs
**Example:** "The client endpoint https://etcd-main-0:2379 was unreachable due to an expired TLS certificate."

---

### druidctl
**Definition:** The CLI tool for interacting with etcd-druid-managed clusters, providing commands to inspect status, trigger operations (via EtcdOpsTask), and manage snapshots without direct kubectl manipulation.
**Avoid:** "etcdctl" (that is the upstream etcd CLI, not the druid CLI), "druid CLI"
**Relationships:** Creates EtcdOpsTask resources; reads Etcd CRD status; wraps common operator interactions
**Example:** "Run `druidctl trigger defrag --etcd=etcd-main --namespace=shoot-ns` to start defragmentation."

---

### Etcd CRD
**Definition:** The Custom Resource Definition that defines the `Etcd` resource schema in Kubernetes, specifying the desired state of an etcd cluster including replicas, backup configuration, TLS settings, and resource requirements.
**Avoid:** "Etcd resource" (slightly ambiguous — could mean the CRD or an instance), "etcd manifest", "etcd spec"
**Relationships:** Instances of this CRD are reconciled by the Druid operator; each instance owns a StatefulSet, Services, Leases, and ConfigMaps
**Example:** "The Etcd CRD was updated to v1alpha2 with new fields for compaction scheduling."
