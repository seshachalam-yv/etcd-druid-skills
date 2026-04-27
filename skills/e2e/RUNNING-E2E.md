# Pre-PR Checklist

**First: read the CI pipeline for the repo you changed.**

Each repo defines its own checks in `.github/workflows/`:

| Repo | Main pipeline file |
|---|---|
| etcd-druid | `.github/workflows/base.yaml` |
| etcd-backup-restore | `.github/workflows/build.yaml` |
| etcd-wrapper | `.github/workflows/build.yaml` |

Read the relevant file before running anything locally — it shows exactly which jobs run on a PR. The commands below are a baseline derived from current pipeline state, but the pipeline is authoritative.

## etcd-druid pipeline jobs (from `.github/workflows/base.yaml`)

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

## etcd-backup-restore pipeline jobs (from `.github/workflows/build.yaml`)

```bash
make check              # golangci-lint
make test-unit          # ginkgo unit tests
make test-integration   # integration tests (runs real etcd + etcdbr locally)
make ci-e2e-kind        # full e2e with Localstack (AWS) by default
# Check pipeline for which providers CI exercises
```

## etcd-wrapper pipeline jobs (from `.github/workflows/build.yaml`)

```bash
make check              # golangci-lint + sast
make test               # unit tests with coverage
# No standalone e2e — validated via etcd-druid e2e with wrapper override (Scenario C3 above)
```
