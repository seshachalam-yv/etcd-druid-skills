# Plugin Improvement Recommendations from etcd-steward Session

## What We Used
- `/etcd-druid:plan` — Created the 20-task plan with waves. Worked well.
- Direct parallel agents — Bypassed `/etcd-druid:implement` for speed.

## What We Should Have Used
- `/etcd-druid:implement` — Per-task subagent loop
- `/etcd-druid:e2e` — KIND setup patterns
- `/etcd-druid:debug` — Nil interface, readiness probe, init endpoint failures
- `/etcd-druid:api-change` — Feature gate addition
- `/etcd-druid:review` — Pre-merge validation

## Concrete Improvements

### 1. Plan Skill: Add "Sidecar Contract Compatibility" Section
When the plan involves feature gates that swap container images (UseEtcdSteward, UpgradeEtcdVersion), the plan template should include:
```
## Sidecar Contract
- [ ] HTTP endpoints expected by etcd-wrapper: /initialization/status, /initialization/start, /config
- [ ] Readiness probe target: port + path must match new sidecar
- [ ] Pod identity: --pod-name/--pod-namespace vs POD_NAME/POD_NAMESPACE env vars
- [ ] Container args: new binary has different CLI flags than old binary
```

### 2. Plan Skill: Add "Feature Gate Checklist"
```
## Feature Gate Files
- [ ] api/config/v1alpha1/features.go — define gate + maturity level
- [ ] internal/common/constants.go — image key constant
- [ ] internal/utils/image.go — image selection logic
- [ ] internal/images/images.yaml — default image entry
- [ ] internal/component/statefulset/builder.go — container args + probes
- [ ] test/utils/constants.go + imagevector.go — test image vector
- [ ] charts/values.yaml — helm values
- [ ] IMAGEVECTOR_OVERWRITE for e2e testing
```

### 3. E2e Skill: Add Distroless Image Warning
```
IMPORTANT: Both etcd and etcd-steward use distroless images.
- No shell, ls, wget, curl, touch available
- Use etcdctl for etcd operations (available in etcd image)
- Use port-forward + HTTP client for HTTP endpoint testing
- Use K8s API (pod logs, status) for observability
- Use $(ENV_VAR) substitution in container args for pod identity
```

### 4. E2e Skill: Add KIND Image Loading Pattern
```
For custom images in KIND:
1. Build binary locally: CGO_ENABLED=0 GOOS=linux GOARCH=arm64 go build -o bin/binary-linux ./cmd/
2. Use simple Dockerfile.e2e (just COPY binary, no multi-stage):
   FROM gcr.io/distroless/static-debian12:nonroot
   COPY bin/binary-linux /binary
   ENTRYPOINT ["/binary"]
3. Push to local registry: docker push localhost:5001/image:tag
4. For IMAGEVECTOR_OVERWRITE: create ConfigMap, mount as volume, set env var
```

### 5. E2e Skill: Add Per-Test Namespace Pattern
```
Each e2e test MUST use a unique namespace derived from t.Name():
  name := strings.ToLower(t.Name())
  name = strings.ReplaceAll(name, "/", "-")
  name = strings.ReplaceAll(name, "_", "-")
  nsName := "e2e-" + name
  if len(nsName) > 63 { nsName = nsName[:63] }
This prevents "namespace is being terminated" conflicts.
```

### 6. Implement Skill: Support Parallel Wave Execution
The current implement skill runs tasks sequentially via subagent loop. Add support for:
- Grouping tasks by dependency wave
- Launching all tasks in a wave as parallel agents
- Verifying each wave before starting the next
- Running `go test -race` after each wave

### 7. Debug Skill: Add "Go Interface Nil Gotcha" Check
When debugging nil pointer dereferences on interface method calls:
```
Check: Is the interface assigned from a function returning (*ConcreteType, error)?
If the function returns (nil, error), the interface is NOT nil.
Fix: Only assign to the interface inside an `if err == nil` block.
```

### 8. Reference Skill: Add etcd-wrapper ↔ Sidecar Contract
Document the implicit contract between etcd-wrapper and the sidecar:
```
etcd-wrapper expects the sidecar (backup-restore or steward) to expose:
  GET  /initialization/status → {"status":"New|Progress|Successful|Failed"}
  POST /initialization/start  → triggers initialization
  GET  /config               → returns etcd config YAML

The wrapper polls /initialization/status until it returns "Successful",
then starts the embedded etcd. Without these endpoints, the pod never becomes ready.

Readiness probe: etcd container checks wrapper's /readyz on port 9095.
When using a different sidecar, the readiness probe must be updated.
```

### 9. Session-Start: Detect New Binary Work Early
The session-start hook should detect when the user asks to build a new binary/sidecar and:
- Skip "look at merged PRs" (no prior art)
- Suggest larger task granularity (package boundary)
- Recommend parallel wave execution
- Flag the sidecar contract requirements

### 10. Add "etcd-druid:feature-gate" Skill
Create a dedicated skill for feature gate work that covers:
- Definition in features.go
- Image key in constants.go
- Image selection in image.go
- Container args in builder.go
- Readiness probe changes
- Test image vector updates
- IMAGEVECTOR_OVERWRITE for e2e
- Helm chart values
This is common enough to warrant its own skill.

### 11. Observations from etcd-steward Build
- Building 17 packages in 5 parallel waves took ~45 minutes (agent time)
- Each wave's agent took 1-5 minutes
- The e2e iteration cycle (build image → deploy → test → debug → fix) took much longer (~3 hours)
- Most e2e failures were contract mismatches, not code bugs
- The plan skill's task structure worked well for the parallel agent approach
- The `testing.T` (no Ginkgo) mandate from design notes was easy to enforce
