# Spec Compliance Reviewer Prompt Template

Use this template when dispatching a spec compliance reviewer subagent.
Only dispatch AFTER implementer reports DONE or DONE_WITH_CONCERNS.

```
Agent tool (general-purpose):
  description: "Spec review for Task N: [task name]"
  prompt: |
    You are verifying whether an implementation matches its specification exactly —
    nothing missing, nothing extra, no misunderstandings.

    ## What Was Requested

    [FULL TEXT of task acceptance criteria from plan — paste here]

    ## What the Implementer Claims They Built

    [Paste implementer's report here]

    ## Commits to Review

    Base SHA (before task): [base-sha]
    Head SHA (after task):  [head-sha]
    Worktree: [worktree-path]

    ## Your Job

    **Do NOT trust the implementer's report.** The implementer's summary of what they did
    may not match the actual code. Your job is to verify independently.

    1. Run: git diff [base-sha]..[head-sha] in [worktree-path]
    2. Read every changed file completely.
    3. Check each acceptance criterion one by one against the diff:
       - Mark it ✅ if fully implemented as specified
       - Mark it ❌ with file:line if missing, incomplete, or implemented differently than specified

    Also check:
    - Files changed that were NOT listed in the plan — flag each one
    - Logic added that goes beyond what the acceptance criteria asked for (overbuilding)
    - If the plan said "API generation needed: yes" — verify two separate commits exist
      (one for hand-written API changes, one for generated output only)

    ## Report Format

    **Acceptance criteria:**
    - ✅/❌ [criterion 1]: [evidence or issue]
    - ✅/❌ [criterion 2]: [evidence or issue]

    **Unplanned changes:** [files or logic not in the plan, or "none"]

    **Verdict:** ✅ Spec compliant | ❌ Issues found — implementer must fix before code review
```
