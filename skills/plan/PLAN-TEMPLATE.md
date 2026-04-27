# Plan File Template

```markdown
> **For agentic workers:** Gate 1 is pre-approved for etcd-steward work.
> For etcd-druid work, present this plan and wait for human approval before starting.
> Use implement Phase 2 (per-task subagent loop) to execute tasks.

## Issue
Link: https://github.com/gardener/etcd-druid/issues/{id}
Summary: one sentence.

## Fork Root
Path: <absolute path to local fork, e.g. /home/user/go/src/github.com/me/etcd-druid>

## Change Type
[ ] API change (api/core/v1alpha1/)
[ ] New component (internal/component/)
[ ] Controller change (internal/controller/)
[ ] Test only

## Feature Gate Impact Checklist *(required when the change introduces or modifies a feature gate that affects container images, args, or cross-container behaviour; omit otherwise)*

Follow the pattern of existing gates — search for `UseEtcdWrapper` or `UpgradeEtcdVersion` across the codebase to find every touch point. The full lifecycle (Alpha → Beta → GA) is documented in `docs/deployment/feature-gates.md` in the etcd-druid repo.

- [ ] Gate definition: `api/config/v1alpha1/features.go` — name, maturity level, default
- [ ] Image key constant: `internal/common/constants.go`
- [ ] Image selection logic: `internal/utils/image.go`
- [ ] Default image entry: `internal/images/images.yaml`
- [ ] Container spec (args, ports, probes): `internal/component/statefulset/builder.go`
- [ ] Test image vector: `test/utils/constants.go` + `test/utils/imagevector.go`
- [ ] Helm chart values: `charts/values.yaml` — add operator config toggle if applicable
- [ ] Cross-container contract: verify the new image satisfies every endpoint expected by other containers in the same Pod (read the consuming container's bootstrap/init source — not just the docs)
- [ ] Readiness/liveness probes: confirm probes still target a valid endpoint after the image swap
- [ ] Pod identity: confirm the new container receives pod name/namespace correctly (env vars vs CLI flags vs downward API)
- [ ] E2e override: document how to test with a custom image build (`IMAGEVECTOR_OVERWRITE`, local KIND registry, ConfigMap mount)

## Design Summary
Chosen approach and why. Alternatives considered.

## Tasks
- [ ] Task 1: <name>
      **depends-on:** — *(fill in: Task N if this task needs another to complete first, or `—` if none)*
      Files: <list>
      Tests: unit | integration | both
      API generation: yes | no

      #### Requirement: <what must be true after this task>
      - WHEN <the observable trigger or state>
      - THEN <specific observable outcome> (verified by `<TestName>` or `<file>:<field>:<value>`)

      *(Add one Requirement block per acceptance criterion. Multiple blocks allowed.)*

- [ ] Task 2: ...

### Acceptance criteria format

The WHEN/THEN format above is the required structure. The table below shows examples of strong vs. weak THEN clauses.

| ❌ Vague — spec-reviewer cannot check | ✅ Falsifiable — spec-reviewer reads code or runs test |
|---------------------------------------|-------------------------------------------------------|
| "state transitions are persisted" | `after Init() returns, member.Transitions[0].State == StateNew` (verified by `TestInitializer_NewSingleNode`) |
| "covers all 4 initialization paths" | `TestInitializer_PathA`, `_PathB`, `_PathC`, `_PathD` all exist and pass |
| "LastRestoration is updated" | `EtcdMember.Status.LastRestoration.Status == RestorationSucceeded` after `TestRestoreFromSnapshot` |

For state machine work: write the exact transition sequence for each path as a table, then name the test that verifies it. The test name IS the acceptance criterion.

## API Delta *(required when Change Type includes API change; omit for non-API plans)*

| Field | Change | Breaking |
|-------|--------|---------|
| `EtcdSpec.<FieldName>` | ADDED — optional `*<type>`, default nil | No |
| `EtcdSpec.<FieldName>` | MODIFIED — <description of change> | No / **Yes** |
| `EtcdSpec.<FieldName>` | REMOVED — replaced by `<new field>` | **Yes** |

*Change types: ADDED, MODIFIED, REMOVED. One row per changed field. Delete this section for non-API plans.*

## PR Checklist (pre-submission)
- [ ] make ci-checks passes (etcd-druid) / make verify (etcd-backup-restore) / make check && make test (etcd-wrapper)
- [ ] make test-unit passes
- [ ] make test-integration passes (if integration touched)
- [ ] make revendor run (etcd-backup-restore and etcd-wrapper only — required if any dependency changed)
- [ ] E2e verification: <test name or "not required — test-only change">
- [ ] Documentation updated in docs/ (if user-facing change)
- [ ] examples/ updated (if API changed)

## Rollback
How to revert if needed.
```
