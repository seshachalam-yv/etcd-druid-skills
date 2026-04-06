# etcd-druid-skills

> A Claude Code plugin for [etcd-druid](https://github.com/gardener/etcd-druid) contributors. Injects domain awareness, workflow discipline, and review rigor into every AI-assisted session.

[![License](https://img.shields.io/badge/license-Apache--2.0-blue.svg)](LICENSE)
[![Claude Code Plugin](https://img.shields.io/badge/Claude%20Code-Plugin-blueviolet)](https://github.com/anthropics/claude-code)
[![Inspired by Superpowers](https://img.shields.io/badge/Inspired%20by-Superpowers-orange)](https://github.com/anthropics/claude-code-superpowers)

---

## What it does

Without this plugin, Claude knows Go and Kubernetes but nothing specific about etcd-druid. You re-explain the operator interface, test framework rules, API generation process, and review requirements every session.

With this plugin, Claude starts already oriented — it knows which repo you're in, reads `docs/development/` before writing code, enforces the two-gate workflow, and runs spec and code review after every task.

The plugin is a **workflow orchestrator, not a code library**. Code patterns and conventions live in each repo's `docs/development/`. The plugin tells Claude where to look and enforces the process.

---

## The three-component system

```
etcd-druid (operator)       Kubernetes operator — owns Etcd CRD, reconciles all cluster resources
etcd-backup-restore         Sidecar — manages snapshots, restore, and etcd initialization
etcd-wrapper                Sidecar — initializes etcd via backup-restore HTTP API, then runs embedded etcd
```

All three run in the Gardener seed cluster. Changes must not break gardenlet's reconciliation assumptions.

---

## Skills

| Skill | Invoke | Auto-activates on | Use when |
|-------|--------|--------------------|----------|
| `feature-dev` | `/etcd-druid:feature-dev` | — | Picking up an issue, planning a feature or bug fix, design-to-PR |
| `api-change` | `/etcd-druid:api-change` | `api/**/*.go` edits | Adding or modifying API fields — CEL validation, generate workflow, CRD tests |
| `tdd` | `/etcd-druid:tdd` | `*.go` edits | Writing new tests or learning the correct test pattern |
| `debug` | `/etcd-druid:debug` | `*.go` edits | Something is failing, broken, or behaving unexpectedly |
| `review` | `/etcd-druid:review` | `*.go` edits | Validating code before opening a PR |
| `reference` | `/etcd-druid:reference` | — | Quick lookup: make targets, file paths, druidctl, git workflow |

`api-change`, `tdd`, `debug`, and `review` activate automatically when Claude edits `.go` files — no invocation needed.

---

## Feature Development Workflow (`feature-dev`)

Two hard gates: no code before Gate 1, no push before Gate 2.

1. **Design** — explore upstream (read-only), identify change type (API / component / controller / test-only), propose 2–3 approaches
2. **Code Plan** — written to `fork/docs/plans/`, includes tasks with acceptance criteria, files, test scope, and API generation flag → **Gate 1: Plan Approval**
3. **Implement** — per-task loop: implementer subagent → spec-review → code-review → fix until both ✅
4. **Verify + PR** — `make ci-checks && make test-unit && make test-integration` → **Gate 2: PR Approval** → `gh pr create`

### Subagent review after every task

Each task passes through two independent subagents before it is marked complete:

- **Spec reviewer** — did the implementation match the acceptance criteria exactly? Were any unplanned files changed?
- **Code reviewer** — does the diff follow `docs/development/` conventions, operator interface requirements, error handling, test framework rules, and commit message format?

When either reviewer finds an issue, the implementer fixes and re-reviews. No task advances until both return ✅.

When the code reviewer finds a mistake in a plugin skill, it outputs a ready-to-use `gh pr create` command targeting this repo.

### Commit conventions

```bash
Add snapshot lease rotation to memberlease component (#1350)   # ✅ imperative, issue number, no period
Fixed the bug.                                                  # ❌ past tense, trailing period, no issue
```

API changes use **two commits** — hand-written types first, `cd api && make generate` output second. Never combine them.

---

## Key invariants

| Rule | Detail |
|------|--------|
| Operator interface | Every component implements `PreSync`, `Sync`, `TriggerDelete`, `GetExistingResourceNames` |
| Generated files | Never edit manually: `zz_generated.deepcopy.go`, `crds/*.yaml`, `charts/crds/*.yaml`, `client/` |
| etcd-druid tests | Go native `testing.T` + Gomega — no Ginkgo, no gomock |
| etcd-backup-restore tests | Ginkgo v2 + Gomega |
| etcd-wrapper tests | Go native `testing.T` + Gomega |
| Async assertions | `Eventually` / `Consistently` — never `time.Sleep()` |
| Upstream | Never commit or push to `github.com/gardener/*` |
| `UseEtcdWrapper` feature gate | **Removed** — delete any reference |
| `--enable-etcd-member-gc` flag | **Removed** in v0.42 — delete any reference |

---

## Installation

```bash
claude plugin install https://github.com/seshachalam-yv/etcd-druid-skills
```

---

## Contributing

For code patterns and conventions: contribute to the relevant repo's `docs/development/` — that is the authoritative source.

For skill workflow fixes: open a PR against this repo and edit `skills/<name>/SKILL.md`.

---

## License

Apache-2.0
