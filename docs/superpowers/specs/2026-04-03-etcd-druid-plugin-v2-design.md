# etcd-druid-skills Plugin v2 Design

**Date:** 2026-04-03  
**Status:** Approved  
**Scope:** Balanced 3-component coverage, `mistakes` skill, self-improvement loop, git checkpoints

---

## Problem Statement

The v1 plugin encodes expert etcd-druid knowledge into 5 skills. However:

1. **Uneven component coverage** — skills focus primarily on etcd-druid; etcd-backup-restore and etcd-wrapper are mentioned but not deeply covered.
2. **No mistake catalogue** — common errors per component are scattered across skills or absent entirely.
3. **No self-improvement loop** — when Claude encounters undocumented patterns, there is no mechanism to surface that gap and invite a contribution.
4. **No git checkpoints** — feature-dev phases don't commit incrementally, making it hard to revert if a suggestion diverges.
5. **No Gardener context** — the seed/shoot model and gardenlet ownership are not captured anywhere.

---

## Goals

1. Balance skill coverage across all 3 components: etcd-druid, etcd-backup-restore, etcd-wrapper.
2. Add a `mistakes` skill as a living catalogue of common errors, anti-patterns, and ecosystem pitfalls.
3. Implement a self-improvement loop: inline flagging of undocumented patterns + standing PR reminder in every skill.
4. Add git checkpoint commits after each phase in feature-dev and after each new mistake entry.
5. Add minimal Gardener context (seed/shoot model, gardenlet ownership, label conventions).

## Non-Goals

- Full Gardener extensions API coverage.
- Windows hook support.
- CI/CD pipeline for the plugin itself.
- README, CHANGELOG, or contributing guide.

---

## Section 1: New `mistakes` Skill

### File

`skills/mistakes/SKILL.md`

### When Invoked

- Automatically by `feature-dev` when entering an unfamiliar component's code.
- Automatically by `debug` when a symptom doesn't match any known phase pattern.
- Explicitly by user: `/etcd-druid:mistakes`

### Catalogue Entry Format

Each mistake follows this structure:

```
### MISTAKE-NNN: <Short title>
**Component:** etcd-druid | etcd-backup-restore | etcd-wrapper | gardener
**Symptom:** What you observe when this goes wrong
**Wrong pattern:** The approach that seems correct but isn't
**Correct pattern:** What to do instead
**Why:** The ecosystem-specific reason this matters
**Added:** YYYY-MM-DD | **PR:** #N
```

### Catalogue Sections

1. **etcd-druid mistakes** — wrong test framework (Ginkgo in druid), skipping Operator interface, bad error wrapping, missing finalizer checks, manual status patching, wrong RBAC marker placement.
2. **etcd-backup-restore mistakes** — wrong log format assumptions, initialization flow misunderstandings, snapshot API misuse, HTTP handler not registered, snapshot lease not updated.
3. **etcd-wrapper mistakes** — readiness probe returning wrong status, TLS client cert path errors, gRPC vs HTTP confusion, graceful shutdown not implemented.
4. **Kubernetes + Gardener anti-patterns** — seed/shoot boundary violations, custom label invention, gardenlet ownership conflicts, async reconciliation timing assumptions.

### Gardener Context Block

```
## Gardener Context
- etcd-druid runs in Gardener's **seed cluster** — never assume shoot API access.
- Gardenlet owns the `Etcd` CR lifecycle — do not manually patch status outside the reconciler.
- Component labels follow `app.kubernetes.io/` convention — do not invent custom label keys.
- Shoot/seed reconciliation is async — etcd readiness gates the shoot's own reconciliation.
- etcd-druid is a Gardener component: changes must not break gardenlet's reconciliation assumptions.
```

### Self-Improvement Loop

**Inline flagging (mid-operation):**
When Claude encounters a pattern not covered in any skill, it flags immediately:
> "This pattern isn't in the mistakes catalogue yet. Consider opening a PR to `etcd-druid-skills` — use the template at the end of `skills/mistakes/SKILL.md`."

**Standing reminder (end of every skill):**
Every skill ends with:
```
## Improve This Skill
Something missing, wrong, or outdated? Open a PR to `etcd-druid-skills`.
Use the contribution template in `skills/mistakes/SKILL.md` for mistake entries.
```

**Contribution template** (inside `mistakes` skill):
```markdown
### MISTAKE-NNN: <Short title>
**Component:** <etcd-druid | etcd-backup-restore | etcd-wrapper | gardener>
**Symptom:** <What you observe>
**Wrong pattern:** <What seems correct but isn't>
**Correct pattern:** <What to do instead>
**Why:** <Ecosystem-specific reason>
**Added:** <YYYY-MM-DD> | **PR:** #<N>
```

**Git commit on new entry:**
Each new mistake entry = one commit:
```
mistakes: add MISTAKE-NNN <short title>
```

---

## Section 2: Enriching Existing Skills

### `tdd` skill

Add explicit sections for:

**etcd-backup-restore:**
- Framework: Ginkgo v2 + Gomega
- HTTP handler tests: `httptest.NewRecorder` + `httptest.NewRequest`
- Snapshot store interface mocking patterns
- Initialization state machine testing (New → Initialized → Failed)

**etcd-wrapper:**
- Framework: Go native `testing.T` + Gomega
- gRPC server test patterns
- TLS test helpers (self-signed cert generation for tests)
- Readiness probe unit test patterns

### `debug` skill

Add per-component log format reminder at top of each phase:

- **Phase 1 (backup-restore):** logrus JSON — fields: `msg`, `level`, `time`, `error`
- **Phase 2 (wrapper):** zap structured JSON — fields: `msg`, `level`, `ts`, `caller`
- **Phase 4 (druid):** logr structured key-value pairs — search by `runID`, `etcd` name

Add escalation path:
> "Symptom doesn't match any phase? → invoke `etcd-druid:mistakes` skill."

### `review` skill

Add checklist sections:

**etcd-backup-restore:**
- HTTP handler registered in router
- Initialization flow respected (no snapshot before initialized)
- Snapshot lease updated after successful snapshot
- logrus used (not zap, not log)

**etcd-wrapper:**
- Readiness probe returns correct HTTP status code
- TLS cert paths match mounted secret paths
- gRPC server implements graceful shutdown
- zap used (not logrus, not log)

### `reference` skill

Add:

**Gardener context block** (same as in `mistakes` skill — canonical copy here):
- Seed vs shoot boundary
- Gardenlet ownership of Etcd CR
- Label conventions
- Async reconciliation gating

**etcd-wrapper endpoints:**
- `/readyz` — HTTP readiness probe
- gRPC port (default 2379)
- Metrics port (default 8080)

**etcd-backup-restore initialization state machine:**
```
New → Initializing → Initialized
               ↘ Failed
```
- `New`: server started, no initialization attempted
- `Initializing`: restore in progress
- `Initialized`: ready to serve snapshots
- `Failed`: restore failed, manual intervention required

### `feature-dev` skill

Add:
- "invoke `etcd-druid:mistakes` when entering an unfamiliar component" instruction after Phase 1.
- Checkpoint commit after each phase (see Section 3 below).
- Per-phase commit message templates.

---

## Section 3: Git Checkpoint Strategy

### In the Plugin's Own Development

Each discrete change = one commit. Never batch unrelated changes:

```
checkpoint: add mistakes skill scaffold
checkpoint: add MISTAKE-001 through MISTAKE-010 (etcd-druid)
checkpoint: add MISTAKE-011 through MISTAKE-020 (backup-restore)
checkpoint: add MISTAKE-021 through MISTAKE-030 (wrapper + gardener)
checkpoint: enrich tdd skill with backup-restore and wrapper patterns
checkpoint: enrich debug skill with per-component log formats
checkpoint: enrich review skill with backup-restore and wrapper checklist
checkpoint: enrich reference skill with gardener context and wrapper endpoints
checkpoint: enrich feature-dev with phase checkpoints and mistakes invocation
checkpoint: add standing PR reminder to all skills
```

### In feature-dev Workflow (Runtime)

After each phase, feature-dev instructs Claude to commit:

| Phase | Commit message template |
|-------|------------------------|
| Phase 1 complete (Design) | `design: <issue-id> document approach` |
| Phase 2 complete (Plan) | `plan: <issue-id> write implementation plan` |
| Phase 4 task N complete (Implement) | `feat: <issue-id> implement <task-name>` |
| Phase 5 complete (Verify) | `test: <issue-id> verify all checks pass` |

**Revert strategy:** If Gate 2 is rejected, use `git revert` back to last checkpoint — never `git reset --hard`.

### In Mistakes Self-Improvement Loop

Each new mistake entry = one commit:
```
mistakes: add MISTAKE-NNN <short title>
```

This makes the mistake catalogue's git history a readable audit trail of what the team learned over time.

---

## Section 4: Session-Start Hook Updates

**File:** `hooks/session-start`

**Changes (minimal, preserves existing structure):**

1. Add `mistakes` to skills list:
   ```
   - etcd-druid:mistakes   → common errors per component + self-improvement loop
   ```

2. Add Gardener context to invariants block:
   ```
   - etcd-druid runs in Gardener's seed cluster; gardenlet owns Etcd CR lifecycle
   ```

3. Add checkpoint reminder to invariants block:
   ```
   - Commit after each phase; use git checkpoints to stay recoverable
   ```

4. Add improvement nudge at end of hook output:
   ```
   Spotted a gap? → open a PR to etcd-druid-skills using template in skills/mistakes/SKILL.md
   ```

**What stays the same:** Hook runner (`run-hook.sh`), `hooks.json`, overall hook length and tone.

---

## Implementation Order

Tasks should be executed in this order, each producing a checkpoint commit:

1. Create `mistakes` skill scaffold (structure, sections, contribution template)
2. Populate `mistakes` catalogue: etcd-druid entries (MISTAKE-001–010)
3. Populate `mistakes` catalogue: etcd-backup-restore entries (MISTAKE-011–020)
4. Populate `mistakes` catalogue: etcd-wrapper + Gardener entries (MISTAKE-021–030)
5. Enrich `tdd` skill with backup-restore and wrapper patterns
6. Enrich `debug` skill with per-component log formats and mistakes escalation
7. Enrich `review` skill with backup-restore and wrapper checklists
8. Enrich `reference` skill with Gardener context, wrapper endpoints, initialization state machine
9. Enrich `feature-dev` with phase checkpoint commits and mistakes invocation
10. Add standing PR reminder to all 5 existing skills
11. Update `session-start` hook with mistakes skill, Gardener context, checkpoint reminder, improvement nudge

---

## Success Criteria

- All 3 components covered with equal depth in tdd, debug, review, reference.
- `mistakes` skill has ≥10 entries per component (30+ total).
- Every skill ends with the "Improve This Skill" PR reminder.
- feature-dev instructs checkpoint commits after each phase.
- Session-start hook mentions `mistakes` skill and Gardener context.
- Each implementation task = one git commit (11 checkpoint commits for v2).
