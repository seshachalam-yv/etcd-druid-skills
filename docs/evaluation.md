# Plugin Evaluation Guide

How to reproduce and extend the evaluation of the etcd-druid-skills plugin.

## Overview

The evaluation tests the plugin against **5 real PR scenarios** from the Gardener etcd ecosystem. Each scenario simulates a developer starting work on a task that maps to an actual merged PR. The test runs the same prompt both **with the plugin** (reading skill files) and **without** (baseline), then grades the output against a set of assertions.

## Test Scenarios

| # | Scenario | Based on Real PR | Type |
|---|----------|-----------------|------|
| 1 | Add traffic distribution values to Etcd CRD | gardener/etcd-druid#1280 | API change |
| 2 | EtcdOpsTask snapshot on hibernation + version upgrade | gardener/etcd-druid#1300 | Feature dev |
| 3 | Fix EtcdOpsTask force-deletion + TTL | gardener/etcd-druid#1308 | Bug fix |
| 4 | Remove failBelowRevision from etcd-backup-restore | gardener/etcd-backup-restore#1013 | Refactoring |
| 5 | Fix copy operation race condition | gardener/etcd-backup-restore#1001 | Enhancement |

## Prerequisites

- Claude Code CLI (`claude`) installed
- Access to `gardener/etcd-druid`, `gardener/etcd-backup-restore` repos (for `gh` commands)
- The etcd-druid-skills plugin installed locally

## How to Run

### 1. Review the eval definitions

```bash
cat skill-creator-workspace/plugin-eval/evals.json
```

Each eval has:
- `prompt` — the developer's request (same text every run)
- `expected_output` — what a good response should contain
- `assertions` — specific, graded pass/fail checks

### 2. Run a single eval (with plugin)

```bash
# Create output directory
mkdir -p skill-creator-workspace/plugin-eval/iteration-N/eval-1-api-change/with_skill/outputs/

# Launch Claude with the plugin skill path
claude -p "Execute this task:
- Skill path: $(pwd)
- Task: <paste prompt from evals.json>
- Save outputs to: $(pwd)/skill-creator-workspace/plugin-eval/iteration-N/eval-1-api-change/with_skill/outputs/

Read the relevant SKILL.md files from skills/ and follow them.
Save your complete response as a markdown file in the outputs directory."
```

### 3. Run a single eval (baseline — no plugin)

```bash
mkdir -p skill-creator-workspace/plugin-eval/iteration-N/eval-1-api-change/without_skill/outputs/

claude -p "Execute this task without any special skills or plugin guidance:
Task: <paste prompt from evals.json>
Save your complete response to: $(pwd)/skill-creator-workspace/plugin-eval/iteration-N/eval-1-api-change/without_skill/outputs/response.md
Do NOT read any files from the skills/ directory."
```

### 4. Grade the results

Read each output file and check each assertion from `evals.json`:
- **PASS** — the output satisfies the assertion (quote evidence)
- **FAIL** — the output does not satisfy the assertion

### 5. Run multiple iterations

Repeat steps 2-4 for iterations 1-5 with identical prompts. Compare pass rates across iterations to measure consistency.

## Assertion Types

| Type | What it checks |
|------|---------------|
| `workflow` | Correct skill invoked, correct phase followed |
| `convention` | Domain-specific convention mentioned (two-commit rule, make revendor, etc.) |
| `completeness` | All required artifacts mentioned (tests, docs, examples) |
| `correctness` | Right files/repos/components identified |
| `planning` | Structured plan with tasks, dependencies, acceptance criteria |
| `discipline` | Iron Laws followed (reproduce before fix, plan before code) |
| `safety` | Anti-patterns avoided (no manual CRD edits, no wrong repo) |

## Interpreting Results

- **>90% with-plugin:** Plugin is working well for this scenario
- **<70% with-plugin:** Gap in the skill definitions — investigate which assertions fail
- **Baseline matches with-plugin:** Assertion is non-discriminating (both pass or both fail)
- **Same assertion fails across iterations:** Structural gap, not flakiness — fix the skill

## Adding New Scenarios

To add a new test scenario based on a real PR:

1. Find a substantive PR (not dependency bump, not hotfix):
   ```bash
   gh pr list --repo gardener/etcd-druid --state merged --limit 30
   gh pr view <number> --json title,body,files
   ```

2. Write a prompt that simulates the developer's starting point — as if the PR hadn't been written yet

3. Define 5-6 assertions covering workflow, conventions, and completeness

4. Add to `evals.json` and run iterations 1-5

## Directory Structure

```
skill-creator-workspace/plugin-eval/
├── evals.json                          # Test definitions + assertions
├── cross-iteration-report.md           # Consistency analysis across all iterations
├── iteration-1/
│   ├── grading-report.md               # Detailed per-assertion grades
│   ├── eval-1-api-change/
│   │   ├── with_skill/outputs/         # Plugin output
│   │   └── without_skill/outputs/      # Baseline output
│   ├── eval-2-feature/
│   │   ├── with_skill/outputs/
│   │   └── without_skill/outputs/
│   └── ...
├── iteration-2/                        # Targeted re-runs after fixes
├── iteration-3/                        # Full run with fixed plugin
├── iteration-4/                        # Consistency check
└── iteration-5/                        # Consistency check
```

## Results Summary (2026-04-21)

| Eval | Plugin (Iter 3-5 avg) | Baseline | Lift |
|------|----------------------|----------|------|
| API Change | 100% | 33% | +67pp |
| Feature Dev | 100% | 67% | +33pp |
| Bug Fix | 80% | 40% | +40pp |
| Refactoring | 100% | 33% | +67pp |
| Enhancement | 100% | 83% | +17pp |
| **Average** | **96%** | **52%** | **+44pp** |

Cross-iteration variance: **zero** (iterations 3-5 produced identical assertion results).
