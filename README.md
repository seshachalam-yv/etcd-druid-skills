# etcd-druid-skills

> A Claude Code plugin for contributors to the [Gardener etcd stack](https://github.com/gardener/etcd-druid). Injects domain awareness, workflow discipline, and review rigor into every AI-assisted session.

[![License](https://img.shields.io/badge/license-Apache--2.0-blue.svg)](LICENSE)
[![Claude Code Plugin](https://img.shields.io/badge/Claude%20Code-Plugin-blueviolet)](https://github.com/anthropics/claude-code)
[![Inspired by Superpowers](https://img.shields.io/badge/Inspired%20by-Superpowers-orange)](https://github.com/anthropics/claude-code-superpowers)

---

## What it does

Without this plugin, Claude knows Go and Kubernetes but nothing specific about the etcd stack. You re-explain the operator interface, test framework rules, API generation process, and review requirements every session.

With this plugin, Claude starts already oriented — it knows which repo you're in, reads `docs/development/` before writing code, enforces the two-gate workflow, and runs spec and code review after every task.

The plugin is a **workflow orchestrator, not a code library**. Code patterns and conventions live in each repo's `docs/development/`. The plugin tells Claude where to look and enforces the process.

---

## The four-component system

```
etcd-druid            Kubernetes operator — owns Etcd CRD, reconciles all cluster resources
etcd-steward          Sidecar — manages etcd member lifecycle, snapshots, and restore (replaces etcd-backup-restore)
etcd-backup-restore   Legacy sidecar — snapshots, restore, and etcd initialization (being replaced by etcd-steward)
etcd-wrapper          Sidecar — starts embedded etcd via steward/backup-restore HTTP API
```

All four run in the Gardener seed cluster. Changes must not break gardenlet's reconciliation assumptions.

---

## Skills

| Skill | Invoke | Auto-activates on | Use when |
|-------|--------|--------------------|----------|
| `feature-dev` | `/etcd-druid:feature-dev` | — | Picking up an issue, planning a feature or bug fix, design-to-PR |
| `api-change` | `/etcd-druid:api-change` | `api/**/*.go` edits | Adding or modifying API fields — CEL validation, generate workflow, CRD tests |
| `tdd` | `/etcd-druid:tdd` | `*.go` edits | Writing new tests or learning the correct test pattern |
| `debug` | `/etcd-druid:debug` | `*.go` edits | Something is failing, broken, or behaving unexpectedly |
| `review` | `/etcd-druid:review` | `*.go` edits | Validating code before opening a PR |
| `e2e` | `/etcd-druid:e2e` | — | Manual e2e testing — KIND setup, custom image builds, sidecar overrides, pre-PR CI |
| `reference` | `/etcd-druid:reference` | — | Quick lookup: make targets, file paths, druidctl, git workflow |

`api-change`, `tdd`, `debug`, and `review` activate automatically when Claude edits `.go` files — no invocation needed.

---

## Feature Development Workflow

```
Issue / bug report
      │
      ▼
 [feature-dev]
      │
      ├─ 1. Orient ──── read upstream, identify change type, check docs/development/
      │
      ├─ 2. Design ──── explore 2-3 approaches, identify risks and cross-repo impact
      │
      ├─ 3. Plan ─────── write docs/plans/<date>-<title>.md with tasks + acceptance criteria
      │                                         │
      │                               ┌─────────▼─────────┐
      │                               │   GATE 1: Approve  │ ← human reviews plan
      │                               └─────────┬─────────┘
      │                                         │
      ├─ 4. Implement ── per-task loop:
      │        implementer subagent
      │              ↓
      │        spec-reviewer  ── did it match acceptance criteria?
      │              ↓
      │        code-reviewer  ── follows conventions, no regressions?
      │              ↓ (fix and re-review until both ✅)
      │
      ├─ 5. Verify ───── make ci-checks && make test-unit && make test-integration
      │                  e2e if required (see decision table in skill)
      │                                         │
      │                               ┌─────────▼─────────┐
      │                               │   GATE 2: Approve  │ ← human reviews PR body
      │                               └─────────┬─────────┘
      │                                         │
      └─ 6. PR ─────────── gh pr create
```

### Two-commit rule for API changes

API changes always produce exactly two commits — never combined:

```
commit 1: Add EtcdMember types and registration          ← hand-written
commit 2: Run cd api && make generate                    ← generated output only
```

### Commit message format

```bash
Add snapshot lease rotation to memberlease component (#1350)   # ✅ imperative, issue ref, no period
Fixed the bug.                                                  # ❌ past tense, trailing period, vague
```

---

## Key invariants

| Rule | Detail |
|------|--------|
| Operator interface | Every component implements `PreSync`, `Sync`, `TriggerDelete`, `GetExistingResourceNames` |
| Generated files | Never edit manually: `zz_generated.deepcopy.go`, `crds/*.yaml`, `charts/crds/*.yaml`, `client/` |
| etcd-druid tests | Go native `testing.T` + Gomega — no Ginkgo, no gomock |
| etcd-backup-restore tests | Ginkgo v2 + Gomega |
| etcd-steward tests | Go native `testing.T` — no Ginkgo |
| etcd-wrapper tests | Go native `testing.T` + Gomega |
| Async assertions | `Eventually` / `Consistently` — never `time.Sleep()` |
| Upstream repos | Never commit or push to `github.com/gardener/*` directly |
| `UseEtcdWrapper` feature gate | **Removed** — delete any reference |
| `--enable-etcd-member-gc` flag | **Removed** in v0.42 — delete any reference |
| `UseEtcdSteward` feature gate | Alpha, disabled by default — do not enable in production |

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
