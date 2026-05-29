# Rejected: Use Operator SDK or Kubebuilder Scaffolding

## Context

Operator SDK and Kubebuilder provide scaffolding tools that generate boilerplate for Kubernetes operators — main.go, controller stubs, webhook setup, Makefile targets, and test harnesses. The question is whether etcd-druid should adopt these frameworks.

## Decision

Rejected.

## Reasoning

1. **Full control over reconciliation logic** — etcd-druid uses a component-based architecture where each reconciler is composed of discrete, testable Operator interface implementations. Scaffolded code imposes its own controller structure that conflicts with this pattern.

2. **Component architecture** — The project splits reconciliation into independent components (e.g., configmap, statefulset, service, member-lease). This decomposition does not map to the single-reconciler-per-resource model that scaffolding tools assume.

3. **Testing patterns** — etcd-druid's test strategy relies on unit-testing individual components in isolation. Generated test harnesses from scaffolding tools encourage integration-style tests that are slower and less targeted.

4. **Generated code conflicts** — Scaffolding tools generate and own certain files. Customizing these files creates maintenance friction on framework upgrades, as regeneration overwrites local changes.

5. **controller-runtime is sufficient** — The project depends on controller-runtime directly, which provides all necessary primitives (manager, controller, reconciler interface, client, cache) without the overhead of a scaffolding layer.

## Prior Discussions

- The project has used controller-runtime directly since its initial architecture.
- The Operator interface pattern is documented in the codebase and is a core design decision.
