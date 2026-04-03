# etcd-druid-skills

A Claude Code plugin that encodes expert knowledge for [etcd-druid](https://github.com/gardener/etcd-druid) contributors. It injects domain awareness, best practices, and workflow skills into every Claude session — so you spend less time on "how does this work" and more time on "what needs to be done."

## What It Does

- **Session orientation** — On every session start, Claude receives a concise briefing on the three-component system (etcd-druid, etcd-backup-restore, etcd-wrapper), working directories, key invariants, and available skills.
- **Domain skills** — Reusable, invocable skills covering the full development lifecycle: feature design through PR, TDD patterns, systematic debugging, pre-PR review, and deep domain reference.
- **Self-improvement loop** — When Claude encounters a pattern not covered by any skill, it flags it inline and prompts you to open a PR to add it.

## The Three-Component System

```
etcd-druid          Kubernetes operator — owns the Etcd CRD, reconciles all cluster resources
etcd-backup-restore Sidecar — manages snapshots, restore, and etcd initialization
etcd-wrapper        Sidecar — initializes etcd via backup-restore HTTP API, then runs embedded etcd
```

All three run in Gardener's **seed cluster**. etcd-druid is reconciled by gardenlet; changes must not break gardenlet's reconciliation assumptions.

## Skills

| Skill | Invoke | Use when |
|-------|--------|----------|
| `feature-dev` | `/etcd-druid:feature-dev` | Starting any feature or bug fix — design → plan → implement → verify → PR |
| `tdd` | `/etcd-druid:tdd` | Writing or fixing tests in any of the three repos |
| `debug` | `/etcd-druid:debug` | etcd pod not ready, snapshots failing, reconciliation stuck, restore not triggering |
| `review` | `/etcd-druid:review` | Before submitting work — safety invariants checklist |
| `reference` | `/etcd-druid:reference` | Deep lookup: backup-restore API, CRD spec, TLS, component authoring, store providers |
| `mistakes` | `/etcd-druid:mistakes` | Common errors per component + Gardener anti-patterns (v2) |

## Installation

```bash
claude /install-plugin https://github.com/seshachalam-yv/etcd-druid-skills
```

Then reload plugins:

```bash
/reload-plugins
```

## Key Invariants

- New components must implement the `Operator` interface: `PreSync`, `Sync`, `TriggerDelete`, `GetExistingResourceNames`
- API changes in `api/core/v1alpha1/` require CEL validation annotations
- **etcd-druid tests:** Go native `testing.T` + Gomega — no Ginkgo
- **etcd-wrapper tests:** Go native `testing.T` + Gomega
- **etcd-backup-restore tests:** Ginkgo v2 + Gomega
- Errors: `fmt.Errorf("failed to X: %w", err)` — never swallow silently
- Commits: imperative sentence case, issue number at end: `Fix X (#1350)`
- Branch naming: `ai/TASK-{issue-id}/{short-description}` in fork
- NEVER commit to upstream; NEVER push without explicit human approval

## Contributing

Found a gap, wrong pattern, or missing best practice? Open a PR.

For mistake entries, use the template in `skills/mistakes/SKILL.md`.  
For skill improvements, edit the relevant `skills/<name>/SKILL.md` directly.

## License

Apache-2.0
