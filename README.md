# etcd-druid-skills

> A Claude Code plugin for contributors to the [Gardener etcd stack](https://github.com/gardener/etcd-druid). Injects domain awareness, workflow discipline, and review rigor into every AI-assisted session.

[![License](https://img.shields.io/badge/license-Apache--2.0-blue.svg)](LICENSE)
[![Version](https://img.shields.io/badge/version-1.4.0-green.svg)](.claude-plugin/plugin.json)
[![Claude Code Plugin](https://img.shields.io/badge/Claude%20Code-Plugin-blueviolet)](https://github.com/anthropics/claude-code)
[![Inspired by Superpowers](https://img.shields.io/badge/Inspired%20by-Superpowers-orange)](https://github.com/obra/superpowers)

---

## What it does

Without this plugin, Claude knows Go and Kubernetes but nothing specific about etcd-druid, etcd-backup-restore, or etcd-wrapper. You re-explain the operator interface, test framework rules, API generation process, and review requirements every session.

With this plugin, Claude starts already oriented — it knows which repo you're in, reads `docs/development/` before writing code, enforces the two-gate workflow, blocks edits to generated files, and runs spec and code review after every task.

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
git commit -m "Add snapshotCount field to EtcdSpec (#1420)"   # hand-written change
git commit -m "Run cd api && make generate (#1420)"           # generated output only
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

Claude: [reads the issue, explores etcd-druid upstream, identifies it as an API change
         in api/core/v1alpha1/ + configmap component change]
        [writes docs/plans/2026-04-07-issue-1420-snapshot-count.md]
        "Code plan written. Reply 'approved' to proceed."

You:   approved

Claude: [creates worktree, dispatches implementer subagent for each task]
        [spec-reviewer and code-reviewer run after each task]
        [runs make ci-checks && make test-unit]
        "All checks pass. Ready to create PR. Choose:
          A) Create PR  B) Push branch only  C) Make changes  D) Discard"

You:   A

Claude: [opens PR against upstream/master]
        PR: https://github.com/<your-fork>/etcd-druid/pull/XXXX
```

---

## The component system

```
etcd-druid            Kubernetes operator — owns Etcd CRD, reconciles all cluster resources
etcd-backup-restore   Sidecar — snapshots, restore, and etcd initialization
etcd-wrapper          Sidecar — starts embedded etcd via the backup-restore HTTP API
etcd-steward          Planned sidecar — will replace etcd-backup-restore (not yet in upstream)
```

etcd-druid, etcd-backup-restore, and etcd-wrapper are active in production. etcd-steward is a planned refactoring of etcd-backup-restore with a cleaner architecture — no upstream code exists yet. When contributing to etcd-steward, the `feature-dev` skill applies with the "new sidecar" classification (skip merged-PR lookup, break tasks at package boundary).

All active components run in the Gardener seed cluster. Changes must not break gardenlet's reconciliation assumptions.

---

## What's inside

### Skills

**Development workflow**
- **feature-dev** — Full issue-to-PR lifecycle with two approval gates, subagent-driven implementation, and cross-repo guidance
- **api-change** — API field design, CEL validation (field-scoped + cross-field), two-commit generate workflow, CRD tests

**Testing**
- **tdd** — Red-Green-Refactor cycle for all three repos with framework-specific guidance (includes testing anti-patterns reference)
- **e2e** — KIND cluster setup, custom image builds, sidecar overrides, pre-PR CI validation

**Debugging**
- **debug** — Systematic 4-phase root cause analysis with delve, log analysis, and build failure triage

**Review**
- **review** — Pre-merge checklist, convention validation, known footguns (runs as isolated read-only subagent)

**Reference**
- **reference** — Quick lookup: make targets, file paths, source locations for all 3 repos, feature gates, CLI flags, tooling versions

### Cross-cutting guides (referenced by skills, not user-invocable)

| Guide | Referenced from | Purpose |
|-------|----------------|---------|
| `verification` | `tdd`, `debug`, `feature-dev` | 5-step gate: run the command, read the output, then claim it passes — never before |
| `receiving-review` | `feature-dev`, `review` | Anti-sycophancy process for handling upstream maintainer feedback on a PR |
| `tdd/testing-anti-patterns.md` | `tdd` | 5 etcd-druid-specific test anti-patterns with correct alternatives |

### Hooks

| Hook | Event | Purpose |
|------|-------|---------|
| `session-start` | SessionStart, WorktreeCreate, PostCompact | Injects domain orientation: component overview, active repo detection, current branch, available skills |
| `guard-generated-files.sh` | PreToolUse (Edit/Write) | **Blocks** edits to generated files (`zz_generated*`, `crds/*.yaml`, `charts/crds/*`, `client/`) |
| `check-dev-docs.sh` | PostToolUse (Edit/Write) | Reminds Claude to read `docs/development/` before editing `.go` source files |

### Subagent prompts

| Prompt | Used by | Role |
|--------|---------|------|
| `implementer-prompt.md` | `feature-dev` Phase 4 | Writes code for a single task, reports status |
| `spec-reviewer-prompt.md` | `feature-dev` Phase 4 | Verifies implementation matches acceptance criteria |
| `code-reviewer-prompt.md` | `feature-dev` Phase 4 | Validates conventions, patterns, and quality |

### Skill interaction map

```
feature-dev ──► api-change (when API types touched)
     │
     ├──► tdd (implementer subagents follow TDD)
     │      └──► testing-anti-patterns.md
     │
     ├──► review (whole-diff review before Gate 2)
     │      └──► receiving-review (if maintainer feedback arrives)
     │
     ├──► e2e (when e2e verification needed)
     │
     └──► verification (before every completion claim)

debug ──► tdd (add regression test after fix)
   └──► review (before PR)

tdd ──► review (before PR)
```

---

## Skills reference

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

---

## Philosophy

### Discipline through Iron Laws, not reminders

Each skill opens with an Iron Law — an unconditional rule stated once, with a rationalization table. The rationalization table names the specific thoughts Claude uses to talk itself out of following the rule ("this task is too small for a plan") and explains why each one fails. This is more effective than repeating the rule as a reminder, because reminders get rationalized away.

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

### Generated file protection via hooks

A `PreToolUse` hook automatically **blocks** any attempt to edit generated files (`zz_generated.deepcopy.go`, CRD YAMLs, `charts/crds/`, `client/`, `docs/api-reference/`). This turns the "never manually edit generated files" invariant from an instruction into an enforced constraint.

### Session orientation via hooks

On every session start (and after context compaction), a `SessionStart` hook injects:
- The component overview with current versions and key packages
- Which repo you are currently in (detected from git remote or directory name)
- The current branch and recent commits
- Key development docs paths for the active repo
- The list of available skills

Claude never loses its domain grounding mid-session, even after compaction truncates earlier context.

---

## Key invariants

| Rule | Detail |
|------|--------|
| Operator interface | Every etcd-druid component implements `PreSync`, `Sync`, `TriggerDelete`, `GetExistingResourceNames` |
| Generated files | Never edit manually — **hook-enforced**: `zz_generated.deepcopy.go`, `crds/*.yaml`, `charts/crds/*.yaml`, `client/`, `docs/api-reference/` |
| etcd-druid tests | Go native `testing.T` + Gomega — no Ginkgo, no gomock |
| etcd-backup-restore tests | Ginkgo v2 + Gomega + `go.uber.org/mock` |
| etcd-wrapper tests | Go native `testing.T` + Gomega — no Ginkgo, no cobra |
| Async assertions | `Eventually` / `Consistently` — never `time.Sleep()` |
| Upstream repos | Never commit or push to `github.com/gardener/*` directly |
| Dependency management | etcd-druid: `make tidy`. etcd-backup-restore and etcd-wrapper: `make revendor` (vendored) |
| `UseEtcdWrapper` feature gate | **GA, locked true** — cannot be disabled; do not add conditional checks |
| `--enable-etcd-member-gc` flag | **Removed** in etcd-backup-restore v0.42 — do not reference |
| `--k8s-member-gc-duration` flag | **Removed** in etcd-backup-restore v0.42 — do not reference |
| `PreferClose` traffic distribution | **Deprecated** — use `PreferSameZone` or `PreferSameNode` |
| Snapshot compression | Enabled by default in etcd-backup-restore v0.40+ (`--compress-snapshots=true`) |

---

## Current versions (as of v1.4.0)

| | etcd-druid | etcd-backup-restore | etcd-wrapper |
|---|---|---|---|
| Latest release | v0.36.1 | v0.42.0 | v0.7.0 |
| Go | 1.24+ | 1.25+ | 1.25+ |
| etcd | 3.5.27 | 3.5.27 | 3.5.27 |
| golangci-lint | v2 | v2 | v2 |
| CI | GitHub Actions | GitHub Actions | GitHub Actions |

---

## Installation

```bash
claude plugin install https://github.com/seshachalam-yv/etcd-druid-skills
```

### Verify installation

Start a new Claude Code session in an etcd-druid, etcd-backup-restore, or etcd-wrapper checkout. You should see the orientation context injected automatically (component overview, active repo, branch info). Then try:

```
/etcd-druid:reference
```

If the reference card appears with your current git state, the plugin is working.

### Update

```bash
claude plugin update etcd-druid
```

---

## Contributing

**For code patterns and conventions:** contribute to the relevant repo's `docs/development/` — that is the authoritative source for how code should be written.

**For skill workflow fixes:** open a PR against this repo and edit `skills/<name>/SKILL.md`.

**For new cross-cutting guides:** add a non-user-invocable skill under `skills/<name>/SKILL.md` with `user-invocable: false` in the frontmatter, then reference it from the relevant skills' Handoff sections.

**For hook improvements:** edit `hooks/hooks.json` and add the corresponding script in `hooks/`.

When modifying skills, test the change by running a real session that exercises the workflow — skills are behavior-shaping code, not prose. A change that looks correct may cause the agent to shortcut or rationalize in unexpected ways.

---

## License

Apache-2.0
