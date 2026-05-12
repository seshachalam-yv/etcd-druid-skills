---
name: grill
description: Use after brainstorm confirms an approach but before writing the code plan — relentlessly stress-tests the design through edge cases, failure modes, and domain-specific gotchas. Hardens plans against surprises.
user-invocable: true
effort: low
---

# Grill: Stress-Test Before You Plan

Relentlessly interview the design to surface edge cases, failure modes, and wrong assumptions BEFORE they become code.

## Iron Law

**NO PLAN WITHOUT STRESS-TESTING THE DESIGN FIRST.**

| Rationalization | Why it fails |
|---|---|
| "The approach is straightforward" | Straightforward approaches hide failure modes in the gaps between steps |
| "We already brainstormed" | Brainstorming confirms intent. Grilling challenges robustness |
| "I'll handle edge cases during implementation" | Edge cases discovered during implementation cause rework and scope creep |
| "The tests will catch problems" | Tests verify what you thought of. Grilling finds what you didn't |

## When to Use

- After `/etcd-druid:brainstorm` confirms an approach, before `/etcd-druid:plan`
- When a design involves state transitions, ordering, or concurrency
- When the change spans multiple components or repos
- When you feel confident — confidence without grilling is overconfidence

## When NOT to Use

- Single-file bug fix with clear reproduction → go to `/etcd-druid:debug`
- Intent is still unclear → stay in `/etcd-druid:brainstorm`
- Plan is already written and approved → too late, proceed with implementation

## Workflow

### Step 1: State the Design in One Paragraph

Before grilling, write a concise summary of what will be built. This is the target.

### Step 2: Walk Each Branch

For every decision point in the design, ask:
- What happens on the **happy path**?
- What happens on **failure**?
- What happens on **timeout**?
- What happens on **concurrent access**?
- What happens on **partial completion** (crash midway)?

### Step 3: Domain-Specific Challenges

Ask these etcd-druid-specific questions:

**For reconciliation changes:**
- What if the Etcd CR is deleted mid-reconcile?
- What if another reconcile is triggered while this one is in progress?
- What if the StatefulSet is not yet ready when this runs?
- Does this respect the component ordering (PreSync → Sync)?

**For EtcdOpsTask changes:**
- What if a task is created while another is InProgress?
- What happens to the task on etcd-druid restart?
- Does the FIFO guarantee hold under this change?
- What is the timeout behavior? Who cleans up stale tasks?

**For backup-restore changes:**
- What if the snapstore is unreachable?
- What if a snapshot is corrupt?
- What if the delta log is ahead of the full snapshot?
- Does this work with immutable snapshots (Object Lock)?

**For etcd-wrapper changes:**
- What if backup-restore sidecar is not ready?
- What if embedded etcd fails to start after initialization?
- What happens on readiness probe timeout?

**For multi-repo changes:**
- Which repo must be released first?
- Can the new version of repo A work with the old version of repo B?
- Is there a version skew window where things break?

### Step 4: Challenge Assumptions

For each assumption in the design:
- "What if this assumption is wrong?"
- "When was this last verified?"
- "Is this documented or just folklore?"

Cross-reference with:
- `skills/glossary/CONTEXT.md` — are terms used precisely?
- `.out-of-scope/` — has this been rejected before?

### Step 5: One Question at a Time

Ask questions **one at a time**. Wait for an answer. Drill deeper if the answer is vague.

Good grilling questions:
- "What happens when X fails halfway through?"
- "You said Y — but what about Z?"
- "How does the operator know when to retry vs give up?"
- "What is the user-visible behavior during this transition?"

Bad questions (too vague):
- "Have you thought about edge cases?"
- "Is this robust?"
- "What could go wrong?"

### Step 6: Summarize Findings

After grilling, produce:

```markdown
## Grill Findings

### Edge Cases to Handle
1. <case> — <how the design addresses it or needs to>
2. ...

### Assumptions Validated
- <assumption> — confirmed by <evidence>

### Assumptions Challenged
- <assumption> — risk: <what could go wrong>

### Scope Additions (if any)
- <thing that needs to be in the plan that wasn't in the brainstorm>

### Out-of-Scope Confirmed
- <thing discussed but explicitly excluded>
```

## Red Flags — Stop and Grill Harder

| Signal | What it means |
|---|---|
| "It'll just work" | Untested assumption — challenge it |
| "We can handle that later" | Scope debt — decide now: in or out |
| Hand-wavy error handling | Ask: "what does the user see when this fails?" |
| No timeout mentioned | Ask: "what if this never completes?" |
| "Same as the existing pattern" | Verify: does the existing pattern actually handle this case? |

## Handoff

- All edge cases addressed → invoke `/etcd-druid:plan` with the grill findings as input
- Design has a fundamental flaw → go back to `/etcd-druid:brainstorm` with the finding
- Discovered a rejected approach → reference `.out-of-scope/<file>` and redirect
