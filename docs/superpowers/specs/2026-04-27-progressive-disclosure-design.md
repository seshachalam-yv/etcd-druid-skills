# Progressive Disclosure: Split Long SKILL.md Files

**Date:** 2026-04-27
**Status:** Draft
**Motivation:** Reduce token consumption by splitting large SKILL.md files into hub + supplementary files. Inspired by patterns in mattpocock/skills.

## Problem

SKILL.md files range from 222-502 lines. Every invocation loads the entire file into context, wasting tokens on reference material the agent doesn't need for the current task.

## Approach

Hub-and-spoke model. Each SKILL.md becomes a workflow hub that links to supplementary files via relative markdown links. The agent loads the hub first; supplementary files are read only when the topic comes up.

## Conventions

- Hub line limits: ~100 for reference-heavy skills, ~150 for workflow-heavy skills
- Supplementary file naming: SCREAMING-CASE (e.g., `CEL-VALIDATION.md`, `FOOTGUNS.md`)
- Existing files renamed to SCREAMING-CASE for consistency
- One level deep: SKILL.md links to supplementary files, supplementary files do not link deeper
- Link format: `[CEL-VALIDATION.md](CEL-VALIDATION.md)` (relative markdown links)

## What Stays in the Hub

- Frontmatter (name, description, user-invocable, effort, paths)
- Iron Law + rationalization table
- Worktree gate reference
- Workflow overview / phase structure
- Cross-skill handoff sections

## What Moves to Supplementary Files

- Reference tables (make targets, CEL syntax, tooling versions)
- Domain-specific knowledge (failure patterns, footguns, test patterns)
- Templates (plan file template, PR checklist)
- Phase-specific details that are only needed when executing that phase

## Skill-by-Skill Split

### 1. `reference` (502 -> ~50 hub + 7 files)

| File | Content |
|---|---|
| `SKILL.md` | Routing table, current git state, staleness warning, skills summary |
| `REPO-PATHS.md` | Source locations for all 3 repos + dev guides |
| `MAKE-TARGETS.md` | Make targets + test commands per repo |
| `GIT-WORKFLOW.md` | Worktree setup, commit style, branch naming per repo |
| `ETCDOPSTASK.md` | OpsTask controller, state machine, druidctl |
| `API-CHANGELOG.md` | Feature gates, recent API additions, BR flags, wrapper flags |
| `DEPENDENCY-MANAGEMENT.md` | Multi-module structure, vendoring, dependabot, Go upgrades per repo |
| `TOOLING-VERSIONS.md` | Version table per repo + cross-container contracts |

### 2. `api-change` (428 -> ~120 hub + 4 files)

| File | Content |
|---|---|
| `SKILL.md` | Iron Law, worktree gate, Steps 1-4 (choose file, design field, add markers, two-commit) |
| `CEL-VALIDATION.md` | Field-scoped, cross-field, immutability CEL patterns + `has()` guard details |
| `CEL-QUICK-REFERENCE.md` | CEL syntax cheat sheet |
| `CRD-TESTING.md` | Test location, skip guard, table-driven pattern, what-to-test matrix |
| `PR-REQUIREMENTS.md` | Examples/docs updates, CI pipeline verification, PR checklist, red flags |

### 3. `implement` (456 -> ~130 hub + 2 new + 3 renamed)

| File | Content |
|---|---|
| `SKILL.md` | Iron Law, workflow overview, Phase 1 (worktree), Phase 2 (task loop dispatch) |
| `PHASE-3-VERIFICATION.md` | Phase 3: ci-checks gate, fix-loop, Gate 2 presentation |
| `PHASE-4-PR.md` | Phase 4: PR creation, receiving-review handoff, post-merge cleanup |
| `IMPLEMENTER-PROMPT.md` | Renamed from `implementer-prompt.md` |
| `SPEC-REVIEWER-PROMPT.md` | Renamed from `spec-reviewer-prompt.md` |
| `CODE-REVIEWER-PROMPT.md` | Renamed from `code-reviewer-prompt.md` |

### 4. `e2e` (374 -> ~100 hub + 3 files)

| File | Content |
|---|---|
| `SKILL.md` | Iron Law, workflow overview, KIND cluster setup, image build basics |
| `SIDECAR-OVERRIDES.md` | Custom image builds for BR/wrapper, sidecar override patterns |
| `RUNNING-E2E.md` | Test execution commands, provider matrix, debugging failures |
| `MULTI-REPO-E2E.md` | Cross-repo e2e patterns (druid + BR + wrapper together) |

### 5. `debug` (288 -> ~140 hub + 2 files)

| File | Content |
|---|---|
| `SKILL.md` | Iron Law, 5-phase workflow (reproduce, isolate, hypothesize, fix, verify) |
| `COMMON-FAILURES.md` | Domain-specific failure patterns: reconciliation loops, backup errors, CRD issues |
| `DEBUG-COMMANDS.md` | Diagnostic commands, log patterns, envtest tricks |

### 6. `review` (266 -> ~120 hub + 2 files)

| File | Content |
|---|---|
| `SKILL.md` | Iron Law, review workflow, diff reading process, verdict format |
| `FOOTGUNS.md` | The 15 known footguns |
| `REVIEW-CHECKLIST.md` | Pattern validation checklist, common review findings |

### 7. `plan` (222 -> ~130 hub + 1 file)

| File | Content |
|---|---|
| `SKILL.md` | Iron Law, work type classification, research phase, plan structure, Gate 1 |
| `PLAN-TEMPLATE.md` | Plan file template with all required sections |

## Reference Updates Required

- `implement/SKILL.md` -- update paths to 3 renamed prompt files
- `tdd/SKILL.md` -- update path to renamed anti-patterns file
- Cross-skill references that point to specific sections should point to the new supplementary file

## Out of Scope

Skills already under 150 lines are unchanged:
- `verification` (59 lines)
- `receiving-review` (94 lines)
- `worktree-gate` (161 lines)
- `observations` (174 lines)

## Totals

- 19 new supplementary files created
- 4 existing files renamed to SCREAMING-CASE
- 7 SKILL.md files rewritten as hubs
- Hub sizes: 50-140 lines (all within limits)

## Risk

- Cross-skill references may break if not updated comprehensively
- Mitigation: grep all SKILL.md files for references to renamed/moved content after implementation
