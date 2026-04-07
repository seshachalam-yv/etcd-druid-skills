# etcd-druid-skills

> A Claude Code plugin for contributors to the [Gardener etcd stack](https://github.com/gardener/etcd-druid). Injects domain awareness, workflow discipline, and review rigor into every AI-assisted session.

[![License](https://img.shields.io/badge/license-Apache--2.0-blue.svg)](LICENSE)
[![Claude Code Plugin](https://img.shields.io/badge/Claude%20Code-Plugin-blueviolet)](https://github.com/anthropics/claude-code)
[![Inspired by Superpowers](https://img.shields.io/badge/Inspired%20by-Superpowers-orange)](https://github.com/anthropics/claude-code-superpowers)

---

## What it does

Without this plugin, Claude knows Go and Kubernetes but nothing specific about etcd-druid, etcd-backup-restore, or etcd-wrapper. You re-explain the operator interface, test framework rules, API generation process, and review requirements every session.

With this plugin, Claude starts already oriented — it knows which of etcd-druid, etcd-backup-restore, or etcd-wrapper you're working in, reads `docs/development/` before writing code, enforces the two-gate workflow, and runs spec and code review after every task.

The plugin is a **workflow orchestrator, not a code library**. Code patterns and conventions live in each repo's `docs/development/`. The plugin tells Claude where to look and enforces the process.

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

```bash
git commit -m "Add EtcdMember types and status fields (#1420)"   # hand-written change
git commit -m "Run cd api && make generate (#1420)"              # generated output only
```

### Commit message format

```bash
Add snapshot lease rotation to memberlease component (#1350)   # ✅ imperative, issue ref, no period
Fixed the bug.                                                  # ❌ past tense, trailing period, vague
```

---

## Usage

### Invoke a skill directly

Type a slash command in Claude Code to activate the relevant workflow:

```
/etcd-druid:feature-dev   I want to implement issue #1420 — add snapshotCount field to EtcdSpec
/etcd-druid:tdd           Write tests for the memberlease component's rotation logic
/etcd-druid:debug         make test-unit is failing with "nil pointer in configmap.Sync"
/etcd-druid:review        Review my changes before I open a PR
/etcd-druid:api-change    I need to add a new field to EtcdSpec with CEL validation
/etcd-druid:e2e           Run e2e tests against my custom etcd-backup-restore image
/etcd-druid:reference     What make targets do I need to run before opening a PR?
```

### Let skills activate automatically

`api-change`, `tdd`, `debug`, and `review` also activate automatically when Claude edits `.go` files — no invocation needed for those workflows.

### Example session

```
You:   /etcd-druid:feature-dev

Claude: [reads the issue, explores etcd-druid upstream, identifies it as an API change in api/core/v1alpha1/ + configmap component change]
        [writes docs/plans/2026-04-07-issue-1420-snapshot-count.md]
        "Code plan written. Reply 'approved' to proceed."

You:   approved

Claude: [creates worktree, dispatches implementer subagent for each task]
        [spec-reviewer and code-reviewer run after each task]
        [runs make ci-checks && make test-unit]
        "All checks pass. Ready to create PR. Choose: A) Create PR  B) Push branch only  C) Make changes  D) Discard"

You:   A

Claude: [opens PR against upstream/master]
        PR: https://github.com/gardener/etcd-druid/pull/XXXX
```

---

## The component system

```
etcd-druid            Kubernetes operator — owns Etcd CRD, reconciles all cluster resources
etcd-backup-restore   Sidecar — snapshots, restore, and etcd initialization (current)
etcd-wrapper          Sidecar — starts embedded etcd via the backup-restore HTTP API
etcd-steward          Future sidecar — not yet implemented; will replace etcd-backup-restore
```

etcd-druid, etcd-backup-restore, and etcd-wrapper are active. etcd-steward is planned and in early design — no upstream code exists yet. When contributing to etcd-steward, the `feature-dev` skill applies with the "new sidecar" classification (skip merged-PR lookup, break tasks at package boundary).

All active components run in the Gardener seed cluster. Changes must not break gardenlet's reconciliation assumptions.

---

## Skills

### User-invocable

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

### Cross-cutting guides (referenced by skills, not user-invocable)

| Guide | Referenced from | Purpose |
|-------|----------------|---------|
| `verification` | `tdd`, `debug`, `feature-dev` | 5-step gate: run the command, read the output, then claim it passes — never before |
| `receiving-review` | `feature-dev`, `review` | Anti-sycophancy process for handling upstream maintainer feedback on a PR |
| `tdd/testing-anti-patterns.md` | `tdd` | 5 etcd-druid-specific test anti-patterns with correct alternatives |

These guides exist to enforce discipline that applies across multiple workflows. They are not directly invocable — the relevant skill points you to them at the right moment.

---

## Philosophy

### Discipline through Iron Laws, not reminders

Each skill opens with an Iron Law — an unconditional rule stated once, with a rationalization table. The rationalization table names the specific thoughts Claude uses to talk itself out of following the rule ("this task is too small for a plan") and explains why each one fails. This is more effective than repeating the rule as a reminder, because reminders get rationalized away.

Every skill has its own Iron Law:

| Skill | Iron Law |
|-------|----------|
| `feature-dev` | NO CODE BEFORE GATE 1. NO PUSH BEFORE GATE 2. |
| `tdd` | NO IMPLEMENTATION CODE BEFORE A FAILING TEST. |
| `debug` | NO FIX ATTEMPT WITHOUT A REPRODUCIBLE FAILURE FIRST. |
| `review` | NO VERDICT WITHOUT READING THE DIFF AND docs/development/ FIRST. |
| `verification` | NO COMPLETION CLAIMS WITHOUT FRESH VERIFICATION EVIDENCE. |
| `receiving-review` | NO FEEDBACK IMPLEMENTATION WITHOUT INDEPENDENT VERIFICATION FIRST. |

### Anti-sycophancy: verification before assertion

The verification gate (`skills/verification/SKILL.md`) enforces a 5-step rule that applies across all workflows:

1. Identify the verification command
2. Run it in **this message** — not a previous one
3. Read the full output — not just the exit code
4. Verify the claim against the output
5. Then make the claim — with evidence

This prevents Claude from asserting "tests pass" based on memory, inference, or a run from a previous message. Evidence precedes assertion — always.

The same principle applies to review feedback. The `receiving-review` guide prevents sycophantic implementation — Claude must verify each maintainer suggestion against the actual code before implementing it, and must ask for clarification rather than guessing when a comment is unclear.

### Session orientation via hooks

On every session start (and after context compaction), a `SessionStart` hook injects:
- The etcd-druid / etcd-backup-restore / etcd-wrapper component overview
- Which of etcd-druid, etcd-backup-restore, or etcd-wrapper you are currently in
- The current branch and recent commits
- The list of available skills

Claude never loses its domain grounding mid-session, even after compaction truncates earlier context.

---

## Key invariants

| Rule | Detail |
|------|--------|
| Operator interface | Every etcd-druid component implements `PreSync`, `Sync`, `TriggerDelete`, `GetExistingResourceNames` |
| Generated files | Never edit manually: `zz_generated.deepcopy.go`, `crds/*.yaml`, `charts/crds/*.yaml`, `client/` |
| etcd-druid tests | Go native `testing.T` + Gomega — no Ginkgo, no gomock |
| etcd-backup-restore tests | Ginkgo v2 + Gomega |
| etcd-wrapper tests | Go native `testing.T` + Gomega |
| etcd-steward tests | Go native `testing.T` — no Ginkgo (future; not yet implemented) |
| Async assertions | `Eventually` / `Consistently` — never `time.Sleep()` |
| Upstream repos | Never commit or push to `github.com/gardener/*` directly |
| `UseEtcdWrapper` feature gate | **Removed** — delete any reference |
| `--enable-etcd-member-gc` flag (etcd-backup-restore) | **Removed** in v0.42 — delete any reference |
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
