---
name: e2e
description: Use for e2e testing — KIND cluster setup, custom image builds, sidecar overrides, running e2e tests, pre-PR CI validation. Not for unit or integration tests.
user-invocable: true
effort: high
---

# etcd-druid Ecosystem — E2E & Manual Testing

Covers three scenarios: (A) test etcd-druid changes, (B) test custom etcd-backup-restore build end-to-end, (C) test custom etcd-wrapper build. Each section is standalone — jump to the one you need.

## Iron Law

**NO PR WITHOUT `make ci-e2e-kind` PASSING IN THE AFFECTED REPO.**

| Rationalization | Why it fails |
|---|---|
| "Unit and integration tests passed" | E2e catches controller-level and sidecar integration bugs that unit tests never see |
| "I only changed etcd-backup-restore, not etcd-druid" | etcd-druid deploys the sidecar — a changed sidecar image must be tested end-to-end via druid |
| "The CI will catch it" | CI runs after the PR is open — you block reviewers with a broken PR |
| "It works on my machine with kubectl apply" | Manual apply skips the reconciliation loop that `make ci-e2e-kind` exercises |

## Red Flags — Stop and Re-read

| Thought | Why it fails |
|---|---|
| "Unit tests pass, so e2e will too" | Unit tests mock everything. E2e catches integration failures unit tests cannot |
| "I'll run e2e after the PR is open" | Broken e2e blocks the entire merge queue |
| "The KIND cluster is slow to set up" | 5 minutes of setup prevents 2 hours of debugging production failures |
| "I only changed one component" | Components interact. E2e tests the interaction, not the component |

---

## Read the Docs First

Each repo has its own e2e testing guide. Read the relevant guide before running anything locally — it contains repo-specific setup, provider prerequisites, and known quirks that are not duplicated here.

| Repo | Doc path | Gist |
|------|----------|------|
| etcd-druid | `docs/development/running-e2e-tests.md` | KIND setup, skaffold deploy, provider flags (`PROVIDERS="none,local"`), kubeconfig location, how to run targeted tests |
| etcd-backup-restore | `docs/development/tests.md` | Integration tests with real etcd, e2e with Localstack/FakeGCS/Azurite, perf tests, how to run with `-tags integration` |
| etcd-wrapper | `docs/development/testing.md` | Unit test patterns (testing.T + Gomega), table-driven tests, coverage; no standalone e2e — tested via etcd-druid e2e |

The CI pipeline file (`.github/workflows/`) for each repo is the authoritative list of what runs on a PR. Read it before raising a PR to know exactly which jobs must pass.

## Worktree Gate

Before building custom images or running e2e tests for your changes, apply the worktree gate (`skills/worktree-gate/SKILL.md`).

If already in a worktree (e.g., dispatched from `implement`): use it — build and test from the worktree path.
If standalone: the gate ensures you're in a worktree branched from `upstream/master`.

All `make docker-build`, `make ci-e2e-kind`, and image override commands run from within the worktree. Use `git diff upstream/master...HEAD` to verify what changes are being tested.

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

## Evidence Session (Manual Verification)

When verifying a task or bug fix by manually deploying etcd-druid and applying an Etcd CR, use the **evidence session** protocol to capture structured proof at every state transition.

**Invoke by saying:** "verify task X", "verify this fix", "run evidence session", or "e2e verify"

The session covers the full arc: deploy operator → spawn per-pod monitors → apply CR → verify state transitions → generate report.

See [EVIDENCE-SESSION.md](EVIDENCE-SESSION.md) for the full protocol and [MONITOR-AGENT.md](MONITOR-AGENT.md) for per-pod monitoring behavior.

---

## Further Reading

For custom sidecar builds (etcd-backup-restore, etcd-wrapper), see [SIDECAR-OVERRIDES.md](SIDECAR-OVERRIDES.md). For pre-PR pipeline checks, see [RUNNING-E2E.md](RUNNING-E2E.md). For cluster observation and handoff, see [MULTI-REPO-E2E.md](MULTI-REPO-E2E.md).
