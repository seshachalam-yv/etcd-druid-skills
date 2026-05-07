---
name: dep
description: Use when writing a new Druid Enhancement Proposal or reviewing an existing DEP draft for quality and completeness. Guides section-by-section authoring with best-practice heuristics, or scores existing drafts against a 20-point rubric covering cross-repo impact (etcd-druid, etcd-backup-restore, etcd-wrapper), feature gates, breaking changes, CEL validations, and Mermaid diagrams.
user-invocable: true
effort: high
---

# Druid Enhancement Proposal (DEP) — Guide & Review

## ⛔ Iron Law

**EVERY DEP IS REVIEWED FROM THREE REPO PERSPECTIVES.**

| Rationalization | Why it fails |
|---|---|
| "This only touches etcd-druid" | API changes flow to sidecars via StatefulSet env/args. Always check. |
| "The sidecar contract doesn't change" | Behavioral changes (timing, ordering) break contracts without API changes |
| "We don't need a feature gate for this" | Any change that could break existing clusters needs a rollback path |
| "CEL validation is an implementation detail" | Missing CEL means invalid state reaches controllers. It's design. |

---

## Mode Detection

Determine the mode from user intent:

| User says | Mode |
|-----------|------|
| "write a DEP", "draft a proposal", "help me write DEP-07" | **Guide** |
| "review this DEP", "check my proposal", "score DEP-06" | **Review** |
| Points to an existing file in `docs/proposals/` | **Review** |
| Describes a new feature/enhancement idea | **Guide** |

---

## Guide Mode

Walk the author through writing a DEP section-by-section.

### Phase 1: Scope & Classification

1. Ask: "What is the enhancement about? One sentence."
2. Classify cross-repo impact:
   - Which repos are affected? (etcd-druid, etcd-backup-restore, etcd-wrapper)
   - Is there an API change? (triggers CEL, two-commit awareness)
   - Is there a behavioral change? (triggers sidecar contract check)
3. Determine next DEP number:
   ```bash
   ls /path/to/gardener/etcd-druid/docs/proposals/*.md | tail -1
   ```
4. Create the DEP file from [DEP-TEMPLATE.md](DEP-TEMPLATE.md)

### Phase 2: Section-by-Section Guidance

For each section of the template, prompt the author with heuristics from [BEST-PRACTICES.md](BEST-PRACTICES.md):

| Section | Key prompt |
|---------|-----------|
| Summary | "Can a reader understand the change without reading the rest?" |
| Terminology | "Are there domain terms a new contributor wouldn't know?" |
| Motivation | "What operational pain or incident motivates this? Link to issues." |
| Goals | "Are these measurable? Can you write a test for each?" |
| Non-Goals | "What adjacent work are you explicitly excluding? Why?" |
| Use Cases | "Give 2-4 real scenarios with pre-conditions and expected outcomes." |
| API Changes | "Show Go structs with kubebuilder markers AND YAML. Include status." |
| Lifecycle/Flow | "What are the state transitions? Which diagram type fits?" |
| Failure Scenarios | "What fails? Who detects? Is it retriable? Recovery path?" |
| Feature Gate | "Does this need a gate? What's the graduation plan?" |
| Compatibility | "Do existing clusters continue working? Migration path?" |
| Metrics | "Is this change observable? What would you alert on?" |
| Alternatives | "What else did you consider? Why was it rejected?" |
| Future Work | "What comes next? Can each item be its own DEP?" |

### Phase 3: Diagram Assistance

After the main sections, suggest diagrams based on content:

1. Read [DIAGRAM-GUIDE.md](DIAGRAM-GUIDE.md) for pattern selection
2. Identify which diagram types are needed based on proposal content
3. Help author write Mermaid syntax or generate it from their description
4. Ensure at least one diagram exists (hard requirement)

### Phase 4: Self-Review

Run the 20-point rubric from [BEST-PRACTICES.md](BEST-PRACTICES.md) against the draft:
- Score each dimension
- Present gaps with specific fix suggestions
- Iterate until score ≥ 26 (Good)

---

## Review Mode

Score an existing DEP against the full rubric.

### Step 1: Read the DEP

Read the target file (user provides path or DEP number).

### Step 2: Score Against Rubric

Apply all 20 dimensions from [BEST-PRACTICES.md](BEST-PRACTICES.md):
- For each dimension: **Present & Strong** (2), **Present but Weak** (1), **Missing** (0)
- Note specific evidence for each score

### Step 3: Cross-Repo Lens

For each affected repo, check:
- **etcd-druid:** CRD changes, controller impact, RBAC, component order
- **etcd-backup-restore:** CLI flags, endpoints, snapshot format, GC behavior
- **etcd-wrapper:** etcd config, peer URLs, TLS, initialization flow

### Step 4: Operational Checks

- **Feature Gate:** Is one needed? Is it documented?
- **Breaking Changes:** Any signals present? Migration path?
- **CEL Validations:** New fields validated? Immutability enforced?
- **Rollback Safety:** What happens if disabled after being enabled?

### Step 5: Present Report

Format:

```
## DEP Review: DEP-NN — Title

### Score: XX/40 (Rating)

### Strengths
- ...

### Gaps (ordered by impact)
1. [Dimension N — Missing] Specific issue + suggested fix
2. [Dimension M — Weak] What's missing + example of what good looks like

### Cross-Repo Findings
- etcd-druid: ...
- etcd-backup-restore: ...
- etcd-wrapper: ...

### Diagram Recommendations
- Missing: [type] diagram for [content]
- Suggestion: [Mermaid code block]
```

---

## Integration with Other Skills

| After DEP is... | Invoke |
|-----------------|--------|
| Approved by maintainers | `/etcd-druid:plan` to create implementation plan |
| Involving API changes | `/etcd-druid:api-change` for CEL/two-commit details |
| Ready for implementation | `/etcd-druid:implement` with the plan |

