---
name: implement
description: Use after plan Gate 1 is approved — worktree setup, per-task subagent loop, verification, PR creation. Requires an approved plan file from /etcd-druid:plan. Do not use for planning, designing approaches, or writing tests only.
user-invocable: true
effort: high
---

# Implementing etcd-druid Work

Execute an approved plan from worktree setup to merged PR. Entry point: an approved plan file path. Two hard gates: Gate 1 already passed (plan approved), Gate 2 before push.

## ⛔ Iron Law

**NO PUSH BEFORE GATE 2.**

| Rationalization | Why it fails |
|---|---|
| "The CI will catch it" | CI runs after the PR is open — you block reviewers with a broken PR |
| "All local checks pass" | Gate 2 is for the human to review the full diff, not just test results |
| "It's a small change" | Small changes in API types and generated files are highest risk |

## Workflow Overview

```dot
digraph implement {
    rankdir=TB;
    "Plan approved (Gate 1 done)" [shape=doublecircle];
    "Phase 1: Worktree Setup" [shape=box];
    "Phase 2: Implement Task" [shape=box];
    "Spec review ✅?" [shape=diamond];
    "Code review ✅?" [shape=diamond];
    "More tasks?" [shape=diamond];
    "Phase 3: Verify" [shape=box];
    "All checks pass?" [shape=diamond];
    "GATE 2: PR Approval" [shape=diamond style=filled fillcolor=red fontcolor=white];
    "Phase 4: PR Creation" [shape=box];

    "Plan approved (Gate 1 done)" -> "Phase 1: Worktree Setup";
    "Phase 1: Worktree Setup" -> "Phase 2: Implement Task";
    "Phase 2: Implement Task" -> "Spec review ✅?";
    "Spec review ✅?" -> "Phase 2: Implement Task" [label="no - fix"];
    "Spec review ✅?" -> "Code review ✅?" [label="yes"];
    "Code review ✅?" -> "Phase 2: Implement Task" [label="no - fix"];
    "Code review ✅?" -> "More tasks?" [label="yes"];
    "More tasks?" -> "Phase 2: Implement Task" [label="yes"];
    "More tasks?" -> "Phase 3: Verify" [label="no"];
    "Phase 3: Verify" -> "All checks pass?";
    "All checks pass?" -> "Phase 3: Verify" [label="no - dispatch fix"];
    "All checks pass?" -> "GATE 2: PR Approval" [label="yes"];
    "GATE 2: PR Approval" -> "Phase 4: PR Creation" [label="approved"];
    "GATE 2: PR Approval" -> "Phase 3: Verify" [label="changes requested"];
}
```

---

## Context Management

Large plans and long implementation sessions fill the context window, causing lost requirements and wrong approaches. Use these patterns to stay within limits.

**Plan-on-disk pattern (default):** The plan file lives on disk (`docs/plans/`), not in conversation context. The orchestrator reads only the current task from the plan file before dispatching each subagent — never load the full plan into context.

**Subagent isolation:** Each implementer subagent gets a clean context window. It reads ~6,000 tokens of task-relevant files but returns a ~400-token summary — 93% context savings for the orchestrator. Always prefer dispatching a fresh subagent over accumulating context in the orchestrator.

**Proactive compaction:** After each task completes and before dispatching the next subagent, evaluate whether the orchestrator context is growing heavy. If it is, compact with focus instructions:
```
/compact Focus on current task requirements and recent test results
```

**The two-corrections rule:** If a subagent has been corrected twice on the same issue, do not retry in the same context. Dispatch a fresh subagent with a better prompt that incorporates what was learned from the failures.

**Commit often:** Commit after each completed task. This creates restore points and keeps the working state clean for the next subagent.

---

## Phase 1: Worktree Setup

Read the plan file first. Extract: fork root, issue number, task list.

**API Delta check:** Scan the plan's task list. If any task's Files list includes a path containing `api/core/v1alpha1/` and the plan has no `## API Delta` section, stop and tell the user:
> "This plan touches API types but has no `## API Delta` section. Please add one (one row per field added, modified, or removed) before I proceed."
Do not create the worktree until the API Delta section exists.

Branch name is derived at worktree-creation time: `feat/issue-{id}/{short-description}` (or `fix/issue-{id}/{short-description}` for bugfixes) — it is not in the plan file.

```bash
cd <fork-root>
git fetch upstream

# Safety: ensure worktree directory is gitignored before creating it
git check-ignore -q .worktrees || {
  echo '.worktrees/' >> .gitignore
  git add .gitignore
  git commit -m "Add .worktrees/ to .gitignore"
}

git worktree add .worktrees/etcd-druid-issue-{id} \
  -b feat/issue-{id}/{short-description} upstream/master
```

Worktree path: `<fork-root>/.worktrees/etcd-druid-issue-{id}`
Branch: `feat/issue-{id}/{short-description}` (or `fix/issue-{id}/{short-description}` for bugfixes)

After creating the worktree, run setup and verify a clean baseline:

```bash
cd <worktree-path>
go mod download

# Verify baseline is clean — new failures mean pre-existing problems, not yours
make test-unit
```

If baseline tests fail: report to user and ask whether to proceed or investigate first.
Do not start implementation on a broken baseline.

Pass worktree path to all subagents.

---

## Parallel Wave Execution

For new sidecar or binary work where the plan groups tasks into independent dependency waves:

1. Identify tasks within each wave that write to non-overlapping directories
2. Launch those tasks as parallel agents (safe when no shared write paths)
3. After all agents in a wave complete, run `go test -count=1 -race ./internal/... ./cmd/...` to verify the wave
4. Only proceed to the next wave after verification passes
5. Fix any failures immediately before continuing

Observed ~60% reduction in one 17-package sidecar build (5h → 2h). Not a universal speedup — only effective when tasks are genuinely non-overlapping and the plan is structured into explicit waves.

The sequential subagent loop (Phase 2 below) remains the default for incremental work where tasks are small and dependencies are tight.

---

## Phase 2: Per-Task Implementation

**Model selection:**

| Task type | Model |
|-----------|-------|
| Test-only change, single file | sonnet |
| New component method, 2–3 files | sonnet |
| API change, new component, multi-file, debugging | opus |

Repeat for each task:

**Before dispatching any subagent — build the readiness matrix:**

1. **Backfill from plan file (handles resume):**
   Read the plan file. For every task showing `- [x]` in the plan file that is not
   yet `completed` in TaskList, call `TaskUpdate` to mark it completed now.
   This makes TaskList accurate for the current session regardless of whether this
   is a fresh start or a resumed session.

2. **Evaluate readiness:**
   For each task, classify:
   - ✅ `completed` — plan file shows `[x]` for this task
   - 🔓 `ready` — all `depends-on` tasks are ✅, or `depends-on: —`
   - 🔒 `blocked` — at least one `depends-on` task is not yet ✅

3. **Render the matrix:**

   ```
   Task Readiness — YYYY-MM-DD — docs/plans/<plan-file>.md

     ✅  Task 1 — <name>    [completed]
     🔓  Task 2 — <name>    [ready]
     🔒  Task 3 — <name>    [blocked — waiting on Task 2]

   Starting with Task 2.
   ```

4. **All-complete guard:** If all tasks show ✅, display the matrix and skip the
   per-task loop entirely — proceed directly to Phase 3 Verify.
   Message: "All tasks already complete. Proceeding to Phase 3 verification."

5. **Start** with the first 🔓 `ready` task. If no task is ready (all blocked),
   stop and report to the user: which tasks are blocked and what they are waiting for.

**a.** Mark task `in_progress` (TaskUpdate)

**b.** Dispatch implementer subagent — see `./implementer-prompt.md`.
   Pass: full task text, worktree path, issue number, files affected, whether API generation is needed.
   The implementer prompt instructs subagents to follow `skills/tdd/SKILL.md` — no separate instruction needed.

**c.** Show implementer report to user.

**d.** Dispatch spec-reviewer — see `./spec-reviewer-prompt.md`.
   Pass: acceptance criteria, implementer report, base SHA, head SHA, worktree path.

**e.** Spec issues → implementer fixes → spec-reviewer re-reviews → repeat until ✅

**f.** Dispatch code-reviewer — see `./code-reviewer-prompt.md`.
   Pass: implementer report, base SHA, head SHA, worktree path.
   Only after spec-reviewer ✅.

**g.** Quality issues → implementer fixes → code-reviewer re-reviews → repeat until ✅

**h.** Mark task `completed` (TaskUpdate) AND edit the plan file to flip this task's
   checkbox from `- [ ]` to `- [x]`:

   ```bash
   # In the plan file at <fork-root>/docs/plans/<plan-file>.md
   # Find the line: - [ ] Task N: <name>
   # Change it to:  - [x] Task N: <name>
   ```

   Both must happen together. TaskUpdate tracks state for the current session;
   the plan file checkbox is the durable cross-session record.
   Do not mark a task complete in TaskUpdate without also flipping the checkbox.

**i.** Next task.

---

## Phase 3: Verify

Run in worktree:

```bash
cd <worktree-path>
make ci-checks          # format + lint (runs on main module)
make test-unit          # unit tests (Go native + Ginkgo suites)
make test-integration   # integration tests with envtest (if integration work done)
```

For API changes, also verify generation is clean:
```bash
cd <worktree-path>/api
make check-generate     # confirms make generate produces no uncommitted diff
```

All must pass. Any failure → dispatch fix subagent with full failure output.
Do not proceed to Gate 2 until clean.

**CI pipeline check (required before Gate 2):**

Run the full CI suite per repo — not just local tests:

| Repo | CI command |
|------|-----------|
| etcd-druid | `make ci-checks && make test-unit` (+ `make test-integration` if touched) |
| etcd-backup-restore | `make revendor && make verify` (revendor is required — vendored deps) |
| etcd-wrapper | `make revendor && make check && make test` (revendor is required — vendored deps) |

If any CI job fails, dispatch a fix subagent with the full failure output. Gate 2 is never presented with failing CI.

**Verification discipline:** Apply the verification gate (`skills/verification/SKILL.md`). Do not claim "all checks pass" based on a previous run or inference.

**E2e verification — decide based on change type:**

| Change type | E2e needed? | Action |
|---|---|---|
| Test-only, no behaviour change | No | Skip |
| Controller logic, component method | Yes | Find matching e2e test, run it targeted |
| New API field, new feature | Yes | Find or write e2e test, run `make ci-e2e-kind` |
| Bug fix with reproduction steps | Yes | Run the specific e2e scenario that reproduces the bug |
| etcd-backup-restore or etcd-wrapper change | Yes | Build custom image, override in druid, run e2e — see `/etcd-druid:e2e` Scenario B or C |

**How to find the right e2e test:**
```bash
# List e2e test functions in etcd-druid
grep -r "func Test" test/e2e/ --include="*.go"

# Find tests related to your change (e.g. configmap, statefulset, backup)
grep -r "TestEtcd\|func Test" test/e2e/ --include="*.go" | grep -i <your-component>

# Run only the relevant test
make PROVIDERS="none,local" \
     GO_TEST_ARGS="-run TestEtcdReconcilerWithNoBackup -v" \
     test-e2e
```

**If no e2e test covers the feature:** note it in the PR's "Special notes for reviewer" section. Opening a follow-up issue for e2e coverage is acceptable; blocking the PR for it is not required unless the change is high-risk.

**Handoff:** Before presenting Gate 2, invoke `/etcd-druid:review` for a final whole-diff review.
This is distinct from the per-task code-reviewer subagent — it reviews the complete change as a human reviewer would see it.
`review` runs as an isolated read-only subagent (`context: fork`) — results are summarized back to this session.
Gate 2 only after review returns LGTM.

---

## Red Flags — Stop and Re-read the Iron Law

| Thought | Why it fails |
|---|---|
| "All local checks pass — Gate 2 is a formality" | Gate 2 is for the human to review intent and diff, not just test results |
| "The per-task code-reviewer already approved — skip the final review" | The code-reviewer sees one task. The final review sees the complete change as a reviewer would |
| "CI will catch any issues after the PR is open" | CI runs after the PR is open — you block reviewers with a broken PR |
| "I only changed one small file" | Small API type changes and generated files are highest risk |

---

## ⛔ GATE 2: PR Approval

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
Find 1–2 merged PRs of the same kind (api-change, bug, enhancement) and read their bodies with `gh pr view <number>`. Mirror the tone, `/area` choice, release note category, and level of detail that the team uses — not a generic template.

**Before pushing:** rebase against `upstream/master` and squash to a minimal number of commits (`git rebase upstream/master`).

Say: **"Ready to create PR. Choose one:
  A) Create PR — I push and open it now
  B) Push branch only — I push; you write the PR description
  C) Make changes — tell me what to fix
  D) Discard — I will confirm before deleting"**

Handle:
- **A** → Phase 4
- **B** → `git push origin <branch>`; print compare URL; stop
- **C** → fix → re-verify → Gate 2 again
- **D** → confirm "Are you sure? This deletes the worktree and branch." → on second confirmation: `git worktree remove` + `git branch -d`

---

## Phase 4: PR Creation

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
