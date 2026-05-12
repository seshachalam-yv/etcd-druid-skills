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
-->

## Terminology

<!--
Optional. Define domain-specific terms used in this proposal.
Include only if readers may not know terms like "leading-backup-sidecar",
"snapshot compaction", "member learner", etc.
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
-->

### API Changes

<!--
Show Go structs AND YAML examples. Include BOTH spec and status.
Use kubebuilder markers. Show CEL validation rules.
If no API change, state "No API changes required" and explain why.
-->

### Lifecycle / Flow

<!--
State transitions, sequence of operations, or reconciliation flow.
MUST include at least one Mermaid diagram.
Use stateDiagram-v2 for lifecycle, sequenceDiagram for cross-component,
flowchart for decision logic.
-->

### Pre-conditions & Failure Scenarios

<!--
For each failure:
- What fails
- Who detects it (which controller/component)
- Is it retriable?
- Recovery path
- Operator escape hatch (if any)
-->

## Feature Gate

<!--
Required if the change introduces a toggleable capability.
- Gate name (e.g., ImmutableBackups)
- Default value (alpha=off, beta=on, GA=always on)
- Graduation criteria from alpha → beta → GA
- Behavior when toggled on a running cluster
- Rollback safety: what happens if gate is disabled after being enabled
-->

## Compatibility

<!--
- Backward compatibility: do existing clusters continue to work unchanged?
- Forward compatibility: can new clusters opt-in incrementally?
- Migration path: what steps must operators take?
- Cross-repo version dependencies: deployment order for etcd-druid,
  etcd-backup-restore, etcd-wrapper
-->

## Metrics

<!--
Optional but encouraged for observable changes.
Define Prometheus metrics: name, type (counter/histogram/gauge), labels.
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
Minimum 2 alternatives evaluated. For each:
- Brief description
- Why it was rejected (bullet-pointed limitations)
- What trade-off made the chosen approach better
-->

## Future Work

<!--
Bounded list of concrete next steps. Not vague aspirations.
Each item should be specific enough to become its own DEP.
-->

## References

<!--
- GitHub issues
- Related GEPs/DEPs
- External documentation
- Benchmarks or measurements
-->
