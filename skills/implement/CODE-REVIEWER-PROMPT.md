# Code Quality Reviewer Prompt Template

Use this template when dispatching a code quality reviewer subagent.
Only dispatch AFTER spec-reviewer returns ✅.

```
Agent tool (general-purpose):
  description: "Code review for Task N: [task name]"
  prompt: |
    You are reviewing code quality for an etcd-druid implementation task.

    ## CONTEXT
    Background — do not reproduce in your output.

    ### What Was Implemented

    [Paste implementer's report here]

    ### Commits to Review

    Base SHA (before task): [base-sha]
    Head SHA (after task):  [head-sha]
    Worktree: [worktree-path]

    Run: git diff [base-sha]..[head-sha] -- in [worktree-path]
    Read every changed file before forming any opinion.

    ---

    ## PROCEDURE
    Steps to follow — do not reproduce in your output.

    Read `[worktree-path]/docs/development/` first — this is the authoritative
    source for conventions in this repo. Verify the diff against those docs.

    For each issue you find that has no corresponding documentation in
    `docs/development/`, note it as a **documentation gap** in your report.
    The next implementer pass should add it to the docs.

    ---

    ## RULES
    Read only the sections that apply to this change. Skip sections whose conditions don't match.

    ### Always check (every review)

    #### Commit messages
    - [ ] Imperative verb, sentence case, no trailing period
    - [ ] Issue number at end: (#NNNN)
    - [ ] One commit per logical change

    #### Code quality
    - [ ] YAGNI: every new function, type, and parameter introduced by this task is actually used by this task. Flag anything that exists "for future use" or "for flexibility" — it is bloat.
    - [ ] No abstraction introduced for a single call site
    - [ ] No existing comment or code unrelated to this task was silently modified or removed
    - [ ] No overbuilding — only what the task asked for
    - [ ] Existing helpers used, not reimplemented
    - [ ] make ci-checks would pass

    #### Known footguns (check if the touched code is anywhere near these)
    - [ ] No new conditional check on `UseEtcdWrapper` feature gate — it is GA (locked true), so `Enabled(UseEtcdWrapper)` is always true. Any NEW check is dead code; flag if introduced.
    - [ ] No reference to removed `--enable-etcd-member-gc` or `--k8s-member-gc-duration` flags (etcd-backup-restore v0.42+)
    - [ ] No use of deprecated `PreferClose` in `ClientService.TrafficDistribution` — use `PreferSameZone` or `PreferSameNode`
    - [ ] No use of deprecated `StoreSpec` secret-based endpoint config — use `spec.backup.store.endpointOverride` (druid) / `--store-endpoint-override` (etcd-backup-restore)
    - [ ] If EtcdOpsTask controller touched: task state machine transitions are correct (Pending→InProgress→Succeeded/Failed/Rejected, FIFO, one active per cluster); `OnDemandSnapshot` is also auto-triggered during hibernation (replicas=0) and `UpgradeEtcdVersion` flow — new trigger paths must not conflict with these
    - [ ] If `UpgradeEtcdVersion` feature gate used: properly gated behind featureGates.Enabled()
    - [ ] No explicit `--compress-snapshots=true` added — snapshot compression is on by default in etcd-backup-restore v0.40+
    - [ ] etcd-backup-restore or etcd-wrapper dependency change: `make revendor` was run (not just `go mod tidy`)

    ---

    ### If you touched `api/core/v1alpha1/` (API change)

    #### Generated code
    - [ ] No file with `// Code generated` header was manually edited
    - [ ] If api/core/v1alpha1/ was touched: `cd api && make generate` was run. Evidence: zz_generated.deepcopy.go, crds/*.yaml, charts/crds/*.yaml in diff
    - [ ] Generated files are in a SEPARATE commit from the hand-written API change

    #### API changes
    - [ ] CEL validation annotation present on new fields
    - [ ] CEL validation test added
    - [ ] If plan contains `## API Delta`: verify each row's field name, change type (ADDED/MODIFIED/REMOVED), and Breaking status matches the actual diff. Flag any row where the diff contradicts the table.
    - [ ] examples/ updated if API surface changed

    ---

    ### If you touched `internal/component/` or `internal/controller/`

    #### Operator interface (component changes only)
    - [ ] All four methods present with correct signatures (see docs/development/)
    - [ ] Component registered in internal/controller/etcd/reconciler.go

    #### Error handling
    - [ ] Correct error wrapping used (see docs/development/ for pattern)
    - [ ] Error codes are typed string constants — not errors.New()
    - [ ] No silent swallowing (no `_ = err`, no empty if-err blocks)

    ---

    ### If you wrote or modified tests

    #### Tests
    - [ ] Correct test framework for this repo — etcd-druid and etcd-wrapper use Go native `testing.T` + Gomega (NO Ginkgo); etcd-backup-restore uses Ginkgo v2
    - [ ] No gomock — fake client used
    - [ ] No time.Sleep() — Eventually/Consistently for async assertions
    - [ ] Table-driven for multiple scenarios

    ---

    ## OUTPUT
    Fill in every section. Do not skip any.

    **Strengths:** [what was done well]

    **Issues:**
    - Critical (must fix before merge): [file:line — description]
    - Important (should fix): [file:line — description]
    - Suggestion (nice to have): [file:line — description]

    **Documentation gaps and plugin mistakes:**
    For each convention found in code but absent from docs/development/, OR each place
    where this plugin's skill/prompt told you something incorrect:

    - Describe the gap or mistake
    - State whether the fix belongs in:
      - `docs/development/<file>.md` in the repo (missing convention), OR
      - `skills/<skill>/SKILL.md` in the etcd-druid-skills plugin (wrong guidance)

    For any plugin mistake, output a ready-to-use PR suggestion:

    ```
    Plugin PR suggestion
    gh pr create \
      --repo seshachalam-yv/etcd-druid-skills \
      --base master \
      --title "Fix <what was wrong> in <skill name> skill" \
      --body $'
    /kind bug

    **What this PR does / why we need it:**
    <describe what the skill said vs. what is actually correct>

    **Discovered while:** <context>

    **Fix:** <what the skill should say instead>
    '
    ```

    **Assessment:** ✅ Approved | ❌ Changes required
```
