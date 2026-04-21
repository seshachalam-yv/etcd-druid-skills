# etcd-druid-skills

Expert development workflow for the [Gardener etcd stack](https://github.com/gardener/etcd-druid) — plan, implement, test, debug, and review with full domain awareness.

[![License](https://img.shields.io/badge/license-Apache--2.0-blue.svg)](LICENSE)
[![Version](https://img.shields.io/badge/version-0.1.1-green.svg)](.claude-plugin/plugin.json)
[![Plugin Pass Rate](https://img.shields.io/badge/eval%20pass%20rate-96%25-brightgreen.svg)](docs/evaluation.md)
[![Inspired by Superpowers](https://img.shields.io/badge/Inspired%20by-Superpowers-orange)](https://github.com/obra/superpowers)

## How it works

When you start a Claude Code session in an etcd-druid, etcd-backup-restore, or etcd-wrapper checkout, the plugin activates automatically. It knows which repo you're in, what branch you're on, and what conventions that repo expects.

Ask it to implement a feature, and it doesn't jump straight into code. It reads the GitHub issue, explores the upstream codebase, writes a structured plan with acceptance criteria, and waits for your approval before touching a single file. That's Gate 1.

After you say "go", it creates an isolated worktree and works through each task using subagents — an implementer writes the code (TDD-first), a spec-reviewer checks it against the plan, and a code-reviewer validates conventions. When everything passes, it runs the full CI suite, drafts a PR body matching the team's Prow label conventions, and presents it for your final approval. That's Gate 2.

It does this because the Gardener etcd ecosystem has specific rules that a general-purpose LLM doesn't know: the two-commit rule for API changes, Ginkgo v2 for etcd-backup-restore tests but Go native for etcd-druid, `make revendor` for vendored repos, CEL validation placement rules, 15+ known footguns that trip up every new contributor. The plugin encodes all of this so you don't have to re-explain it every session.

And because skills trigger automatically, you don't need to do anything special. Your coding agent just knows etcd-druid.

## Installation

### Claude Code (Marketplace)

```bash
/plugin marketplace add seshachalam-yv/etcd-druid-skills
/plugin install etcd-druid-skills@seshachalam-yv-etcd-druid-skills
```

### Manual (settings.json)

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

### Verify

Start a session in an etcd-druid checkout. You should see the orientation context (component overview, active repo, branch info). Then:

```
/etcd-druid:reference
```

If the reference card appears with your current git state, you're set.

### Update

```
/plugin marketplace update seshachalam-yv-etcd-druid-skills
```

## The Basic Workflow

```
1. /etcd-druid:plan       Read issue → explore upstream → write plan → GATE 1 (you approve)
2. /etcd-druid:implement  Create worktree → per-task subagents → spec + code review → CI → GATE 2 (you approve) → PR
```

That's the core loop. Everything else supports it:

- **api-change** activates when API types are touched — CEL validation, two-commit generate workflow, CRD tests
- **tdd** activates when tests are written — correct framework per repo, Red-Green-Refactor
- **debug** activates when something breaks — systematic root cause, reproduce before fix
- **review** runs before Gate 2 — full-diff review against `docs/development/` conventions

## What's Inside

### Skills (9 user-invocable)

**Planning & Execution**
- **plan** — Issue intake, approach selection, code plan with WHEN/THEN acceptance criteria. Gate 1.
- **implement** — Worktree setup, per-task subagent loop (implementer → spec-reviewer → code-reviewer), CI verification, PR creation. Gate 2.

**Domain-Specific**
- **api-change** — Field design, CEL validation (field-scoped + cross-field), kubebuilder markers, two-commit generate workflow, CRD integration tests
- **tdd** — Framework per repo (Go native for druid/wrapper, Ginkgo v2 for backup-restore), fake client patterns, testing anti-patterns
- **debug** — 6-phase root cause analysis, Delve debugging, per-repo log analysis, build failure triage tables
- **e2e** — KIND cluster setup, custom sidecar image builds, IMAGEVECTOR_OVERWRITE, pre-PR CI

**Quality**
- **review** — 10-step checklist, 15 known footguns, Gardener PR conventions (Prow labels, release notes), repo-specific framework validation
- **reference** — Make targets, file paths, feature gates, CLI flags, dependency management, cherry-pick workflow
- **observations** — Triage plugin self-improvement findings. Choose: raise PR, skip, or dismiss.

### Cross-Cutting (referenced by skills, not user-invocable)

- **verification** — 5-step evidence gate: run command → read output → then claim it passes
- **receiving-review** — Handle maintainer feedback without sycophancy: verify before implementing

### Subagent Prompts

- **implementer-prompt.md** — Task implementation with TDD, self-review checklist
- **spec-reviewer-prompt.md** — Verify implementation matches acceptance criteria
- **code-reviewer-prompt.md** — Validate conventions, patterns, quality

### Hooks (5 active)

| Hook | When | What |
|------|------|------|
| **session-start** | Session start, worktree create, post-compaction | Injects domain orientation, detects active repo, surfaces pending observations |
| **guard-generated-files** | Before Edit/Write | **Blocks** edits to generated files (`zz_generated*`, CRDs, `client/`) |
| **check-dev-docs** | After Edit/Write | Reminds to read the relevant `docs/development/` guide for the file being edited |
| **detect-correction** | User message submitted | Watches for correction phrases to trigger the plugin self-improvement evaluator |
| **observe-plugin-improvement** | Session end | Captures high-confidence plugin gaps as structured observations |

## Philosophy

### Iron Laws, not reminders

Each skill opens with one unconditional rule and a table of the specific rationalizations that cause violations. This is more effective than repeating rules because it addresses the actual thought patterns ("this task is too small for a plan", "I'll add the test after") rather than the abstract principle.

| Skill | Iron Law |
|-------|----------|
| plan | NO CODE BEFORE GATE 1 |
| implement | NO PUSH BEFORE GATE 2 |
| tdd | NO IMPLEMENTATION CODE BEFORE A FAILING TEST |
| debug | NO FIX ATTEMPT WITHOUT A REPRODUCIBLE FAILURE FIRST |
| review | NO VERDICT WITHOUT READING THE DIFF AND docs/development/ FIRST |
| verification | NO COMPLETION CLAIMS WITHOUT FRESH VERIFICATION EVIDENCE |

### Workflow orchestrator, not code library

Code patterns and conventions live in each repo's `docs/development/`. The plugin tells Claude where to look and enforces the process — it never duplicates what the repos already document.

### Plugin self-improvement

Every session is evaluated asynchronously. When a specific gap is found (wrong claim, missing footgun, stale flag), it's captured as a structured observation. At the next session, you triage: raise a PR, skip, or dismiss. No PR is ever raised without your explicit choice.

### Assumption surfacing

The `plan` skill requires Claude to state every assumption explicitly before proposing approaches. Silent interpretation is the most common AI coding failure — this prevents it.

## Evaluation

The plugin is tested against 5 real PR scenarios from `gardener/etcd-druid` and `gardener/etcd-backup-restore`:

| Scenario | Based on Real PR | Plugin | Baseline | Lift |
|----------|-----------------|--------|----------|------|
| API change | etcd-druid#1280 | 100% | 33% | +67pp |
| Feature dev | etcd-druid#1300 | 100% | 67% | +33pp |
| Bug fix | etcd-druid#1308 | 80% | 40% | +40pp |
| Refactoring | etcd-backup-restore#1013 | 100% | 33% | +67pp |
| Enhancement | etcd-backup-restore#1001 | 100% | 83% | +17pp |
| **Average** | | **96%** | **52%** | **+44pp** |

5 iterations, zero cross-iteration variance. See [docs/evaluation.md](docs/evaluation.md) for the full methodology and reproduction guide.

## The Component System

```
etcd-druid            Kubernetes operator — owns Etcd CRD, reconciles cluster resources
etcd-backup-restore   Sidecar — snapshots, restore, etcd initialization
etcd-wrapper          Sidecar — starts embedded etcd via backup-restore HTTP API
```

All three run in the Gardener seed cluster. The plugin knows each repo's testing framework, dependency management style, CI pipeline, and logging framework — and adjusts its guidance accordingly.

| | etcd-druid | etcd-backup-restore | etcd-wrapper |
|---|---|---|---|
| Test framework | Go native + Gomega | Ginkgo v2 + Gomega | Go native + Gomega |
| Dependencies | `make tidy` | `make revendor` (vendored) | `make revendor` (vendored) |
| CI command | `make ci-checks` | `make verify` | `make check && make test` |
| Logging | logr | logrus | zap |

## Contributing

**Skill workflow fixes:** Edit `skills/<name>/SKILL.md` and open a PR against this repo.

**Code patterns and conventions:** Contribute to the relevant repo's `docs/development/` — that is the authoritative source.

**New cross-cutting guides:** Add a skill with `user-invocable: false` in frontmatter, then reference it from relevant skills' Handoff sections.

**Testing changes:** Run a real session that exercises the workflow. Skills are behavior-shaping code — a change that looks correct may cause the agent to shortcut in unexpected ways. See [docs/evaluation.md](docs/evaluation.md) for the formal evaluation framework.

## License

Apache-2.0
