# Diagram Guide for DEPs

Every DEP MUST include at least one Mermaid diagram. Use the table below to choose the right type based on your proposal content.

> **Anti-pattern: redundant diagrams.** A diagram earns its place by making
> branching, ordering, or state visible at a glance. If your diagram only
> restates two or three sentences of surrounding prose, remove it — reviewers
> will ask "do we need this?" and they will be right. Diagrams should add
> structure that the text alone cannot convey.

## When to Use Which Diagram

| Proposal content | Diagram type | Mermaid syntax |
|-----------------|--------------|----------------|
| Component has discrete lifecycle phases | State diagram | `stateDiagram-v2` |
| Multi-step orchestration across components | Flowchart | `flowchart TD` |
| Request/response between 2-3 actors | Sequence diagram | `sequenceDiagram` |
| New component in existing ecosystem | Architecture diagram | `flowchart LR` with subgraphs |
| Decision logic with branches | Flowchart with decisions | `flowchart TD` with `{}` diamond nodes |
| Failure recovery paths | Flowchart | `flowchart TD` |

## Rules

1. At least one diagram per DEP (hard requirement)
2. State diagrams for any proposal with lifecycle phases
3. Sequence diagrams for cross-component interaction with specific message ordering
4. Use Mermaid syntax (renders in GitHub markdown)
5. Diagrams inline in proposal body (unless >30 lines, then separate file in `assets/`)
6. Label all transitions with the triggering event or condition
7. Include error/failure transitions, not just happy path

## Quality Checklist

Before committing a diagram, walk this list. These are the recurring nits
reviewers raise on DEP diagrams:

- [ ] **Every decision arrow has a label.** A diamond with one labelled arrow
      and one unlabelled arrow is the #1 reviewer complaint. Both `Yes`/`No`
      branches (or every named condition) must be on the arrow, not implied.
- [ ] **Every node names the entity it refers to.** "Is etcd process dead?"
      is ambiguous — which pod? Prefer "Is etcd process dead in selected
      pod?" or scope the question with prior context in the diagram.
- [ ] **Failure paths are present.** Not just the happy path — show what
      happens when a step fails, retries, or escalates.
- [ ] **The diagram earns its place.** If it only restates the surrounding
      prose without adding branching, ordering, or state structure, remove
      it (see anti-pattern at the top of this file).
- [ ] **Source file is committed alongside the rendered image.** If you use
      Excalidraw / draw.io / external tooling to produce a `.png` in
      `docs/proposals/assets/`, also commit the source file (`.excalidraw`,
      `.drawio`, or the Mermaid block) so future authors can edit it.
- [ ] **Inline Mermaid for diagrams that fit.** Prefer inline Mermaid blocks
      over external `.png` files when the diagram is under ~30 lines —
      Mermaid renders in GitHub and stays diff-friendly.

## Patterns by Scenario

### Lifecycle / State Machine

Use when: EtcdMember states, EtcdOpsTask states, migration phases, feature gate transitions.

```mermaid
stateDiagram-v2
    [*] --> Pending
    Pending --> InProgress: Controller picks up task
    InProgress --> Succeeded: Task completes
    InProgress --> Failed: Unrecoverable error
    Pending --> Rejected: Pre-conditions not met
    Failed --> [*]
    Succeeded --> [*]
    Rejected --> [*]
```

### Cross-Component Interaction

Use when: druid ↔ backup-restore communication, scale-up handshake, snapshot trigger flow.

```mermaid
sequenceDiagram
    participant Druid as etcd-druid
    participant BR as etcd-backup-restore
    participant Etcd as etcd (via wrapper)
    participant Store as Object Store

    Druid->>BR: POST /snapshot (via EtcdOpsTask)
    BR->>Etcd: Take snapshot
    Etcd-->>BR: Snapshot data
    BR->>Store: Upload snapshot
    Store-->>BR: Upload confirmed
    BR-->>Druid: Update EtcdOpsTask status → Succeeded
```

### Reconciliation / Decision Flow

Use when: Controller reconciliation logic, pre-condition evaluation, feature gate behavior.

```mermaid
flowchart TD
    A[Reconcile triggered] --> B{Feature gate enabled?}
    B -->|No| C[Skip — use legacy path]
    B -->|Yes| D{Pre-conditions met?}
    D -->|No| E[Set status: Rejected]
    D -->|Yes| F[Execute task]
    F --> G{Success?}
    G -->|Yes| H[Set status: Succeeded]
    G -->|No| I{Retriable?}
    I -->|Yes| J[Requeue with backoff]
    I -->|No| K[Set status: Failed]
```

### Architecture / Component Relationships

Use when: Introducing new sidecar, new controller, or showing how components interact in a cluster.

```mermaid
flowchart LR
    subgraph Seed Cluster
        subgraph etcd Pod
            W[etcd-wrapper]
            BR[etcd-backup-restore]
            E[etcd process]
        end
        D[etcd-druid controller]
        STS[StatefulSet]
    end
    subgraph External
        OS[Object Store]
    end

    D -->|reconciles| STS
    STS -->|manages| W
    W -->|starts| E
    BR -->|snapshots| E
    BR -->|uploads to| OS
    D -->|creates EtcdOpsTask| BR
```

### Breaking Change Impact

Use when: Showing which components are affected by an API or behavioral change.

```mermaid
flowchart TD
    Change[API Field Added/Modified] --> Druid[etcd-druid]
    Change --> BR[etcd-backup-restore]
    Change --> Wrapper[etcd-wrapper]

    Druid --> |CRD update| CRD[make generate]
    Druid --> |Controller logic| Ctrl[Reconciler change]
    Druid --> |Validation| CEL[CEL rules]

    BR --> |CLI flag| Flag[New etcdbrctl flag]
    BR --> |Behavior| Snap[Snapshot handling]

    Wrapper --> |Config| Cfg[etcd config template]
```

### CEL Validation Decision Tree

Use when: Deciding what type of CEL validation to apply to new/changed fields.

```mermaid
flowchart TD
    A[New/changed field] --> B{Mutable after creation?}
    B -->|No| C["Add CEL: self == oldSelf"]
    B -->|Yes| D{Cross-field dependency?}
    D -->|Yes| E[Add XValidation rule at parent level]
    D -->|No| F{Enum or bounded range?}
    F -->|Yes| G["Add +kubebuilder:validation:Enum or Min/Max"]
    F -->|No| H[Field-scoped format validation only]
    C --> I[Document in DEP API Changes section]
    E --> I
    G --> I
    H --> I
```
