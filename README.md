# etcd-druid-skills

A Claude Code plugin that encodes expert knowledge for [etcd-druid](https://github.com/gardener/etcd-druid) contributors. It injects domain awareness, best practices, and workflow skills into every Claude session — so you spend less time on "how does this work" and more time on "what needs to be done."

## What It Does

- **Session orientation** — On every session start, Claude receives a concise briefing on the three-component system (etcd-druid, etcd-backup-restore, etcd-wrapper), working directories, key invariants, available skills, and the current git branch/recent commits.
- **Domain skills** — Reusable, invocable skills covering the full development lifecycle: feature design through PR, TDD patterns, systematic debugging, pre-PR review, and domain reference.

## The Three-Component System

```
etcd-druid          Kubernetes operator — owns the Etcd CRD, reconciles all cluster resources
etcd-backup-restore Sidecar — manages snapshots, restore, and etcd initialization
etcd-wrapper        Sidecar — initializes etcd via backup-restore HTTP API, then runs embedded etcd
```

All three run in Gardener's **seed cluster**. etcd-druid is reconciled by gardenlet; changes must not break gardenlet's reconciliation assumptions.

## Skills

| Skill | Invoke | Use when |
|-------|--------|----------|
| `feature-dev` | `/etcd-druid:feature-dev` | Starting any feature or bug fix — full design-to-PR workflow |
| `tdd` | `/etcd-druid:tdd` | Writing or fixing tests in any of the three repos |
| `debug` | `/etcd-druid:debug` | Test failures, reconciliation loops, backup failures, unexpected behavior |
| `review` | `/etcd-druid:review` | Self-review before a PR or reviewing someone else's contribution |
| `reference` | `/etcd-druid:reference` | Quick lookup: make targets, error patterns, operator interface, fake client, paths |

## Feature Development Workflow (`feature-dev`)

The `feature-dev` skill runs a structured design-to-PR workflow with two hard human approval gates.

```
Issue received
    │
    ▼
Phase 1: Design
  • Explore upstream (read-only) to understand affected controller/component/API
  • Identify change type: API | component | controller | test-only
  • Propose 2–3 approaches with trade-offs
    │
    ▼
Phase 2: Code Plan
  • Written to fork: docs/plans/YYYY-MM-DD-issue-{id}-{description}.md
  • Includes: change type, tasks with acceptance criteria, files, test scope,
    API generation flag, and pre-PR checklist
    │
    ▼
⛔ GATE 1: Plan Approval  ──── changes requested ────▶ back to Code Plan
  • No code written before this gate
  • No worktree created before this gate
    │ approved
    ▼
Phase 3: Worktree Setup
  git worktree add ../etcd-druid-ai-TASK-{id} -b ai/TASK-{id}/claude/{desc} upstream/master
    │
    ▼
Phase 4: Per-Task Implementation  (repeat for each task)
  • Implementer subagent writes code + tests, commits, reports
  • Spec-reviewer subagent: did it match the acceptance criteria exactly?
  • Code-reviewer subagent: does it follow etcd-druid conventions?
  • Fix loop until both reviewers ✅
    │ all tasks done
    ▼
Phase 5: Verify
  make ci-checks && make test-unit && make test-integration
  (API changes: cd api && make check-generate)
    │ all pass
    ▼
⛔ GATE 2: PR Approval  ──── changes requested ────▶ back to Verify
  • Shows: PR title, body draft (/area /kind release-note), diff stat, commit list
  • Options: Create PR | Push branch only | Make changes | Discard
    │ approved
    ▼
Phase 6: PR Creation
  git push origin <branch>
  gh pr create --base master --title "..." --body "..."
```

### Commit conventions

- One commit per logical change — imperative, sentence case, no trailing period
- Issue number at end: `Add snapshot lease rotation to memberlease component (#1350)`
- API changes use two commits:
  - Commit 1: hand-written API types/markers
  - Commit 2: `cd api && make generate` output only

## Key Invariants

- New components must implement the `Operator` interface: `PreSync`, `Sync`, `TriggerDelete`, `GetExistingResourceNames`
- Register via `registry.Register(component.Kind, operator)` in `internal/controller/etcd/reconciler.go`
- Error codes: typed string constants (`druidapicommon.ErrorCode = "ERR_GET_FOO"`) — use `druiderr.WrapError`, never `fmt.Errorf`
- API changes in `api/core/v1alpha1/` require CEL validation annotations (`+kubebuilder:validation:XValidation`)
- Generated files (`zz_generated.deepcopy.go`, `api/core/v1alpha1/crds/*.yaml`, `charts/crds/*.yaml`, `client/`): NEVER edit manually — run `cd api && make generate`
- **etcd-druid tests:** Go native `testing.T` + Gomega — no Ginkgo in `internal/`
- **etcd-wrapper tests:** Go native `testing.T` + Gomega
- **etcd-backup-restore tests:** Ginkgo v2 + Gomega
- NEVER commit to upstream; NEVER push without explicit human approval

## Installation

```bash
claude /install-plugin https://github.com/seshachalam-yv/etcd-druid-skills
/reload-plugins
```

## Contributing

Found a gap, wrong pattern, or missing best practice? Open a PR against this repo.
For skill improvements, edit the relevant `skills/<name>/SKILL.md` directly.

## License

Apache-2.0
