---
title: DEP Title
dep-number: NN
creation-date: YYYY-MM-DD
status: provisional|implementable|implemented
authors:
- "@author"
reviewers:
- "@reviewer"
---

# DEP-NN: Short descriptive title

## Summary

<!--
A good summary is at least a paragraph. A reader should understand the change
without reading further. Do not restate the title.

Voice: factual and declarative. Avoid editorializing language ("poorly ordered",
"naive", "broken") about existing Kubernetes / etcd behavior — describe what is
true today and what your proposal changes, not value judgements.
-->

## Terminology

<!--
Optional. Define domain-specific terms used in this proposal.
Include only if readers may not know terms like "leading-backup-sidecar",
"snapshot compaction", "member learner", etc.

Rules for every term you define:
- One-line operational test: "How do I check if X is in this state?"
  Example: "Participating pod: a pod whose etcd readiness probe passes."
- Do not redefine upstream Kubernetes / etcd terms. If you use Leader, Learner,
  Quorum, Eviction, RollingUpdate, OnDelete — link to the upstream doc and use
  the upstream meaning.
- Cover transient states: a "restarting" or "scheduling" pod must fall into one
  of your defined buckets, or be listed as a separate case.
- The term must be derivable from observable cluster state, not from internal
  controller variables.
-->

## Motivation

<!--
Describe the operational pain, incidents, or inefficiency that motivates this.
Link to real issues. Include empirical data where possible.
-->

### Goals

<!--
List measurable goals. "Zero downtime during X", "Automate N-step process",
"Reduce recovery time from M minutes to N seconds".
Minimum 3 goals. Each should be verifiable.
-->

### Non-Goals

<!--
Minimum 3 non-goals. Draw boundaries to prevent scope creep.
Each non-goal should explain WHY it's excluded.
-->

## Proposal

### Use Cases

<!--
2-4 concrete scenarios. Each should have:
- Scenario description
- Pre-conditions
- Expected outcome
- Which repos are involved
- Single-replica vs multi-replica behavior (if behavior differs, state both
  cases explicitly — reviewers consistently ask about singleton clusters).
-->

### API Changes

<!--
Show Go structs AND YAML examples. Include BOTH spec and status.
Use kubebuilder markers. Show CEL validation rules.
If no API change, state "No API changes required" and explain why.

Apply the implementation-swap test (Best-Practices Dimension 17):
For every proposed field, label, annotation, or status reason — would this
still make sense if we replaced the underlying implementation (e.g., StatefulSet
→ custom controller)? If no, it's an implementation detail. Hide it behind a
feature gate or use a public Go constant; do not surface it in the CRD.
-->

### Lifecycle / Flow

<!--
State transitions, sequence of operations, or reconciliation flow.
MUST include at least one Mermaid diagram.
Use stateDiagram-v2 for lifecycle, sequenceDiagram for cross-component,
flowchart for decision logic.

See DIAGRAM-GUIDE.md "Quality Checklist" — every decision arrow needs a label,
every node must unambiguously identify the entity it refers to, failure paths
must be present.
-->

### Pre-conditions & Failure Scenarios

<!--
For EACH failure scenario, fill in:

- What fails — concrete scenario, not "an error occurs"
- Who detects — which controller / probe / external actor
- Retriable? — timeout value? backoff strategy (linear / exponential / capped)?
- Surfacing channel — pick all that apply:
    [ ] Etcd.status.conditions
    [ ] Kubernetes Event
    [ ] Prometheus metric
    [ ] log line
- Indefinite-block analysis — does this failure starve other work?
  (e.g., one stuck pod blocking all updates cluster-wide)
- Infrastructure-stuck cases — PV pending, scheduling failure, CSI attach
  timeout, image pull backoff: explicitly handled?
- Operator escape hatch — manual intervention path (annotation, kubectl
  command, EtcdOpsTask)
-->

### Public Surface vs. Internal Mechanics

<!--
List which aspects of this proposal are public API contracts and which are
internal implementation details. For each item, classify:
- Public — visible in CRD, status, events, documented behavior. Stable.
- Internal — controller logic, label keys, status reason strings, ordering
  choices, lease holder identity values. May change between releases.

Apply the implementation-swap test: would the public surface still make sense
if we replaced the underlying mechanism (StatefulSet, leases, etc.)?

When you reference an internal Kubernetes label / annotation / status string,
either use its public Go constant (e.g., appsv1.StatefulSetRevisionLabel) or
explicitly acknowledge that you depend on a non-binding internal contract.
-->

### Controller Boundaries

<!--
Required if this proposal introduces a new controller, splits responsibility
across controllers, or touches a primary object that another reconciler also
writes to.

- List every other controller / reconciler that writes to the same primary
  object (Etcd CR, StatefulSet, Pod, lease, etc.).
- Coordination signal: how do these controllers stay coordinated? (revision
  hash, status condition, lease, label, annotation)
- Overlap behavior: if controller A is mid-rollout when controller B pushes
  a new desired state, who wins? Is there a documented hand-off?
- Why a new controller? Justify why this work cannot fit into an existing
  reconciler. The default Kubernetes pattern is "one controller per primary
  object" — deviations need a reason.
-->

## Feature Gate

<!--
Required if the change introduces a toggleable capability.

- Gate name (PascalCase, e.g., ImmutableBackups, OnDeleteUpdateStrategy)
- Default value (alpha=off, beta=on, GA=always on) — new features default OFF
- Default-flip release: when do you propose flipping the default from off → on?
  After how many releases of production exposure? State this so reviewers know
  when behavior changes for everyone.
- Graduation criteria from alpha → beta → GA
- Behavior when toggled on a running cluster
- Rollback safety: what happens if the gate is disabled after being enabled
- Mid-flight toggle: if a multi-step operation is in progress and the gate
  flips off (or strategy changes), what happens? Does in-flight work complete,
  abort, or hand off?
- Feature gate vs. API field: justify why you chose a gate (or why you chose
  a CRD field instead). Prefer a gate when the choice is invisible to the
  operator's mental model; prefer a field only when the operator has a real,
  lasting decision to make.
-->

## Compatibility

<!--
- Backward compatibility: do existing clusters continue to work unchanged?
- Forward compatibility: can new clusters opt-in incrementally?
- Migration path: what steps must operators take?
- Cross-repo version dependencies: deployment order for etcd-druid,
  etcd-backup-restore, etcd-wrapper
- Adjacent-system impact: VPA, Cluster Autoscaler, PodDisruptionBudget, CSI,
  self-hosted variant. Don't generalize from Gardener defaults — scope your
  claims ("in Gardener", "when configured with X") if behavior depends on
  landscape-specific config.
-->

## Metrics

<!--
Optional but encouraged for observable changes.

For each metric:
- Name: etcddruid_<subsystem>_<measurement>_<unit>
  (snake_case, subsystem prefix, unit suffix like _seconds / _bytes / _total)
- Type: counter / histogram / gauge
- Labels: include {namespace, name} for cluster-scoped metrics; do NOT encode
  feature flags in the metric name (use a label instead — e.g.,
  etcddruid_update_duration_seconds{strategy="OnDelete"} beats a separate
  etcddruid_ondelete_update_duration_seconds metric).
- Computability: where does the "start time" come from for duration metrics?
  Especially important for stateless controllers — must be derivable from
  status / annotations, not in-memory state.
- Alertability: what would you alert on? If "nothing", reconsider whether
  you need this metric.
-->

## Testing Strategy

<!--
How will this feature be validated? For each repo affected:
- Unit tests: key scenarios, which packages
- Integration tests: envtest-based, what controllers/components
- E2e tests: KIND cluster scenarios, which providers
- Manual verification: kubectl commands to confirm behavior

Include the expected test commands:
  etcd-druid: make test-unit, make test-integration, make ci-e2e-kind
  etcd-backup-restore: make test-unit, make test-integration
  etcd-wrapper: make test
-->

## Alternatives

<!--
Minimum 3 alternatives evaluated. At least ONE must come from this list:
- Do nothing / use an existing Kubernetes primitive (PDB, maxUnavailable,
  existing controller)
- Extend an existing controller / component instead of creating a new one
- Configuration option in an existing API field instead of a new code path
- The inverse design (e.g., feature gate where you proposed an API field,
  or vice versa)

For each alternative:
- Brief description
- Why it was rejected — bullet-pointed limitations (not "too complex")
- The trade-off that made the chosen approach better
-->

## Future Work

<!--
Bounded list of concrete next steps. Not vague aspirations.
Each item should be specific enough to become its own DEP.
Maximum 5 items.
-->

## Decision Records

<!--
Link to decision records that capture closed offline-discussion outcomes —
rejected approaches, why-we-decided-X, debates that don't belong in the
public DEP body.

This DEP is a public-facing document. DO NOT inline internal-only deliberation
here. Decision records live in `docs/decisions/` (or as linked GitHub
discussions / issues) and are referenced by link.

Format:
- [Decision: <topic>](link) — one-line summary
-->

## References

<!--
- GitHub issues
- Related GEPs/DEPs
- External documentation (Kubernetes / etcd upstream docs)
- Benchmarks or measurements

Always link the source for claims about Kubernetes or etcd behavior. "The
StatefulSet controller does X" needs a link to the upstream code or design doc.
-->
