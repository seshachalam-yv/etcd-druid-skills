# PR Requirements and CI Verification

## Step 6: Update examples/ and docs/

**examples/** — if the new field is user-facing (an operator would set it), add an example to `examples/etcd/druid_v1alpha1_etcd.yaml`. Optional fields can be commented out. Show the type, not just a placeholder:

```yaml
# additionalAdvertisePeerUrls:
# - memberName: etcd-main-0
#   urls:
#   - http://etcd-main-0.etcd-main-peer.default.svc:2380
```

**docs/** — if the change is user-facing or changes operator behaviour, update `docs/`. The PR checklist in `.github/pull_request_template.md` requires:
- If new docs files added or docs structure modified: update `mkdocs.yml` and `docs/README.md` (Table of Contents). Follow `docs/development/updating-documentation.md` to test locally.
- If changing the API behaviour: update `docs/development/changing-api.md` or relevant guide.

---

## Step 7: CI Pipeline Verification (required — Gate 2 never presented with failing CI)

Run all of these in order before presenting Gate 2. Any failure → dispatch fix subagent with full output.

```bash
# From worktree root
cd <worktree-path>
make ci-checks          # format + lint + license + api-diff (catches field naming issues)
make test-unit          # confirms deepcopy generation is syntactically correct
make test-integration   # runs test/it/crdvalidation/ — your CEL tests are here

# From api/ module
cd <worktree-path>/api
make check-generate     # fails if make generate would produce a diff — means commit 2 is stale
make check-apidiff      # fails on breaking API changes — must pass or be explicitly excepted
```

**If `make check-apidiff` fails with an unexpected breaking change:**
The API diff tool found a field removal, rename, or type change you didn't intend. Fix the field design. If the breaking change is intentional, follow `docs/development/changing-api.md` to add it to the compatibility exception list.

**If `make test-integration` fails on a CEL test:**
- `skipCELTestsForOlderK8sVersions(t)` guard missing → add it
- envtest K8s version < 1.29 → the skip guard handles this automatically
- CEL rule syntax error → run `kubectl apply --dry-run=server -f api/core/v1alpha1/crds/*.yaml` against a live cluster to see the CEL parse error

**Gate 2 is never presented with failing CI.** All five commands above must pass.

---

## Step 8: PR Requirements

**Read the template first.** The PR template lives in `.github/pull_request_template.md` in the repo — read it directly and fill every section. Prow bots parse `/area` and `/kind`; wrong values or missing lines stall the review.

**Look at a merged API-change PR for reference:**
```bash
gh pr list --state merged --repo gardener/etcd-druid --label kind/api-change --limit 5
gh pr view <number>   # read the body of a comparable PR
```
Mirror the `/area` choice, description style (include a YAML snippet of the new field if user-facing), release note category, and checklist tick pattern from a real merged PR — not a generic template.

**API-change-specific notes for "Special notes for your reviewer":**
- State that the two-commit rule was followed (commit 1 = hand-written API changes, commit 2 = `make generate` output)
- List each CEL rule added and what invariant it enforces

**Before pushing:** squash to a minimal number of commits, rebase against `upstream/master`:
```bash
git rebase upstream/master
# result: 1 commit (hand-written API changes) + 1 commit (make generate output)
```

**Reviewer checklist — API changes:**
- [ ] New fields have `+optional` or `+required`
- [ ] Optional fields have `omitempty` in JSON tag
- [ ] CEL rules have `has()` guards on optional field references
- [ ] Field-scoped rules placed on innermost struct
- [ ] Cross-field rules (referencing `self.metadata` or two sub-structs) placed on `Etcd` root type
- [ ] `MaxItems` set on lists used in CEL iteration
- [ ] Commit 1 = hand-written only; Commit 2 = `make generate` output only
- [ ] `cd api && make check-generate` passes
- [ ] `cd api && make check-apidiff` passes
- [ ] Test added in `test/it/crdvalidation/etcd/` for every CEL rule
- [ ] `examples/` updated if field is user-facing
- [ ] `docs/` updated if behaviour is user-facing; `mkdocs.yml` and `docs/README.md` updated if new files added
- [ ] No manual edits to `zz_generated.deepcopy.go`, CRD YAMLs, or `docs/api-reference/`

---

## Red Flags — Stop and Re-read the Iron Law

| Thought | Why it fails |
|---|---|
| "The CEL rule is simple — I'll add the test after" | CEL syntax errors are silent until the CRD is applied; the test is the only CI gate |
| "I only changed one field — two commits is overkill" | Mixed hand-written + generated commits break `git bisect` and make rollback impossible |
| "I ran `make generate` — the test is redundant" | `make generate` checks syntax; the integration test checks runtime semantics |
| "The field is internal — no CEL validation needed" | Internal fields are still validated at admission; an untested rule may silently accept invalid input |
