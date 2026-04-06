# etcd-druid-skills

A Claude Code plugin that encodes expert knowledge for [etcd-druid](https://github.com/gardener/etcd-druid) contributors. It injects domain awareness and workflow skills into every Claude session — so you spend less time on "how does this work" and more time on "what needs to be done."

## What It Does

- **Session orientation** — On every session start, Claude receives a concise briefing on the three-component system, key invariants, available skills, and the current git state. If you open Claude inside one of the three repos, the hook detects which repo you're in and tells Claude exactly which `docs/development/` files to read.
- **Domain skills** — Reusable, invocable skills covering the full development lifecycle: feature design through PR, TDD patterns, systematic debugging, pre-PR review, and quick reference.
- **Living documentation** — Skills instruct Claude to read and update `docs/development/` in each repo as part of normal work. The repos own the patterns; the plugin owns the workflow.

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
| `feature-dev` | `/etcd-druid:feature-dev` | Any development work — picking up an issue, planning a feature or bug fix, design-to-PR |
| `tdd` | `/etcd-druid:tdd` | Writing new tests or learning the correct test pattern for any of the three repos |
| `debug` | `/etcd-druid:debug` | Something is failing, broken, or behaving unexpectedly |
| `review` | `/etcd-druid:review` | Validating code before opening a PR — self-review or reviewing a colleague's PR |
| `reference` | `/etcd-druid:reference` | Quick lookup: make targets, file paths, git workflow, branch naming |

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
  • Read docs/development/ before writing any code
  • Implementer subagent writes code + tests, commits, reports
  • Spec-reviewer subagent: did it match the acceptance criteria exactly?
  • Code-reviewer subagent: does it follow the repo's documented conventions?
  • Fix loop until both reviewers ✅
  • Document any pattern found but not yet in docs/development/
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
- Generated files (`zz_generated.deepcopy.go`, `api/core/v1alpha1/crds/*.yaml`, `charts/crds/*.yaml`, `client/`): NEVER edit manually — run `cd api && make generate`
- **etcd-druid tests:** Go native `testing.T` + Gomega — no Ginkgo in `internal/`
- **etcd-wrapper tests:** Go native `testing.T` + Gomega
- **etcd-backup-restore tests:** Ginkgo v2 + Gomega
- NEVER commit to upstream; NEVER push without explicit human approval
- Conventions and code patterns live in each repo's `docs/development/` — read them, update them

## Installation

```bash
claude /install-plugin https://github.com/seshachalam-yv/etcd-druid-skills
/reload-plugins
```

## Contributing

Found a gap, wrong pattern, or missing best practice? Open a PR against this repo.
For skill improvements, edit the relevant `skills/<name>/SKILL.md` directly.
For code patterns and conventions, contribute to the relevant repo's `docs/development/`.

## License

Apache-2.0
