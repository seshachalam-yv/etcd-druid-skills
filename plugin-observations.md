# Plugin Observations

Captured plugin improvement findings from development sessions.

---

## OBS-001

**Type:** missing-content
**Confidence:** high
**Source:** etcd-steward-v1-e2e-debugging
**Count:** 3
**Status:** resolved

**File:** skills/reference/SKILL.md
**Section:** Reference content
**Wrong / Missing:** MISSING — no cross-repo contract documentation or guidance to check it
**Correct:** Add section: "## Cross-Container Contracts\nWhen a Pod has multiple containers that communicate (e.g., etcd-wrapper ↔ sidecar, etcd ↔ backup-restore), there is an implicit HTTP/gRPC contract between them. Before modifying or replacing any container image:\n1. Read the consuming container's source to identify expected endpoints (check its bootstrap/initialization code for HTTP calls to the other container)\n2. Read docs/development/ in both repos for documented contracts\n3. If no documentation exists, file an issue or add a doc in the upstream repo describing the contract\n\nKnown contracts to check:\n- etcd-wrapper → sidecar: see etcd-wrapper/internal/bootstrap/ for expected HTTP endpoints\n- etcd container readiness probe: may target wrapper or sidecar port — verify it matches the actual serving container\n- Pod identity: check whether containers expect env vars (POD_NAME/POD_NAMESPACE) vs CLI flags vs downward API"
**Apply:** MULTILINE — apply manually
**Evidence:** "Replacing a sidecar image without understanding the cross-container contract caused pods to never become ready. The contract was implicit in etcd-wrapper's bootstrap code, not documented anywhere."

---

## OBS-002

**Type:** missing-content
**Confidence:** high
**Source:** etcd-steward-v1-e2e-debugging
**Count:** 2
**Status:** resolved

**File:** skills/e2e/SKILL.md
**Section:** E2e testing guidance
**Wrong / Missing:** MISSING — no guidance on testing with minimal/distroless container images
**Correct:** Add section: "## Testing with Minimal Container Images\nMany production container images (distroless, scratch, alpine-minimal) have no shell, no coreutils, no HTTP clients. Before writing e2e tests:\n1. Check what tools are available: `docker run --rm <image> ls /` — if this fails, the image is distroless\n2. For etcd operations: use etcdctl if available in the etcd image, otherwise use the K8s API or port-forward\n3. For HTTP endpoint testing: use port-forward + Go HTTP client, not kubectl exec with wget/curl\n4. For observability: use K8s pod logs API and container status checks, not shell commands\n5. For data verification: use the application's own CLI tools or API, not filesystem inspection\n\nCommon pitfalls:\n- `etcdctl get --count-only` requires `--write-out=fields` in etcd 3.5+\n- K8s env var substitution `$(ENV_VAR)` works in container args but not in all fields\n- TCP socket probes are more reliable than exec probes in distroless images"
**Apply:** MULTILINE — apply manually
**Evidence:** "E2e tests failed because they assumed shell tools (ls, wget) existed in distroless container images. Required 2 rewrite cycles."

---

## OBS-003

**Type:** missing-content
**Confidence:** high
**Source:** etcd-steward-v1-e2e-debugging
**Count:** 3
**Status:** resolved

**File:** skills/plan/SKILL.md
**Section:** Plan template
**Wrong / Missing:** MISSING — no checklist for feature gates that change container images or cross-container behavior
**Correct:** Add to plan template after the Change Type section: "## Feature Gate Impact Checklist (required when the gate changes container images, args, or cross-container behavior)\n- [ ] Gate definition: api/config/v1alpha1/features.go — name, maturity level, default\n- [ ] Image key: internal/common/constants.go — new image key constant\n- [ ] Image selection: internal/utils/image.go — conditional logic based on gate\n- [ ] Default image: internal/images/images.yaml — embedded image entry\n- [ ] Container spec: internal/component/statefulset/builder.go — CLI args, ports, probes\n- [ ] Test image vector: test/utils/constants.go + test/utils/imagevector.go\n- [ ] Cross-container contract: verify the new image satisfies all contracts expected by other containers in the same Pod (read the consuming container's source code)\n- [ ] Readiness/liveness probes: verify probes still target a valid endpoint after the image swap\n- [ ] Pod identity mechanism: verify the new container receives pod name/namespace correctly (env vars vs flags vs downward API)\n- [ ] E2e override mechanism: document how to test with custom images (IMAGEVECTOR_OVERWRITE, local registry, ConfigMap mount)"
**Apply:** MULTILINE — apply manually
**Evidence:** "UseEtcdSteward feature gate required changes to 7+ files. Missing any file caused silent failures. The sidecar contract and readiness probe changes were discovered through trial and error because no checklist existed."

---

## OBS-004

**Type:** missing-content
**Confidence:** high
**Source:** etcd-steward-v1-code-review
**Count:** 2
**Status:** resolved

**File:** skills/debug/SKILL.md
**Section:** Common Go patterns
**Wrong / Missing:** MISSING — no guidance on nil pointer dereference when an interface holds a nil concrete value
**Correct:** Add to debug skill under a new section: "## Common Go Gotchas\n\n### Nil Interface vs Nil Concrete Value\nA nil pointer dereference on an interface method call often means the interface is not nil but holds a nil concrete value.\n```go\n// WRONG: if NewLocal returns (nil, err), store is NOT nil — it's (*LocalSnapStore)(nil)\nvar store SnapStore\nstore, err = NewLocal(path)\nif store != nil { store.List() } // PANICS — store is non-nil interface with nil value\n\n// RIGHT: use intermediate variable\nvar store SnapStore\nlocal, err := NewLocal(path)\nif err == nil { store = local }\n```\nWhen debugging: if the crash is `nil pointer dereference` on an interface method call, check whether the interface was assigned from a function returning `(*ConcreteType, error)` — the `nil` concrete pointer makes a non-nil interface.\n\n### Container Crash Debugging in K8s\nWhen a pod container crashes in e2e:\n1. `kubectl logs <pod> -c <container> --previous` — get logs from the crashed container\n2. Check for Go panic stack traces — they show the exact file:line\n3. If the crash is in initialization, check whether required endpoints/services are available\n4. If the crash is intermittent, check for race conditions with `-race` flag"
**Apply:** MULTILINE — apply manually
**Evidence:** "etcd-steward crashed with SIGSEGV on a nil *LocalSnapStore assigned to a non-nil SnapStore interface. Required 3 rebuild cycles to diagnose because the nil check passed."

---

## OBS-005

**Type:** missing-content
**Confidence:** medium
**Source:** etcd-steward-v1-e2e-debugging
**Count:** 1
**Status:** resolved

**File:** skills/e2e/SKILL.md
**Section:** KIND cluster setup
**Wrong / Missing:** MISSING — no documented pattern for testing with custom container images in KIND
**Correct:** Add section: "## Custom Container Images in KIND e2e\n\n### Build Pattern (fastest iteration)\n1. Build binary for target platform: `CGO_ENABLED=0 GOOS=linux GOARCH=<arch> go build -o bin/<name>-linux ./cmd/<name>/`\n2. Create a minimal Dockerfile (no multi-stage, no go build inside Docker):\n   ```dockerfile\n   FROM gcr.io/distroless/static-debian12:nonroot\n   COPY bin/<name>-linux /<name>\n   ENTRYPOINT [\"/<name>\"]\n   ```\n3. Push to KIND's local registry: `docker build -t localhost:5001/<name>:dev . && docker push localhost:5001/<name>:dev`\n\n### Override Pattern (for operator-managed images)\nWhen the operator selects images via an image vector (like etcd-druid's IMAGEVECTOR_OVERWRITE):\n1. Create a ConfigMap with the override YAML\n2. Mount it as a volume on the operator deployment\n3. Set the override env var pointing to the mount path\n4. Restart the deployment to pick up changes\n\n### Test Namespace Pattern\nEach e2e test must use a unique namespace to avoid cleanup conflicts:\n```go\nname := strings.ToLower(t.Name())\nname = strings.ReplaceAll(name, \"/\", \"-\")\nname = strings.ReplaceAll(name, \"_\", \"-\")\nns := \"e2e-\" + name\nif len(ns) > 63 { ns = ns[:63] }\n```"
**Apply:** MULTILINE — apply manually
**Evidence:** "Setting up custom images in KIND required multiple undocumented steps. Docker build cache issues, multi-platform image loading failures, and namespace conflicts each caused separate debugging sessions."

---

## OBS-006

**Type:** enhancement
**Confidence:** medium
**Source:** etcd-steward-v2-implementation
**Count:** 1
**Status:** resolved

**File:** skills/implement/SKILL.md
**Section:** Phase 2 workflow
**Wrong / Missing:** MISSING — implement skill only supports sequential per-task execution, no parallel wave support
**Correct:** Add section: "## Parallel Wave Execution\nFor new sidecar/binary work where the plan groups tasks into dependency waves:\n1. Identify tasks within each wave that write to non-overlapping directories\n2. Launch those tasks as parallel agents (safe when no shared write paths)\n3. After all agents in a wave complete, run `go test -count=1 -race ./internal/... ./cmd/...` to verify the wave\n4. Only proceed to the next wave after verification passes\n5. Fix any failures immediately before continuing\n\nThis reduces implementation time by ~60% for large projects (measured: 5h→2h for 17-package sidecar build).\n\nThe sequential subagent loop remains the default for incremental work where tasks are small and dependencies are tight."
**Apply:** MULTILINE — apply manually
**Evidence:** "v2 etcd-steward build used parallel wave execution completing in ~2 hours. v1 sequential approach took ~5 hours. The 60% time savings came from parallelizing non-conflicting package creation."
