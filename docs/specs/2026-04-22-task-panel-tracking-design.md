# Task Panel Tracking for etcd-druid Skills

> **Status:** Approved design — not yet implemented.
> **Date:** 2026-04-22

## Problem

The Claude Code task panel (blue bar at bottom showing tasks with status icons) is driven by `TaskCreate`/`TaskUpdate` tools. Superpowers' brainstorming skill explicitly instructs Claude to create tasks for each phase, giving users visual progress tracking. The etcd-druid skills have clear phases and checklists but never instruct Claude to create tasks — the panel stays empty.

## Goal

Add explicit `TaskCreate`/`TaskUpdate` instructions to each etcd-druid skill so users see workflow progress in the task panel, matching the Superpowers experience.

## Design Principle

Follow the Superpowers brainstorming pattern:
- Place a `## Checklist` section near the top of each skill
- Use the exact phrase: **"You MUST create a task for each of these items and mark each completed as you finish it"**
- List items as a numbered list matching the skill's natural phases
- Mark tasks `in_progress` when starting, `completed` when done

Skills that are short lookups (reference) or non-user-invocable (verification, receiving-review) do NOT need task tracking.

---

## Skill-by-Skill Design

### 1. `plan` (HIGH IMPACT)

**Current state:** Line 38 says "Create tasks for all workflow phases with TaskCreate" but is vague — no explicit list of what tasks to create.

**Change:** Replace line 38 with a full checklist section after the Iron Law block:

```markdown
## Checklist

You MUST create a task for each of these items and mark each completed as you finish it:

1. Read and quote the issue
2. Explore upstream code
3. State assumptions
4. Ask clarifying questions
5. Propose 2-3 approaches
6. Confirm approach with user
7. Write code plan to file
8. GATE 1 — present plan for approval
9. Handoff to implement
```

---

### 2. `implement` (HIGH IMPACT)

**Current state:** References `TaskUpdate` at lines 163 and 182 for per-task tracking, and has backfill logic (lines 131-136) for resume. But never creates the initial task list.

**Change:** Add a checklist section before Phase 1:

```markdown
## Checklist

You MUST create tasks for all phases with TaskCreate before starting work:

1. Read plan file and extract tasks
2. Set up worktree
3. Verify baseline tests pass
4. [Dynamic: after reading the plan, create one task per plan task]
5. Run verification suite (Phase 3)
6. Final review (invoke /etcd-druid:review)
7. GATE 2 — present for PR approval
8. Create PR
```

The dynamic tasks (step 4) are created after reading the plan file in Phase 1. Each plan task becomes a TaskCreate call with subject matching the plan task name. The existing TaskUpdate calls at lines 163/182 remain unchanged — they mark these dynamic tasks in_progress/completed.

---

### 3. `api-change` (MEDIUM IMPACT)

**Current state:** No task tracking. 8 sequential steps.

**Change:** Add checklist:

```markdown
## Checklist

You MUST create a task for each of these items and mark each completed as you finish it:

1. Choose file and struct (read API Delta)
2. Design field with markers
3. Add validation annotations (CEL)
4. Two-commit generate workflow
5. Write CRD validation tests
6. Update examples/ and docs/
7. CI pipeline verification
8. PR requirements check
```

---

### 4. `debug` (MEDIUM IMPACT)

**Current state:** No task tracking. 6 phases.

**Change:** Add checklist:

```markdown
## Checklist

You MUST create a task for each of these items and mark each completed as you finish it:

1. Read the error carefully
2. Reproduce consistently
3. Locate in source
4. Form single hypothesis
5. Fix root cause and verify
6. Commit fix (or escalate if 3+ failures)
```

---

### 5. `tdd` (LOW IMPACT)

**Current state:** No task tracking. Red-Green-Refactor cycle.

**Change:** Add checklist. TDD is cyclical, so tasks represent one cycle:

```markdown
## Checklist

You MUST create a task for each of these items and mark each completed as you finish it:

1. Write failing test (Red)
2. Write minimal code to pass (Green)
3. Refactor while staying green
4. Commit passing test group
```

Note: For multiple TDD cycles, create a fresh set of tasks for each cycle.

---

### 6. `review` (LOW IMPACT)

**Current state:** No task tracking. 10-step checklist but runs as a single pass.

**Change:** Add checklist:

```markdown
## Checklist

You MUST create a task for each of these items and mark each completed as you finish it:

1. Read diff, docs, and similar merged PRs
2. Check operator interface completeness
3. Check error handling
4. Check API changes
5. Check RBAC markers
6. Check status updates and finalizers
7. Check tests
8. Check commit messages
9. Check docs and PR body
10. Check known footguns
11. Issue verdict
```

---

### 7. `e2e` (LOW IMPACT)

**Current state:** No task tracking. 3 scenarios (A, B, C) — user picks one.

**Change:** Add conditional checklist based on scenario:

```markdown
## Checklist

After the user selects a scenario, create tasks for that scenario's steps.

**Scenario A tasks:**
1. Build and load etcd-druid image
2. Create KIND cluster
3. Run automated e2e
4. Verify results and cleanup

**Scenario B tasks:**
1. Create KIND cluster (B0)
2. Build etcd-backup-restore image
3. Push to local registry
4. Override sidecar image in etcd-druid
5. Run integrated e2e pipeline
6. Run etcd-backup-restore own e2e (optional)

**Scenario C tasks:**
1. Build etcd-wrapper image
2. Test with local dev scripts
3. Test via etcd-druid e2e with override
```

---

### 8. `observations` (LOW IMPACT)

**Current state:** No task tracking. 4-step triage.

**Change:** Add checklist:

```markdown
## Checklist

You MUST create a task for each of these items and mark each completed as you finish it:

1. Read and pre-verify all open observations
2. Present each verified observation for triage
3. Act on user choices (R/S/D)
4. Summary
```

---

### Skills that do NOT need task tracking

| Skill | Reason |
|-------|--------|
| `reference` | Pure lookup — no workflow phases |
| `verification` | Shared gate, not user-invocable, called inline by other skills |
| `receiving-review` | Not user-invocable, called by implement/review |

---

## Implementation Notes

- Each skill gets a `## Checklist` section placed after the `## Iron Law` section
- The checklist wording follows the Superpowers pattern exactly: "You MUST create a task for each..."
- No `activeForm` parameter needed (Superpowers doesn't use it either)
- Tasks are created at skill invocation, marked `in_progress` when starting, `completed` when done
- For `implement`, dynamic tasks from the plan file supplement the fixed phase tasks
- The plan skill's existing line 38 reference to TaskCreate is replaced by the explicit checklist

## Testing

After implementation, verify by invoking each skill and confirming:
1. Tasks appear in the blue panel at the bottom
2. Tasks transition through pending → in_progress → completed
3. The task list matches the skill's natural workflow phases
