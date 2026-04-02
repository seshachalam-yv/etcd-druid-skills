# Implementer Subagent Prompt Template

Use this template when dispatching an implementer subagent for an etcd-druid task.

```
Agent tool (general-purpose):
  description: "Implement Task N: [task name]"
  prompt: |
    You are implementing a task in the etcd-druid operator codebase.

    ## Task

    [FULL TEXT of task from plan — paste here, do not make subagent read file]

    ## Context

    - Issue: #[issue-id]
    - Worktree path (your working directory): [worktree-path]
    - Fork: /Users/I568019/go/src/github.com/seshachalam-yv/etcd-druid
    - Upstream (read-only reference): /Users/I568019/go/src/github.com/gardener/etcd-druid
    - Branch: ai/TASK-[issue-id]/claude/[short-description]
    - Files affected: [list from plan]

    ## Before You Begin

    If you have questions about requirements, approach, or anything unclear — ask now.
    Do not guess. Do not make assumptions. Pause and ask.

    ## etcd-druid Conventions

    **Operator interface** (if task touches internal/component/):
    Every new component must implement all four methods:
      - PreSync(ctx OperatorContext, etcd *druidv1alpha1.Etcd) error
      - Sync(ctx OperatorContext, etcd *druidv1alpha1.Etcd) error
      - TriggerDelete(ctx OperatorContext, etcdObjMeta metav1.ObjectMeta) error
      - GetExistingResourceNames(ctx OperatorContext, etcdObjMeta metav1.ObjectMeta) ([]string, error)
    Register new component in createAndInitializeOperatorRegistry() in
    internal/controller/etcd/reconciler.go

    **API changes** (if task touches api/core/v1alpha1/):
    - Add +kubebuilder:validation:XValidation CEL annotation for new fields
    - Run make generate after changes
    - Update charts/ CRD YAML

    **Error handling (internal/component/ code):**
    Use druiderr.WrapError — NOT fmt.Errorf:
      import druiderr "github.com/gardener/etcd-druid/internal/errors"
      return druiderr.WrapError(err, ErrGetFoo, component.OperationPreSync,
          "failed to get foo for etcd %s", druidv1alpha1.GetNamespaceName(etcd.ObjectMeta))
    Error vars are package-level: var ErrGetFoo = errors.New("ErrGetFoo")
    Never swallow errors silently.

    **Logging (etcd-druid):**
    log.FromContext(ctx).WithValues("etcd", req.NamespacedName)

    **OperatorContext construction (in tests):**
      import "github.com/gardener/etcd-druid/internal/component"
      import "github.com/google/uuid"
      import "github.com/go-logr/logr"
      opCtx := component.NewOperatorContext(context.Background(), logr.Discard(), uuid.NewString())

    **Tests:**
    - Use Go native testing.T (not Ginkgo) with Gomega assertions
    - Import: . "github.com/onsi/gomega"
    - Use table-driven struct slices for multiple scenarios
    - DO NOT use gomock — use testutils fake client instead:
        import "github.com/gardener/etcd-druid/test/utils"
        // Single object with error injection:
        cl := testutils.CreateTestFakeClientForObjects(getErr, nil, nil, nil, existingObjects, objKey)
        // Or builder pattern:
        cl := testutils.NewTestClientBuilder().WithObjects(objs...).Build()
    - Never use time.Sleep() — use gomega.Eventually/Consistently
    - Check existing tests in the same package before writing new ones
    - Helpers live in test/utils/ — use before creating new ones

    **Commit message style** (one commit per task):
    "Verb noun detail (#[issue-id])"
    Examples:
      Add PreSync method to statefulset operator (#1350)
      Fix TLS secret rotation in configmap component (#1350)
      Add unit tests for memberlease operator (#1350)

    ## Your Job

    1. Implement exactly what the task specifies — nothing more, nothing less
    2. Write tests following the pattern above (check existing tests in same package first)
    3. Run: make test-unit (for unit tests) or make test-integration (for integration tests)
    4. Commit with the message style above
    5. Self-review (see below)
    6. Report back

    Work from: [worktree-path]

    ## Self-Review Before Reporting

    - Did I implement everything in the task acceptance criteria?
    - Did I follow Go native testing.T + Gomega (not Ginkgo)?
    - Did I follow the commit message style (no trailing period)?
    - Did I avoid overbuilding (YAGNI)?
    - Do tests pass: make test-unit?
    - Did I only commit to the worktree branch, not upstream?

    Fix any issues before reporting.

    ## Report Format

    - **Status:** DONE | DONE_WITH_CONCERNS | BLOCKED | NEEDS_CONTEXT
    - What I implemented (files changed, with paths)
    - Test results (pass count, command run)
    - Commit SHA(s)
    - Self-review findings (if any)
    - Concerns (if DONE_WITH_CONCERNS)
```
