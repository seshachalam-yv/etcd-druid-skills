---
name: api-change
description: Use for any etcd-druid API field addition or modification — CEL validation, kubebuilder markers, two-commit generate workflow, CRD tests. Not for controller or test-only work.
user-invocable: true
effort: high
paths: "api/core/v1alpha1/*.go"
---

# etcd-druid API Change Guide

Complete workflow for adding or modifying fields in `api/core/v1alpha1/`. Covers struct design, all validation types, code generation, tests, and PR requirements.

## Iron Law

**NO CEL RULE SHIPS WITHOUT A TEST IN `test/it/crdvalidation/`.**

| Rationalization | Why it fails |
|---|---|
| "The rule is simple, obviously correct" | CEL syntax errors are silent until the CRD is applied — the test catches them |
| "I tested it manually with kubectl" | Manual tests don't run in CI; the integration test suite does |
| "The field-scoped rule is covered, cross-field is obvious" | Cross-field rules reference `self.metadata` — they fail differently, test separately |
| "K8s < 1.29 doesn't support CEL anyway" | Two CRD variants exist; missing the test means the CEL variant is unverified |

---

## Worktree Gate

Before modifying any API types or running generation, apply the worktree gate (`skills/worktree-gate/SKILL.md`).

If already in a worktree (e.g., dispatched from `implement`): use it.
If standalone: the gate creates a worktree branched from `upstream/master`.

All API changes, `cd api && make generate`, and CRD validation tests happen inside the worktree. Use `git diff upstream/master...HEAD` to verify exactly what changed before committing.

## Step 1: Choose the Right File and Struct

**Before writing any code:** Read the `## API Delta` section of the plan file for this task.
This is the canonical statement of what this change should add, modify, or remove.
Your Commit 1 diff must match every row in that table — no more, no less.
If the plan has no `## API Delta` section, stop and ask the plan author to add one.

```
API types:   api/core/v1alpha1/etcd.go
OpsTask:     api/core/v1alpha1/etcdopstask.go
```

**Struct hierarchy in etcd.go:**

```
Etcd                     <- root; cross-field CEL goes here
└── EtcdSpec
    ├── Replicas          <- scalar with field-level CEL
    ├── EtcdConfig        <- etcd process config; field-scoped CEL goes here
    │   └── AdditionalAdvertisePeerURLs []AdditionalPeerURL
    ├── BackupSpec        <- backup config; struct-level CEL goes here
    ├── SharedConfig      <- autoCompaction
    └── SchedulingConstraints
```

**Rule:** Place the annotation on the **innermost struct** where all referenced fields live. If a rule references `self.metadata` or `self.spec.*` from two different sub-structs, it must go on `Etcd` (root).

---

## Step 2: Design the Field

```go
// AdditionalPeerURL is an example of a new struct.
type AdditionalPeerURL struct {
    // MemberName is the etcd member name (e.g., etcd-main-0).
    // +required
    // +kubebuilder:validation:Required
    // +kubebuilder:validation:MinLength=1
    // +kubebuilder:validation:MaxLength=253
    // +kubebuilder:validation:Pattern=`^[a-z0-9]([-a-z0-9]*[a-z0-9])?-[0-9]+$`
    MemberName string `json:"memberName"`

    // URLs is a list of additional peer URLs for this member.
    // +required
    // +kubebuilder:validation:MinItems=1
    // +kubebuilder:validation:MaxItems=5
    // +listType=atomic
    URLs []string `json:"urls"`
}
```

**Standard markers checklist:**

| Marker | When to use |
|--------|-------------|
| `+optional` / `+required` | All fields — never omit |
| `omitempty` in JSON tag | Optional fields only |
| `+kubebuilder:validation:Enum=...` | Fixed set of string values |
| `+kubebuilder:validation:Pattern=...` | String format constraint |
| `+kubebuilder:validation:MinLength/MaxLength` | String length bounds |
| `+kubebuilder:validation:MinItems/MaxItems` | Slice cardinality |
| `+kubebuilder:validation:MinProperties=1` | Must set at least one sub-field |
| `+listType=atomic` | Slices where order matters or items aren't uniquely keyed |
| `+kubebuilder:default=<value>` | Optional fields with a documented default — sets the value at admission time so the handler never sees nil. Do NOT hardcode defaults in handler/controller code when a kubebuilder marker can express the same default. Convention: `OnDemandSnapshotConfig` and other existing API fields use this pattern. |

**MaxItems cost budget:** CEL validation cost scales with list length. Use `MaxItems=10` for lists that will be iterated in CEL rules — this keeps cost within the CRD admission webhook budget.

**Default values:** When an optional field has a documented default, set it via `+kubebuilder:default=<value>` on the struct field. The API type is the single source of truth for defaults — never define defaults only in handler code. If using `metav1.Duration`, apply `+kubebuilder:validation:Pattern="^([0-9]+(\\.[0-9]+)?(ns|us|µs|ms|s|m|h))+$"` for format validation.

---

## Step 3: Add Validation Annotations

Add kubebuilder markers, field-scoped CEL, cross-field CEL, and immutability rules as needed. Full details, code examples, `has()` guard explanation, silent-pass failure mode, and cross-field checklist are in [CEL-VALIDATION.md](CEL-VALIDATION.md).

---

## Step 4: Two-Commit Generate Workflow

**Commit 1 — hand-written API changes only:**

Files in this commit: `api/core/v1alpha1/*.go` (your edits)
Nothing generated. Message style: `feat(api): add <field> to <type> (#<issue>)`

**Commit 2 — generated output only:**

```bash
cd api && make generate
```

Generated files:
- `api/core/v1alpha1/zz_generated.deepcopy.go`
- `api/core/v1alpha1/crds/druid.gardener.cloud_etcds.yaml` (with CEL)
- `api/core/v1alpha1/crds/druid.gardener.cloud_etcds_without_cel.yaml` (CEL stripped)
- `charts/crds/druid.gardener.cloud_etcds.yaml`
- `docs/api-reference/etcd-druid-api.md`

Message style: `chore: generate CRDs and deepcopy for <field> (#<issue>)`

**NEVER manually edit generated files.** Verify generation is clean before committing:

```bash
cd api && make check-generate   # fails if make generate would produce a diff
cd api && make check-apidiff    # fails on breaking API changes
```

**Two CRD variants:** `make generate` produces both automatically. The `_without_cel.yaml` variant strips all `x-kubernetes-validations` blocks via `yq`. You do not need to maintain them separately.

---

## Steps 5-8: Testing, CI, and PR

- **Step 5 — CRD Validation Tests:** Location, skip guard, table-driven pattern, and what-to-test matrix are in [CRD-TESTING.md](CRD-TESTING.md).
- **Steps 6-8 — examples/docs, CI verification, PR requirements:** Reviewer checklist and Red Flags are in [PR-REQUIREMENTS.md](PR-REQUIREMENTS.md).

---

## CEL Quick Reference

Common CEL patterns for guards, immutability, duration comparison, list iteration, and string operations: [CEL-QUICK-REFERENCE.md](CEL-QUICK-REFERENCE.md).

---

## Handoff

After completing the API change:
- CI pipeline passes (Step 7 all green) → return to `/etcd-druid:implement` Phase 3 (verify gate)
- Debugging a failing CEL test or stale generation → invoke `/etcd-druid:debug`
- Writing the CEL test → follow `skills/tdd/SKILL.md` (use `skipCELTestsForOlderK8sVersions(t)` guard)
