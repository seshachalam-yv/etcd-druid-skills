# Phase 3: Verify

Run in worktree:

```bash
cd <worktree-path>
make ci-checks          # format + lint (runs on main module)
make test-unit          # unit tests (Go native + Ginkgo suites)
make test-integration   # integration tests with envtest (if integration work done)
```

For API changes, also verify generation is clean:
```bash
cd <worktree-path>/api
make check-generate     # confirms make generate produces no uncommitted diff
```

All must pass. Any failure → dispatch fix subagent with full failure output.
Do not proceed to Gate 2 until clean.

**CI pipeline check (required before Gate 2):**

Run the full CI suite per repo — not just local tests:

| Repo | CI command |
|------|-----------|
| etcd-druid | `make ci-checks && make test-unit` (+ `make test-integration` if touched) |
| etcd-backup-restore | `make revendor && make verify` (revendor is required — vendored deps) |
| etcd-wrapper | `make revendor && make check && make test` (revendor is required — vendored deps) |

If any CI job fails, dispatch a fix subagent with the full failure output. Gate 2 is never presented with failing CI.

**Verification discipline:** Apply the verification gate (`skills/verification/SKILL.md`). Do not claim "all checks pass" based on a previous run or inference.

**E2e verification — decide based on change type:**

| Change type | E2e needed? | Action |
|---|---|---|
| Test-only, no behaviour change | No | Skip |
| Controller logic, component method | Yes | Find matching e2e test, run it targeted |
| New API field, new feature | Yes | Find or write e2e test, run `make ci-e2e-kind` |
| Bug fix with reproduction steps | Yes | Run the specific e2e scenario that reproduces the bug |
| etcd-backup-restore or etcd-wrapper change | Yes | Build custom image, override in druid, run e2e — see `/etcd-druid:e2e` Scenario B or C |

**How to find the right e2e test:**
```bash
# List e2e test functions in etcd-druid
grep -r "func Test" test/e2e/ --include="*.go"

# Find tests related to your change (e.g. configmap, statefulset, backup)
grep -r "TestEtcd\|func Test" test/e2e/ --include="*.go" | grep -i <your-component>

# Run only the relevant test
make PROVIDERS="none,local" \
     GO_TEST_ARGS="-run TestEtcdReconcilerWithNoBackup -v" \
     test-e2e
```

**If no e2e test covers the feature:** note it in the PR's "Special notes for reviewer" section. Opening a follow-up issue for e2e coverage is acceptable; blocking the PR for it is not required unless the change is high-risk.

**Handoff:** Before presenting Gate 2, invoke `/etcd-druid:review` for a final whole-diff review.
This is distinct from the per-task code-reviewer subagent — it reviews the complete change as a human reviewer would see it.
`review` runs as an isolated read-only subagent (`context: fork`) — results are summarized back to this session.
Gate 2 only after review returns LGTM.
