---
name: brainstorm
description: Use before plan when the user asks for a feature or significant change — explores intent, requirements, and constraints before planning. Do not use for bug fixes with clear reproduction or trivial one-file changes.
user-invocable: true
effort: low
---

# Brainstorming etcd-druid Changes

Explore what the user actually wants before committing to a plan. Prevents planning the wrong thing.

## ⛔ Iron Law

**NO PLAN WITHOUT CONFIRMED INTENT.**

| Rationalization | Why it fails |
|---|---|
| "The issue is clear enough" | Issues describe symptoms. You need to understand intent |
| "I know what they want" | You have a hypothesis. Confirm it |
| "Planning will clarify things" | Planning locks in assumptions. Brainstorming surfaces them |
| "This is obvious" | "Obvious" precedes most wrong implementations |

## When to Use

- User says "add X", "implement Y", "we need Z"
- GitHub issue is ambiguous or has multiple possible approaches
- Change spans multiple repos (etcd-druid + etcd-backup-restore + etcd-wrapper)
- You're unsure which component is affected

## When NOT to Use

- Bug fix with clear stack trace and reproduction steps → go directly to `/etcd-druid:debug`
- Single-file test addition → go directly to `/etcd-druid:tdd`
- User explicitly says "just do it" or provides exact implementation details
- User has already brainstormed and is asking for a plan

## Workflow

### Step 1: Understand the Request

Read the issue or user message. Before anything else, state:
- What you think they're asking for (one sentence)
- What's ambiguous or unclear
- What assumptions you're making

### Step 2: Explore (Read-Only)

```bash
# Which component is affected?
find internal/component/ internal/controller/ -name "*.go" | head -20

# Has this been done before? Check merged PRs
gh pr list --state merged --repo gardener/etcd-druid --search "<keywords>" --limit 5
```

### Step 3: Clarify

Ask the user 1-3 focused questions. Domain questions, not implementation questions.

Good: "Should this field be optional or required?"
Bad: "Should I use a pointer or value type?"

### Step 4: Propose Approaches

For simple changes: state the approach and ask for confirmation.
For complex changes: present 2-3 options with trade-offs.

Always include:
- Scope (which repos, which components)
- Breaking change? (API compatibility)
- Test scope (unit / integration / e2e)

### Step 5: Confirm and Handoff

Once the user confirms an approach:

Say: **"Approach confirmed. Invoking `/etcd-druid:plan` to create the implementation plan."**

Then invoke `/etcd-druid:plan` with the confirmed context.

## Red Flags — Stop and Re-read

| Thought | Why it fails |
|---|---|
| "I already know what to build" | You have a hypothesis. Confirm it costs 30 seconds |
| "The user will correct me in plan review" | Plan review is for plan quality, not intent discovery |
| "Brainstorming is overkill for this" | 3 clarifying sentences is not overkill. A wrong plan is |
| "Let me just start exploring code" | Exploration without intent leads to rabbit holes |

## Handoff

- Approach confirmed → invoke `/etcd-druid:plan` with context
- User says "just do it" with enough detail → skip to `/etcd-druid:plan` directly
- Scope turns out to be a bug → redirect to `/etcd-druid:debug`
- Scope turns out to be test-only → redirect to `/etcd-druid:tdd`
