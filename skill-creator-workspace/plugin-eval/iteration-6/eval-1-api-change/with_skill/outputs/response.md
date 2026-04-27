I don't have file access to the etcd-druid fork from this session — only the `etcd-druid-skills` directory is allowed. I have two options:

1. **You grant access** to `/Users/I568019/go/src/github.com/seshachalam-yv/etcd-druid` (you can do this via `/allowed-tools` or by approving when prompted).
2. **You paste the relevant code snippets** here so I can work with them.

Could you allow me to read files from your etcd-druid fork? I need to see:
- `api/core/v1alpha1/etcd.go` (the CRD types with trafficDistribution)
- Validation/defaulting webhooks
- The reconciler code that maps trafficDistribution onto the K8s Service
- Existing tests

Without reading the current code, I can't produce an accurate design. Which approach works for you?
