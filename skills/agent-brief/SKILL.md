---
name: agent-brief
description: Use when writing GitHub issues for etcd-druid, etcd-backup-restore, or etcd-wrapper — generates durable, behavioral issue descriptions with complete acceptance criteria. Use for new issues, not for existing well-formed ones.
user-invocable: true
effort: low
---

# Agent Brief: Durable Issue Descriptions

Generate GitHub issue descriptions that can be picked up by any contributor or AI agent without additional context.

## Iron Law

**NO ISSUE WITHOUT COMPLETE ACCEPTANCE CRITERIA.**

| Rationalization | Why it fails |
|---|---|
| "It's obvious what needs to happen" | Obvious to you right now. Not to someone picking this up in 3 months |
| "I'll clarify in comments later" | Comments get buried. The issue body is the source of truth |
| "The PR will make it clear" | The PR implements ONE interpretation. Acceptance criteria prevent wrong implementations |
| "It's just a small fix" | Small fixes with ambiguous scope become large PRs with review churn |

## Principles of a Good Agent Brief

1. **Durable** — no file paths or line numbers (these rot). Describe interfaces and behavioral contracts.
2. **Behavioral** — describe WHAT must be true, not HOW to implement it. "When X happens, Y should be observable" not "add a check in file Z".
3. **Complete acceptance criteria** — every criterion is falsifiable. Someone can verify pass/fail.
4. **Explicit scope boundaries** — "This issue does NOT cover: ..." prevents scope creep.
5. **Self-contained** — a reader unfamiliar with the conversation can understand the issue fully.

## Template

```markdown
## Context
<1-3 sentences: what exists today and why it's insufficient>

## Desired Behavior
<Behavioral description using WHEN/THEN format>

- WHEN <trigger/state>
- THEN <observable outcome>

## Acceptance Criteria
- [ ] <Falsifiable criterion 1>
- [ ] <Falsifiable criterion 2>
- [ ] <Falsifiable criterion 3>

## Scope Boundaries
This issue does NOT cover:
- <explicitly excluded thing 1>
- <explicitly excluded thing 2>

## Classification
- Type: bug | enhancement | refactoring
- Repos affected: etcd-druid | etcd-backup-restore | etcd-wrapper
- Breaking change: yes | no
- Test scope: unit | integration | e2e
```

## Anti-patterns (What Makes a BAD Issue)

| Bad Pattern | Why It Fails | Fix |
|------------|--------------|-----|
| "Fix the snapshot issue" | Which issue? No reproduction, no criteria | Add WHEN/THEN + acceptance criteria |
| "Refactor compactor.go" | File-path based, no behavioral goal | Describe the behavioral improvement |
| "Add error handling" | Where? For what? How much? | "WHEN X fails, THEN Y is returned with Z message" |
| "Similar to PR #123" | Requires reading another PR for context | Self-contained description |
| Acceptance criteria: "works correctly" | Not falsifiable | "returns StatusCondition Ready=True within 30s" |

## Workflow

1. Understand the change (read conversation/brainstorm context)
2. Classify: bug, enhancement, or refactoring
3. Write behavioral description (WHEN/THEN)
4. Write falsifiable acceptance criteria
5. Define scope boundaries explicitly
6. Generate the issue using `gh issue create`

## Scope Boundaries Guidance

Always include at least 2 "does NOT cover" items. Common boundaries:
- "Does not cover backward compatibility migration"
- "Does not cover metrics/alerting changes"
- "Does not cover documentation updates beyond code comments"
- "Does not cover other repos (scoped to etcd-druid only)"
- "Does not cover e2e test changes"

## Handoff

- Issue created → suggest `/etcd-druid:plan` for implementation
- Issue too large → recommend splitting into multiple agent briefs
- Issue is a bug → suggest adding reproduction steps, then `/etcd-druid:debug`
