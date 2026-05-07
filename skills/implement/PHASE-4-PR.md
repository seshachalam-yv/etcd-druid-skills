# Phase 4: PR Creation, Multi-Repo Changes, and Cherry-Picks

## Red Flags — Stop and Re-read the Iron Law

| Thought | Why it fails |
|---|---|
| "All local checks pass — Gate 2 is a formality" | Gate 2 is for the human to review intent and diff, not just test results |
| "The per-task code-reviewer already approved — skip the final review" | The code-reviewer sees one task. The final review sees the complete change as a reviewer would |
| "CI will catch any issues after the PR is open" | CI runs after the PR is open — you block reviewers with a broken PR |
| "I only changed one small file" | Small API type changes and generated files are highest risk |

---

## GATE 2: PR Approval

STOP. No push. No `gh pr create`.

**Who approves:** The human — by choosing A, B, C, or D. Do not self-select an option.

Present:
- PR title (imperative, sentence case, no trailing period)
- PR body draft (see format below)
- `git diff --stat upstream/master...HEAD`
- Full commit list

**PR body:** Read `.github/pull_request_template.md` in the repo and fill it in exactly — Prow bots read the `/area` and `/kind` lines. Do not invent the section names or format from memory.

Before drafting the body, run:
```bash
gh pr list --state merged --repo gardener/etcd-druid --limit 5
```
Find 1-2 merged PRs of the same kind (api-change, bug, enhancement) and read their bodies with `gh pr view <number>`. Mirror the tone, `/area` choice, release note category, and level of detail that the team uses — not a generic template.

**Before pushing:** rebase against `upstream/master` and squash to a minimal number of commits (`git rebase upstream/master`).

Say: **"Ready to create PR. Choose one:
  A) Create PR — I push and open it now
  B) Push branch only — I push; you write the PR description
  C) Make changes — tell me what to fix
  D) Discard — I will confirm before deleting"**

Handle:
- **A** → Phase 4 PR Creation (below)
- **B** → `git push origin <branch>`; print compare URL; stop
- **C** → fix → re-verify → Gate 2 again
- **D** → confirm "Are you sure? This deletes the worktree and branch." → on second confirmation: `git worktree remove` + `git branch -d`

---

## PR Creation

```bash
cd <worktree-path>
git push origin feat/issue-{id}/{short-description}
gh pr create \
  --base master \
  --title "<approved title>" \
  --body "<approved body>"
```

Show the PR URL.
For handling incoming review feedback after the PR is open, follow `skills/receiving-review/SKILL.md`.

---

## Subagent Status Handling

| Status | Action |
|--------|--------|
| DONE | Proceed to spec review |
| DONE_WITH_CONCERNS | Read concerns. Correctness/scope issue → fix first. Observation only → note and proceed |
| NEEDS_CONTEXT | Provide missing context and re-dispatch implementer. NEEDS_CONTEXT = information only the human has |
| BLOCKED | More context → re-dispatch with stronger model → break task smaller → escalate to human. BLOCKED = task appears impossible as specified |

**Never dispatch multiple implementer subagents in parallel.** Concurrent writes to the same worktree cause conflicts and corrupt the branch history. Always wait for one to complete (or report BLOCKED/NEEDS_CONTEXT) before dispatching the next.

### When parallel agents ARE appropriate

The ban on parallel implementers applies only to tasks writing to the same worktree.
Parallel agents are appropriate when tasks have no shared write state:

| Scenario | Safe to parallelize? |
|----------|---------------------|
| Two implementers on the same worktree | NO — git conflicts |
| Implementer + spec-reviewer | YES — reviewer is read-only |
| Implementer + code-reviewer | YES — reviewer is read-only |
| Fix lint in unrelated packages across separate worktrees | YES — separate branches |
| Run tests in etcd-druid + etcd-backup-restore simultaneously | YES — separate repos |
| Two read-only exploration agents | YES — no writes |

**Rule:** if both agents could write to the same file path at the same time, serialize. Otherwise, parallelize freely.

**Enforcement:** You MUST dispatch spec-reviewer and code-reviewer in a single message containing two Agent tool calls — not in separate messages. Dispatching them sequentially when they are both read-only violates this rule. If you dispatched them in separate messages, you serialized unnecessarily.

---

## Multi-Repo Changes

Some changes span multiple repos (e.g., a new API field in etcd-druid + a new flag in etcd-backup-restore + a config change in etcd-wrapper). The etcd version upgrade flow (`UpgradeEtcdVersion`) is a canonical example.

### When to suspect a multi-repo change

- Adding a new field to `EtcdSpec` that affects sidecar behaviour
- Changing backup/restore semantics (snapshot format, compression, storage)
- Changing etcd configuration that flows through the wrapper
- Any change related to `UpgradeEtcdVersion`, `--next-cluster-version-compatible`, or `--store-endpoint-override`

### Multi-repo workflow

1. **Identify the dependency chain.** etcd-druid depends on etcd-backup-restore and etcd-wrapper via image vector (`internal/images/images.yaml`). Changes flow:
   ```
   etcd-backup-restore (or etcd-wrapper) → image released → etcd-druid image vector updated
   ```

2. **Plan per-repo.** The code plan (in `/etcd-druid:plan` Phase 2) must list tasks per repo with explicit cross-repo dependencies.

3. **Separate PRs per repo.** Each repo gets its own PR. Never combine cross-repo changes into a single PR.

4. **Test each repo independently first:**
   ```bash
   # In etcd-backup-restore fork:
   make verify && make ci-e2e-kind

   # In etcd-wrapper fork:
   make test && make check

   # In etcd-druid fork:
   make ci-checks && make test-unit && make test-integration
   ```

5. **Integration test with custom images.** After individual tests pass, test the full stack together using `/etcd-druid:e2e` Scenario B (custom backup-restore) or C (custom wrapper) with `IMAGEVECTOR_OVERWRITE`.

6. **PR ordering.** Open the sidecar PR first (etcd-backup-restore or etcd-wrapper). Once merged and released, update the image vector in etcd-druid and open that PR.

7. **Vendoring.** etcd-backup-restore and etcd-wrapper use `go mod vendor`. After any dependency change: `make revendor`. etcd-druid does NOT vendor — use `make tidy`.

---

## POC / Prototype Workflow

For exploratory work or DEP validation that spans multiple repos without formal PRs:

### When to use POC mode
- Validating a DEP design end-to-end before writing the formal implementation
- Testing cross-repo integration (druid + backup-restore + wrapper)
- Exploring approaches where the design may change significantly

### POC workflow differences
| Aspect | Formal | POC |
|--------|--------|-----|
| Branch | feat/issue-{id}/... | poc/{dep-id}/{description} |
| Reviews | Spec + code per task | Self-review only |
| CI gates | Full make ci-checks | Compile + targeted tests |
| E2e | make ci-e2e-kind | Manual KIND + kubectl verification |
| Commits | Atomic, reviewed | WIP allowed, squash later |
| Multi-repo | Separate PRs | Single worktree per repo, test together |

### Cross-repo POC testing
1. Build custom sidecar images with unique tags
2. Push to local KIND registry (localhost:5001)
3. Deploy druid with IMAGEVECTOR_OVERWRITE pointing to custom images
4. Verify flow manually with kubectl
5. Document findings for formal implementation plan

---

## Cherry-Pick / Hotfix Workflow

When a fix needs to be backported to a maintenance release branch (e.g., `hotfix-v0.35`, `hotfix-v0.36`):

### When to cherry-pick

- Bug fix merged to `master` that affects a released version
- Security patch needed on an older release
- The gardener-ci-robot creates automated cherry-pick PRs — if you see `[hotfix-vX.Y]` prefix PRs, this is the pattern

### Manual cherry-pick workflow

```bash
# Ensure you have the hotfix branch
git fetch upstream
git checkout -b hotfix-v0.36-fix-<short-desc> upstream/hotfix-v0.36

# Cherry-pick the squashed commit from master (most PRs are squash-merged)
git cherry-pick -x <commit-sha>
# If the commit is a merge commit (not squash-merged), use: git cherry-pick -x -m 1 <commit-sha>

# Resolve conflicts if any, then verify
make ci-checks && make test-unit

# Push and create PR targeting the hotfix branch
git push origin hotfix-v0.36-fix-<short-desc>
gh pr create --base hotfix-v0.36 --title "[hotfix-v0.36] <original title>" --body "..."
```

### Rules

- Cherry-pick PRs target the `hotfix-vX.Y` branch, NOT `master`
- PR title must be prefixed with `[hotfix-vX.Y]`
- The fix should already be merged to `master` first — backport, don't forward-port
- If the cherry-pick has conflicts, resolve them and note the conflict resolution in the PR body
- Run the same CI checks as a normal PR (`make ci-checks`, `make test-unit`)
