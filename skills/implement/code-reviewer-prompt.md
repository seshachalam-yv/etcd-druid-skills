# Code Quality Reviewer Prompt Template

Use this template when dispatching a code quality reviewer subagent.
Only dispatch AFTER spec-reviewer returns ✅.

```
Agent tool (general-purpose):
  description: "Code review for Task N: [task name]"
  prompt: |
    You are reviewing code quality for an etcd-druid implementation task.

    ## What Was Implemented

    [Paste implementer's report here]

    ## Commits to Review

    Base SHA (before task): [base-sha]
    Head SHA (after task):  [head-sha]
    Worktree: [worktree-path]

    Run: git diff [base-sha]..[head-sha] -- in [worktree-path]
    Read every changed file before forming any opinion.

    ## How to Review

    Read `[worktree-path]/docs/development/` first — this is the authoritative
    source for conventions in this repo. Verify the diff against those docs.

    For each issue you find that has no corresponding documentation in
    `docs/development/`, note it as a **documentation gap** in your report.
    The next implementer pass should add it to the docs.

    ## Checklist

    For each item, verify against the actual diff — do not assume.

    ### Generated code (check before anything else)
    - [ ] No file with `// Code generated` header was manually edited
    - [ ] If api/core/v1alpha1/ was touched: `cd api && make generate` was run
          Evidence: zz_generated.deepcopy.go, crds/*.yaml, charts/crds/*.yaml in diff
    - [ ] Generated files are in a SEPARATE commit from the hand-written API change

    ### Operator interface (if new or modified component in internal/component/)
    - [ ] All four methods present with correct signatures (see docs/development/)
    - [ ] Component registered in internal/controller/etcd/reconciler.go

    ### Error handling (internal/component/ and internal/controller/)
    - [ ] Correct error wrapping used (see docs/development/ for pattern)
    - [ ] Error codes are typed string constants — not errors.New()
    - [ ] No silent swallowing (no `_ = err`, no empty if-err blocks)

    ### API changes (if api/core/v1alpha1/ touched)
    - [ ] CEL validation annotation present on new fields
    - [ ] CEL validation test added
    - [ ] examples/ updated if API surface changed

    ### Tests
    - [ ] Correct test framework for this repo — etcd-druid and etcd-wrapper use Go native `testing.T` + Gomega (NO Ginkgo); etcd-backup-restore uses Ginkgo v2
    - [ ] No gomock — fake client used
    - [ ] No time.Sleep() — Eventually/Consistently for async assertions
    - [ ] Table-driven for multiple scenarios

    ### Commit messages
    - [ ] Imperative verb, sentence case, no trailing period
    - [ ] Issue number at end: (#NNNN)
    - [ ] One commit per logical change

    ### Known footguns (check if the touched code is anywhere near these)
    - [ ] No new conditional check on `UseEtcdWrapper` feature gate — it is GA (locked true), so `Enabled(UseEtcdWrapper)` is always true. Any NEW check is dead code; flag if introduced.
    - [ ] No reference to removed `--enable-etcd-member-gc` or `--k8s-member-gc-duration` flags (etcd-backup-restore v0.42+)
    - [ ] No use of deprecated `PreferClose` in `ClientService.TrafficDistribution` — use `PreferSameZone` or `PreferSameNode`
    - [ ] If EtcdOpsTask controller touched: task state machine transitions are correct
          (Pending→InProgress→Succeeded/Failed/Rejected, FIFO, one active per cluster)
    - [ ] If `UpgradeEtcdVersion` feature gate used: properly gated behind featureGates.Enabled()

    ### Code quality
    - [ ] YAGNI: every new function, type, and parameter introduced by this task is actually used
          by this task. Flag anything that exists "for future use" or "for flexibility" — it is bloat.
    - [ ] No abstraction introduced for a single call site
    - [ ] No existing comment or code unrelated to this task was silently modified or removed
    - [ ] No overbuilding — only what the task asked for
    - [ ] Existing helpers used, not reimplemented
    - [ ] make ci-checks would pass

    ## Report Format

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
