---
name: e2e
description: Use for manual e2e testing of etcd-druid, etcd-backup-restore, or etcd-wrapper — KIND cluster setup, custom image builds, loading images, sidecar overrides, running e2e tests, and pre-PR CI validation. Not for unit/integration tests.
user-invocable: true
effort: high
---

# etcd-druid Ecosystem — E2E & Manual Testing

Covers three scenarios: (A) test etcd-druid changes, (B) test custom etcd-backup-restore build end-to-end, (C) test custom etcd-wrapper build. Each section is standalone — jump to the one you need.

## ⛔ Iron Law

**NO PR WITHOUT `make ci-e2e-kind` PASSING IN THE AFFECTED REPO.**

| Rationalization | Why it fails |
|---|---|
| "Unit and integration tests passed" | E2e catches controller-level and sidecar integration bugs that unit tests never see |
| "I only changed etcd-backup-restore, not etcd-druid" | etcd-druid deploys the sidecar — a changed sidecar image must be tested end-to-end via druid |
| "The CI will catch it" | CI runs after the PR is open — you block reviewers with a broken PR |
| "It works on my machine with kubectl apply" | Manual apply skips the reconciliation loop that `make ci-e2e-kind` exercises |

---

## Prerequisites

Before starting, verify you have the tools:

```bash
kind version         # v0.20+
docker version       # Docker Engine running
kubectl version      # 1.28+
helm version         # v3+
skaffold version     # v2+
```

Find e2e CI pipelines for each repo — read `.github/workflows/` before running locally to understand what the pipeline does and what providers it tests.

---

## Scenario A: Test etcd-druid Changes

### A1. Build and load the etcd-druid image

```bash
cd <fork-root>              # your etcd-druid fork worktree
make docker-build           # builds $IMG (europe-docker.pkg.dev/gardener-project/snapshots/gardener/etcd-druid:<VERSION>)
```

### A2. Create KIND cluster (if not already running)

```bash
make kind-up
# Creates cluster named "etcd-druid-e2e" with local registry on :5001
# Kubeconfig written to: hack/kind/kubeconfig
export KUBECONFIG=$(pwd)/hack/kind/kubeconfig
```

### A3. Run automated e2e (recommended)

```bash
make ci-e2e-kind \
  PROVIDERS="none,local" \
  RETAIN_KIND_CLUSTER=true    # keep cluster after tests for inspection
```

This runs the full pipeline: prepare helm charts → deploy etcd-druid → run e2e suite.

### A4. Run e2e against an already-deployed cluster

```bash
# Deploy etcd-druid manually first:
make NAMESPACE=etcd-druid-e2e \
     CERT_EXPIRY_DAYS=30 \
     prepare-helm-charts
make DRUID_E2E_TEST=true \
     ENABLE_ETCD_COMPONENT_PROTECTION_WEBHOOK=true \
     deploy

# Then run specific tests:
make NAMESPACE=etcd-druid-e2e \
     PROVIDERS="none,local" \
     GO_TEST_ARGS="-run TestEtcdControllerReconciliation -v" \
     test-e2e
```

### A5. Cleanup

```bash
make clean-e2e-test-resources   # removes test namespaces
make kind-down                  # destroys KIND cluster
```

---

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

---

## Pre-PR Checklist (each repo has its own pipeline)

**First: read the CI pipeline for the repo you changed.**

Each repo defines its own checks in `.github/workflows/`:

| Repo | Main pipeline file |
|---|---|
| etcd-druid | `.github/workflows/base.yaml` |
| etcd-backup-restore | `.github/workflows/build.yaml` |
| etcd-wrapper | `.github/workflows/build.yaml` |

Read the relevant file before running anything locally — it shows exactly which jobs run on a PR. The commands below are a baseline derived from current pipeline state, but the pipeline is authoritative.

### etcd-druid pipeline jobs (from `.github/workflows/base.yaml`)

```bash
make tidy                          # go mod tidy (must produce no diff)
make ci-checks                     # format + lint + license headers + api-diff
make --directory=api test-unit     # API package unit tests
make test-unit                     # all unit tests
make test-integration              # integration tests with envtest
make ci-e2e-kind                   # full e2e — run last, blocks until done
# For API changes only:
cd api && make check-generate && make check-apidiff
```

### etcd-backup-restore pipeline jobs (from `.github/workflows/build.yaml`)

```bash
make check              # golangci-lint
make test-unit          # ginkgo unit tests
make test-integration   # integration tests (runs real etcd + etcdbr locally)
make ci-e2e-kind        # full e2e with Localstack (AWS) by default
# Check pipeline for which providers CI exercises
```

### etcd-wrapper pipeline jobs (from `.github/workflows/build.yaml`)

```bash
make check              # golangci-lint + sast
make test               # unit tests with coverage
# No standalone e2e — validated via etcd-druid e2e with wrapper override (Scenario C3 above)
```

---

## Observing a Running Cluster

After deploying with `RETAIN_KIND_CLUSTER=true`:

```bash
export KUBECONFIG=<fork>/hack/kind/kubeconfig

# Watch etcd-druid controller logs
kubectl logs -n etcd-druid-e2e deploy/etcd-druid -f

# Watch etcd pod logs (etcd-main-0 is the first member)
kubectl logs -n <test-ns> etcd-main-0 -c etcd-wrapper -f
kubectl logs -n <test-ns> etcd-main-0 -c etcd-backup-restore -f

# Check Etcd resource status
kubectl get etcd -A -o wide
kubectl describe etcd etcd-main -n <test-ns>

# Check backup status
kubectl get etcd etcd-main -n <test-ns> -o jsonpath='{.status.lastFullBackup}'
```

---

## Handoff

After e2e passes:
- If invoked from `/etcd-druid:implement` Phase 3 — return there to complete the verify checklist and proceed to Gate 2
- If invoked standalone — invoke `/etcd-druid:review` for pre-PR checklist
- Check `.github/workflows/` in the repo to confirm which CI checks run automatically on PR open
