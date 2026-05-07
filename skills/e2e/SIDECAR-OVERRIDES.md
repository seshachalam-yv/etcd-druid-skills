# Sidecar Image Override Workflows

## Scenario B: Test a Custom etcd-backup-restore Build

etcd-druid deploys etcd-backup-restore as a sidecar. The sidecar image reference comes from `internal/images/images.yaml` and is overridden at runtime via `IMAGEVECTOR_OVERWRITE`.

### B0. Preconditions

```bash
cd <etcd-druid-fork>
make kind-up   # creates cluster "etcd-druid-e2e" AND local registry on :5001 — must run first
export KUBECONFIG=$(pwd)/hack/kind/kubeconfig
kubectl get nodes   # verify cluster is ready before proceeding
```

The local registry on port 5001 is created by `make kind-up` in the etcd-druid fork. All `docker push localhost:5001/...` calls in B1–B3 depend on this. Run B0 before anything else.

### B1. Build etcd-backup-restore image

If your change adds or updates a Go dependency (e.g., a new compression library), run `make revendor` first — etcd-backup-restore uses `vendor/` and `make docker-build` will use stale vendor files otherwise:

```bash
cd <etcd-backup-restore-fork>
make revendor     # only if dependencies changed
make docker-build
# Default tag: europe-docker.pkg.dev/gardener-project/snapshots/gardener/etcdbrctl:<VERSION>
# Use a local tag to avoid registry conflicts:
docker tag europe-docker.pkg.dev/gardener-project/snapshots/gardener/etcdbrctl:<VERSION> \
           localhost:5001/etcdbrctl:dev
```

> **Cache warning:** If rebuilding after source changes, Docker may serve a cached binary
> from a previous build layer. Use `--no-cache` to force a full rebuild:
> ```bash
> docker build --no-cache -t localhost:5001/etcdbrctl:dev .
> ```
> Alternatively, use a unique tag per build (e.g., `dev-$(git rev-parse --short HEAD)`)
> to avoid cache confusion entirely.

### B2. Push image to local KIND registry

Use Option A (push to local registry) — it is faster than loading directly and works for both `kind load` and the registry pull path. `localhost:5001` was created by `make kind-up` in B0.

```bash
docker push localhost:5001/etcdbrctl:dev
```

Option B (direct load into KIND) — use only if the registry is unavailable:
```bash
kind load docker-image localhost:5001/etcdbrctl:dev --name etcd-druid-e2e
```

### B3. Override the sidecar image in etcd-druid

etcd-druid reads sidecar images from `internal/images/images.yaml` but respects `IMAGEVECTOR_OVERWRITE` — a JSON string pointing to override entries. Create an override file:

```bash
cat > /tmp/imagevector-override.json <<EOF
{
  "images": [
    {
      "name": "etcd-backup-restore",
      "repository": "localhost:5001/etcdbrctl",
      "tag": "dev"
    }
  ]
}
EOF
export IMAGEVECTOR_OVERWRITE="$(cat /tmp/imagevector-override.json)"
```

Then deploy etcd-druid with the override active:
```bash
cd <etcd-druid-fork>
make NAMESPACE=etcd-druid-e2e \
     CERT_EXPIRY_DAYS=30 \
     prepare-helm-charts
# Pass IMAGEVECTOR_OVERWRITE inline (or export it first — both work).
# The value must reach the deployed binary's environment via skaffold.
IMAGEVECTOR_OVERWRITE="$(cat /tmp/imagevector-override.json)" \
make DRUID_E2E_TEST=true \
     ENABLE_ETCD_COMPONENT_PROTECTION_WEBHOOK=true \
     deploy
```

### B4. Run the integrated e2e pipeline

```bash
cd <etcd-druid-fork>
# Run the full pipeline with the override active:
IMAGEVECTOR_OVERWRITE="$(cat /tmp/imagevector-override.json)" \
make ci-e2e-kind \
  PROVIDERS="none,local" \
  RETAIN_KIND_CLUSTER=true
```

This is required before any PR — the Iron Law mandates `make ci-e2e-kind` passes. The manual `deploy` step in B3 is for iterative testing only; always run the full pipeline before raising a PR.

### B5. Run etcd-backup-restore's own e2e suite

etcd-backup-restore has its own independent e2e tests (not via etcd-druid):

```bash
cd <etcd-backup-restore-fork>
make kind-up                         # creates cluster "etcdbr-e2e"
make ci-e2e-kind                     # AWS/Localstack by default
make ci-e2e-kind-gcp                 # GCP/FakeGCS
make ci-e2e-kind-azure               # Azure/Azurite
```

To test a custom image in its own e2e suite:
```bash
make docker-build
kind load docker-image <image:tag> --name etcdbr-e2e
make ci-e2e-kind PROVIDERS="aws"
```

Read `.github/workflows/` in etcd-backup-restore to see what the CI pipeline tests and which providers it exercises before each PR.

---

## Scenario C: Test a Custom etcd-wrapper Build

etcd-wrapper has no independent e2e test suite. It is tested via etcd-druid's e2e tests and via the local dev setup scripts.

### C1. Build etcd-wrapper image

```bash
cd <etcd-wrapper-fork>
make docker-build
# Default tag: europe-docker.pkg.dev/gardener-project/snapshots/gardener/etcd-wrapper:<VERSION>
docker tag europe-docker.pkg.dev/gardener-project/snapshots/gardener/etcd-wrapper:<VERSION> \
           localhost:5001/etcd-wrapper:dev
```

### C2. Test with etcd-wrapper's own local dev scripts

```bash
# Create KIND cluster
./hack/local-dev/kind.sh -n wrapper-test

# Load images
kind load docker-image localhost:5001/etcd-wrapper:dev -n wrapper-test
kind load docker-image localhost:5001/etcdbrctl:dev -n wrapper-test   # if also testing custom etcdbr

# Deploy 3-node etcd cluster with custom wrapper + backup-restore
./hack/local-dev/etcd-up.sh \
  -n test-ns \
  -s 3 \
  -t true \
  -i etcd-main \
  -m localhost:5001/etcdbrctl:dev \
  -w localhost:5001/etcd-wrapper:dev

# Cleanup
./hack/local-dev/etcd-down.sh --namespace test-ns
./hack/local-dev/kind.sh -n wrapper-test -d
```

### C3. Test via etcd-druid e2e with wrapper override

Override both sidecars simultaneously when running etcd-druid e2e:

```bash
cat > /tmp/imagevector-override.json <<EOF
{
  "images": [
    {
      "name": "etcd-backup-restore",
      "repository": "localhost:5001/etcdbrctl",
      "tag": "dev"
    },
    {
      "name": "etcd-wrapper",
      "repository": "localhost:5001/etcd-wrapper",
      "tag": "dev"
    }
  ]
}
EOF

cd <etcd-druid-fork>
IMAGEVECTOR_OVERWRITE="$(cat /tmp/imagevector-override.json)" \
make DRUID_E2E_TEST=true \
     ENABLE_ETCD_COMPONENT_PROTECTION_WEBHOOK=true \
     deploy
make PROVIDERS="none,local" test-e2e
```
