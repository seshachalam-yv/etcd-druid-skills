# Git Workflow & Branch Naming

## Git Workflow

```bash
# Create worktree (under .worktrees/, gitignored)
git worktree add .worktrees/etcd-druid-issue-{id} \
  -b feat/issue-{id}/{short-description} upstream/master

# Commit style (no trailing period)
git commit -m "Add foo to bar component (#1350)"

# PR (from worktree, after human approval)
gh pr create --title "Add foo to bar component" --body "..." --base master
```

## Branch Naming

```
feat/issue-{issue-id}/{short-description}   (features/enhancements)
fix/issue-{issue-id}/{short-description}     (bugfixes)
Example: feat/issue-1350/add-configmap-ttl
```
