---
name: finish
description: Use when implementation is complete and tests pass — PR creation, branch push, or cleanup. Use after standalone debug/tdd sessions or when you have uncommitted work ready to ship. Do not use mid-implementation.
user-invocable: true
effort: low
---

# Finishing Development Work

Complete a development branch by verifying, presenting options, and executing the chosen path.

## ⛔ Iron Law

**NO PR WITHOUT PASSING TESTS.**

| Rationalization | Why it fails |
|---|---|
| "CI will catch it" | CI runs after the PR is open — broken PRs block reviewers |
| "It's just a docs change" | Docs changes can break generated content. Verify |
| "Tests passed earlier" | Earlier is not now. Run them |

## When to Use

- After a standalone `debug` session produced a fix
- After a `tdd` session has green tests and implementation
- When you have commits on a feature branch ready to ship
- When `implement` Phase 4 would be overkill (no plan file, no Gate 1)

## When NOT to Use

- Mid-implementation (use `implement` Phase 4 instead)
- Before tests pass (fix tests first)
- On `master` or `upstream/master` (nothing to finish)

## Workflow

### Step 1: Verify

Run the verification gate (`skills/verification/SKILL.md`). If it fails, fix before proceeding.

### Step 2: Determine Context

```bash
# What branch am I on?
git branch --show-current

# What's the diff against master?
git diff --stat upstream/master...HEAD

# How many commits?
git log --oneline upstream/master..HEAD
```

### Step 3: Present Options

Show the user:
- Branch name and commit count
- `git diff --stat` summary
- Test results from Step 1

Then present:

**"Ready to complete. Choose one:
  A) Create PR — I push and open it now
  B) Push branch only — I push; you write the PR description
  C) Keep as-is — stop here, leave the branch
  D) Discard — I will confirm before deleting"**

### Step 4: Execute

- **A** → Follow PR Creation from `skills/implement/PHASE-4-PR.md`
- **B** → `git push origin <branch>` ; print compare URL; stop
- **C** → Stop. Report worktree path for later use
- **D** → Follow Option D (provenance-based cleanup) from `skills/implement/PHASE-4-PR.md`

## Red Flags — Stop and Re-read

| Thought | Why it fails |
|---|---|
| "I'll push first, then fix the test" | Broken pushes block reviewers. Fix first |
| "The worktree is messy, just delete it" | Commits may be valuable. Always offer Keep before Discard |
| "I'll squash later" | Squash now. Messy history in PRs wastes reviewer time |
| "This is too small for a PR" | If you made commits, it's worth a PR. Small PRs merge fastest |

## Handoff

- PR created → work is done (monitor CI, respond to review via `skills/receiving-review/SKILL.md`)
- Branch pushed without PR → user writes PR description manually
- Kept as-is → worktree remains for later use
- Discarded → clean state, no further action
