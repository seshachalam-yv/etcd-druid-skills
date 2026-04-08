---
name: receiving-review
description: Guide for handling incoming code review feedback — referenced by implement and review. Not user-invocable.
user-invocable: false
---

# Receiving Code Review Feedback

## ⛔ Iron Law

**NO FEEDBACK IMPLEMENTATION WITHOUT INDEPENDENT VERIFICATION FIRST.**

| Rationalization | Why it fails |
|---|---|
| "The maintainer said so" | Maintainers can be wrong. Verify the suggestion against the code. |
| "It's a small change, just do it" | Small unverified changes introduce bugs. Verify first. |
| "I don't want to push back" | Implementing wrong suggestions wastes more time than clarifying. |
| "They probably mean X" | Probably is not a basis for changing code. Ask if unclear. |

## Process

### Step 1: Receive — Read every comment fully

Read the full comment thread before acting on any single comment.
A later comment may clarify or supersede an earlier one.

### Step 2: Categorize each comment

| Category | Definition | Action |
|----------|-----------|--------|
| **Must fix** | Correctness issue, convention violation, missing requirement | Verify and implement |
| **Should fix** | Quality improvement, clarity, better pattern | Verify and implement unless it conflicts with something |
| **Opinion** | Style preference with no clear right answer | Note it, respond with reasoning, do not implement without discussion |
| **Unclear** | Cannot determine what change is being requested | Ask before implementing |

### Step 3: Verify each must-fix and should-fix independently

Do NOT trust that the suggestion is correct just because a maintainer made it.

For each suggestion:
1. Read the referenced code
2. Confirm the issue exists as described
3. Confirm the proposed fix is actually correct
4. If the suggestion conflicts with `docs/development/` conventions — flag it explicitly

### Step 4: Implement verified fixes

One fix per commit. Commit message: `Address review feedback: <what was changed> (#NNNN)`.

Apply the verification gate (`skills/verification/SKILL.md`) after each batch of fixes.

After all fixes are committed, re-run CI locally before responding:

| Repo | Command |
|------|---------|
| etcd-druid | `make ci-checks && make test-unit` |
| etcd-backup-restore | `make check && make test-unit` |
| etcd-wrapper | `make check && make test` |

Gate: CI must pass before posting responses to the PR thread.

### Step 5: Respond with evidence

For each comment:
- **Implemented:** "Done in commit <sha> — <one sentence what changed>"
- **Not implemented (opinion):** "I kept the original approach because <reason>"
- **Unclear:** "Can you clarify — are you asking for X or Y?"

## Unclear Feedback Gate

If a comment cannot be acted on unambiguously, stop and ask:

> "I want to make sure I understand your feedback on [file:line]. Are you asking for [interpretation A] or [interpretation B]?"

Do not guess. Do not implement the wrong thing and hope for the best.

## Handoff

Once all Must-fix and Should-fix comments are addressed and CI passes:

1. Push the fixes: `git push origin <branch>`
2. Re-request review on the PR: `gh pr edit <number> --add-reviewer <reviewer>`
3. Post a top-level PR comment summarising what changed:
   > "All feedback addressed. Summary: [list each Must/Should-fix item and the commit sha that resolved it]"

If all feedback was Opinion or Unclear (nothing to implement): respond inline and do not re-request review — wait for the reviewer to continue the thread.

When the PR is approved: return to `/etcd-druid:implement` Phase 3 to complete Gate 2 and merge.
