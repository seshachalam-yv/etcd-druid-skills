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

    ## etcd-druid Conventions Checklist

    For each item, verify against the actual diff — do not assume.

    ### Generated code (CRITICAL — check before anything else)
    - [ ] No file with `// Code generated` header was manually edited
          Check: git diff [base-sha]..[head-sha] | grep "^+" | grep -v "^+++" | grep "Code generated"
          If any such file was hand-edited: Critical — instruct implementer to revert and run `cd api && make generate`
    - [ ] If api/core/v1alpha1/ was touched: `cd api && make generate` was run
          Evidence: zz_generated.deepcopy.go, api/core/v1alpha1/crds/*.yaml, charts/crds/*.yaml in diff
    - [ ] Generated files are in a SEPARATE commit from the hand-written API change
          (Commit 1: API types. Commit 2: `Run make generate`. They must be distinct commits.)

    ### Operator interface (if new or modified component in internal/component/)
    - [ ] PreSync(ctx OperatorContext, etcd *druidv1alpha1.Etcd) error — correct signature
    - [ ] Sync(ctx OperatorContext, etcd *druidv1alpha1.Etcd) error — correct signature
    - [ ] TriggerDelete(ctx OperatorContext, etcdObjMeta metav1.ObjectMeta) error — correct signature
    - [ ] GetExistingResourceNames(ctx OperatorContext, etcdObjMeta metav1.ObjectMeta) ([]string, error) — correct signature
    - [ ] Component registered via registry.Register() in internal/controller/etcd/reconciler.go

    ### Error handling (internal/component/ and internal/controller/)
    - [ ] druiderr.WrapError() used — import druiderr "github.com/gardener/etcd-druid/internal/errors"
    - [ ] Error codes are typed string constants: `const ErrGetFoo druidapicommon.ErrorCode = "ERR_GET_FOO"` — NOT errors.New()
    - [ ] apierrors.IsNotFound(err) used to skip not-found before wrapping
    - [ ] No silent swallowing (no `_ = err`, no empty if-err blocks)

    ### API changes (if api/core/v1alpha1/ touched)
    - [ ] CEL annotation present: `+kubebuilder:validation:XValidation:rule="...",message="..."`
    - [ ] CEL validation test added in test/it/crdvalidation/etcd/ or test/it/crdvalidation/etcdopstask/
    - [ ] examples/ updated if API surface changed

    ### RBAC
    - [ ] +kubebuilder:rbac markers added for any new resource/verb combinations

    ### Status updates and finalizers
    - [ ] r.Status().Update() used (not r.Update()) for status subresource fields
    - [ ] controllerutil.ContainsFinalizer checked before cleanup

    ### Tests
    - [ ] Go native testing.T — no Ginkgo in internal/component/ or internal/controller/etcd/
    - [ ] Gomega: `import . "github.com/onsi/gomega"`, `g := NewWithT(t)`
    - [ ] No gomock — testutils.CreateTestFakeClientForObjects() or testutils.NewTestClientBuilder()
    - [ ] OperatorContext: component.NewOperatorContext(ctx, logr.Discard(), uuid.NewString())
    - [ ] DruidErrors checked via testutils.CheckDruidError(g, expected, actual)
    - [ ] t.Parallel() present on test function and in subtests
    - [ ] No time.Sleep() — Eventually/Consistently used for async assertions
    - [ ] Table-driven struct slice for multiple scenarios

    ### Commit messages
    - [ ] Imperative verb, sentence case, no trailing period
    - [ ] Issue number at end: (#NNNN)
    - [ ] One commit per logical change (API commit + generate commit are expected to be separate)

    ### Code quality
    - [ ] No overbuilding — only what the task asked for
    - [ ] Existing test helpers in test/utils/ used, not reimplemented
    - [ ] make ci-checks would pass (format, lint, license headers)

    ## Report Format

    **Strengths:** [what was done well]

    **Issues:**
    - Critical (must fix before merge): [file:line — description]
    - Important (should fix): [file:line — description]
    - Suggestion (nice to have): [file:line — description]

    **Assessment:** ✅ Approved | ❌ Changes required
```
