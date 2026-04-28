# Common Failures

## Build Failure Triage

### `make ci-checks` failures

| Failure pattern | Cause | Fix |
|----------------|-------|-----|
| `goimports-reviser` diff | Import ordering wrong | `make format` then commit |
| `golangci-lint` errors | Lint violations | Fix reported issues; check `.golangci.yaml` for config |
| License header missing | New file without SPDX header | `make add-license-headers` |
| `check-git-status` fails | Uncommitted changes after format/generate | Commit generated changes separately |
| `check-apidiff` fails | Breaking API change | Read `docs/development/changing-api.md` for deprecation path |
| `check-generate` fails | Generated files stale | `cd api && make generate` and commit output |

### `make test-unit` / `make test-integration` failures

| Failure pattern | Cause | Fix |
|----------------|-------|-----|
| `envtest` binary missing | Setup not run | `make start-envtest` or set `KUBEBUILDER_ASSETS` |
| CRD not found in envtest | Wrong CRD path | Check `CRDDirectoryPaths` in test setup |
| Flaky `Eventually` timeout | Timeout too short or race | Increase timeout; add retry-on-conflict for status updates |
| `gomock` expectation not met | Mock setup wrong | Check `EXPECT()` calls match actual invocations |
| `NEGATIVE:` test prefix | etcd-backup-restore naming convention | Not a failure — these run in a separate pass |

### Dependency / module failures

| Failure pattern | Cause | Fix |
|----------------|-------|-----|
| `go mod tidy` produces diff | Deps changed but not tidied | `make tidy` (etcd-druid) or `make revendor` (ebr, wrapper) |
| `vendor/` directory stale | Deps changed but not re-vendored | `make revendor` (etcd-backup-restore, etcd-wrapper only) |
| Module mismatch (api/ vs root) | API module has separate go.mod | `cd api && go mod tidy` separately |

## envtest Debugging Tips

envtest starts a real API server and etcd for integration tests. Common issues:

- **API server won't start:** Check if ports 1024-65535 range has conflicts. envtest picks random ports.
- **CRD installation fails:** Verify CRD YAML files exist at the paths in `CRDDirectoryPaths`. Both CEL and non-CEL variants must be present.
- **K8s version mismatch:** CEL validation tests require K8s >= 1.29. Use `skipCELTestsForOlderK8sVersions(t)` guard.
- **CEL rule silently accepts invalid input** (test asserts rejection, got `nil`): the `XValidation` rule is placed on the wrong struct level — `self.*` can only reference fields within the struct it is annotated on. Move the rule to the innermost struct that owns all referenced fields, or to the `Etcd` root type for cross-field rules. Confirm the rule was emitted by running `kubectl apply --dry-run=server -f api/core/v1alpha1/crds/*.yaml` and checking that `x-kubernetes-validations` appears at the expected path in the output.
- **Slow tests:** envtest startup takes 5-10s. Group related tests in the same test function to share the env.
- **Status update conflicts:** Use retry-on-conflict when updating `.status` — see etcd-druid PR #1302 for the pattern.
- **Cleanup:** `defer testEnv.Stop()` must always run. Leaked envtest processes block ports.

## Common Go Gotchas

### Nil interface vs nil concrete value

A nil pointer dereference on an interface method call often means the interface variable is non-nil but holds a nil concrete value. This happens when a function returns `(*ConcreteType, error)` and the concrete pointer is `nil` on the error path — assigning that result directly to an interface variable produces a non-nil interface that panics on any method call.

Fix: only assign to the interface variable inside an `if err == nil` block, using an intermediate concrete variable. See the Go specification section on [Interface values](https://go.dev/ref/spec#Interface_types) for the underlying rule.

When debugging: if `panic: runtime error: invalid memory address or nil pointer dereference` occurs on an interface method call and the nil guard passes, check whether the interface was assigned from a function returning a pointer type — the pointer being nil does not make the interface nil.

### Container crash debugging in Kubernetes

When a Pod container crashes in e2e:
1. `kubectl logs <pod> -c <container> --previous` — get logs from the crashed instance
2. Go panic stack traces show the exact `file:line` — read them fully before changing any code
3. If the crash is in initialisation, check whether required endpoints or services are reachable before the container starts
4. If the crash is intermittent, add `-race` to your test binary or run `go test -count=1 -race ./...` locally before concluding it is a logic bug
