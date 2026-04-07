---
name: verification
description: Shared verification gate — referenced by tdd, debug, and feature-dev. Not user-invocable.
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

## The 5-Step Gate

BEFORE claiming work is complete, a test passes, or a check is clean:

1. IDENTIFY the verification command
   - etcd-druid unit: `make test-unit`
   - etcd-druid lint:  `make ci-checks`
   - etcd-druid integration: `make test-integration`
   - etcd-backup-restore: `make verify`
   - etcd-wrapper: `make test && make check`

2. RUN it in this message — not a previous one

3. READ the full output — not just the exit code
   - Look for `FAIL`, `--- FAIL`, `Error`, `WARN` in the output
   - Count passing vs failing tests
   - Read any stack traces

4. VERIFY the claim against the output
   - "All tests pass" requires zero failures in the output
   - "ci-checks passes" requires no diff and no lint errors

5. THEN make the claim — with the command and result as evidence
