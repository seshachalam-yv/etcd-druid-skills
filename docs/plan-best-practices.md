# Plan Best Practices

Guidelines for writing and executing plans that stay within context limits and avoid the common friction patterns observed across 96+ sessions.

## The Core Problem

Large monolithic plans consume context tokens throughout the entire implementation phase. Combined with file reads and command outputs, this fills the context window and causes Claude to lose track of requirements, edit wrong files, or take wrong approaches.

**Observed friction from usage data (1,686 messages across 96 sessions):**
- 37 wrong-approach events
- 28 buggy-code instances
- 19 misunderstood-request events
- Only 28% of tasks fully achieved; marathon sessions show diminishing returns

## Plan Size Guidelines

| Plan scope | Max lines | Strategy |
|------------|-----------|----------|
| Single file change | Skip plan | Direct implementation |
| 1-3 file change | ~30 lines | Inline checklist |
| 4-10 file change | ~100 lines | Task-level plan on disk |
| 10+ file change | Split into chunks | Multiple plans, one per subsystem |

**Rule of thumb:** If you can describe the diff in one sentence, skip the plan. If the plan exceeds 150 lines, break it up.

## Plan Structure

Follow the Superpowers plan format with granular, bite-sized steps:

```markdown
# [Feature Name] Implementation Plan

**Goal:** [One sentence]
**Architecture:** [2-3 sentences]
**Tech Stack:** [Key technologies]
---

## File Map

| File | Action | Purpose |
|------|--------|---------|
| `exact/path/to/file.go` | Modify | Add field |
| `exact/path/to/test.go` | Create | Unit test |

## Task 1: [Component Name]

**Files:**
- Modify: `exact/path/to/file.go:123-145`
- Test: `tests/exact/path/to/test.go`

- [ ] Write failing test
- [ ] Run test, confirm FAIL
- [ ] Implement change
- [ ] Run test, confirm PASS
- [ ] Commit
```

### Absolute Rules

- **No placeholders** — no TBD, TODO, "similar to Task N", "add appropriate handling"
- **Exact file paths** — prevents wrong-file edits (observed: editing `docs/pages/index.html` instead of root `index.html`)
- **Exact commands with expected output** — prevents guessing
- **2-5 minute steps** — each step is one action, independently verifiable

## Execution Patterns

### Pattern 1: Plan on Disk (Recommended)

Save plan to file → `/clear` → implement from file reference.

```
Session 1: Research → write plan → save to docs/plans/feature-x.md → /clear
Session 2: Read plan file → implement task 1 → commit → /clear
Session 3: Read plan file → implement task 2 → commit
```

**Why:** The plan lives on disk, not in conversation. Claude reads it on-demand instead of carrying it in context the whole time.

### Pattern 2: Subagent Per Task

Dispatch a fresh subagent for each task in the plan. Each subagent gets its own clean context window.

```
Main session: Read plan → dispatch subagent for Task 1 → review → dispatch for Task 2 → review
```

**Why:** Subagents read ~6,000 tokens of files but return ~400-token summaries. That is 93% context savings.

### Pattern 3: Phase-Gated Prompts

For tasks where you stay in one session, use explicit phase boundaries:

```
Phase 1 - Scope (max 3 minutes): List files to modify. STOP and wait for approval.
Phase 2 - Implement: Execute checklist. Run tests after each change. Max 2 fix attempts per failure.
Phase 3 - Verify: Full test suite. Summary table of changes.
```

**Why:** Prevents unbounded exploration (observed: 37 wrong-approach events, many from exploring too long before acting).

## Context Window Management

### Proactive Compaction

Run `/compact` with focus instructions before context gets heavy:

```
/compact Focus on the API field changes and test results
```

Add to your CLAUDE.md for automatic behavior:

```markdown
# Compact instructions
When compacting, preserve test output, code changes, and the current task from the plan.
```

### The Two Corrections Rule

If you have corrected Claude twice on the same issue in one session, the context is cluttered with failed approaches. Run `/clear` and restart with a better prompt that incorporates what you learned.

### Path-Scoped Rules

Move specialized instructions to `.claude/rules/` with path filters:

```markdown
---
paths:
  - "pkg/api/**/*.go"
---
Follow the two-commit rule: one commit adds the field, a second runs make generate.
```

These load only when Claude reads matching files, saving context for everything else.

## OpenSpec Integration (Optional)

For complex brownfield changes, consider using [OpenSpec](https://github.com/Fission-AI/OpenSpec) alongside the plan workflow:

```
openspec/changes/add-feature-x/
  proposal.md        # WHY and WHAT (intent, scope)
  specs/api/spec.md  # Delta specs (ADDED/MODIFIED/REMOVED)
  design.md          # HOW (architecture decisions)
  tasks.md           # Implementation checklist
```

**Key benefit:** Delta specs describe what changes relative to current behavior, not the whole system — ideal for the etcd-druid ecosystem where you are always modifying existing code.

## Anti-Patterns

| Anti-pattern | Problem | Fix |
|-------------|---------|-----|
| One plan for entire feature | Fills context, loses detail | Split into task-level plans |
| Plan in conversation only | Lost on `/compact` | Save to disk file |
| Exploring before planning | 37 wrong-approach events | Time-box exploration to 3 minutes |
| No verification commands | 28 buggy-code instances | Include exact `make test` / `go vet` commands |
| Placeholders in plan | Agent interprets freely | Write actual code in every step |
| Marathon single-session | Diminishing returns after ~45 min | `/clear` between tasks, commit often |
| Editing without confirming path | Wrong-file edits | Always state full file path in plan |

## Recommended CLAUDE.md Additions

Based on observed friction, add these to your project's CLAUDE.md:

```markdown
## Plan Execution
- For complex multi-file tasks, prefer systematic file-by-file changes over extensive exploration
- If exploration exceeds 3 minutes without producing code, pause and propose a plan
- After running `make generate`, always run `make test` synchronously before proceeding
- Always confirm the correct file path before editing — distinguish root files from docs/ subdirectories

## Gardener Workflow
- Follow the 8-step checklist: types → generate → constants → reconciler → tests → docs → test suite → commit
- Check existing Interface definitions before type-casting to unexported types
- Search for existing feature gate references with `grep -r` before starting implementation
```

## Further Reading

- [Superpowers writing-plans skill](https://github.com/obra/superpowers) — detailed plan format with TDD steps
- [OpenSpec by Fission-AI](https://github.com/Fission-AI/OpenSpec) — delta-based spec workflow for brownfield changes
- [Claude Code Best Practices](https://code.claude.com/docs/en/best-practices) — official context management guidance
- [Claude Code Context Window](https://code.claude.com/docs/en/context-window) — interactive visualization of token usage
