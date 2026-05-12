---
name: prototype
description: Use when designing complex state machines, reconciliation flows, or multi-step controller logic — builds a throwaway Go CLI to drive the state model through edge cases before implementing in the real controller. Not for UI work.
user-invocable: true
effort: medium
---

# Prototype — LOGIC Branch for Go/Kubernetes

Build a throwaway CLI to explore state machines and reconciliation flows BEFORE touching the real controller.

## Iron Law

**NO COMPLEX STATE MACHINE WITHOUT EXPLORATION FIRST.**

| Rationalization | Why it fails |
|---|---|
| "I can see the transitions in my head" | You cannot. State machines have combinatorial edge cases that only surface when driven |
| "The spec covers everything" | Specs describe happy paths. Prototypes find the unhappy ones |
| "It's just three states" | Three states with two error modes and a timeout is nine transitions minimum |
| "I'll refactor the controller if it's wrong" | Refactoring a reconciler mid-flight risks regressions in production clusters |

## When to Use

- New EtcdOpsTask state transitions (Pending -> InProgress -> Succeeded/Failed/Rejected)
- New reconciliation flow with multiple branches
- Multi-step operations (backup -> compact -> defrag -> restore)
- Component lifecycle with complex ordering

## The Pattern (LOGIC Branch for Go)

- Create a throwaway `cmd/prototype-<name>/main.go` (never merged)
- Pure state machine module behind a simple CLI (stdin commands, stdout state)
- The state module is portable — liftable into the real controller once validated
- Full state dump after each transition
- No Kubernetes dependencies in the prototype — pure Go logic

## Workflow

1. **Define states and transitions as Go types** — enumerate every state, every event, every guard condition
2. **Build the CLI driver** — reads commands like "init", "snapshot", "fail", "recover" from stdin
3. **Print full state after each command** — the entire state struct, not just the current state name
4. **Drive through every edge case manually** — concurrent tasks, timeouts, double-failures, re-entry
5. **Extract the validated state module** into the real implementation
6. **Delete the prototype** — it was throwaway from day one

## Template Structure

```
cmd/prototype-<name>/
├── main.go          (CLI driver — throwaway)
├── state.go         (state machine — liftable)
└── state_test.go    (table-driven edge cases)
```

## Rules

- **Throwaway from day one** — never merge the `cmd/` directory
- **One command to run:** `go run ./cmd/prototype-<name>/`
- **No persistence** — state lives in memory only
- **No external dependencies** — pure Go standard library
- **Surface the state** — print full state struct after every transition
- **Delete or absorb when done** — the state module moves to `internal/`, the CLI dies

## Example Commands (EtcdOpsTask Prototype)

```
> create snapshot-task
State: {Type: OnDemandSnapshot, State: Pending, ...}

> start
State: {Type: OnDemandSnapshot, State: InProgress, StartTime: ...}

> succeed
State: {Type: OnDemandSnapshot, State: Succeeded, CompletionTime: ...}

> create snapshot-task  (while another is active)
State: {Type: OnDemandSnapshot, State: Rejected, Reason: "another task active"}
```

## Handoff

- **State machine validated** — extract the state module, invoke `/etcd-druid:plan` for real implementation
- **Found unexpected edge cases** — document them in the plan's acceptance criteria before implementing
