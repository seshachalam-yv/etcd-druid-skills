<img src="docs/logo.svg" alt="etcd-druid-skills" width="520">

**Ecosystem:** [etcd-druid](https://github.com/gardener/etcd-druid) · [etcd-backup-restore](https://github.com/gardener/etcd-backup-restore) · [etcd-wrapper](https://github.com/gardener/etcd-wrapper)
<br>**Website:** [seshachalam-yv.github.io/etcd-druid-skills](https://seshachalam-yv.github.io/etcd-druid-skills/)

<p>
  <a href="https://seshachalam-yv.github.io/etcd-druid-skills/"><img src="https://img.shields.io/badge/website-GitHub%20Pages-blue.svg" alt="Website"></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-Apache--2.0-blue.svg" alt="License"></a>
  <a href=".claude-plugin/plugin.json"><img src="https://img.shields.io/badge/version-0.3.1-green.svg" alt="Version"></a>
  <a href="docs/evaluation.md"><img src="https://img.shields.io/badge/eval%20pass%20rate-96%25-brightgreen.svg" alt="Eval Pass Rate"></a>
  <a href="https://github.com/obra/superpowers"><img src="https://img.shields.io/badge/Inspired%20by-Superpowers-orange" alt="Inspired by Superpowers"></a>
</p>

A Claude Code plugin that makes your AI coding agent a capable etcd-druid contributor — not just a code writer, but a workflow-following engineer who knows the two-commit rule, picks the right test framework per repo, protects generated files, and won't push without your approval.

Without this plugin, an LLM working in etcd-druid makes the same mistakes every new contributor makes: editing `zz_generated_*` files, using the wrong test framework, skipping `make revendor`, placing CEL validation in the wrong file, jumping straight to code without a plan. This plugin encodes 15+ known footguns and a gated plan → implement → review workflow so those mistakes never reach your PR.

When you start a session in any etcd-druid, etcd-backup-restore, or etcd-wrapper checkout, the plugin auto-detects the repo, reads the relevant `docs/development/` guide, and activates the right skills — no configuration required.

## ⚡ Without vs. With This Plugin

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

## 📋 Requirements

| Requirement | Minimum |
|-------------|---------|
| Claude Code | 1.x (any version with plugin support) |
| Claude model | `claude-sonnet-4-5` or newer (Haiku floor was raised; Opus recommended for `plan` and `implement`) |
| Repos supported | `gardener/etcd-druid`, `gardener/etcd-backup-restore`, `gardener/etcd-wrapper` |
| OS | macOS, Linux (anywhere Claude Code runs) |

The plugin auto-detects which repo you are in at session start. It does not modify any repo files — all changes are in your Claude Code session context.

## 🚀 Installation

### Claude Code (Marketplace)

```bash
/plugin marketplace add seshachalam-yv/etcd-druid-skills
/plugin install etcd-druid-skills@seshachalam-yv-etcd-druid-skills
```

<details>
<summary><strong>Manual install (settings.json)</strong></summary>

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

</details>

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

## 🔄 Workflow

```
 Issue / Bug Report / Feature Request
       │
       ▼
 ┌───────────────── /etcd-druid:brainstorm ──────────────────┐
 │  Understand intent → explore → clarify → confirm approach │
 └────────────────────────────┬──────────────────────────────┘
                              │
                              ▼
 ┌─────────────────────── /etcd-druid:plan ───────────────────────┐
 │  Read issue → explore upstream → design approach → write plan  │
 │  Self-review: spec coverage, placeholders, type consistency    │
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

 ─── Standalone path (debug/tdd → finish) ───

 debug / tdd ──→ /etcd-druid:finish ──→ PR / push / keep / discard
```

### 🔗 Skill Interactions

```
brainstorm ──► plan ──► implement ──┬──► api-change*  ──► CEL, two-commit, CRD tests
                  │                 ├──► tdd*         ──► Red-Green-Refactor per repo
                  │                 ├──► review*      ──► 15 footguns, Prow labels
                  │                 ├──► e2e          ──► KIND, custom images, CI
                  │                 └──► verification ──► run → read → then claim
                  │
                  └──► Gate 1                 debug* ──► tdd ──► finish ──► PR
                                              finish ──► Gate 2 (standalone path)

dep ──► plan (after DEP is approved, creates implementation plan)

   * = auto-activates on .go edits
```

The core loop is **brainstorm → plan → Gate 1 → implement → Gate 2 → PR**. The standalone path is **debug/tdd → finish → PR**.

### 🛠 Skills

**Planning & Execution**

| Skill | Invoke | Description |
|-------|--------|-------------|
| [brainstorm](skills/brainstorm/SKILL.md) | `/etcd-druid:brainstorm` | Explores intent, requirements, and constraints before planning. Surfaces assumptions, confirms approach. Use before `plan` for ambiguous or multi-repo changes. |
| [plan](skills/plan/SKILL.md) | `/etcd-druid:plan` | Issue intake → approach selection → code plan with WHEN/THEN acceptance criteria. Inline self-review catches placeholders and consistency bugs. Outputs an approved plan file. **Gate 1** blocks all code until you approve. |
| [implement](skills/implement/SKILL.md) | `/etcd-druid:implement` | Worktree setup → per-task subagent loop (implementer → spec-reviewer → code-reviewer) → CI verify → PR draft. **Gate 2** blocks push until you approve. |
| [finish](skills/finish/SKILL.md) | `/etcd-druid:finish` | Completes a development branch after standalone debug/tdd sessions. Verifies tests, presents 4 options (PR/push/keep/discard), provenance-based cleanup. |

**Domain-Specific**

| Skill | Invoke | Auto-activates | Description |
|-------|--------|----------------|-------------|
| [api-change](skills/api-change/SKILL.md) | `/etcd-druid:api-change` | `api/**/*.go` edits | Field design, CEL validation (field-scoped + cross-field), kubebuilder markers, two-commit generate workflow, CRD integration tests |
| [tdd](skills/tdd/SKILL.md) | `/etcd-druid:tdd` | `*.go` edits | Red-Green-Refactor per repo; correct framework (Go native for druid/wrapper, Ginkgo v2 for backup-restore); fake client patterns; testing anti-patterns |
| [debug](skills/debug/SKILL.md) | `/etcd-druid:debug` | `*.go` edits | 6-phase root cause analysis, Delve, per-repo log analysis, build failure triage |
| [e2e](skills/e2e/SKILL.md) | `/etcd-druid:e2e` | — | KIND cluster setup, custom sidecar image builds, IMAGEVECTOR_OVERWRITE, pre-PR CI, evidence sessions with per-pod monitoring |

**Quality & Reference**

| Skill | Invoke | Auto-activates | Description |
|-------|--------|----------------|-------------|
| [review](skills/review/SKILL.md) | `/etcd-druid:review` | `*.go` edits | 10-step checklist, 15 known footguns, Prow labels, release notes; runs as an isolated read-only subagent |
| [dep](skills/dep/SKILL.md) | `/etcd-druid:dep` | — | Guide writing or review Druid Enhancement Proposals; 20-dimension rubric covering cross-repo impact, feature gates, breaking changes, CEL validations, Mermaid diagrams |
| [reference](skills/reference/SKILL.md) | `/etcd-druid:reference` | — | Make targets, file paths, feature gates, CLI flags, dependency management, cherry-pick workflow |
| [observations](skills/observations/SKILL.md) | `/etcd-druid:observations` | — | Triage plugin self-improvement findings: raise PR, skip, or dismiss |

**Cross-cutting (referenced by skills, not directly invocable)**

| Skill | Referenced by | Description |
|-------|--------------|-------------|
| [verification](skills/verification/SKILL.md) | tdd, debug, implement, review | 5-step evidence gate: run command → read output → then claim it passes. Prevents false completion claims. |
| [receiving-review](skills/receiving-review/SKILL.md) | implement, review | Handle maintainer feedback without sycophancy: verify before implementing suggestions. |

**Collaboration & Design**

| Skill | Invoke | Description |
|-------|--------|-------------|
| [glossary](skills/glossary/SKILL.md) | `/etcd-druid:glossary` | Domain terminology and context for the etcd-druid ecosystem. Provides consistent definitions across all skill interactions. |
| [grill](skills/grill/SKILL.md) | `/etcd-druid:grill` | Structured design interrogation — asks hard questions about your approach before you commit to implementation. |
| [prototype](skills/prototype/SKILL.md) | `/etcd-druid:prototype` | Rapid proof-of-concept validation. Build the smallest thing that tests your riskiest assumption. |
| [agent-brief](skills/agent-brief/SKILL.md) | `/etcd-druid:agent-brief` | Generate focused context briefs for sub-agents. Ensures dispatched agents have exactly the context they need. |

## 💡 Philosophy

**Iron Laws, not reminders.** Each skill opens with one unconditional rule and a table of the rationalizations that cause violations. Addressing the thought pattern ("this task is too small for a plan") is more effective than repeating the abstract principle.

**Workflow orchestrator, not code library.** Code patterns and conventions live in each repo's `docs/development/`. The plugin tells Claude where to look and when to look — it never duplicates what the repos already document.

**Plugin self-improvement.** Every session is evaluated asynchronously. Specific gaps (wrong claim, missing footgun, stale flag) are captured as structured observations. At the next session, you triage: raise a PR, skip, or dismiss. No PR is ever raised without your explicit choice.

**Assumption surfacing before action.** The `plan` skill requires Claude to state every assumption explicitly before proposing approaches. Silent interpretation is the most common AI coding failure — this prevents it.

### ⚖️ Iron Laws

| Skill | Law |
|-------|-----|
| brainstorm | NO PLAN WITHOUT CONFIRMED INTENT |
| plan | NO CODE BEFORE GATE 1 |
| implement | NO PUSH BEFORE GATE 2 |
| finish | NO PR WITHOUT PASSING TESTS |
| dep | EVERY DEP IS REVIEWED FROM THREE REPO PERSPECTIVES |
| tdd | NO IMPLEMENTATION CODE BEFORE A FAILING TEST |
| debug | NO FIX ATTEMPT WITHOUT A REPRODUCIBLE FAILURE FIRST |
| review | NO VERDICT WITHOUT READING THE DIFF AND docs/development/ FIRST |
| verification | NO COMPLETION CLAIMS WITHOUT FRESH VERIFICATION EVIDENCE |

## 📊 Evaluation

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

## 🧩 The Component System

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

## 🔧 Compatibility

| Plugin version | etcd-druid | etcd-backup-restore | etcd-wrapper | Claude Code |
|----------------|-----------|---------------------|--------------|-------------|
| `0.1.x` | `v0.22+` | `v0.30+` | `v0.7+` | Any version with plugin support |

The plugin targets the current `master` branch of each repo. For older release branches, skills still apply but some make targets and file paths may differ — consult that branch's `docs/development/`.

## 💬 Getting Help

1. **Check the reference skill first** — `/etcd-druid:reference` covers make targets, file paths, flags, and git workflow for all three repos.
2. **Review the evaluation guide** — [`docs/evaluation.md`](docs/evaluation.md) explains how the plugin is tested and how to reproduce results.
3. **Search existing issues** — [github.com/seshachalam-yv/etcd-druid-skills/issues](https://github.com/seshachalam-yv/etcd-druid-skills/issues)
4. **Open a new issue** — include the skill name, what you expected, and what actually happened.

For questions about the underlying etcd ecosystem (not the plugin), the best places are the [Gardener community page](https://gardener.cloud/community/) and the respective repo's GitHub Discussions.

## 🤝 Contributing

**Skill workflow fixes:** Edit `skills/<name>/SKILL.md` and open a PR against this repo.

**Code patterns and conventions:** Contribute to the relevant repo's `docs/development/` — that is the authoritative source.

**New cross-cutting guides:** Add a skill with `user-invocable: false` in frontmatter, then reference it from relevant skills' Handoff sections.

**Testing changes:** Run a real session that exercises the workflow. Skills are behavior-shaping code — a change that looks correct may cause the agent to shortcut in unexpected ways. See [docs/evaluation.md](docs/evaluation.md) for the formal evaluation framework.

## 📄 License

Apache-2.0
