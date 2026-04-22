# etcd-druid-skills

**Ecosystem:** [etcd-druid](https://github.com/gardener/etcd-druid) · [etcd-backup-restore](https://github.com/gardener/etcd-backup-restore) · [etcd-wrapper](https://github.com/gardener/etcd-wrapper)

<p>
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-Apache--2.0-blue.svg" alt="License"></a>
  <a href=".claude-plugin/plugin.json"><img src="https://img.shields.io/badge/version-0.1.1-green.svg" alt="Version"></a>
  <a href="docs/evaluation.md"><img src="https://img.shields.io/badge/eval%20pass%20rate-96%25-brightgreen.svg" alt="Eval Pass Rate"></a>
  <a href="https://github.com/obra/superpowers"><img src="https://img.shields.io/badge/Inspired%20by-Superpowers-orange" alt="Inspired by Superpowers"></a>
</p>

A Claude Code plugin that makes your AI coding agent a capable etcd-druid contributor — not just a code writer, but a workflow-following engineer who knows the two-commit rule, picks the right test framework per repo, protects generated files, and won't push without your approval.

Without this plugin, an LLM working in etcd-druid makes the same mistakes every new contributor makes: editing `zz_generated_*` files, using the wrong test framework, skipping `make revendor`, placing CEL validation in the wrong file, jumping straight to code without a plan. This plugin encodes 15+ known footguns and a gated plan → implement → review workflow so those mistakes never reach your PR.

When you start a session in any etcd-druid, etcd-backup-restore, or etcd-wrapper checkout, the plugin auto-detects the repo, reads the relevant `docs/development/` guide, and activates the right skills — no configuration required.

## Without vs. With This Plugin

<table>
<tr>
<th>Generic Claude on an API change task</th>
<th>With etcd-druid-skills</th>
</tr>
<tr>
<td>

- Edits `zz_generated_deepcopy.go` directly
- Uses `gomega` in etcd-druid unit tests (wrong — Go native + Gomega only in specific pattern)
- Forgets `make generate` after adding a field
- Skips CEL validation entirely
- Opens a PR without `release-note` Prow label
- No plan written; jumps straight to implementation

</td>
<td>

- **Blocks** edits to any `zz_generated_*` file via hook
- Reads `docs/development/` for the repo before touching any file
- Follows the **two-commit rule**: one commit adds the field, a second runs `make generate`
- Places CEL validation in the correct file with field-scoped + cross-field rules
- Drafts PR body with `release-note` block and correct Prow labels
- Writes a plan with WHEN/THEN acceptance criteria; waits for Gate 1 before any code

</td>
</tr>
</table>

## Requirements

| Requirement | Minimum |
|-------------|---------|
| Claude Code | 1.x (any version with plugin support) |
| Claude model | `claude-sonnet-4-5` or newer (Haiku floor was raised; Opus recommended for `plan` and `implement`) |
| Repos supported | `gardener/etcd-druid`, `gardener/etcd-backup-restore`, `gardener/etcd-wrapper` |
| OS | macOS, Linux (anywhere Claude Code runs) |

The plugin auto-detects which repo you are in at session start. It does not modify any repo files — all changes are in your Claude Code session context.

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
 Issue / Bug Report
       │
       ▼
 ┌─────────────────────── /etcd-druid:plan ───────────────────────┐
 │  Read issue → explore upstream → design approach → write plan  │
 │  Plan includes: tasks, WHEN/THEN criteria, files, test scope   │
 └────────────────────────────┬───────────────────────────────────┘
                              │
                    ┌─────────▼─────────┐
                    │  ⛔ GATE 1        │  ← you review the plan
                    │  "approved" to go │
                    └─────────┬─────────┘
                              │
 ┌────────────────────── /etcd-druid:implement ───────────────────┐
 │                                                                │
 │  1. Create worktree + verify baseline tests                    │
 │                                                                │
 │  2. Per-task loop:                                             │
 │     ┌──────────────────────────────────────────┐               │
 │     │  Implementer ──→ Spec-reviewer ──→ Code-reviewer         │
 │     │       ↑                    │              │              │
 │     │       └── fix issues ──────┘──────────────┘              │
 │     └──────────────────────────────────────────┘               │
 │                                                                │
 │  3. Verify: make ci-checks && make test-unit                   │
 │  4. Final review: /etcd-druid:review (whole diff)              │
 └────────────────────────────┬───────────────────────────────────┘
                              │
                    ┌─────────▼─────────┐
                    │  ⛔ GATE 2        │  ← you review the diff
                    │  A) Create PR     │
                    │  B) Push only     │
                    │  C) Make changes  │
                    │  D) Discard       │
                    └─────────┬─────────┘
                              │
                         gh pr create
```

### Skill Interactions

```
plan ──► implement ──┬──► api-change*  ──► CEL, two-commit, CRD tests
   │                 ├──► tdd*         ──► Red-Green-Refactor per repo
   │                 ├──► review*      ──► 15 footguns, Prow labels
   │                 ├──► e2e          ──► KIND, custom images, CI
   │                 └──► verification ──► run → read → then claim
   │
   └──► Gate 1                 debug* ──► tdd ──► review ──► Gate 2

   * = auto-activates on .go edits
```

The core loop is **plan → Gate 1 → implement → Gate 2 → PR**. Everything else supports it:

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
