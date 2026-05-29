# Building the Feedback Loop

The single most important debugging skill: before diagnosing anything, build a fast, deterministic, repeatable pass/fail signal. "Building the feedback loop IS the skill. Everything else is mechanical."

## The Rule

Do NOT form hypotheses until you have a loop that:
1. Reproduces the failure consistently
2. Runs in under 30 seconds
3. Produces a clear PASS/FAIL output
4. Can be re-run after every change

## 10 Ways to Build a Feedback Loop (Progressive)

### 1. Targeted Test Run
The simplest loop — isolate the failing test:
```bash
go test ./internal/component/<name>/... -v -run TestSpecificCase -count=1
```
Works when: a test is already failing.

### 2. Minimal Reproduction Test
Write a new focused test that exercises only the failing path:
```go
func TestReproduction_Issue1234(t *testing.T) {
    // Minimal setup that triggers the bug
    // Assert the expected vs actual behavior
}
```
Works when: no existing test covers the failure.

### 3. Script-Based Verification
A shell script that runs, checks output, exits 0/1:
```bash
#!/bin/bash
output=$(go test ./... -run TestFoo 2>&1)
if echo "$output" | grep -q "EXPECTED_STRING"; then
    echo "PASS"; exit 0
else
    echo "FAIL: $output"; exit 1
fi
```
Works when: the failure signal is in log output, not test assertions.

### 4. envtest Harness
Spin up a minimal envtest environment and reconcile:
```go
func TestReconcileReproduction(t *testing.T) {
    env := envtest.Environment{CRDDirectoryPaths: []string{"..."}}
    cfg, _ := env.Start()
    defer env.Stop()
    // Create resource, trigger reconcile, assert outcome
}
```
Works when: the bug is in reconciliation logic that needs a real API server.

### 5. Delve Conditional Breakpoint
Set a breakpoint that only triggers on the failing condition:
```bash
dlv test ./internal/controller/etcd/ -- -test.run TestReconcile
(dlv) break reconciler.go:142
(dlv) cond 1 etcd.Status.Ready == nil
(dlv) continue
```
Works when: you need to inspect state at a specific moment.

### 6. Log-Grep Loop
Add tagged debug logs, run, grep for the tag:
```go
log.Info("[DEBUG-1234] state at checkpoint", "value", someVar)
```
```bash
go test ./... -run TestFoo 2>&1 | grep "\[DEBUG-1234\]"
```
Works when: state flows through many layers and you need to trace it.

### 7. Differential Loop (Before/After)
Run the same test against two versions and diff the output:
```bash
git stash && go test ./... -run TestFoo > /tmp/before.txt 2>&1
git stash pop && go test ./... -run TestFoo > /tmp/after.txt 2>&1
diff /tmp/before.txt /tmp/after.txt
```
Works when: a recent change broke something and you need to find what changed.

### 8. Snapshot Provider Stub
For backup-restore issues, create a minimal snapstore that returns controlled data:
```go
type stubSnapstore struct{ snapshots []Snapshot }
func (s *stubSnapstore) List() (brtypes.SnapList, error) { return s.snapshots, nil }
```
Works when: debugging restore/compaction logic without real cloud storage.

### 9. Fuzz/Property Loop
Generate random inputs and check invariants:
```go
func FuzzReconcile(f *testing.F) {
    f.Add(int32(3), true)
    f.Fuzz(func(t *testing.T, replicas int32, withTLS bool) {
        // Build Etcd spec, reconcile, check invariants hold
    })
}
```
Works when: the bug is input-dependent and you can't guess which input triggers it.

### 10. HITL (Human-in-the-Loop) Bash Script
Interactive script that shows state and asks for next action:
```bash
#!/bin/bash
echo "Current state:"; kubectl get etcd -A -o wide
echo ""; read -p "Action [reconcile/delete/scale]: " action
# Execute action, show result, loop
```
Works when: the bug only reproduces in a real cluster and you need to explore interactively.

## Making the Loop Faster

Once you have a loop, optimize it:
- Remove unnecessary setup (don't spin up what you don't need)
- Use `-short` flag to skip slow subtests
- Use `-count=1` to disable test caching
- Use `-timeout 30s` to fail fast on hangs
- Run only the specific subtest: `-run TestFoo/specific_case`

## When Your Loop Is Ready

You know your feedback loop is good when:
1. Running it takes < 30 seconds
2. It fails consistently without the fix
3. It passes consistently with the fix
4. Someone else could run it without explanation

Only THEN proceed to Phase 4 (Form a Hypothesis) in the main debug skill.
