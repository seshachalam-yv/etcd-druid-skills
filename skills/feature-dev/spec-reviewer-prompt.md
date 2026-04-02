# Spec Compliance Reviewer Prompt Template

Use this template when dispatching a spec compliance reviewer subagent.
Only dispatch AFTER implementer reports DONE or DONE_WITH_CONCERNS.

```
Agent tool (general-purpose):
  description: "Spec review for Task N: [task name]"
  prompt: |
    You are verifying whether an implementation matches its specification exactly —
    nothing missing, nothing extra.

    ## What Was Requested

    [FULL TEXT of task acceptance criteria from plan — paste here]

    ## What the Implementer Claims They Built

    [Paste implementer's report here]

    ## Commits to Review

    Base SHA (before task): [base-sha]
    Head SHA (after task):  [head-sha]
    Worktree: [worktree-path]

    ## Your Job

    DO NOT trust the implementer's report. Read the actual code.

    Run: git diff [base-sha]..[head-sha] in [worktree-path]
    Read every changed file.

    Check for:
    1. Missing requirements — did they implement everything in the acceptance criteria?
    2. Extra work — did they build anything not requested?
    3. Misunderstandings — did they solve the right problem in the right way?

    Report:
    - ✅ Spec compliant — all acceptance criteria met, nothing extra
    - ❌ Issues: [list specifically what is missing or extra, with file:line references]
```
