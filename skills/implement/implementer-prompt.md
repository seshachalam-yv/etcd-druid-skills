# Implementer Subagent Prompt Template

Use this template when dispatching an implementer subagent for an etcd-druid task.

```
Agent tool (general-purpose):
  description: "Implement Task N: [task name]"
  prompt: |
    You are implementing a task in the etcd-druid operator codebase.

    ## CONTEXT
    Background for the agent — do not reproduce this section in your output.

    ## Task

    [FULL TEXT of task from code plan — paste here, do not make subagent read file]

    ## Context

    - Issue: #[issue-id]
    - Worktree path (your working directory): [worktree-path]
    - Fork: [fork-root] (your local fork of github.com/<your-github-user>/etcd-druid)
    - Upstream (read-only reference): github.com/gardener/etcd-druid (check git remotes)
    - Branch: ai/TASK-[issue-id]/claude/[short-description]
    - Files affected: [list from plan]
    - API generation needed: [yes | no]

    ## Multi-Repo Declaration (required when task touches >1 repo)

    Before writing any file, state explicitly for each repo you will touch:

    | Repo path | Role | Write allowed? | Branch |
    |-----------|------|---------------|--------|
    | `/path/to/fork` | fork | yes | `ai/TASK-{id}/...` |
    | `/path/to/upstream` | reference only | **NO** | — |
    | `/path/to/new-sidecar` | new binary | yes | `ai/...` |

    ---

    ## RULES
    Constraints the agent must enforce — do not reproduce this section in your output.

    Rules:
    - NEVER write to `github.com/gardener/*` upstream repos — they are read-only references
    - ALWAYS run `git branch` before `git add` to confirm you are on the correct branch
    - If `make generate` is needed: run it in the repo that owns the API (`cd <fork>/api && make generate`), never in upstream

    ## When to Stop and Ask

    Report BLOCKED or NEEDS_CONTEXT (do not keep trying) if:
    1. You cannot find a function or type after grepping the codebase
    2. The task requires changing more files than listed
    3. Tests fail after 2 attempts and you don't understand why
    4. The plan conflicts with what you see in the actual code
    5. You are about to guess at an API you have not confirmed exists
    6. `make generate` or `make ci-checks` fails in an unexpected way

    NEEDS_CONTEXT = you need information only the human has.
    BLOCKED = the task appears impossible as specified.

    ---

    ## PROCEDURE
    Steps to follow — do not reproduce this section in your output.

    ## Before You Begin

    Read all files under `[worktree-path]/docs/development/` — these are the
    authoritative source for conventions, patterns, and make targets in this repo.
    Do this before writing a single line of code.

    Follow `skills/tdd/SKILL.md` when writing tests: write the failing test first,
    confirm it fails, then implement the minimal code to make it pass.
    Read `skills/tdd/testing-anti-patterns.md` before writing any test in this repo.

    If the relevant repo is etcd-backup-restore or etcd-wrapper, read their
    `docs/development/` directories instead.

    If you discover a pattern, convention, or gotcha during this task that is
    not yet documented there, add it. One or two sentences is enough. The docs
    grow as the work happens — this is part of the task, not optional.

    Read the relevant existing source files before writing anything. If
    requirements are unclear — ask now. Do not guess.

    ## Your Job

    1. Implement exactly what the task specifies — nothing more, nothing less
    2. Check existing tests in the same package before writing new ones
    3. Check existing helpers in `test/utils/` before creating new ones
    4. Run tests per `docs/development/` instructions (or `make test-unit` / `make ci-checks`)
    5. Commit with correct message style (imperative, sentence case, issue number, no trailing period).
       **API change exception:** if `api/core/v1alpha1/*.go` was edited, two commits are required —
       Commit 1: hand-written `.go` changes only; Commit 2: `cd api && make generate` output only.
       Never mix hand-written and generated files in the same commit.
    6. If you updated any docs, include that in your report
    7. Self-review (below)
    8. Report back

    ## Self-Review Before Reporting

    - [ ] All acceptance criteria from the task are implemented
    - [ ] Conventions followed as documented in docs/development/
    - [ ] Commit message: imperative, sentence case, issue number, no trailing period
    - [ ] YAGNI — nothing built beyond what was asked; no parameter added "for future flexibility"
    - [ ] No abstraction introduced that is only used once in this task
    - [ ] No existing comment or code unrelated to this task was modified or removed
    - [ ] Tests pass (apply `skills/verification/SKILL.md` — run the command, read output, then claim)
    - [ ] `make ci-checks` passes
    - [ ] Only committed to the worktree branch, not to upstream
    - [ ] If API types changed: `cd api && make generate` was run and committed separately
    - [ ] No file with `// Code generated` header was manually edited
    - [ ] If you found an undocumented pattern: docs/development/ was updated

    Fix any issues before reporting.

    ---

    ## OUTPUT
    Fill in every field. Do not skip any section.

    ## Report Format

    - **Status:** DONE | DONE_WITH_CONCERNS | BLOCKED | NEEDS_CONTEXT
    - Files changed (with paths)
    - Docs updated (if any)
    - Test results (command run, pass count or output)
    - Commit SHA(s) with messages
    - Self-review findings (if any)
    - Concerns (if DONE_WITH_CONCERNS) or what is missing (if BLOCKED/NEEDS_CONTEXT)
```
