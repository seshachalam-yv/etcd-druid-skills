Here's what I've gathered from the project context:

**What I know:**
- This is **etcd-backup-restore** (not etcd-druid) — uses vendoring (`make revendor`), Ginkgo v2 for tests, and has its own conventions
- `failBelowRevision` was added in PR #184 ~5 years ago, hasn't been used since, and issue #1013 tracks its removal
- The feature touches: CLI options (`cmd/options.go`), initializer (`pkg/initializer/`), data validator (`pkg/initializer/validator/`), HTTP API (`pkg/server/httpAPI.go`), helm chart values, and integration tests
- This is a **breaking change** requiring a CHANGELOG entry
- etcd-backup-restore tests use **Ginkgo v2 + Gomega** with NEGATIVE: prefix convention

**My assumptions before we proceed:**
1. This is a clean removal — no replacement feature, no deprecation period (it was never adopted)
2. No consumers in etcd-druid or etcd-wrapper currently reference `failBelowRevision` (we should verify)
3. The helm chart changes won't affect etcd-druid's chart rendering since etcd-druid is the primary chart consumer
4. This doesn't require a major version bump — just a clear breaking-change release note

Before I propose approaches, one clarifying question:

**Is there any downstream consumer (etcd-druid, etcd-wrapper, or Gardener itself) that passes `failBelowRevision` to etcd-backup-restore?** For example, does etcd-druid set this value in the sidecar container args or pass it via the HTTP initialization endpoint? If so, that would expand the scope beyond just etcd-backup-restore.
