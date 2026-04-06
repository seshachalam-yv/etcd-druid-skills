---
name: api-change
description: Use for any etcd-druid API field addition or modification — new fields, CEL validation (field-scoped and cross-field), kubebuilder markers, two-commit generate workflow, CRD tests, /kind api-change PR label. Not for controller or test-only work.
user-invocable: true
effort: high
paths: "api/core/v1alpha1/*.go"
---

# etcd-druid API Change Guide

Complete workflow for adding or modifying fields in `api/core/v1alpha1/`. Covers struct design, all validation types, code generation, tests, and PR requirements.

## ⛔ Iron Law

**NO CEL RULE SHIPS WITHOUT A TEST IN `test/it/crdvalidation/`.**

| Rationalization | Why it fails |
|---|---|
| "The rule is simple, obviously correct" | CEL syntax errors are silent until the CRD is applied — the test catches them |
| "I tested it manually with kubectl" | Manual tests don't run in CI; the integration test suite does |
| "The field-scoped rule is covered, cross-field is obvious" | Cross-field rules reference `self.metadata` — they fail differently, test separately |
| "K8s < 1.29 doesn't support CEL anyway" | Two CRD variants exist; missing the test means the CEL variant is unverified |

---

## Step 1: Choose the Right File and Struct

```
API types:   api/core/v1alpha1/etcd.go
OpsTask:     api/core/v1alpha1/etcdopstask.go
```

**Struct hierarchy in etcd.go:**

```
Etcd                     ← root; cross-field CEL goes here
└── EtcdSpec
    ├── Replicas          ← scalar with field-level CEL
    ├── EtcdConfig        ← etcd process config; field-scoped CEL goes here
    │   └── AdditionalAdvertisePeerURLs []AdditionalPeerURL
    ├── BackupSpec        ← backup config; struct-level CEL goes here
    ├── SharedConfig      ← autoCompaction
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

**MaxItems cost budget:** CEL validation cost scales with list length. Use `MaxItems=10` for lists that will be iterated in CEL rules — this keeps cost within the CRD admission webhook budget.

---

## Step 3: Add Validation Annotations

### 3a. Standard kubebuilder markers (no CEL)

Use for stateless constraints that don't cross field boundaries:

```go
// +kubebuilder:validation:Enum=basic;extensive
type MetricsLevel string

// Duration field pattern:
// +kubebuilder:validation:Type=string
// +kubebuilder:validation:Pattern="^([0-9]+(\\.[0-9]+)?(ns|us|µs|ms|s|m|h))+$"
ReelectionPeriod *metav1.Duration `json:"reelectionPeriod,omitempty"`
```

### 3b. Field-scoped CEL (`XValidation` on a struct)

Use when the rule references only fields **within the same struct**:

```go
// +kubebuilder:validation:XValidation:rule="!(has(self.deltaSnapshotPeriod) && has(self.garbageCollectionPeriod)) || duration(self.deltaSnapshotPeriod).getSeconds() < duration(self.garbageCollectionPeriod).getSeconds()",message="garbageCollectionPeriod must be greater than deltaSnapshotPeriod"
// +kubebuilder:validation:XValidation:rule="!has(self.additionalAdvertisePeerUrls) || !has(self.peerUrlTls) || self.additionalAdvertisePeerUrls.all(m, m.urls.all(u, u.startsWith('https://')))",message="when peerUrlTls is enabled, all peer URLs must use https://"
type EtcdConfig struct {
```

**`has()` guard:** Always wrap optional field references in `has(self.fieldName)` before dereferencing. Omitting the guard causes the rule to fail when the field is absent.

### 3c. Cross-field CEL (on the root `Etcd` or `EtcdSpec` type)

Use when the rule references `self.metadata` OR fields from two different sub-structs:

```go
// +kubebuilder:validation:XValidation:rule="!has(self.spec.etcd.additionalAdvertisePeerUrls) || self.spec.etcd.additionalAdvertisePeerUrls.all(m, m.memberName.startsWith(self.metadata.name + '-'))",message="additionalAdvertisePeerUrls member names must start with the Etcd resource name followed by a dash"
// +kubebuilder:validation:XValidation:rule="!has(self.spec.etcd.additionalAdvertisePeerUrls) || self.spec.etcd.additionalAdvertisePeerUrls.all(m, m.memberName.matches('^[a-z0-9]([-a-z0-9]*[a-z0-9])?-[0-9]+$') && int(m.memberName.substring(m.memberName.lastIndexOf('-')+1)) < self.spec.replicas)",message="additionalAdvertisePeerUrls member name index must be less than replicas"
type Etcd struct {
```

**Cross-field checklist:**
- [ ] Rule placed on the type that owns **both** referenced paths
- [ ] `self.metadata.name` access → must be on `Etcd`, not `EtcdSpec`
- [ ] `self.spec.replicas` cross-reference → must be on `Etcd` or `EtcdSpec`, not `EtcdConfig`
- [ ] `has()` guard on every optional traversal path
- [ ] `MaxItems` set on the list field to bound CEL cost

### 3d. Immutability CEL

```go
// Immutable field (once set, cannot change):
// +kubebuilder:validation:XValidation:rule="self == oldSelf",message="storageClass is immutable"
StorageClass *string `json:"storageClass,omitempty"`

// Immutable presence (field can be added once, but not removed):
// +kubebuilder:validation:XValidation:rule="has(oldSelf.storageClass) == has(self.storageClass)",message="etcd.spec.storageClass is an immutable field."
type EtcdSpec struct {

// Monotonic constraint (can scale up or to 0, never down):
// +kubebuilder:validation:XValidation:rule="self==0 ? true : self < oldSelf ? false : true",message="Replicas can either be increased or be downscaled to 0."
Replicas int32 `json:"replicas"`
```

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

## Step 5: Write CRD Validation Tests

### Location

```
test/it/crdvalidation/etcd/          ← for Etcd CRD
test/it/crdvalidation/etcdopstask/   ← for EtcdOpsTask CRD
```

### Skip guard (required for all CEL tests)

```go
func TestMyNewCELRule(t *testing.T) {
    skipCELTestsForOlderK8sVersions(t)  // skips if K8s < 1.29
    testNs, g := setupTestEnvironment(t)
    ...
}
```

### Table-driven pattern

```go
func TestValidateAdditionalAdvertisePeerUrls(t *testing.T) {
    skipCELTestsForOlderK8sVersions(t)
    testNs, g := setupTestEnvironment(t)

    tests := []struct {
        name      string
        urls      []druidv1alpha1.AdditionalPeerURL
        replicas  int32
        expectErr bool
    }{
        {
            name: "valid member name with index < replicas",
            urls: []druidv1alpha1.AdditionalPeerURL{{MemberName: "etcd-main-0", URLs: []string{"http://peer:2380"}}},
            replicas: 3,
            expectErr: false,
        },
        {
            name: "member index >= replicas should fail",
            urls: []druidv1alpha1.AdditionalPeerURL{{MemberName: "etcd-main-5", URLs: []string{"http://peer:2380"}}},
            replicas: 3,
            expectErr: true,
        },
        {
            name: "member name not prefixed with etcd name should fail",
            urls: []druidv1alpha1.AdditionalPeerURL{{MemberName: "wrong-0", URLs: []string{"http://peer:2380"}}},
            replicas: 3,
            expectErr: true,
        },
    }

    for _, tc := range tests {
        t.Run(tc.name, func(t *testing.T) {
            t.Parallel()
            etcd := utils.EtcdBuilderWithoutDefaults(testNs, "etcd-main").
                WithReplicas(tc.replicas).Build()
            etcd.Spec.Etcd.AdditionalAdvertisePeerURLs = tc.urls
            validateEtcdCreation(g, etcd, tc.expectErr)
        })
    }
}
```

**One test function per CEL rule.** Field-scoped and cross-field rules get separate test functions even if they cover related fields.

### What to test

| Rule type | Scenarios to cover |
|-----------|-------------------|
| Enum | valid value, invalid value |
| Pattern | matching string, non-matching string |
| MaxItems | exactly at limit, one over limit |
| Field-scoped cross-field | both fields absent (OK), constraint met, constraint violated |
| Immutability | unchanged (OK), changed (fails) |
| Cross-field (metadata ref) | name prefix correct, name prefix wrong |
| Cross-field (index < replicas) | index in range, index = replicas (fails), index > replicas (fails) |
| TLS scheme | peerUrlTls set + https URLs (OK), peerUrlTls set + http URLs (fails), peerUrlTls absent + http URLs (OK) |

---

## Step 6: Update examples/

If the new field is user-facing (an operator would set it), add an example usage to:

```
examples/etcd/druid_v1alpha1_etcd.yaml
```

Optional fields can be commented out. Show the type, not just a placeholder:

```yaml
# additionalAdvertisePeerUrls:
# - memberName: etcd-main-0
#   urls:
#   - http://etcd-main-0.etcd-main-peer.default.svc:2380
```

---

## Step 7: PR Requirements

**`/kind` label for API changes:** `api-change` — not `feature` or `enhancement`.

**PR body must include:**

```
/area control-plane
/kind api-change

**What this PR does / why we need it:**
<description>

**Fixes:** #<issue-number>

**Special notes for reviewer:**
Two-commit rule followed: commit 1 = hand-written API changes, commit 2 = make generate output.

**Release note:**
feature operator
```

**Reviewer checklist items specific to API changes:**
- [ ] New fields have `+optional` or `+required`
- [ ] Optional fields have `omitempty` in JSON tag
- [ ] CEL rules have `has()` guards on optional field references
- [ ] Field-scoped rules placed on innermost struct
- [ ] Cross-field rules (referencing `self.metadata` or two sub-structs) placed on `Etcd` root type
- [ ] `MaxItems` set on lists used in CEL iteration
- [ ] Commit 1 = hand-written only; Commit 2 = generated only
- [ ] `cd api && make check-generate` passes
- [ ] `cd api && make check-apidiff` passes
- [ ] Test added in `test/it/crdvalidation/etcd/` for every CEL rule
- [ ] `examples/` updated if field is user-facing
- [ ] No manual edits to `zz_generated.deepcopy.go`, CRD YAMLs, or `docs/api-reference/`

---

## CEL Quick Reference

```cel
# Optional field guard
has(self.fieldName)

# Presence immutability
has(oldSelf.field) == has(self.field)

# Value immutability
self == oldSelf

# Duration comparison
duration(self.period1).getSeconds() < duration(self.period2).getSeconds()

# List: all elements satisfy predicate
self.myList.all(item, item.field > 0)

# Nested list iteration
self.myList.all(m, m.urls.all(u, u.startsWith('https://')))

# String prefix
self.name.startsWith(self.metadata.name + '-')

# Regex match
self.name.matches('^[a-z0-9]([-a-z0-9]*[a-z0-9])?-[0-9]+$')

# Extract integer from suffix after last dash
int(self.name.substring(self.name.lastIndexOf('-') + 1))

# Combine optional guard with rule (cross-field pattern)
!has(self.spec.etcd.myField) || self.spec.etcd.myField.all(m, <rule>)
```

---

## Handoff

After completing the API change:
- Run `make ci-checks` from the worktree root
- Run `make test-integration` (CRD validation tests live in the integration suite)
- Invoke `/etcd-druid:review` for pre-PR checklist
