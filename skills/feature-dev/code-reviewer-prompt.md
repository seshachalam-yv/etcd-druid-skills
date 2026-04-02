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

    Run: git diff [base-sha]..[head-sha] in [worktree-path]
    Read every changed file before forming any opinion.

    ## etcd-druid Conventions Checklist

    For each item, check the actual code — do not assume:

    Operator interface (if new component):
    - [ ] PreSync implemented with correct signature
    - [ ] Sync implemented with correct signature
    - [ ] TriggerDelete implemented with correct signature
    - [ ] GetExistingResourceNames implemented with correct signature
    - [ ] Registered in createAndInitializeOperatorRegistry()

    API changes (if api/core/v1alpha1/ touched):
    - [ ] CEL validation annotation present (+kubebuilder:validation:XValidation)
    - [ ] make generate was run (zz_generated.deepcopy.go updated)

    RBAC:
    - [ ] +kubebuilder:rbac markers added for any new resource verbs

    Error handling (internal/component/ code):
    - [ ] druiderr.WrapError() used (NOT fmt.Errorf) — import druiderr "github.com/gardener/etcd-druid/internal/errors"
    - [ ] Error vars are package-level: var ErrGetFoo = errors.New("ErrGetFoo")
    - [ ] No silent error swallowing (no _ = err, no empty catch)

    Status updates:
    - [ ] r.Status().Update() used, not r.Update() for status fields

    Finalizers:
    - [ ] controllerutil.ContainsFinalizer checked before cleanup

    Tests:
    - [ ] Go native testing.T (no Ginkgo in etcd-druid)
    - [ ] Gomega assertions used (import . "github.com/onsi/gomega")
    - [ ] No gomock — fake client used: testutils.CreateTestFakeClientForObjects() or testutils.NewTestClientBuilder()
    - [ ] OperatorContext constructed with: component.NewOperatorContext(ctx, logr.Discard(), uuid.NewString())
    - [ ] No time.Sleep() — Eventually/Consistently used for async
    - [ ] Table-driven tests for multiple scenarios

    Commit messages:
    - [ ] Sentence case, imperative, no trailing period
    - [ ] Issue number appended: (#NNNN)

    ## Report Format

    **Strengths:** [what was done well]

    **Issues:**
    - Critical (must fix before merge): [list with file:line]
    - Important (should fix): [list with file:line]
    - Suggestion (nice to have): [list with file:line]

    **Assessment:** ✅ Approved | ❌ Changes required
```
