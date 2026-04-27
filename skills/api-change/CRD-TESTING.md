# CRD Validation Tests

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
