# CEL Validation Annotations

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

**`omitempty` + `has()` interaction:** A field tagged `json:",omitempty"` is omitted from serialization when zero-valued, so `has()` returns `false` for it when absent. A field tagged without `omitempty` is serialized even when zero-valued — `has()` returns `true` even if the value is `""` or `0`. Write your `has()` guard to match the field's actual `omitempty` tag, otherwise the guard may always pass or always fail depending on zero-value behaviour.

**Silent-pass failure mode:** If a test asserts that an invalid value is rejected but gets `nil` instead, the `XValidation` rule is placed on the wrong struct. A rule annotated on `EtcdConfig` can only reference `self.*` fields within `EtcdConfig` — it cannot see `self.spec.backup.*` or `self.metadata.*`. Move the rule to the innermost struct that owns all referenced fields, or to the `Etcd` root type for cross-field rules. Verify the rule was emitted in the CRD output:

```bash
kubectl apply --dry-run=server -f api/core/v1alpha1/crds/druid.gardener.cloud_etcds.yaml 2>&1 | grep -A2 "x-kubernetes-validations"
# or dry-run without a cluster:
grep "x-kubernetes-validations" api/core/v1alpha1/crds/druid.gardener.cloud_etcds.yaml
```

If `x-kubernetes-validations` does not appear at the path you expect, the annotation was on the wrong type — regenerate after moving it.

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
