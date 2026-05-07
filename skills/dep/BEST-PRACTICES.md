# DEP Best Practices Rubric

This rubric is used in both Guide and Review modes. Each dimension is scored:
- **Present & Strong** (2 points) — fully addressed with depth
- **Present but Weak** (1 point) — mentioned but lacks detail
- **Missing** (0 points) — not addressed

Total possible: 40 points.

| Score range | Rating | Action |
|-------------|--------|--------|
| 34-40 | Excellent | Ready for maintainer review |
| 26-33 | Good | Minor gaps to fill |
| 18-25 | Needs Work | Significant sections need expansion |
| 0-17 | Incomplete | Major rework needed |

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

**Check:** Are there 2-4 scenarios? Does each name specific pre-conditions? Are the repos involved identified?

### 7. Failure Scenarios With Recovery

**Good:** GEP-0039 categorizes failures (quorum loss, KAPI unhealthy) with specific recovery paths and actor assignments. Distinguishes retriable vs non-retriable.

**Bad:** Only the happy path described. "Errors will be handled appropriately."

**Check:** Are there 3+ failure scenarios? Is recovery actor named? Are escape hatches documented?

### 8. Alternatives With Rejection Rationale

**Good:** GEP-0039 evaluates "etcd Mirror Maker", "etcd Gateway", "3-Member etcd Cluster" with bullet-pointed limitations. GEP-0037 evaluates Karpenter with 5 specific rejection reasons.

**Bad:** "We considered nothing else" or strawman alternatives.

**Check:** Are there 2+ alternatives? Does each have specific rejection reasons (not just "too complex")?

### 9. Compatibility Is Explicit

**Good:** DEP-06: "Clusters without immutable buckets continue to function without any changes" + forward compatibility path + migration steps.

**Bad:** Assumes greenfield. No mention of existing clusters.

**Check:** Are backward compat, forward compat, and migration path all addressed?

### 10. References Link to Evidence

**Good:** Links to GitHub issues, related GEPs/DEPs, cloud provider documentation, benchmarks.

**Bad:** No links. Claims without evidence.

**Check:** Can every major claim be traced to a linked source?

---

## B. Operational & Cross-Repo (11-16)

### 11. Feature Gate

**Questions to ask:**
- Does this need a feature gate?
- What's the gate name? (Convention: `<FeatureName>`, e.g., `ImmutableBackups`)
- Default value? (alpha=off, beta=on, GA=always on)
- Graduation criteria from alpha → beta → GA?
- API-level toggle vs compile-time gate?
- What happens when toggled on a running cluster?
- What happens when toggled OFF on a cluster that had it ON?

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

---

## C. Diagrams & Evidence (17-20)

### 17. Appropriate Diagrams

**Hard requirement:** At least one Mermaid diagram per DEP.

See [DIAGRAM-GUIDE.md](DIAGRAM-GUIDE.md) for patterns and selection criteria.

**Check:** Is there a diagram? Does the type match the content? Are failure paths shown?

### 18. Empirical Evidence

**Good:** GEP-0039 cites "180ms threshold from extensive empirical testing across AWS, GCP, Azure." GEP-0037 built a simulation environment and presents benchmark data.

**Check:** Are design decisions backed by data? Are thresholds explained with methodology?

### 19. Phased Rollout Plan

**Good:** GEP-0038 defines 4 implementation phases with clear scope boundaries and explicit "Phase N will be a separate proposal" markers.

**Check:** Is the implementation phased? Are later phases explicitly deferred? Are phase boundaries clear?

### 20. Future Work Bounded

**Good:** Concrete list: "Dependent ordering among tasks will be addressed later" (DEP-05). Not vague: "We'll make it better in the future."

**Check:** Is each future item specific enough to become its own DEP? Are there no more than 5 items?

---

## Cross-Repo Review Lens

In BOTH Guide and Review modes, always evaluate from these three perspectives:

| Repo | What to check |
|------|-------------|
| **gardener/etcd-druid** | CRD/API changes, controller reconciliation, component changes, webhook changes, feature gates, RBAC |
| **gardener/etcd-backup-restore** | Sidecar behavior, backup/restore flow, snapshot handling, CLI commands (`etcdbrctl`), leader election, backup directory layout, garbage collection |
| **gardener/etcd-wrapper** | etcd process management, member lifecycle, peer communication, TLS handling, readiness/liveness probes, etcd configuration |

### Questions per repo:

**etcd-druid:**
- Does the CRD need new fields? (triggers two-commit workflow)
- Which controller is affected? (etcd, etcdcopybackupstask, compaction, secret)
- Are new RBAC permissions needed?
- Does this affect the component reconciliation order?

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

## Context

This is the best practices rubric for the `dep` skill in the etcd-druid-skills plugin. It encodes quality patterns learned from real GEPs (0037, 0038, 0039) and DEPs (04, 05, 06).
