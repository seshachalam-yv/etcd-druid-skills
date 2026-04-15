# etcd-druid-skills

> A Claude Code plugin for contributors to the [Gardener etcd stack](https://github.com/gardener/etcd-druid). Injects domain awareness, workflow discipline, and review rigor into every AI-assisted session.

[![License](https://img.shields.io/badge/license-Apache--2.0-blue.svg)](LICENSE)
[![Version](https://img.shields.io/badge/version-1.8.0-green.svg)](.claude-plugin/plugin.json)
[![Claude Code Plugin](https://img.shields.io/badge/Claude%20Code-Plugin-blueviolet)](https://github.com/anthropics/claude-code)
[![Inspired by Superpowers](https://img.shields.io/badge/Inspired%20by-Superpowers-orange)](https://github.com/obra/superpowers)

---

## Philosophy

### Discipline through Iron Laws, not reminders

Each skill opens with an Iron Law — an unconditional rule stated once, with a rationalization table. The rationalization table names the specific thoughts Claude uses to talk itself out of following the rule ("this task is too small for a plan") and explains why each one fails. This is more effective than repeating the rule as a reminder, because reminders get rationalized away.

| Skill | Iron Law |
|-------|----------|
| `plan` | NO CODE BEFORE GATE 1. |
| `implement` | NO PUSH BEFORE GATE 2. |
| `tdd` | NO IMPLEMENTATION CODE BEFORE A FAILING TEST. |
| `debug` | NO FIX ATTEMPT WITHOUT A REPRODUCIBLE FAILURE FIRST. |
| `review` | NO VERDICT WITHOUT READING THE DIFF AND docs/development/ FIRST. |
| `verification` | NO COMPLETION CLAIMS WITHOUT FRESH VERIFICATION EVIDENCE. |
| `receiving-review` | NO FEEDBACK IMPLEMENTATION WITHOUT INDEPENDENT VERIFICATION FIRST. |

### Plugin self-improvement loop

Every response is evaluated asynchronously by a Stop hook. When Claude-as-evaluator finds a specific, high-confidence finding — a wrong claim, missing footgun, stale flag, unclear workflow step — it writes a structured `OBS-NNN` entry to a local `plugin-observations.md` file.

Three gates must all pass before anything is written:
1. Exact plugin file and section identified
2. Exact wrong or missing text stated
3. Exact correct replacement specified — specific enough to write the fix without further investigation

At the next session start, if open observations exist, you are notified. Run `/etcd-druid:observations` to review them. For each entry you choose:
- **R** — raise a PR to fix it now (Claude reads the file, applies the fix, opens the PR)
- **S** — skip, keep open for later
- **D** — dismiss, not worth acting on

No PR is ever raised without your explicit choice. The hook only captures; you decide.

### Assumption surfacing before action

The most common LLM coding failure is running with a wrong assumption silently. `plan` Phase 1 requires Claude to state every assumption explicitly — expected behaviour, scope, which repo, whether the change is breaking — before proposing approaches. Any assumption it is not confident in must be surfaced as a question. Silent interpretation is not allowed.

### YAGNI enforcement

LLMs tend to overbuild: they add parameters "for future flexibility", introduce abstractions for a single call site, and implement 500 lines where 50 would do. This plugin enforces YAGNI at three gates:

- **Implementer self-review**: every new function, type, and parameter must be used by this task
- **Code-reviewer checklist**: flags anything that exists "for future use"
- **Spec-reviewer**: flags logic added beyond what the acceptance criteria asked for

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

## Installation

**Step 1 — Add the marketplace** (once per machine):

In Claude Code, run:
```
/plugin marketplace add seshachalam-yv/etcd-druid-skills
```

**Step 2 — Install the plugin:**
```
/plugin install etcd-druid-skills@seshachalam-yv-etcd-druid-skills
```

Alternatively, add both to your `~/.claude/settings.json` directly:

```json
{
  "extraKnownMarketplaces": {
    "seshachalam-yv-etcd-druid-skills": {
      "source": {
        "source": "github",
        "repo": "seshachalam-yv/etcd-druid-skills"
      }
    }
  },
  "enabledPlugins": {
    "etcd-druid-skills@seshachalam-yv-etcd-druid-skills": true
  }
}
```

### Verify installation

Start a new Claude Code session in an etcd-druid, etcd-backup-restore, or etcd-wrapper checkout. You should see the orientation context injected automatically (component overview, active repo, branch info). Then try:

```
/etcd-druid:reference
```

If the reference card appears with your current git state, the plugin is working.

### Update

To pull the latest version of the plugin:
```
/plugin marketplace update seshachalam-yv-etcd-druid-skills
```

---

## What it does

Without this plugin, Claude knows Go and Kubernetes but nothing specific about etcd-druid, etcd-backup-restore, or etcd-wrapper. You re-explain the operator interface, test framework rules, API generation process, and review requirements every session.

With this plugin, Claude starts already oriented — it knows which repo you're in, reads `docs/development/` before writing code, enforces the two-gate workflow, blocks edits to generated files, and runs spec and code review after every task.

The plugin is a **workflow orchestrator, not a code library**. Code patterns and conventions live in each repo's `docs/development/`. The plugin tells Claude where to look and enforces the process.

---

## Development Workflow

The workflow is split into two focused skills — plan first, then implement:

```
Issue / bug report
      │
      ▼
  [/etcd-druid:plan]
      │
      ├─ 1. Orient ──── read upstream, identify change type, check docs/development/
      │
      ├─ 2. Design ──── explore 2-3 approaches, identify risks and cross-repo impact
      │
      └─ 3. Code plan ─ write docs/plans/<date>-<title>.md with tasks + acceptance criteria
                                               │
                                     ┌─────────▼─────────┐
                                     │   GATE 1: Approve  │ ← human reviews plan
                                     └─────────┬─────────┘
                                               │
  [/etcd-druid:implement]
      │
      ├─ 1. Worktree ── git worktree add, go mod download, baseline tests
      │
      ├─ 2. Implement ── per-task loop:
      │        implementer subagent
      │              ↓
      │        spec-reviewer  ── did it match acceptance criteria?
      │              ↓
      │        code-reviewer  ── follows conventions, no regressions?
      │              ↓ (fix and re-review until both ✅)
      │
      ├─ 3. Verify ───── make ci-checks && make test-unit && make test-integration
      │                  e2e if required (see decision table in skill)
      │                  CI pipeline check: verify all jobs pass per repo
      │                                         │
      │                               ┌─────────▼─────────┐
      │                               │   GATE 2: Approve  │ ← human reviews PR body + diff
      │                               └─────────┬─────────┘
      │                                         │
      └─ 4. PR ─────────── gh pr create
```

### Skill interactions

```
plan ──► implement
           │
           ├──► api-change (when API types touched)
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

### Pre-PR CI requirement

Before Gate 2, Claude verifies that all CI jobs pass for the relevant repo. For etcd-druid:

```bash
make ci-checks        # format + lint + license + api-diff
make test-unit        # Go native + Ginkgo suites
make test-integration # envtest-based integration tests (if touched)
```

For etcd-backup-restore and etcd-wrapper: `make verify`. If any CI job fails, the fix subagent is dispatched before Gate 2 is presented. Gate 2 is never presented with failing CI.

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
/etcd-druid:plan        I want to implement issue #1420 — add snapshotCount field to EtcdSpec
/etcd-druid:implement   docs/plans/2026-04-08-issue-1420-snapshot-count.md
/etcd-druid:tdd         Write tests for the memberlease component's rotation logic
/etcd-druid:debug       make test-unit is failing with "nil pointer in configmap.Sync"
/etcd-druid:review      Review my changes before I open a PR
/etcd-druid:api-change  I need to add a new field to EtcdSpec with CEL validation
/etcd-druid:e2e         Run e2e tests against my custom etcd-backup-restore image
/etcd-druid:reference   What make targets do I need to run before opening a PR?
/etcd-druid:observations
```

### Let skills activate automatically

`api-change`, `tdd`, `debug`, and `review` also activate automatically when Claude edits `.go` files — no invocation needed for those workflows.

### Example session

```
You:   /etcd-druid:plan

Claude: [reads the issue, explores etcd-druid upstream, identifies it as an API change
         in api/core/v1alpha1/ + configmap component change]
        [writes docs/plans/2026-04-08-issue-1420-snapshot-count.md]
        "Code plan written. Reply 'approved' to proceed."

You:   approved

You:   /etcd-druid:implement docs/plans/2026-04-08-issue-1420-snapshot-count.md

Claude: [creates worktree, dispatches implementer subagent for each task]
        [spec-reviewer and code-reviewer run after each task]
        [runs make ci-checks && make test-unit — all pass]
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

etcd-druid, etcd-backup-restore, and etcd-wrapper are active in production. etcd-steward is a planned refactoring of etcd-backup-restore with a cleaner architecture — no upstream code exists yet. When contributing to etcd-steward, the `plan` + `implement` skills apply with the "new sidecar" classification (skip merged-PR lookup, break tasks at package boundary).

All active components run in the Gardener seed cluster. Changes must not break gardenlet's reconciliation assumptions.

---

## What's inside

### Skills

**Development workflow**
- **plan** — Design phase: issue orientation, approach selection, code plan with acceptance criteria. Output: approved plan file. Gate 1 approval before any code.
- **implement** — Execution phase: worktree setup, per-task subagent loop, verification, CI checks, PR creation. Input: approved plan file from `plan`. Gate 2 before push.
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
- **observations** — Triage captured plugin improvement observations; invoke when session-start flags pending observations

### Cross-cutting guides (referenced by skills, not user-invocable)

| Guide | Referenced from | Purpose |
|-------|----------------|---------|
| `verification` | `tdd`, `debug`, `implement` | 5-step gate: run the command, read the output, then claim it passes — never before |
| `receiving-review` | `implement`, `review` | Anti-sycophancy process for handling upstream maintainer feedback on a PR |
| `tdd/testing-anti-patterns.md` | `tdd` | 5 etcd-druid-specific test anti-patterns with correct alternatives |

### Hooks

| Hook | Event | Purpose |
|------|-------|---------|
| `session-start` | SessionStart, WorktreeCreate, PostCompact | Injects domain orientation: component overview, active repo detection, current branch, available skills. Surfaces pending plugin observations if any exist. |
| `guard-generated-files.sh` | PreToolUse (Edit/Write) | **Blocks** edits to generated files (`zz_generated*`, `crds/*.yaml`, `charts/crds/*`, `client/`) |
| `check-dev-docs.sh` | PostToolUse (Edit/Write) | Reminds Claude to read `docs/development/` before editing `.go` source files |
| `detect-correction.sh` | UserPromptSubmit (async) | Watches for user correction phrases ("that's wrong", "actually it's", "no longer exists", etc.). Sets a flag file so the Stop hook knows to run the LLM evaluator on that response. |
| `observe-plugin-improvement.sh` | Stop (async) | Three-channel gap capture: (1) `<plugin-gap>` XML markers in responses (zero cost), (2) LLM evaluator triggered only when correction flag is set, (3) review skill writes gaps directly. Writes structured `OBS-NNN` entries to `plugin-observations.md`. |

### Subagent prompts

| Prompt | Used by | Role |
|--------|---------|------|
| `implementer-prompt.md` | `implement` Phase 2 | Writes code for a single task, reports status |
| `spec-reviewer-prompt.md` | `implement` Phase 2 | Verifies implementation matches acceptance criteria |
| `code-reviewer-prompt.md` | `implement` Phase 2 | Validates conventions, patterns, and quality |

---

## Skills reference

### User-invocable

| Skill | Invoke | Auto-activates on | Use when |
|-------|--------|--------------------|----------|
| `plan` | `/etcd-druid:plan` | — | Picking up an issue — design, approach selection, code plan with Gate 1 |
| `implement` | `/etcd-druid:implement` | — | Gate 1 approved — worktree setup, subagent loop, CI verify, PR with Gate 2 |
| `api-change` | `/etcd-druid:api-change` | `api/**/*.go` edits | Adding or modifying API fields — CEL validation, generate workflow, CRD tests |
| `tdd` | `/etcd-druid:tdd` | `*.go` edits | Writing new tests or learning the correct test pattern |
| `debug` | `/etcd-druid:debug` | `*.go` edits | Something is failing, broken, or behaving unexpectedly |
| `review` | `/etcd-druid:review` | `*.go` edits | Validating code before opening a PR |
| `e2e` | `/etcd-druid:e2e` | — | Manual e2e testing — KIND setup, custom image builds, sidecar overrides, pre-PR CI |
| `reference` | `/etcd-druid:reference` | — | Quick lookup: make targets, file paths, druidctl, git workflow |
| `observations` | `/etcd-druid:observations` | — | Review captured plugin improvement findings — raise PR, skip, or dismiss |

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
| Pre-PR CI | All CI jobs must pass before Gate 2 — `make ci-checks && make test-unit` for etcd-druid, `make verify` for sidecars |

---

## Current versions (as of v1.8.0)

| | etcd-druid | etcd-backup-restore | etcd-wrapper |
|---|---|---|---|
| Latest release | v0.36.1 | v0.42.0 | v0.7.0 |
| Go | 1.24+ | 1.25+ | 1.25+ |
| etcd | 3.5.27 | 3.5.27 | 3.5.27 |
| golangci-lint | v2 | v2 | v2 |
| CI | GitHub Actions | GitHub Actions | GitHub Actions |

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
