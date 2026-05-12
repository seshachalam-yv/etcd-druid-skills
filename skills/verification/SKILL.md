---
name: verification
description: Shared verification gate — referenced by tdd, debug, implement, and receiving-review. Not user-invocable.
user-invocable: false
---

# Verification Gate

## ⛔ Iron Law

**NO COMPLETION CLAIMS WITHOUT FRESH VERIFICATION EVIDENCE.**

| Rationalization | Why it fails |
|---|---|
| "I ran it earlier and it passed" | Earlier runs do not count. Run it in this message. |
| "The exit code was 0" | Exit code 0 with failing subtests is possible. Read the full output. |
| "Nothing changed since the last run" | You cannot know that without running it. |
| "It's obviously fine" | "Obviously" precedes most verification failures. |

## Red Flags — Stop and Re-read

| Thought | Why it fails |
|---|---|
| "It passed last time I ran it" | Last time is not this time. Run it now |
| "I only changed a comment" | Comments in Go can break generated code. Verify |
| "The CI will verify" | CI runs after push. Broken pushes block reviewers |
| "I can see it's correct from the code" | Reading is not running. Run the command |

## Worktree Context

Verification commands must run in the active worktree, not the fork root. If a worktree is active (from `implement`, `debug`, `tdd`, or any code-modifying skill), `cd` into it before running any verification command. Use `git diff upstream/master...HEAD` to confirm you are verifying the right changes.

## The 5-Step Gate

BEFORE claiming work is complete, a test passes, or a check is clean:

1. IDENTIFY the verification command
   - etcd-druid unit: `make test-unit`
   - etcd-druid lint:  `make ci-checks`
   - etcd-druid integration: `make test-integration`
   - etcd-druid generated files: `cd api && make check-generate` (fails if `make generate` would produce a diff — run this if `api/` was touched)
   - etcd-backup-restore: `make verify`
   - etcd-wrapper: `make test && make check`

2. RUN it in this message — not a previous one

3. READ the full output — not just the exit code
   - Look for `FAIL`, `--- FAIL`, `Error` in the output
   - Count passing vs failing tests
   - Read any stack traces

4. VERIFY the claim against the output
   - "Tests pass" requires zero test failures in the output (`FAIL` / `--- FAIL` absent)
   - "ci-checks passes" requires no diff and no lint errors reported
   - "Integration tests pass" requires zero failures in the envtest output
   - "verify passes" (etcd-backup-restore) requires both check and test-unit to show no failures
   - "check-generate passes" requires exit 0 with no "would regenerate" output
   - Any positive claim requires the specific evidence from the output that supports it

5. THEN make the claim — with the command and result as evidence

## Handoff

After all required verification commands pass for the repo being worked on:

- **From `tdd`** — return to the TDD cycle (test passes → next test)
- **From `receiving-review`** — CI clean → proceed to Step 5 (respond with evidence)
- **From `/etcd-druid:implement`** — all gates pass → proceed to Gate 2 and PR creation
