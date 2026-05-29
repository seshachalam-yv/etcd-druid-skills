# DEP Best Practices Rubric

This rubric is used in both Guide and Review modes. Each dimension is scored:
- **Present & Strong** (2 points) — fully addressed with depth
- **Present but Weak** (1 point) — mentioned but lacks detail
- **Missing** (0 points) — not addressed

Total possible: 50 points across 25 dimensions.

| Score range | Rating | Action |
|-------------|--------|--------|
| 42-50 | Excellent | Ready for maintainer review |
| 32-41 | Good | Minor gaps to fill |
| 22-31 | Needs Work | Significant sections need expansion |
| 0-21 | Incomplete | Major rework needed |

---

## A. Structure & Content (1-10)

### 1. Summary Stands Alone

**Good:** "This proposal introduces immutable backups for etcd clusters managed by etcd-druid. By leveraging cloud provider immutability features, backups taken by etcd-backup-restore can neither be modified nor deleted once created for a configurable retention duration." (DEP-06)

**Bad:** "This DEP adds immutable backups." (just restates the title)

**Check:** Can a reader who only reads the Summary understand WHAT changes and WHY?

### 2. Motivation Shows Pain

**Good:** Links to real issues, operational incidents, quantified impact. DEP-04: "Today, etcd-druid mainly acts as an etcd cluster provisioner, and seldom takes remediatory actions if the etcd cluster goes into an undesired state that needs to be resolved by a human operator."

**Bad:** "It would be nice to have X" without evidence of need.

**Check:** Is there at least one link to a real issue or incident? Is the pain quantified?

### 3. Goals Are Measurable

**Good:** "Zero downtime for the shoot cluster's Kubernetes API server during the migration process" (GEP-0039). "Automate the latter [recovery]... to make it quicker and error-free" (DEP-05).

**Bad:** "Improve reliability" or "Make backups better."

**Check:** For each goal, can you write a test that verifies it's met?

### 4. Non-Goals Draw Boundaries

**Good:** DEP-05 lists specific exclusions with rationale: "In the current scope, capability to abort/suspend an out-of-band task is not going to be provided. This could be considered as an enhancement based on pull."

**Bad:** Missing entirely, or listing things no one would expect (strawman non-goals).

**Check:** Are there 5+ non-goals? Does each explain WHY it's excluded? Would removing any cause scope creep?

### 5. Proposal Is Concrete

**Good:** Go struct definitions with kubebuilder markers, YAML examples showing both spec AND status, specific controller and package names.

**Bad:** "We will add a field to track the state" without showing what it looks like.

**Check:** Could an engineer implement this section without asking clarifying questions?

### 6. Use Cases Ground the Design

**Good:** DEP-05 provides 5 use cases, each with specific scenarios, pre-conditions, and task configs. DEP-06 describes hibernation, migration, and corruption scenarios.

**Bad:** Generic descriptions disconnected from real operations.

**Check:** Are there 2-4 scenarios? Does each name specific pre-conditions? Are the repos involved identified? Are single-replica vs multi-replica clusters handled distinctly when behavior differs?

### 7. Failure Scenarios With Recovery

**Good:** GEP-0039 categorizes failures (quorum loss, KAPI unhealthy) with specific recovery paths and actor assignments. Distinguishes retriable vs non-retriable. Names timeout values, backoff strategy, and where the stuck state surfaces (Etcd condition, Event, metric).

**Bad:** Only the happy path described. "Errors will be handled appropriately."

**Check (per failure):**
- [ ] What fails — concrete scenario, not "an error occurs"
- [ ] Who detects — specific controller / probe / external actor
- [ ] Retriable? — timeout value? backoff strategy (linear / exponential / capped)?
- [ ] Surfacing channel — `Etcd.status.conditions` / Kubernetes Event / metric / log line
- [ ] Indefinite-block analysis — does this failure starve other work? (e.g., one stuck pod blocking all updates cluster-wide)
- [ ] Infrastructure-stuck cases — PV pending, scheduling failure, CSI attach timeout, image pull backoff: explicitly handled?
- [ ] Operator escape hatch — manual intervention path documented

### 8. Alternatives With Rejection Rationale

**Good:** GEP-0039 evaluates "etcd Mirror Maker", "etcd Gateway", "3-Member etcd Cluster" with bullet-pointed limitations. GEP-0037 evaluates Karpenter with 5 specific rejection reasons.

**Bad:** "We considered nothing else" or strawman alternatives.

**Check:** Minimum **3 alternatives**, and at least one MUST come from this list:
- Do nothing / use an existing Kubernetes primitive (PDB, `maxUnavailable`, existing controller)
- Extend an existing controller / component instead of creating a new one
- Configuration option in an existing API field instead of a new code path
- The inverse design (e.g., feature gate where you proposed an API field, or vice versa)

For each alternative: brief description, **bullet-pointed** rejection reasons (not "too complex"), and the trade-off that made the chosen approach better.

### 9. Compatibility Is Explicit

**Good:** DEP-06: "Clusters without immutable buckets continue to function without any changes" + forward compatibility path + migration steps.

**Bad:** Assumes greenfield. No mention of existing clusters.

**Check:** Are backward compat, forward compat, and migration path all addressed?

### 10. References Link to Evidence

**Good:** Links to GitHub issues, related GEPs/DEPs, cloud provider documentation, benchmarks, upstream Kubernetes/etcd source code or design docs.

**Bad:** No links. Claims without evidence. Assertions about Kubernetes/etcd behavior without a link to the source or upstream docs.

**Check:** Can every major claim ("the StatefulSet controller does X", "etcd learners reject reads") be traced to a linked source?

---

## B. Operational & Cross-Repo (11-20)

### 11. Feature Gate

**Questions to ask:**
- Does this need a feature gate?
- What's the gate name? (Convention: `<FeatureName>`, e.g., `ImmutableBackups`)
- Default value? Convention: alpha=off, beta=on, GA=always on. **New features default OFF in alpha.**
- **Default-flip release:** when does the default flip from off → on? After how many releases of production exposure? State this explicitly so reviewers know when behavior changes for everyone.
- Graduation criteria from alpha → beta → GA?
- API-level toggle vs compile-time gate?
- What happens when toggled on a running cluster?
- What happens when toggled OFF on a cluster that had it ON?

**Feature gate vs API field — when to choose which:**
- **Feature gate** (preferred): the choice is invisible to the operator's mental model, or it's a temporary opt-in for rollout safety. Avoids permanent CRD-surface debt. Use when the user has no meaningful operational decision to make.
- **API field**: the operator has a real, lasting decision (e.g., per-cluster security profile, per-cluster scaling policy). Justify why this decision must persist in the public CRD rather than being hidden behind a gate.

**Good:** GEP-0038 uses per-Seed API field for gradual rollout because some providers can't support the feature.

### 12. Breaking Changes

**Signals that indicate a breaking change:**
- CRD field removal or type change
- Changed semantics of existing fields
- New required fields without defaults
- Changed sidecar CLI flags or endpoints
- Changed backup directory layout or snapshot format
- StatefulSet spec changes that trigger rolling restart
- Changed container ports or probe endpoints

**Questions to ask:**
- Does this break existing API contracts?
- Is there a migration path? How many releases for deprecation?
- Does it break backup-restore ↔ druid contract?
- Does it break wrapper ↔ druid contract?
- Can old and new versions coexist during rollout?

### 13. Cross-Repo Coordination

**Questions to ask:**
- Which repos need changes? (etcd-druid, etcd-backup-restore, etcd-wrapper)
- What's the rollout order? Can they be deployed independently?
- Is there a version dependency? (e.g., "requires backup-restore >= v0.35")
- Actor responsibilities: which controller does what per step?
- Coordination signals: labels, annotations, conditions that pass state?
- What happens during mixed-version rollout?

**Good:** GEP-0031 has separate sections for each affected component with explicit responsibilities.

### 14. Sidecar Contract

**Questions to ask:**
- Is the contract between druid and backup-restore/wrapper defined?
- New CLI flags on `etcdbrctl`?
- New HTTP endpoints on the sidecar?
- Changed probe behavior (readiness/liveness)?
- Changed environment variables passed by druid to sidecars?

### 15. Rollback Safety

**Questions to ask:**
- Feature gate disabled after being enabled — what happens?
- Data written while feature was ON — is it still readable?
- CRD fields populated while ON — are they preserved or lost?
- StatefulSet changes — does rollback trigger a restart?
- Backup format changes — can old backup-restore read new backups?
- **Mid-flight toggle:** if a multi-step operation is in progress and the gate flips OFF (or strategy changes), what is the behavior? Does the in-flight work complete, abort, or hand off?

### 16. CEL Validations

**Checklist:**
- [ ] Field-scoped validation: enums, ranges, formats
- [ ] Immutability: fields that must not change after creation (`self == oldSelf`)
- [ ] Cross-field invariants: "if A is set, B is required" / mutual exclusivity
- [ ] Transition rules: status fields that can only move forward
- [ ] Default values: `+kubebuilder:default` where sensible
- [ ] Optional vs Required: new fields on existing resources MUST be optional
- [ ] `has()` guard: optional field references in CEL must use `has(self.field)`

**Good pattern (from DEP-05):**
```go
// +kubebuilder:validation:Required
// +kubebuilder:validation:XValidation:rule="self == oldSelf",message="config is immutable"
Config EtcdOpsTaskConfig `json:"config"`
```

### 17. Public-API vs. Implementation-Detail Discipline

The DEP is a **public-facing document**. Every proposed API field, label key, annotation, status reason string, or named convention must pass the **implementation-swap test**: would this still make sense if we replaced the underlying implementation?

**Examples:**
- ❌ Proposing `Etcd.spec.updateStrategy: OnDelete | RollingUpdate` exposes that we use a StatefulSet. If we replace the StatefulSet with a custom controller, the field stops making sense — it's an implementation detail leaking into the public API.
- ✅ Proposing a feature gate `OnDeleteUpdateStrategy` keeps the choice internal; the operator-visible behavior is described abstractly ("druid coordinates pod updates safely").
- ❌ Hard-coding a reference to `controller-revision-hash` label string in a DEP — that's an internal Kubernetes label whose key may change. Reference the public Go constant (`appsv1.StatefulSetRevisionLabel`) and acknowledge the dependency.
- ❌ Treating a member-lease `holderIdentity` value as a contract without flagging it as fragile.

**Check:**
- For every proposed API field, label, annotation, status reason: ask "would this still make sense if we replaced the underlying mechanism?" If no → it's an implementation detail; hide behind a feature gate or use a public Go constant.
- Are internal mechanisms (controller-revision-hash strings, label keys, lease holder identities) acknowledged as non-binding contracts when referenced?
- Does the DEP separate "public surface" (CRD, status, events, documented behavior) from "internal mechanics" (controller logic, ordering choices)?

### 18. Terminology Precision

Reviewers consistently push back on imprecise or contradictory terminology. New domain terms must hold up to scrutiny.

**Check (for every defined term):**
- [ ] **Operational test:** can you write a one-line test for membership? ("How do I check if pod X is `participating`?" → "Pod X passes its etcd readiness probe.")
- [ ] **No upstream contradiction:** if you reuse a Kubernetes/etcd term (Leader, Learner, Quorum, Eviction, RollingUpdate), use the upstream definition exactly. Link to the upstream doc.
- [ ] **State-transition coverage:** if a term names a state, what about transient states (restarting, learner-promoting, scheduling)? Either the term covers them or you list them as separate cases.
- [ ] **Single observable signal:** the term should be derivable from observable cluster state, not from implementation internals.

**Bad:** Coining "Participating pod" / "Non-Participating pod" without defining how to observe membership and without addressing transient states (restarting, briefly down).

**Good:** "**Participating pod:** A pod whose etcd container is currently a leader or follower in the cluster's quorum (i.e., its etcd readiness probe passes). Members in `restarting`, `learner`, or `unhealthy` state are non-participating regardless of cause."

### 19. Controller Boundary Hygiene

If the proposal introduces a new controller, splits responsibility across controllers, or touches a primary object that another reconciler already writes to, race conditions become a primary risk. Reviewers will block on this.

**Check:**
- [ ] List every other controller / reconciler that writes to the same primary object (Etcd CR, StatefulSet, Pod).
- [ ] Define the **coordination signal** between controllers: revision hash, status condition, lease, label, annotation.
- [ ] State explicitly what happens during **overlap**: if controller A is mid-rollout when controller B pushes a new desired state, who wins?
- [ ] State the **rollback semantics**: if the new controller is disabled mid-flight (gate off, replicas=0, deletion), what happens?
- [ ] Justify why the work needs a new controller vs. integrating into an existing reconciler. The default Kubernetes pattern is "one controller per primary object" — deviations need a reason.

### 20. Metrics Design

Beyond "is it observable?" — verify metric names, labels, and computability.

**Naming convention:** `etcddruid_<subsystem>_<measurement>_<unit>` (e.g., `etcddruid_compaction_duration_seconds`).

**Check:**
- [ ] **Naming:** snake_case, subsystem prefix, ends in unit suffix (`_seconds`, `_bytes`, `_total`).
- [ ] **Labels:** include `{namespace, name}` for cluster-scoped metrics so multi-cluster operators can group/filter.
- [ ] **Don't encode features in names:** if the measurement is generic (e.g., "update duration"), use a metric label for the strategy, not separate metrics per feature flag. `etcddruid_update_duration_seconds{strategy="OnDelete"}` beats `etcddruid_ondelete_update_duration_seconds`.
- [ ] **Computability for stateless controllers:** if the controller is stateless, where does "start time" come from for duration metrics? Status condition? Annotation? In-memory time would be lost across reconciler restarts.
- [ ] **Alertability:** what would you alert on? If the answer is "nothing", you may not need this metric.

---

## C. Diagrams & Evidence (21-23)

### 21. Appropriate Diagrams

**Hard requirement:** At least one Mermaid diagram per DEP.

See [DIAGRAM-GUIDE.md](DIAGRAM-GUIDE.md) for patterns, the quality checklist, and selection criteria.

**Check:** Is there a diagram? Does the type match the content? Are failure paths shown? Does every decision arrow have a label? Does every node unambiguously identify the entity it refers to? Does the diagram add structure not visible in surrounding prose?

### 22. Empirical Evidence

**Good:** GEP-0039 cites "180ms threshold from extensive empirical testing across AWS, GCP, Azure." GEP-0037 built a simulation environment and presents benchmark data.

**Check:** Are design decisions backed by data? Are thresholds explained with methodology?

### 23. Phased Rollout Plan

**Good:** GEP-0038 defines 4 implementation phases with clear scope boundaries and explicit "Phase N will be a separate proposal" markers.

**Check:** Is the implementation phased? Are later phases explicitly deferred? Are phase boundaries clear?

---

## D. Future Work, Decisions, Adjacent Systems (24-25)

### 24. Future Work Bounded & Decision Records Linked

**Good (Future Work):** Concrete list: "Dependent ordering among tasks will be addressed later" (DEP-05). Not vague: "We'll make it better in the future."

**Good (Decision Records):** Closed offline-discussion outcomes are captured in `docs/decisions/` (or a linked GitHub discussion/issue) and referenced from the DEP — not inlined.

**Check:**
- Is each future-work item specific enough to become its own DEP?
- Are there no more than 5 items?
- Did any offline-discussion notes leak into the public DEP body? **Move them to a linked decision record.** The DEP is public; internal-only deliberation is not.
- For decisions that were debated and closed, is there a link to the decision record so future readers can see the rejected paths and rationale?

### 25. Adjacent-System Impact

Beyond the three core repos, real clusters interact with adjacent systems. Missing these is a recurring review-blocker.

**Check (which apply to your change):**
- [ ] **Vertical Pod Autoscaler (VPA)** — does the change affect pod resources? VPA uses the eviction API; that interaction may bypass your custom logic.
- [ ] **Cluster Autoscaler** — `cluster-autoscaler.kubernetes.io/safe-to-evict` annotation behavior. Single-replica vs HA differences.
- [ ] **PodDisruptionBudget** — interaction with `OnDelete`/eviction. Different operators (e.g., Gardener) may use `AlwaysAllow` PDB policy that defeats classic protection.
- [ ] **CSI / volume attach** — slow attach can manifest as "stuck pod" failure mode.
- [ ] **Self-hosted variants** — if your design depends on a Kubernetes feature only present in managed environments (Gardener-style member leases), state explicitly: "self-hosted is out of scope" or describe the fallback.
- [ ] **Distribution-specific defaults** — don't generalize from Gardener defaults to all environments. If you assert "the operator will always do X", scope it: "in Gardener" or "when configured with Y".

---

## Cross-Repo Review Lens

In BOTH Guide and Review modes, always evaluate from these four perspectives:

| Repo / System | What to check |
|------|-------------|
| **gardener/etcd-druid** | CRD/API changes, controller reconciliation, component changes, webhook changes, feature gates, RBAC |
| **gardener/etcd-backup-restore** | Sidecar behavior, backup/restore flow, snapshot handling, CLI commands (`etcdbrctl`), leader election, backup directory layout, garbage collection |
| **gardener/etcd-wrapper** | etcd process management, member lifecycle, peer communication, TLS handling, readiness/liveness probes, etcd configuration |
| **Adjacent systems** | VPA, Cluster Autoscaler, PodDisruptionBudget, CSI, self-hosted variant, Gardener landscape policy (e.g., `AlwaysAllow`) |

### Questions per repo:

**etcd-druid:**
- Does the CRD need new fields? (triggers two-commit workflow)
- Which controller is affected? (etcd, etcdcopybackupstask, compaction, secret)
- Are new RBAC permissions needed?
- Does this affect the component reconciliation order?
- Does another reconciler write to the same primary object? (see Dimension 19)

**etcd-backup-restore:**
- Are new `etcdbrctl` subcommands needed?
- Does the backup/restore flow change?
- Does the snapshot format or directory layout change?
- Are there new HTTP endpoints for druid to call?
- Does garbage collection behavior change?

**etcd-wrapper:**
- Does the etcd configuration template change?
- Are there new peer URL configurations?
- Do TLS certificates need new SANs?
- Does the member initialization flow change?

**Adjacent systems:**
- Does any change interact with VPA's eviction API calls?
- Does Cluster Autoscaler's safe-to-evict annotation behavior shift?
- Does the change weaken or rely on PDB protection (and is the operator's PDB policy assumed)?
- Does the design quietly assume Gardener defaults that don't hold for self-hosted users?
