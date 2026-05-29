---
name: glossary
description: Use when domain terms are ambiguous, during onboarding, or when writing issues/PRs that need precise terminology. Maintains the canonical CONTEXT.md glossary for the etcd-druid ecosystem.
user-invocable: true
effort: low
---

# Domain Glossary — etcd-druid Ecosystem

## Iron Law

**NO AMBIGUOUS TERM LEFT UNDEFINED.**

Every domain term used in conversation, issues, PRs, or code comments MUST have a
single canonical definition. If a term could mean two things, it goes in the glossary.

---

## When to Use This Skill

- A domain term appears in conversation that could be misunderstood
- Onboarding a new contributor who needs precise vocabulary
- Writing an issue, PR description, or DEP that uses ecosystem-specific terminology
- Reviewing code where naming is inconsistent with established glossary
- Resolving a disagreement about what a term means

---

## CONTEXT.md Format

Each entry in [CONTEXT.md](CONTEXT.md) follows this structure:

```markdown
### <Term>
**Definition:** <precise one-sentence definition specific to etcd-druid>
**Avoid:** <wrong or ambiguous aliases people mistakenly use>
**Relationships:** <how it connects to other glossary terms>
**Example:** <one-line usage showing the term in context>
```

Rules for entries:
- Only project-specific terms belong here (not general Go or Kubernetes terms unless
  etcd-druid uses them with a different or narrower meaning)
- The "Avoid" section lists common wrong names, abbreviations, or conflations that
  cause confusion in practice
- Definitions must be precise enough to distinguish similar concepts (e.g., full
  snapshot vs. delta snapshot)

---

## Workflow

1. **Identify** — notice an ambiguous or unfamiliar domain term in the conversation
2. **Check** — look up the term in [CONTEXT.md](CONTEXT.md)
3. **If missing** — define it following the format above and add it to CONTEXT.md
4. **If wrong or stale** — correct the definition with a brief note on what changed
5. **Cite** — when answering, use the canonical term and reference the glossary

When adding a new term, consider:
- Does it overlap with an existing entry? If so, clarify the boundary.
- Are there common aliases that should go in "Avoid"?
- What other glossary terms does it relate to?

---

## Rules

1. **Scope:** Only terms specific to the etcd-druid ecosystem. Generic Kubernetes
   concepts (Pod, Deployment, Service) stay out unless etcd-druid gives them special
   meaning.
2. **Precision over brevity:** A definition that is too short to distinguish from a
   related concept is worse than no definition.
3. **Avoid section is mandatory:** Every term has at least one common wrong name or
   conflation. If you cannot think of one, the term may not need a glossary entry.
4. **One canonical name:** If two names refer to the same thing, pick one as canonical
   and list the other under "Avoid."
5. **Living document:** CONTEXT.md is updated in-place. No versioning of individual
   entries; git history provides that.

---

## Handoff

- After defining terms, hand off to `/etcd-druid:plan` or `/etcd-druid:implement` if
  the clarified terminology unblocks design or coding work.
- If a term definition reveals an API naming inconsistency, consider raising it via
  `/etcd-druid:brainstorm` before changing code.
- Reference this glossary from `/etcd-druid:dep` when writing Druid Enhancement
  Proposals to ensure consistent terminology.
