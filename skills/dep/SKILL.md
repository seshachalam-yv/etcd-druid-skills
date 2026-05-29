---
name: dep
description: Use when writing a new Druid Enhancement Proposal or reviewing an existing DEP draft for quality and completeness. Guides section-by-section authoring with best-practice heuristics, or scores existing drafts against a 25-dimension / 50-point rubric covering cross-repo impact (etcd-druid, etcd-backup-restore, etcd-wrapper) plus adjacent systems (VPA, Cluster Autoscaler, PDB), public-API discipline, terminology precision, controller boundaries, feature gates, breaking changes, CEL validations, metrics design, and Mermaid diagrams.
user-invocable: true
effort: high
---

# Druid Enhancement Proposal (DEP) — Guide & Review

## Iron Law

**EVERY DEP IS REVIEWED FROM THREE REPO PERSPECTIVES PLUS ADJACENT SYSTEMS.**

| Rationalization | Why it fails |
|---|---|
| "This only touches etcd-druid" | API changes flow to sidecars via StatefulSet env/args. Always check. |
| "The sidecar contract doesn't change" | Behavioral changes (timing, ordering) break contracts without API changes. |
| "We don't need a feature gate for this" | Any change that could break existing clusters needs a rollback path. New features default OFF in alpha. |
| "CEL validation is an implementation detail" | Missing CEL means invalid state reaches controllers. It's design. |
| "I'll surface this internal mechanism in the API" | The DEP is public; StatefulSet/leases/labels are internal. APIs outlive implementations. Hide internals behind feature gates, not CRD fields. |
| "I coined a clear new term, the operational test is obvious" | If you can't write a one-line test for "is X in this state right now?", reviewers can't either. |
| "There's no race condition between these two controllers" | Two controllers writing to the same primary object is a race until proven otherwise. Document the coordination signal. |
| "I'll mention this offline-discussion outcome in the DEP" | The DEP is public-facing. Move closed deliberation to a linked decision record. |

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
   - Are adjacent systems involved? (VPA, Cluster Autoscaler, PDB, CSI, Gardener landscape config, self-hosted variant)
3. **Controller-boundary check:** Does the proposal introduce a new controller, or touch a primary object that another reconciler also writes to? If yes, plan to document the coordination signal up front (Best-Practices Dimension 19).
4. **Single-replica vs HA:** State explicitly whether behavior differs between single-replica and multi-replica clusters. Reviewers consistently ask this, so address it before they do.
5. Determine next DEP number:
   ```bash
   ls docs/proposals/*.md | tail -1
   ```
6. Create the DEP file from [DEP-TEMPLATE.md](DEP-TEMPLATE.md)

### Phase 2: Section-by-Section Guidance

For each section of the template, prompt the author with heuristics from [BEST-PRACTICES.md](BEST-PRACTICES.md):

| Section | Key prompt |
|---------|-----------|
| Summary | "Can a reader understand the change without reading the rest? Are you describing what changes (factual) instead of editorializing about what's wrong today?" |
| Terminology | "For each coined term, give a one-line operational test ('how do I check if X is in this state?'). Don't redefine upstream Kubernetes/etcd terms — link to upstream. Cover transient states." |
| Motivation | "What operational pain or incident motivates this? Link to real issues." |
| Goals | "Are these measurable? Can you write a test for each?" |
| Non-Goals | "What adjacent work are you explicitly excluding? Why?" |
| Use Cases | "Give 2-4 real scenarios with pre-conditions and expected outcomes. Does behavior differ for single-replica vs multi-replica?" |
| API Changes | "Show Go structs with kubebuilder markers AND YAML. Include status. Apply the implementation-swap test: would each field still make sense if we replaced StatefulSet with a custom controller?" |
| Lifecycle/Flow | "What are the state transitions? Which diagram type fits? Every decision arrow must be labelled." |
| Failure Scenarios | "What fails? Who detects? Is it retriable? Timeout/backoff? Where does the stuck state surface (condition / event / metric)? Does this failure block other work indefinitely?" |
| Public Surface vs. Internal Mechanics | "Which parts of this proposal are public contracts and which are internal mechanics? Acknowledge fragile internal references (label keys, status reason strings)." |
| Controller Boundaries | "If you propose a new controller, list every other reconciler touching the same primary object and define the coordination signal. Justify why a new controller vs. extending an existing one." |
| Feature Gate | "Does this need a gate? Default off in alpha; when do you flip the default? Feature gate vs. API field — why this choice? Mid-flight toggle behavior?" |
| Compatibility | "Do existing clusters continue working? Migration path? Adjacent systems (VPA, CA, PDB, CSI, self-hosted)?" |
| Metrics | "Naming follows etcddruid_<subsystem>_<measurement>_<unit>. Include {namespace, name} labels. Don't encode feature names in metric names — use a label. For stateless controllers, where does start-time come from?" |
| Alternatives | "What else did you consider? Minimum 3, including at least one of: 'use existing K8s primitive', 'extend an existing controller', 'configuration option in existing API', 'inverse design'. Bullet-pointed rejection reasons." |
| Future Work | "What comes next? Can each item be its own DEP? (max 5)" |
| Decision Records | "Did any offline-discussion notes leak into the DEP body? Move them to a linked decision record (`docs/decisions/` or GitHub discussion)." |

### Phase 3: Diagram Assistance

After the main sections, suggest diagrams based on content:

1. Read [DIAGRAM-GUIDE.md](DIAGRAM-GUIDE.md) for pattern selection AND the Quality Checklist
2. Identify which diagram types are needed based on proposal content
3. Help author write Mermaid syntax or generate it from their description
4. Ensure at least one diagram exists (hard requirement)
5. Walk the Quality Checklist: every decision arrow labelled, every node names its entity, failure paths shown, no redundant diagrams

### Phase 4: Self-Review

Run the 25-dimension rubric from [BEST-PRACTICES.md](BEST-PRACTICES.md) against the draft:
- Score each dimension (2 = Present & Strong, 1 = Present but Weak, 0 = Missing) — total 50 points
- Present gaps with specific fix suggestions
- Iterate until score ≥ 32 (Good)

**Pre-flight self-review checklist (run before declaring "ready"):**

- [ ] Every coined term has a one-line operational test, and transient states are covered.
- [ ] Every proposed API field passes the implementation-swap test (would it still make sense if the underlying mechanism changed?).
- [ ] No internal/implementation strings (controller-revision-hash, lease holderIdentity, internal label keys) are referenced as if they were public contracts — either use the public Go constant or acknowledge the fragility.
- [ ] No offline-discussion notes leak into the public DEP body — move to a linked decision record.
- [ ] Every failure scenario answers: who detects? timeout? backoff? surfacing channel? indefinite-block analysis?
- [ ] Every decision arrow in every diagram has a label.
- [ ] Alternatives section has ≥3 entries including at least one "existing primitive / extend existing controller / inverse design" option.
- [ ] Feature gate section names the default-flip release and justifies gate-vs-field.
- [ ] Cross-repo lens includes adjacent-system impact (VPA, CA, PDB, CSI, self-hosted).
- [ ] Voice is factual and declarative — no editorializing about Kubernetes / etcd existing behavior.
- [ ] Every claim about Kubernetes / etcd behavior has a link to upstream code or docs.

---

## Review Mode

Score an existing DEP against the full rubric.

### Step 1: Read the DEP

Read the target file (user provides path or DEP number).

### Step 2: Score Against Rubric

Apply all 25 dimensions from [BEST-PRACTICES.md](BEST-PRACTICES.md):
- For each dimension: **Present & Strong** (2), **Present but Weak** (1), **Missing** (0)
- Note specific evidence for each score
- Total range: 0–50

### Step 3: Four-Lens Cross-Repo Review

For each affected repo / system, check:
- **etcd-druid:** CRD changes, controller impact, RBAC, component order, controller-boundary races
- **etcd-backup-restore:** CLI flags, endpoints, snapshot format, GC behavior
- **etcd-wrapper:** etcd config, peer URLs, TLS, initialization flow
- **Adjacent systems:** VPA / Cluster Autoscaler / PDB interaction, CSI corner cases, self-hosted variant, Gardener-specific assumptions

### Step 4: Operational Checks

- **Public-API discipline:** Are CRD fields, label keys, status reasons, and named conventions free of implementation-detail leakage? (Dimension 17)
- **Terminology precision:** Does every coined term have an operational test and not contradict upstream meaning? (Dimension 18)
- **Controller boundaries:** If a new controller is introduced, is the coordination signal with existing reconcilers documented? (Dimension 19)
- **Feature gate:** Is one needed? Default off in alpha? Default-flip release named? Gate-vs-field justified? Mid-flight toggle behavior?
- **Breaking changes:** Any signals present? Migration path?
- **CEL validations:** New fields validated? Immutability enforced?
- **Rollback safety:** What happens if disabled after being enabled — including mid-flight?
- **Failure scenarios:** Timeout / backoff / surfacing / indefinite-block analysis present?
- **Metrics design:** Naming convention? Labels include {namespace, name}? Computability for stateless controllers?
- **Decision records:** Internal deliberation moved out of public DEP body?

### Step 5: Present Report

Format:

```
## DEP Review: DEP-NN — Title

### Score: XX/50 (Rating)

### Strengths
- ...

### Gaps (ordered by impact)
1. [Dimension N — Missing] Specific issue + suggested fix
2. [Dimension M — Weak] What's missing + example of what good looks like

### Cross-Repo Findings
- etcd-druid: ...
- etcd-backup-restore: ...
- etcd-wrapper: ...
- Adjacent systems: ... (VPA / CA / PDB / CSI / self-hosted as applicable)

### Diagram Recommendations
- Missing labels on: <arrow / node>
- Missing: [type] diagram for [content]
- Suggestion: [Mermaid code block]

### Voice & Style
- (Any editorializing language to make factual?)
- (Any unsupported claims about K8s / etcd behavior — needs upstream link?)
```

---

## Integration with Other Skills

| After DEP is... | Invoke |
|-----------------|--------|
| Approved by maintainers | `/etcd-druid:plan` to create implementation plan |
| Involving API changes | `/etcd-druid:api-change` for CEL/two-commit details |
| Ready for implementation | `/etcd-druid:implement` with the plan |

## Red Flags — Stop and Re-read

| Thought | Why it fails |
|---|---|
| "I'll write the code first, DEP later" | DEP exists to validate design before wasting implementation time. |
| "Only etcd-druid is affected" | API changes flow to sidecars. Always check all three repos plus adjacent systems. |
| "The DEP is good enough at 22/50" | Below 32 = Needs Work. Gaps in design surface as bugs in code. |
| "Diagrams are optional" | They're not. One Mermaid diagram minimum is a hard requirement. Every decision arrow must be labelled. |
| "This implementation detail belongs in the public CRD" | If swapping the underlying mechanism would break the field, it's an internal detail. Hide it behind a feature gate. |
| "Two controllers can both write to this object — they'll cooperate" | Until proven otherwise, that's a race. Document the coordination signal or merge the work into one reconciler. |
| "My new term is self-explanatory" | If you can't write the one-line operational test, reviewers will rewrite the term for you. |
| "I'll inline the offline-discussion outcome here" | Decision records live in `docs/decisions/` or linked discussions, not in the public DEP body. |
